codeunit 62101 "D4P Bulk Reschedule Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // -----------------------------------------------------------------------
    //  Shared fixtures
    //  Fixture grammar (matches MockAdminAPI):
    //    "<Version>|<available>|<DD-MM-YYYY or 0>|<Month>|<Year>"
    //  Multiple versions per env: separate records with the two-char literal \n.
    //
    //  Isolation note: TestIsolation = Codeunit rolls back the database once
    //  per codeunit run (not per individual test). Each test uses a unique
    //  customer number so BCEnv.SetRange("Customer No.", CustNo) scopes
    //  only the records that test inserted.
    // -----------------------------------------------------------------------
    var
        MockAPI: Codeunit "D4P Mock Admin API";
        Orchestrator: Codeunit "D4P BC Bulk Reschedule Mgt";
        Assert: Codeunit "Library Assert";
        TenantIdA: Guid;
        TenantIdB: Guid;
        TenantIdC: Guid;
        IsInitialized: Boolean;

    // -----------------------------------------------------------------------
    //  Test 1 — Happy path: all three environments succeed
    // -----------------------------------------------------------------------
    [Test]
    procedure BulkReschedule_HappyPath_AllSucceed()
    var
        BCEnv: Record "D4P BC Environment";
        TempPlan: Record "D4P BC Reschedule Plan Line" temporary;
        SelectCalls: List of [Text];
        CustNo: Code[20];
        SucceededCount: Integer;
        FailedCount: Integer;
        SkippedCount: Integer;
    begin
        // Arrange
        Initialize();
        MockAPI.Reset();
        CustNo := EnsureCustomer('TBULK-T1');

        CreateTestEnv(BCEnv, CustNo, TenantIdA, 'PROD-A');
        CreateTestEnv(BCEnv, CustNo, TenantIdB, 'PROD-B');
        CreateTestEnv(BCEnv, CustNo, TenantIdC, 'PROD-C');

        MockAPI.SetFixtureForEnv('PROD-A', '27.5|true|01-06-2026|6|2026');
        MockAPI.SetFixtureForEnv('PROD-B', '27.5|true|01-06-2026|6|2026');
        MockAPI.SetFixtureForEnv('PROD-C', '27.5|true|01-06-2026|6|2026');

        Orchestrator.SetAdminAPI(MockAPI);

        BCEnv.SetRange("Customer No.", CustNo);
        Orchestrator.BuildPlan(BCEnv, TempPlan);

        // Simulate user accepting defaults: set Target Version on each Pending row
        TempPlan.SetRange(Result, TempPlan.Result::Pending);
        if TempPlan.FindSet(true) then
            repeat
                TempPlan."Target Version" := '27.5';
                TempPlan.Modify();
            until TempPlan.Next() = 0;

        // Act
        Orchestrator.ApplyPlan(TempPlan);

        // Assert — count-level
        TempPlan.Reset();
        TempPlan.SetRange(Result, TempPlan.Result::Succeeded);
        SucceededCount := TempPlan.Count();

        TempPlan.SetRange(Result, TempPlan.Result::Failed);
        FailedCount := TempPlan.Count();

        TempPlan.SetRange(Result, TempPlan.Result::Skipped);
        SkippedCount := TempPlan.Count();

        Assert.AreEqual(3, SucceededCount, 'Expected 3 Succeeded rows');
        Assert.AreEqual(0, FailedCount, 'Expected 0 Failed rows');
        Assert.AreEqual(0, SkippedCount, 'Expected 0 Skipped rows');

        SelectCalls := MockAPI.GetSelectCalls();
        Assert.AreEqual(3, SelectCalls.Count(), 'Expected SelectTargetVersion called 3 times');

        // U6: per-env identity assertions — catches bugs where count is correct but
        // row assignments are swapped or a wrong env is recorded as Succeeded.
        TempPlan.Reset();
        TempPlan.SetRange("Environment Name", 'PROD-A');
        Assert.IsTrue(TempPlan.FindFirst(), 'Expected PROD-A in plan');
        Assert.AreEqual(TempPlan.Result::Succeeded, TempPlan.Result, 'PROD-A should be Succeeded');

        TempPlan.SetRange("Environment Name", 'PROD-B');
        Assert.IsTrue(TempPlan.FindFirst(), 'Expected PROD-B in plan');
        Assert.AreEqual(TempPlan.Result::Succeeded, TempPlan.Result, 'PROD-B should be Succeeded');

        TempPlan.SetRange("Environment Name", 'PROD-C');
        Assert.IsTrue(TempPlan.FindFirst(), 'Expected PROD-C in plan');
        Assert.AreEqual(TempPlan.Result::Succeeded, TempPlan.Result, 'PROD-C should be Succeeded');
    end;

    // -----------------------------------------------------------------------
    //  Test 2 — One env's SelectTargetVersion returns false; others succeed
    // -----------------------------------------------------------------------
    [Test]
    procedure BulkReschedule_OneFails_OthersSucceed()
    var
        BCEnv: Record "D4P BC Environment";
        TempPlan: Record "D4P BC Reschedule Plan Line" temporary;
        SelectCalls: List of [Text];
        CustNo: Code[20];
        SucceededCount: Integer;
        FailedCount: Integer;
    begin
        // Arrange
        Initialize();
        MockAPI.Reset();
        CustNo := EnsureCustomer('TBULK-T2');

        CreateTestEnv(BCEnv, CustNo, TenantIdA, 'ENV-A');
        CreateTestEnv(BCEnv, CustNo, TenantIdB, 'SANDBOX-A');
        CreateTestEnv(BCEnv, CustNo, TenantIdC, 'ENV-C');

        MockAPI.SetFixtureForEnv('ENV-A', '27.5|true|01-06-2026|6|2026');
        MockAPI.SetFixtureForEnv('SANDBOX-A', '27.5|true|01-06-2026|6|2026');
        MockAPI.SetFixtureForEnv('ENV-C', '27.5|true|01-06-2026|6|2026');

        MockAPI.ForceFailOn('SANDBOX-A');

        Orchestrator.SetAdminAPI(MockAPI);

        BCEnv.SetRange("Customer No.", CustNo);
        Orchestrator.BuildPlan(BCEnv, TempPlan);

        TempPlan.SetRange(Result, TempPlan.Result::Pending);
        if TempPlan.FindSet(true) then
            repeat
                TempPlan."Target Version" := '27.5';
                TempPlan.Modify();
            until TempPlan.Next() = 0;

        // Act
        Orchestrator.ApplyPlan(TempPlan);

        // Assert — count-level
        TempPlan.Reset();
        TempPlan.SetRange(Result, TempPlan.Result::Succeeded);
        SucceededCount := TempPlan.Count();

        TempPlan.SetRange(Result, TempPlan.Result::Failed);
        FailedCount := TempPlan.Count();

        Assert.AreEqual(2, SucceededCount, 'Expected 2 Succeeded rows');
        Assert.AreEqual(1, FailedCount, 'Expected 1 Failed row');

        // All 3 must have been attempted (skip-and-continue, not early abort)
        SelectCalls := MockAPI.GetSelectCalls();
        Assert.AreEqual(3, SelectCalls.Count(), 'Expected all 3 envs to be attempted');

        // U6: per-env identity assertions — catches bugs where a wrong env is marked Failed
        // or where result identities are swapped while counts still appear correct.
        TempPlan.Reset();
        TempPlan.SetRange("Environment Name", 'ENV-A');
        Assert.IsTrue(TempPlan.FindFirst(), 'Expected ENV-A in plan');
        Assert.AreEqual(TempPlan.Result::Succeeded, TempPlan.Result, 'ENV-A should be Succeeded');

        TempPlan.SetRange("Environment Name", 'SANDBOX-A');
        Assert.IsTrue(TempPlan.FindFirst(), 'Expected SANDBOX-A in plan');
        Assert.AreEqual(TempPlan.Result::Failed, TempPlan.Result, 'SANDBOX-A should be Failed');

        TempPlan.SetRange("Environment Name", 'ENV-C');
        Assert.IsTrue(TempPlan.FindFirst(), 'Expected ENV-C in plan');
        Assert.AreEqual(TempPlan.Result::Succeeded, TempPlan.Result, 'ENV-C should be Succeeded');
    end;

    // -----------------------------------------------------------------------
    //  Test 3 — Fetch failure: plan row should be Skipped, Reason mentions fetch
    // -----------------------------------------------------------------------
    [Test]
    procedure BulkReschedule_FetchFailure_MarkedSkipped()
    var
        BCEnv: Record "D4P BC Environment";
        TempPlan: Record "D4P BC Reschedule Plan Line" temporary;
        CustNo: Code[20];
    begin
        // Arrange
        Initialize();
        MockAPI.Reset();
        CustNo := EnsureCustomer('TBULK-T3');

        CreateTestEnv(BCEnv, CustNo, TenantIdA, 'FLAKY-ENV');
        MockAPI.ForceThrowOnFetch('FLAKY-ENV');
        Orchestrator.SetAdminAPI(MockAPI);

        // Act
        BCEnv.SetRange("Customer No.", CustNo);
        Orchestrator.BuildPlan(BCEnv, TempPlan);

        // Assert
        Assert.AreEqual(1, TempPlan.Count(), 'Expected exactly 1 plan row');

        TempPlan.FindFirst();
        Assert.AreEqual(TempPlan.Result::Skipped, TempPlan.Result,
            'Expected plan row to be Skipped after fetch failure');
        Assert.IsTrue(
            StrPos(LowerCase(TempPlan.Reason), 'fetch') > 0,
            StrSubstNo('Expected Reason to mention fetch, got: %1', TempPlan.Reason));
    end;

    // -----------------------------------------------------------------------
    //  Test 4 — No available updates: plan row Skipped with informative reason
    // -----------------------------------------------------------------------
    [Test]
    procedure BulkReschedule_NoAvailableUpdates_MarkedSkipped()
    var
        BCEnv: Record "D4P BC Environment";
        TempPlan: Record "D4P BC Reschedule Plan Line" temporary;
        CustNo: Code[20];
    begin
        // Arrange
        Initialize();
        MockAPI.Reset();
        CustNo := EnsureCustomer('TBULK-T4');

        CreateTestEnv(BCEnv, CustNo, TenantIdA, 'STALE-ENV');
        // No fixture registered → mock returns zero rows
        Orchestrator.SetAdminAPI(MockAPI);

        // Act
        BCEnv.SetRange("Customer No.", CustNo);
        Orchestrator.BuildPlan(BCEnv, TempPlan);

        // Assert
        Assert.AreEqual(1, TempPlan.Count(), 'Expected exactly 1 plan row');

        TempPlan.FindFirst();
        Assert.AreEqual(TempPlan.Result::Skipped, TempPlan.Result,
            'Expected Skipped when no updates available');
        Assert.IsTrue(
            (StrPos(LowerCase(TempPlan.Reason), 'no update') > 0) or
            (StrPos(LowerCase(TempPlan.Reason), 'no available') > 0) or
            (StrPos(LowerCase(TempPlan.Reason), 'available') > 0),
            StrSubstNo('Expected Reason to mention updates availability, got: %1', TempPlan.Reason));
    end;

    // -----------------------------------------------------------------------
    //  Test 5 — OnBeforeApplyReschedule subscriber sets Skip=true for one env.
    //
    //  The subscriber lives in the separate D4P Skip Sandbox B Subscriber
    //  codeunit (manual binding) because AL0501 forbids static event
    //  subscribers in test codeunits. The test explicitly binds the
    //  subscriber for the duration of the orchestrator calls.
    // -----------------------------------------------------------------------
    [Test]
    procedure BulkReschedule_SubscriberSkips_ApplyNotCalled()
    var
        BCEnv: Record "D4P BC Environment";
        TempPlan: Record "D4P BC Reschedule Plan Line" temporary;
        Subscriber: Codeunit "D4P Skip Sandbox B Subscriber";
        SelectCalls: List of [Text];
        CustNo: Code[20];
        ContainsSandboxB: Boolean;
        I: Integer;
    begin
        // Arrange
        Initialize();
        MockAPI.Reset();
        CustNo := EnsureCustomer('TBULK-T5');

        CreateTestEnv(BCEnv, CustNo, TenantIdA, 'SANDBOX-B');
        CreateTestEnv(BCEnv, CustNo, TenantIdB, 'KEEP-C');
        CreateTestEnv(BCEnv, CustNo, TenantIdC, 'KEEP-D');

        MockAPI.SetFixtureForEnv('SANDBOX-B', '27.5|true|01-06-2026|6|2026');
        MockAPI.SetFixtureForEnv('KEEP-C', '27.5|true|01-06-2026|6|2026');
        MockAPI.SetFixtureForEnv('KEEP-D', '27.5|true|01-06-2026|6|2026');

        Orchestrator.SetAdminAPI(MockAPI);

        BindSubscription(Subscriber);

        BCEnv.SetRange("Customer No.", CustNo);
        Orchestrator.BuildPlan(BCEnv, TempPlan);

        TempPlan.SetRange(Result, TempPlan.Result::Pending);
        if TempPlan.FindSet(true) then
            repeat
                TempPlan."Target Version" := '27.5';
                TempPlan.Modify();
            until TempPlan.Next() = 0;

        // Act — OnBeforeApplyReschedule fires via the bound subscriber
        Orchestrator.ApplyPlan(TempPlan);

        UnbindSubscription(Subscriber);

        // Assert: SANDBOX-B is Skipped
        TempPlan.Reset();
        TempPlan.SetRange("Environment Name", 'SANDBOX-B');
        TempPlan.FindFirst();
        Assert.AreEqual(TempPlan.Result::Skipped, TempPlan.Result,
            'Expected SANDBOX-B to be Skipped by subscriber');

        // SANDBOX-B must NOT appear in SelectCalls
        SelectCalls := MockAPI.GetSelectCalls();
        ContainsSandboxB := false;
        for I := 1 to SelectCalls.Count() do
            if StrPos(SelectCalls.Get(I), 'SANDBOX-B') > 0 then
                ContainsSandboxB := true;
        Assert.IsFalse(ContainsSandboxB,
            'SelectTargetVersion must not have been called for SANDBOX-B');

        Assert.AreEqual(2, SelectCalls.Count(),
            'Expected SelectTargetVersion called for the 2 non-skipped envs');
    end;

    // -----------------------------------------------------------------------
    //  Test 6 — Empty selection raises an error
    // -----------------------------------------------------------------------
    [Test]
    procedure BulkReschedule_EmptySelection_RaisesError()
    var
        BCEnv: Record "D4P BC Environment";
        EmptyErrorText: Text;
    begin
        // Arrange
        Initialize();

        // Filter that matches nothing
        BCEnv.SetRange("Customer No.", 'NO-SUCH-CUST-99');

        // Act & Assert
        asserterror Orchestrator.RunBulkReschedule(BCEnv);

        EmptyErrorText := GetLastErrorText();
        Assert.IsTrue(EmptyErrorText <> '', 'Expected a non-empty error message');
        Assert.IsTrue(
            (StrPos(LowerCase(EmptyErrorText), 'select') > 0) or
            (StrPos(LowerCase(EmptyErrorText), 'environment') > 0),
            StrSubstNo('Expected error to mention selection or environments, got: %1', EmptyErrorText));
    end;

    // -----------------------------------------------------------------------
    //  T2 — OnAfterApplyReschedule fires for every processed environment
    //
    //  3 envs are used. SANDBOX-MID is configured to fail via ForceFailOn so
    //  that the subscriber sees at least one Succeeded and one Failed entry.
    //  The test binds D4P Apply Recorder Subscriber (manual binding), runs
    //  BuildPlan + ApplyPlan, then asserts:
    //    - exactly 3 subscriber calls were recorded (one per env),
    //    - at least one call ends with "|Succeeded",
    //    - at least one call ends with "|Failed".
    // -----------------------------------------------------------------------
    [Test]
    procedure BulkReschedule_OnAfterApplyReschedule_FiresForEveryProcessedEnv()
    var
        BCEnv: Record "D4P BC Environment";
        TempPlan: Record "D4P BC Reschedule Plan Line" temporary;
        Recorder: Codeunit "D4P Apply Recorder Subscriber";
        Calls: List of [Text];
        CustNo: Code[20];
        HasSucceeded: Boolean;
        HasFailed: Boolean;
        I: Integer;
        Entry: Text;
    begin
        // Arrange
        Initialize();
        MockAPI.Reset();
        CustNo := EnsureCustomer('TBULK-T7');

        CreateTestEnv(BCEnv, CustNo, TenantIdA, 'PROD-X');
        CreateTestEnv(BCEnv, CustNo, TenantIdB, 'SANDBOX-MID');
        CreateTestEnv(BCEnv, CustNo, TenantIdC, 'PROD-Z');

        MockAPI.SetFixtureForEnv('PROD-X', '27.5|true|01-06-2026|6|2026');
        MockAPI.SetFixtureForEnv('SANDBOX-MID', '27.5|true|01-06-2026|6|2026');
        MockAPI.SetFixtureForEnv('PROD-Z', '27.5|true|01-06-2026|6|2026');

        // SANDBOX-MID will fail on SelectTargetVersion
        MockAPI.ForceFailOn('SANDBOX-MID');

        Orchestrator.SetAdminAPI(MockAPI);
        Recorder.ClearCalls();
        BindSubscription(Recorder);

        BCEnv.SetRange("Customer No.", CustNo);
        Orchestrator.BuildPlan(BCEnv, TempPlan);

        // Accept defaults for all Pending rows
        TempPlan.SetRange(Result, TempPlan.Result::Pending);
        if TempPlan.FindSet(true) then
            repeat
                TempPlan."Target Version" := '27.5';
                TempPlan.Modify();
            until TempPlan.Next() = 0;

        // Act
        Orchestrator.ApplyPlan(TempPlan);

        UnbindSubscription(Recorder);

        // Assert
        Calls := Recorder.GetCalls();
        Assert.AreEqual(3, Calls.Count(),
            'OnAfterApplyReschedule must fire exactly once per processed environment (3 expected)');

        HasSucceeded := false;
        HasFailed := false;
        for I := 1 to Calls.Count() do begin
            Entry := Calls.Get(I);
            if StrPos(Entry, '|Succeeded') > 0 then
                HasSucceeded := true;
            if StrPos(Entry, '|Failed') > 0 then
                HasFailed := true;
        end;

        Assert.IsTrue(HasSucceeded,
            'At least one subscriber entry must show |Succeeded (PROD-X or PROD-Z)');
        Assert.IsTrue(HasFailed,
            'At least one subscriber entry must show |Failed (SANDBOX-MID was configured to fail)');
    end;

    // -----------------------------------------------------------------------
    //  T3 — ApplyPlan on an all-Skipped plan makes zero API calls
    //
    //  The temp plan is constructed directly (bypassing BuildPlan) with 3 rows
    //  all pre-set to Result = Skipped. ApplyPlan filters on Pending rows so
    //  it must find nothing to process and make no SelectTargetVersion calls.
    //  Row states must remain Skipped after the call.
    // -----------------------------------------------------------------------
    [Test]
    procedure BulkReschedule_ApplyPlanAllSkipped_MakesNoApiCalls()
    var
        TempPlan: Record "D4P BC Reschedule Plan Line" temporary;
        SelectCalls: List of [Text];
        SkippedCount: Integer;
        TenantIdX: Guid;
        TenantIdY: Guid;
        TenantIdZ: Guid;
    begin
        // Arrange — build the plan manually; no BuildPlan or database envs needed
        Evaluate(TenantIdX, '{20000000-0000-0000-0000-000000000001}');
        Evaluate(TenantIdY, '{20000000-0000-0000-0000-000000000002}');
        Evaluate(TenantIdZ, '{20000000-0000-0000-0000-000000000003}');

        MockAPI.Reset();
        Orchestrator.SetAdminAPI(MockAPI);

        // Row 1
        TempPlan.Init();
        TempPlan."Entry No." := 1;
        TempPlan."Customer No." := 'TBULK-T8';
        TempPlan."Tenant ID" := TenantIdX;
        TempPlan."Environment Name" := 'SKP-ENV-1';
        TempPlan.Result := TempPlan.Result::Skipped;
        TempPlan.Reason := 'Pre-skipped';
        TempPlan.Insert();

        // Row 2
        TempPlan.Init();
        TempPlan."Entry No." := 2;
        TempPlan."Customer No." := 'TBULK-T8';
        TempPlan."Tenant ID" := TenantIdY;
        TempPlan."Environment Name" := 'SKP-ENV-2';
        TempPlan.Result := TempPlan.Result::Skipped;
        TempPlan.Reason := 'Pre-skipped';
        TempPlan.Insert();

        // Row 3
        TempPlan.Init();
        TempPlan."Entry No." := 3;
        TempPlan."Customer No." := 'TBULK-T8';
        TempPlan."Tenant ID" := TenantIdZ;
        TempPlan."Environment Name" := 'SKP-ENV-3';
        TempPlan.Result := TempPlan.Result::Skipped;
        TempPlan.Reason := 'Pre-skipped';
        TempPlan.Insert();

        // Act
        Orchestrator.ApplyPlan(TempPlan);

        // Assert — zero SelectTargetVersion calls
        SelectCalls := MockAPI.GetSelectCalls();
        Assert.AreEqual(0, SelectCalls.Count(),
            'ApplyPlan on an all-Skipped plan must make zero SelectTargetVersion API calls');

        // All rows must remain Skipped
        TempPlan.Reset();
        TempPlan.SetRange(Result, TempPlan.Result::Skipped);
        SkippedCount := TempPlan.Count();
        Assert.AreEqual(3, SkippedCount,
            'All 3 rows must remain Skipped after ApplyPlan with no Pending rows');
    end;

    // -----------------------------------------------------------------------
    //  T4 — Retry Failed: only Failed rows are re-applied; Succeeded rows are
    //       untouched and not re-sent to the API
    //
    //  Flow:
    //    Run 1: ENV-A succeeds, ENV-B fails (ForceFailOn).
    //    Reset: ENV-B row is manually set back to Pending (simulating the
    //           "Retry Failed" UI gesture). ClearFailures() removes the mock's
    //           forced-failure so the second call will succeed.
    //    Run 2: ApplyPlan again — only ENV-B's Pending row is processed.
    //
    //  Key assertions:
    //    - After run 2: ENV-A is still Succeeded, ENV-B is now Succeeded.
    //    - Total SelectCalls = 3: ENV-A (run 1) + ENV-B (run 1) + ENV-B (run 2).
    //      ENV-A must NOT appear in SelectCalls a second time.
    // -----------------------------------------------------------------------
    [Test]
    procedure BulkReschedule_RetryFailed_OnlyReappliesFailedRowsSuccessIsPreserved()
    var
        BCEnv: Record "D4P BC Environment";
        TempPlan: Record "D4P BC Reschedule Plan Line" temporary;
        SelectCalls: List of [Text];
        CustNo: Code[20];
        EnvACallCount: Integer;
        EnvBCallCount: Integer;
        I: Integer;
        Entry: Text;
    begin
        // Arrange — run 1
        Initialize();
        MockAPI.Reset();
        CustNo := EnsureCustomer('TBULK-T9');

        CreateTestEnv(BCEnv, CustNo, TenantIdA, 'ENV-A');
        CreateTestEnv(BCEnv, CustNo, TenantIdB, 'ENV-B');

        MockAPI.SetFixtureForEnv('ENV-A', '27.5|true|01-06-2026|6|2026');
        MockAPI.SetFixtureForEnv('ENV-B', '27.5|true|01-06-2026|6|2026');

        // ENV-B will fail on the first run
        MockAPI.ForceFailOn('ENV-B');

        Orchestrator.SetAdminAPI(MockAPI);

        BCEnv.SetRange("Customer No.", CustNo);
        Orchestrator.BuildPlan(BCEnv, TempPlan);

        // Accept defaults for all Pending rows
        TempPlan.SetRange(Result, TempPlan.Result::Pending);
        if TempPlan.FindSet(true) then
            repeat
                TempPlan."Target Version" := '27.5';
                TempPlan.Modify();
            until TempPlan.Next() = 0;

        // Run 1: ENV-A succeeds, ENV-B fails
        Orchestrator.ApplyPlan(TempPlan);

        // Verify run 1 state before retry
        TempPlan.Reset();
        TempPlan.SetRange("Environment Name", 'ENV-A');
        TempPlan.FindFirst();
        Assert.AreEqual(TempPlan.Result::Succeeded, TempPlan.Result,
            'ENV-A must be Succeeded after run 1');

        TempPlan.Reset();
        TempPlan.SetRange("Environment Name", 'ENV-B');
        TempPlan.FindFirst();
        Assert.AreEqual(TempPlan.Result::Failed, TempPlan.Result,
            'ENV-B must be Failed after run 1');

        // Simulate "Retry Failed" UI gesture: reset ENV-B to Pending
        TempPlan.Result := TempPlan.Result::Pending;
        TempPlan.Reason := '';
        TempPlan.Modify();

        // Clear the forced failure so ENV-B succeeds on retry
        MockAPI.ClearFailures();

        // Act — run 2 (retry): only ENV-B's Pending row is processed
        Orchestrator.ApplyPlan(TempPlan);

        // Assert — ENV-A unchanged (still Succeeded)
        TempPlan.Reset();
        TempPlan.SetRange("Environment Name", 'ENV-A');
        TempPlan.FindFirst();
        Assert.AreEqual(TempPlan.Result::Succeeded, TempPlan.Result,
            'ENV-A must still be Succeeded after retry — its row was not Pending so it must not be touched');

        // ENV-B now Succeeded
        TempPlan.Reset();
        TempPlan.SetRange("Environment Name", 'ENV-B');
        TempPlan.FindFirst();
        Assert.AreEqual(TempPlan.Result::Succeeded, TempPlan.Result,
            'ENV-B must be Succeeded after retry');

        // Total SelectCalls = 3: ENV-A×1 (run 1) + ENV-B×1 (run 1) + ENV-B×1 (run 2)
        SelectCalls := MockAPI.GetSelectCalls();
        Assert.AreEqual(3, SelectCalls.Count(),
            'Total SelectTargetVersion calls must be 3: ENV-A once (run 1) and ENV-B twice (runs 1 and 2)');

        // ENV-A must appear exactly once (not retried)
        EnvACallCount := 0;
        EnvBCallCount := 0;
        for I := 1 to SelectCalls.Count() do begin
            Entry := SelectCalls.Get(I);
            if StrPos(Entry, 'ENV-A|') = 1 then
                EnvACallCount += 1;
            if StrPos(Entry, 'ENV-B|') = 1 then
                EnvBCallCount += 1;
        end;

        Assert.AreEqual(1, EnvACallCount,
            'ENV-A must appear in SelectCalls exactly once (initial run only, not retried)');
        Assert.AreEqual(2, EnvBCallCount,
            'ENV-B must appear in SelectCalls exactly twice (run 1 failed + run 2 retry)');
    end;

    // -----------------------------------------------------------------------
    //  U4 — Subscriber vetoes ALL envs: no API calls, all rows Skipped
    //
    //  Binds D4P Veto All Subscriber which unconditionally sets Skip := true.
    //  Verifies that:
    //    - All 3 plan rows end up with Result = Skipped.
    //    - The Reason on each row contains 'subscriber' (from SkippedBySubscriberLbl).
    //    - SelectTargetVersion is never called (count = 0).
    //
    //  This is distinct from Test 5 (which skips only one named env). It tests
    //  the boundary case where the entire plan is consumed by the subscriber gate
    //  without a single API call.
    // -----------------------------------------------------------------------
    [Test]
    procedure BulkReschedule_SubscriberVetoesAll_NoApiCallsAllSkipped()
    var
        BCEnv: Record "D4P BC Environment";
        TempPlan: Record "D4P BC Reschedule Plan Line" temporary;
        VetoSubscriber: Codeunit "D4P Veto All Subscriber";
        SelectCalls: List of [Text];
        CustNo: Code[20];
        SkippedCount: Integer;
        TenantIdD: Guid;
        TenantIdE: Guid;
        TenantIdF: Guid;
    begin
        // Arrange
        Initialize();
        MockAPI.Reset();
        CustNo := EnsureCustomer('TBULK-U4');

        Evaluate(TenantIdD, '{30000000-0000-0000-0000-000000000001}');
        Evaluate(TenantIdE, '{30000000-0000-0000-0000-000000000002}');
        Evaluate(TenantIdF, '{30000000-0000-0000-0000-000000000003}');

        CreateTestEnv(BCEnv, CustNo, TenantIdD, 'VETO-ENV-1');
        CreateTestEnv(BCEnv, CustNo, TenantIdE, 'VETO-ENV-2');
        CreateTestEnv(BCEnv, CustNo, TenantIdF, 'VETO-ENV-3');

        MockAPI.SetFixtureForEnv('VETO-ENV-1', '27.5|true|01-06-2026|6|2026');
        MockAPI.SetFixtureForEnv('VETO-ENV-2', '27.5|true|01-06-2026|6|2026');
        MockAPI.SetFixtureForEnv('VETO-ENV-3', '27.5|true|01-06-2026|6|2026');

        Orchestrator.SetAdminAPI(MockAPI);

        BCEnv.SetRange("Customer No.", CustNo);
        Orchestrator.BuildPlan(BCEnv, TempPlan);

        // Simulate user accepting defaults for all Pending rows
        TempPlan.SetRange(Result, TempPlan.Result::Pending);
        if TempPlan.FindSet(true) then
            repeat
                TempPlan."Target Version" := '27.5';
                TempPlan.Modify();
            until TempPlan.Next() = 0;

        // Bind the veto-all subscriber before ApplyPlan
        BindSubscription(VetoSubscriber);

        // Act
        Orchestrator.ApplyPlan(TempPlan);

        UnbindSubscription(VetoSubscriber);

        // Assert — all 3 rows must be Skipped
        TempPlan.Reset();
        TempPlan.SetRange(Result, TempPlan.Result::Skipped);
        SkippedCount := TempPlan.Count();
        Assert.AreEqual(3, SkippedCount,
            'All 3 plan rows must be Skipped when the veto-all subscriber fires for every env');

        // Assert — each row's Reason must mention 'subscriber'
        TempPlan.Reset();
        if TempPlan.FindSet() then
            repeat
                Assert.IsTrue(
                    StrPos(LowerCase(TempPlan.Reason), 'subscriber') > 0,
                    StrSubstNo('Expected Reason to contain ''subscriber'' for env %1, got: %2',
                        TempPlan."Environment Name", TempPlan.Reason));
            until TempPlan.Next() = 0;

        // Assert — zero API calls (subscriber fired before SelectTargetVersion)
        SelectCalls := MockAPI.GetSelectCalls();
        Assert.AreEqual(0, SelectCalls.Count(),
            'SelectTargetVersion must not have been called when every env is vetoed by subscriber');
    end;

    // -----------------------------------------------------------------------
    //  U5 — BuildPlan replaces existing plan rows (reset contract)
    //
    //  Verifies that BuildPlan calls TempPlan.DeleteAll before inserting new
    //  rows. Two stale rows are pre-inserted directly into TempPlan. After
    //  BuildPlan runs for 1 real env, the count must be exactly 1 (not 3) and
    //  the remaining row must be the real env's row, not a stale one.
    //
    //  Note: ApplyPlan is NOT called here. The stale rows have no matching
    //  D4P BC Environment records; calling ApplyPlan on them would trigger the
    //  M3 "env no longer exists" path. The contract being tested is purely
    //  BuildPlan's responsibility to clear before populating.
    // -----------------------------------------------------------------------
    [Test]
    procedure BulkReschedule_BuildPlanReplacesExistingRows()
    var
        BCEnv: Record "D4P BC Environment";
        TempPlan: Record "D4P BC Reschedule Plan Line" temporary;
        CustNo: Code[20];
        TenantIdG: Guid;
        TenantIdStale1: Guid;
        TenantIdStale2: Guid;
    begin
        // Arrange — pre-populate TempPlan with 2 stale rows that BuildPlan must discard
        Evaluate(TenantIdStale1, '{40000000-0000-0000-0000-000000000001}');
        Evaluate(TenantIdStale2, '{40000000-0000-0000-0000-000000000002}');
        Evaluate(TenantIdG,      '{40000000-0000-0000-0000-000000000003}');

        TempPlan.Init();
        TempPlan."Entry No." := 1;
        TempPlan."Customer No." := 'STALE-CUST';
        TempPlan."Tenant ID" := TenantIdStale1;
        TempPlan."Environment Name" := 'STALE-1';
        TempPlan.Result := TempPlan.Result::Pending;
        TempPlan.Insert();

        TempPlan.Init();
        TempPlan."Entry No." := 2;
        TempPlan."Customer No." := 'STALE-CUST';
        TempPlan."Tenant ID" := TenantIdStale2;
        TempPlan."Environment Name" := 'STALE-2';
        TempPlan.Result := TempPlan.Result::Pending;
        TempPlan.Insert();

        Assert.AreEqual(2, TempPlan.Count(), 'Pre-condition: TempPlan must have 2 stale rows before BuildPlan');

        // Register 1 real env
        Initialize();
        MockAPI.Reset();
        CustNo := EnsureCustomer('TBULK-U5');

        CreateTestEnv(BCEnv, CustNo, TenantIdG, 'REAL-ENV');
        MockAPI.SetFixtureForEnv('REAL-ENV', '27.5|true|01-06-2026|6|2026');
        Orchestrator.SetAdminAPI(MockAPI);

        // Act
        BCEnv.SetRange("Customer No.", CustNo);
        Orchestrator.BuildPlan(BCEnv, TempPlan);

        // Assert — exactly 1 row (the 2 stale rows must have been discarded by DeleteAll)
        Assert.AreEqual(1, TempPlan.Count(),
            'BuildPlan must replace all existing rows; TempPlan must contain exactly 1 row after build (not 3)');

        // Assert — the surviving row is the real env's row, not a stale one
        TempPlan.Reset();
        TempPlan.FindFirst();
        Assert.AreEqual('REAL-ENV', TempPlan."Environment Name",
            'The single remaining plan row must be for REAL-ENV, not a stale row');
        Assert.AreNotEqual('STALE-1', TempPlan."Environment Name",
            'STALE-1 must not survive BuildPlan''s reset');
        Assert.AreNotEqual('STALE-2', TempPlan."Environment Name",
            'STALE-2 must not survive BuildPlan''s reset');
    end;

    // -----------------------------------------------------------------------
    //  Helpers
    // -----------------------------------------------------------------------

    local procedure Initialize()
    begin
        if IsInitialized then
            exit;

        Evaluate(TenantIdA, '{10000000-0000-0000-0000-000000000001}');
        Evaluate(TenantIdB, '{10000000-0000-0000-0000-000000000002}');
        Evaluate(TenantIdC, '{10000000-0000-0000-0000-000000000003}');

        IsInitialized := true;
    end;

    /// <summary>
    /// Inserts a D4P BC Customer with the given explicit number.
    /// Bypasses the No. Series OnInsert trigger by calling Insert(false).
    /// Idempotent: returns immediately if the record already exists.
    /// </summary>
    local procedure EnsureCustomer(CustNo: Code[20]): Code[20]
    var
        Customer: Record "D4P BC Customer";
    begin
        if not Customer.Get(CustNo) then begin
            Customer.Init();
            Customer."No." := CustNo;
            Customer.Name := StrSubstNo('Test Customer %1', CustNo);
            Customer.Insert(false);
        end;
        exit(CustNo);
    end;

    /// <summary>
    /// Inserts a D4P BC Environment record scoped to the given customer and tenant.
    /// </summary>
    local procedure CreateTestEnv(var BCEnv: Record "D4P BC Environment"; CustomerNo: Code[20]; TenantId: Guid; EnvName: Text[30])
    begin
        BCEnv.Init();
        BCEnv."Customer No." := CustomerNo;
        BCEnv."Tenant ID" := TenantId;
        BCEnv.Name := CopyStr(EnvName, 1, MaxStrLen(BCEnv.Name));
        BCEnv."Application Family" := 'BusinessCentral';
        BCEnv.Type := 'Sandbox';
        BCEnv.State := 'Active';
        BCEnv."Current Version" := '27.4.0.0';
        BCEnv.Insert(false);
    end;
}
