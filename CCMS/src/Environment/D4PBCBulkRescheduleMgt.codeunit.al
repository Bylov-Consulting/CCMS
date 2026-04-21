namespace D4P.CCMS.Environment;

codeunit 62004 "D4P BC Bulk Reschedule Mgt"
{
    var
        AdminAPI: Interface "D4P IBC Admin API";
        AdminAPIInjected: Boolean;

    /// <summary>
    /// Test seam: inject an implementation of "D4P IBC Admin API" (e.g. a mock).
    /// MUST have a real body even during RED — otherwise tests cannot substitute the mock
    /// and would end up calling the default implementation (live HTTP) or an unassigned
    /// interface variable. Setting the injected flag lets EnsureAdminAPI (GREEN) decide
    /// whether to fall back to the default codeunit.
    /// </summary>
    /// <param name="NewAPI">The implementation to use for all subsequent Admin API calls.</param>
    procedure SetAdminAPI(NewAPI: Interface "D4P IBC Admin API")
    begin
        AdminAPI := NewAPI;
        AdminAPIInjected := true;
    end;

    /// <summary>
    /// Full flow: BuildPlan -> (user confirms via page 62032) -> ApplyPlan -> ShowSummary.
    /// </summary>
    /// <param name="BCEnvironment">Multi-selected environment records.</param>
    procedure RunBulkReschedule(var BCEnvironment: Record "D4P BC Environment")
    begin
        // RED stub: intentionally empty.
    end;

    /// <summary>
    /// Iterates BCEnvironment, populates TempPlan. Catches per-env fetch failures
    /// and marks rows Skipped with a reason. Opens phase-1 progress dialog.
    /// RED stub: MUST return silently leaving TempPlan empty so tests can observe
    /// "no rows inserted" as an AssertError, not a runtime Error.
    /// </summary>
    procedure BuildPlan(var BCEnvironment: Record "D4P BC Environment"; var TempPlan: Record "D4P BC Reschedule Plan Line" temporary)
    begin
        // RED stub: intentionally empty. DO NOT Error() here.
    end;

    /// <summary>
    /// Iterates TempPlan rows where Result = Pending. TryApply per row, mutates Result.
    /// Commit() after each apply. Publishes the 2 events. Opens phase-2 progress dialog.
    /// </summary>
    procedure ApplyPlan(var TempPlan: Record "D4P BC Reschedule Plan Line" temporary)
    begin
        // RED stub: intentionally empty.
    end;

    /// <summary>
    /// Runs page 62033 (Bulk Reschedule Summary) modally against TempPlan.
    /// </summary>
    procedure ShowSummary(var TempPlan: Record "D4P BC Reschedule Plan Line" temporary)
    begin
        // RED stub: intentionally empty.
    end;

    /// <summary>
    /// Publishes before each apply. Subscribers set Skip:=true to veto an individual env.
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

    [TryFunction]
    local procedure TryApply(var PlanLine: Record "D4P BC Reschedule Plan Line" temporary)
    begin
        // RED stub: intentionally empty.
    end;
}
