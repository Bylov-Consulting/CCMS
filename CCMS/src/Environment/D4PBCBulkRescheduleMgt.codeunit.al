namespace D4P.CCMS.Environment;

codeunit 62004 "D4P BC Bulk Reschedule Mgt"
{
    var
        // Per-env fetch result carried across the TryFunction boundary. AL's
        // [TryFunction] semantics make it awkward to pass a var Record param to a
        // function that also invokes an interface method, so we stage the result here.
        TempFetchBuffer: Record "D4P BC Available Update" temporary;
        // Companion to TempFetchBuffer: the raw JSON payload for the most recent fetch,
        // staged across the TryFunction boundary so BuildPlan can push it into the per-env
        // cache consumed by the dialog's AssistEdit drilldown.
        TempFetchRawResponse: Text;
        // Per-env raw JSON cache populated during BuildPlan and forwarded to the dialog so
        // AssistEdit drilldowns can re-parse without a second API round-trip.
        FetchCache: Dictionary of [Text, Text];
        AdminAPI: Interface "D4P IBC Admin API";
        AdminAPIInjected: Boolean;
        UnknownErrorLbl: Label 'unknown error';
        EnvGoneErr: Label 'Environment %1 no longer exists in the local database.', Comment = '%1 = Environment Name';

    /// <summary>
    /// Test seam: injects a custom API implementation. Intended for CCMS.Test only.
    /// In production, the default <see cref="Codeunit::D4P BC Admin API"/> is used
    /// automatically via <c>EnsureAdminAPI</c>. Calling this from a non-test context
    /// is supported but semantically risky — a non-authenticating or mis-routed
    /// implementation would be used for every subsequent API call in this session.
    /// </summary>
    /// <param name="NewAPI">The implementation to use for all subsequent API calls.</param>
    procedure SetAdminAPI(NewAPI: Interface "D4P IBC Admin API")
    begin
        AdminAPI := NewAPI;
        AdminAPIInjected := true;
    end;

    /// <summary>
    /// Full flow: empty-selection guard, Confirm, BuildPlan -> user review via page 62032 ->
    /// ApplyPlan -> ShowSummary (page 62033).
    /// </summary>
    procedure RunBulkReschedule(var BCEnvironment: Record "D4P BC Environment")
    var
        TempPlan: Record "D4P BC Reschedule Plan Line" temporary;
        TempPendingCheck: Record "D4P BC Reschedule Plan Line" temporary;
        BulkDialog: Page "D4P Bulk Reschedule Dialog";
        FetchDialog: Dialog;
        DialogFetchCache: Dictionary of [Text, Text];
        EnvCount: Integer;
        NoSelectionErr: Label 'Select one or more environments before bulk rescheduling.';
        ConfirmMsg: Label 'Reschedule updates for %1 environment(s)?', Comment = '%1 = Number of environments';
        FetchingMsg: Label 'Fetching available updates for the selected environments...';
        NothingToRescheduleMsg: Label 'Nothing to reschedule — none of the selected environments has an update available.';
    begin
        EnsureAdminAPI();

        if BCEnvironment.IsEmpty() then
            Error(NoSelectionErr);

        EnvCount := BCEnvironment.Count();
        if not Confirm(ConfirmMsg, false, EnvCount) then
            exit;

        // BuildPlan itself does no UI — a single indeterminate progress dialog is adequate
        // because phase-1 is typically sub-second-per-env and partners have already confirmed.
        // Per-env progress would require threading the dialog through BuildPlan's signature,
        // which the test-engineer intentionally kept clean.
        FetchDialog.Open(FetchingMsg);
        BuildPlan(BCEnvironment, TempPlan);
        FetchDialog.Close();

        // If every row ended up Skipped (no available updates / all fetches failed) there's
        // nothing the user can act on, so short-circuit instead of opening a dead dialog.
        TempPendingCheck.Copy(TempPlan, true);
        TempPendingCheck.Reset();
        TempPendingCheck.SetRange(Result, TempPendingCheck.Result::Pending);
        if TempPendingCheck.IsEmpty() then begin
            Message(NothingToRescheduleMsg);
            exit;
        end;

        BulkDialog.SetData(TempPlan);
        // Forward the orchestrator's (potentially mocked) interface into the dialog so the
        // AssistEdit drilldown uses the same seam — no more bypass via `new Codeunit`.
        BulkDialog.SetAdminAPI(AdminAPI);
        // Warm the dialog's per-env cache with the raw JSONs BuildPlan already fetched —
        // turns a click-on-AssistEdit from a second API round-trip into a dictionary lookup.
        GetFetchCache(DialogFetchCache);
        BulkDialog.SetFetchCache(DialogFetchCache);
        if BulkDialog.RunModal() <> Action::OK then
            exit;

        BulkDialog.GetData(TempPlan);

        ApplyPlan(TempPlan);

        ShowSummary(TempPlan);
    end;

    /// <summary>
    /// Iterates BCEnvironment, populates TempPlan. Per-env fetch failures are caught
    /// via a TryFunction and recorded as Skipped rows (not propagated). Envs with an
    /// empty update list are also marked Skipped with a descriptive reason.
    /// </summary>
    procedure BuildPlan(var BCEnvironment: Record "D4P BC Environment"; var TempPlan: Record "D4P BC Reschedule Plan Line" temporary)
    var
        Parser: Codeunit "D4P BC Update Parser";
        TargetVersion: Text[100];
        DefaultDate: Date;
        ExpectedMonth: Integer;
        ExpectedYear: Integer;
        EntryNo: Integer;
        AvailableFlag: Boolean;
        FetchReason: Text;
        FetchFailedLbl: Label 'Fetch failed: %1', Comment = '%1 = Error message from GetLastErrorText';
        NoUpdatesLbl: Label 'No updates available';
    begin
        EnsureAdminAPI();

        TempPlan.Reset();
        TempPlan.DeleteAll(false);

        // Reset the per-env raw-JSON cache at the start of every BuildPlan run. Without
        // this, a second BuildPlan on the same orchestrator instance would serve stale
        // fixture data into AssistEdit drilldowns for the previous invocation's envs.
        Clear(FetchCache);

        if not BCEnvironment.FindSet() then
            exit;

        EntryNo := 0;
        repeat
            EntryNo += 1;

            TempPlan.Init();
            TempPlan."Entry No." := EntryNo;
            TempPlan."Customer No." := BCEnvironment."Customer No.";
            TempPlan."Tenant ID" := BCEnvironment."Tenant ID";
            TempPlan."Environment Name" := CopyStr(BCEnvironment.Name, 1, MaxStrLen(TempPlan."Environment Name"));
            TempPlan."Application Family" := BCEnvironment."Application Family";
            TempPlan."Current Version" := BCEnvironment."Current Version";
            TempPlan.Result := TempPlan.Result::Pending;

            ClearFetchBuffer();
            if not TryFetchUpdates(BCEnvironment) then begin
                FetchReason := GetLastErrorText();
                if FetchReason = '' then
                    FetchReason := UnknownErrorLbl;
                TempPlan.Result := TempPlan.Result::Skipped;
                TempPlan.Reason := CopyStr(StrSubstNo(FetchFailedLbl, FetchReason), 1, MaxStrLen(TempPlan.Reason));
            end else begin
                // Cache the raw JSON under the env name so AssistEdit drilldowns can re-parse
                // without another API hit. Populated regardless of whether the fetch returned
                // rows — a legitimate empty payload is still a valid cache hit.
                CacheRawResponse(BCEnvironment.Name, TempFetchRawResponse);

                if TempFetchBuffer.IsEmpty() then begin
                    TempPlan.Result := TempPlan.Result::Skipped;
                    TempPlan.Reason := CopyStr(NoUpdatesLbl, 1, MaxStrLen(TempPlan.Reason));
                end else begin
                    // Pick a default target version from the fetched candidates.
                    TargetVersion := '';
                    DefaultDate := 0D;
                    ExpectedMonth := 0;
                    ExpectedYear := 0;
                    Parser.PickDefaultTargetVersion(TempFetchBuffer, TargetVersion, DefaultDate, ExpectedMonth, ExpectedYear);

                    TempPlan."Target Version" := TargetVersion;
                    TempPlan."Selected Date" := DefaultDate;
                    TempPlan."Latest Selectable Date" := DefaultDate;
                    TempPlan."Expected Month" := ExpectedMonth;
                    TempPlan."Expected Year" := ExpectedYear;

                    // "Available" flips to true if we picked an available candidate (i.e. a Date was set).
                    AvailableFlag := DefaultDate <> 0D;
                    TempPlan.Available := AvailableFlag;
                end;
            end;

            TempPlan.Insert(false);
        until BCEnvironment.Next() = 0;
    end;

    /// <summary>
    /// Iterates TempPlan rows where Result = Pending. For each:
    ///  - Publishes OnBeforeApplyReschedule with Skip byref.
    ///  - If Skip=true: marks Skipped with 'Skipped by subscriber', continues.
    ///  - Else calls TryApply which invokes AdminAPI.SelectTargetVersion.
    ///  - On success marks Succeeded; on failure marks Failed with GetLastErrorText reason.
    ///  - Commit() after each apply for skip-and-continue durability across mid-run
    ///    hard failures (mirrors the plan's documented skip-and-continue contract).
    ///  - Publishes OnAfterApplyReschedule regardless of outcome.
    /// </summary>
    procedure ApplyPlan(var TempPlan: Record "D4P BC Reschedule Plan Line" temporary)
    var
        BCEnv: Record "D4P BC Environment";
        Skip: Boolean;
        ApplyReason: Text;
        SkippedBySubscriberLbl: Label 'Skipped by subscriber';
    begin
        EnsureAdminAPI();

        TempPlan.Reset();
        TempPlan.SetRange(Result, TempPlan.Result::Pending);
        if not TempPlan.FindSet() then
            // Early-exit: do NOT Reset() here — discarding caller filters would be surprising
            // in the Retry Failed flow. The end-of-procedure Reset() covers the happy path.
            exit;

        repeat
            Skip := false;
            OnBeforeApplyReschedule(TempPlan, Skip);

            if Skip then begin
                TempPlan.Result := TempPlan.Result::Skipped;
                TempPlan.Reason := CopyStr(SkippedBySubscriberLbl, 1, MaxStrLen(TempPlan.Reason));
                TempPlan.Modify(false);
                // Commit() — partial progress must be durable per skip-and-continue contract.
                Commit();
                OnAfterApplyReschedule(TempPlan);
            end else begin
                // Re-fetch the environment record so SelectTargetVersion can Modify it.
                // SetLoadFields constrains reads AND the set available for a subsequent
                // Modify — include every field SelectTargetVersion touches (read or write):
                //   Reads: "Customer No.", "Tenant ID", "Application Family", Name
                //   Writes: "Target Version", "Selected DateTime", "Expected Availability"
                BCEnv.SetLoadFields(
                    "Customer No.", "Tenant ID", "Application Family", Name,
                    "Target Version", "Selected DateTime", "Expected Availability");
                if not BCEnv.Get(TempPlan."Customer No.", TempPlan."Tenant ID", TempPlan."Environment Name") then begin
                    // Environment was deleted between BuildPlan and ApplyPlan (or from the UI
                    // mid-run). Emit an explicit, actionable reason instead of silently falling
                    // through to an opaque downstream "BCTenant.Get failed" inside the interface.
                    TempPlan.Result := TempPlan.Result::Failed;
                    TempPlan.Reason := CopyStr(StrSubstNo(EnvGoneErr, TempPlan."Environment Name"), 1, MaxStrLen(TempPlan.Reason));
                    TempPlan.Modify(false);
                    // Commit() — partial progress must be durable per skip-and-continue contract.
                    Commit();
                    OnAfterApplyReschedule(TempPlan);
                end else begin
                    if TryApply(TempPlan, BCEnv) then begin
                        TempPlan.Result := TempPlan.Result::Succeeded;
                        TempPlan.Reason := '';
                    end else begin
                        ApplyReason := GetLastErrorText();
                        if ApplyReason = '' then
                            ApplyReason := UnknownErrorLbl;
                        TempPlan.Result := TempPlan.Result::Failed;
                        TempPlan.Reason := CopyStr(ApplyReason, 1, MaxStrLen(TempPlan.Reason));
                    end;
                    TempPlan.Modify(false);
                    // Commit() — partial progress must be durable per skip-and-continue contract.
                    Commit();
                    OnAfterApplyReschedule(TempPlan);
                end;
            end;
        until TempPlan.Next() = 0;

        TempPlan.Reset();
    end;

    /// <summary>
    /// Runs the summary page for TempPlan. The summary page receives a fresh orchestrator
    /// instance for its Retry Failed action; ApplyPlan calls EnsureAdminAPI() on every
    /// invocation, so a fresh instance re-binds the default Admin API correctly. AL has
    /// no "self" reference for codeunits, hence the local instance. We also forward our
    /// (possibly injected) AdminAPI interface so Retry Failed stays on the same seam.
    /// </summary>
    procedure ShowSummary(var TempPlan: Record "D4P BC Reschedule Plan Line" temporary)
    var
        RetryOrchestrator: Codeunit "D4P BC Bulk Reschedule Mgt";
        SummaryPage: Page "D4P Bulk Reschedule Summary";
    begin
        // Defensive: the summary is a modal UI. If this codeunit is ever invoked from a
        // job queue, API endpoint, or other headless context, skip the page instead of
        // hard-erroring on RunModal. Callers that need headless behavior should consume
        // TempPlan directly.
        if not GuiAllowed() then
            exit;

        EnsureAdminAPI();
        SummaryPage.SetData(TempPlan);
        SummaryPage.SetOrchestrator(RetryOrchestrator);
        SummaryPage.SetAdminAPI(AdminAPI);
        SummaryPage.RunModal();
    end;

    /// <summary>
    /// Publishes before each apply. Subscribers set Skip := true to veto an individual env.
    /// </summary>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeApplyReschedule(var PlanLine: Record "D4P BC Reschedule Plan Line" temporary; var Skip: Boolean)
    begin
    end;

    /// <summary>
    /// Publishes after each apply. For observability / audit sinks.
    /// </summary>
    [IntegrationEvent(false, false)]
    local procedure OnAfterApplyReschedule(var PlanLine: Record "D4P BC Reschedule Plan Line" temporary)
    begin
    end;

    /// <summary>
    /// [TryFunction] wrapper around AdminAPI.SelectTargetVersion. Converts a false return
    /// into an Error so the orchestrator sees a uniform success/failure signal via the
    /// TryFunction result and GetLastErrorText().
    /// </summary>
    [TryFunction]
    local procedure TryApply(var PlanLine: Record "D4P BC Reschedule Plan Line" temporary; var BCEnv: Record "D4P BC Environment")
    var
        APIFailureErr: Label 'Admin API reported the reschedule request failed.';
        Success: Boolean;
    begin
        Success := AdminAPI.SelectTargetVersion(
            BCEnv,
            PlanLine."Target Version",
            PlanLine."Selected Date",
            PlanLine."Expected Month",
            PlanLine."Expected Year");
        if not Success then
            Error(APIFailureErr);
    end;

    /// <summary>
    /// [TryFunction] wrapper around AdminAPI.GetAvailableUpdates. Stages the result
    /// in TempFetchBuffer because AL forbids passing a var Record param into a TryFunction's
    /// own var param together with an interface invocation.
    /// </summary>
    [TryFunction]
    local procedure TryFetchUpdates(var BCEnvironment: Record "D4P BC Environment")
    begin
        AdminAPI.GetAvailableUpdates(BCEnvironment, TempFetchBuffer, TempFetchRawResponse);
    end;

    local procedure ClearFetchBuffer()
    begin
        TempFetchBuffer.Reset();
        TempFetchBuffer.DeleteAll(false);
        TempFetchRawResponse := '';
    end;

    /// <summary>
    /// Stage a raw-JSON payload for an env into the per-run cache. Later handed to the
    /// dialog via GetFetchCache so AssistEdit can re-parse without re-hitting the API.
    /// </summary>
    local procedure CacheRawResponse(EnvName: Text; RawResponse: Text)
    begin
        if FetchCache.ContainsKey(EnvName) then
            FetchCache.Set(EnvName, RawResponse)
        else
            FetchCache.Add(EnvName, RawResponse);
    end;

    /// <summary>
    /// Hand the per-env raw-JSON cache built during BuildPlan to the caller so it can
    /// forward it into the dialog (SetFetchCache) and avoid AssistEdit re-fetches.
    /// </summary>
    procedure GetFetchCache(var TargetCache: Dictionary of [Text, Text])
    begin
        TargetCache := FetchCache;
    end;

    /// <summary>
    /// If no mock/impl was injected, bind AdminAPI to the default D4P BC Admin API codeunit.
    /// </summary>
    local procedure EnsureAdminAPI()
    var
        DefaultImpl: Codeunit "D4P BC Admin API";
    begin
        if AdminAPIInjected then
            exit;

        AdminAPI := DefaultImpl;
        AdminAPIInjected := true;
    end;
}
