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

        MockAPI.SetFixtureForEnv('PROD-A', '27.5|true|01-06-2030|6|2030');
        MockAPI.SetFixtureForEnv('PROD-B', '27.5|true|01-06-2030|6|2030');
        MockAPI.SetFixtureForEnv('PROD-C', '27.5|true|01-06-2030|6|2030');

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

        MockAPI.SetFixtureForEnv('ENV-A', '27.5|true|01-06-2030|6|2030');
        MockAPI.SetFixtureForEnv('SANDBOX-A', '27.5|true|01-06-2030|6|2030');
        MockAPI.SetFixtureForEnv('ENV-C', '27.5|true|01-06-2030|6|2030');

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

        MockAPI.SetFixtureForEnv('SANDBOX-B', '27.5|true|01-06-2030|6|2030');
        MockAPI.SetFixtureForEnv('KEEP-C', '27.5|true|01-06-2030|6|2030');
        MockAPI.SetFixtureForEnv('KEEP-D', '27.5|true|01-06-2030|6|2030');

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

        MockAPI.SetFixtureForEnv('PROD-X', '27.5|true|01-06-2030|6|2030');
        MockAPI.SetFixtureForEnv('SANDBOX-MID', '27.5|true|01-06-2030|6|2030');
        MockAPI.SetFixtureForEnv('PROD-Z', '27.5|true|01-06-2030|6|2030');

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

        MockAPI.SetFixtureForEnv('ENV-A', '27.5|true|01-06-2030|6|2030');
        MockAPI.SetFixtureForEnv('ENV-B', '27.5|true|01-06-2030|6|2030');

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

        MockAPI.SetFixtureForEnv('VETO-ENV-1', '27.5|true|01-06-2030|6|2030');
        MockAPI.SetFixtureForEnv('VETO-ENV-2', '27.5|true|01-06-2030|6|2030');
        MockAPI.SetFixtureForEnv('VETO-ENV-3', '27.5|true|01-06-2030|6|2030');

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
        MockAPI.SetFixtureForEnv('REAL-ENV', '27.5|true|01-06-2030|6|2030');
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
    //  U6 — Available update with no latest-selectable-date must still be
    //       marked Available on the plan row (PR #5 review finding)
    //
    //  The Admin API can return a genuinely available version (available=true)
    //  that carries no scheduleDetails / latestSelectableDate, i.e. its
    //  "Latest Selectable Date" parses to 0D. PickDefaultTargetVersion still
    //  picks it (it is the best Available candidate), so BuildPlan produces a
    //  Pending row with Target Version = 27.5.
    //
    //  Requirement: the plan row's Available flag must reflect the SOURCE
    //  candidate's real availability (available=true), NOT merely whether a
    //  selectable date exists. The current production code derives it from the
    //  date (AvailableFlag := DefaultDate <> 0D), so it is wrongly false here.
    //
    //  Why this matters downstream: on apply, D4P BC Admin API.SelectTargetVersion
    //  derives IsAvailable := (SelectedDate <> 0D). Because BuildPlan dropped the
    //  candidate's real availability into a 0D-driven flag and a 0D Selected Date,
    //  a genuinely available version is rescheduled through the UNRELEASED branch
    //  (no scheduleDetails). The root cause is the Available flag computed here.
    // -----------------------------------------------------------------------
    [Test]
    procedure BulkReschedule_AvailableUpdateWithNoDate_MarkedAvailable()
    var
        BCEnv: Record "D4P BC Environment";
        TempPlan: Record "D4P BC Reschedule Plan Line" temporary;
        SelectCalls: List of [Text];
        CustNo: Code[20];
    begin
        // GIVEN an environment whose only update is genuinely available
        // (available=true) but for which the Admin API returned NO
        // latest-selectable-date (field 3 = 0 -> Latest Selectable Date = 0D).
        Initialize();
        MockAPI.Reset();
        CustNo := EnsureCustomer('TBULK-U6');

        CreateTestEnv(BCEnv, CustNo, TenantIdA, 'AVAIL-NODATE');
        MockAPI.SetFixtureForEnv('AVAIL-NODATE', '27.5|true|0|0|0');

        Orchestrator.SetAdminAPI(MockAPI);

        // WHEN BuildPlan derives the default plan row from the fetched candidates.
        BCEnv.SetRange("Customer No.", CustNo);
        Orchestrator.BuildPlan(BCEnv, TempPlan);

        // THEN the available candidate is picked as a Pending row (sanity — passes today)
        TempPlan.Reset();
        TempPlan.SetRange("Environment Name", 'AVAIL-NODATE');
        Assert.IsTrue(TempPlan.FindFirst(), 'Expected a plan row for AVAIL-NODATE');
        Assert.AreEqual('27.5', TempPlan."Target Version",
            'BuildPlan must select the available candidate 27.5 as the default target version');
        Assert.AreEqual(TempPlan.Result::Pending, TempPlan.Result,
            'A row with an available update must be Pending, not Skipped');

        // AND its Available flag must come from the candidate's real availability
        // (available=true), not from the presence of a selectable date. This is the
        // load-bearing assertion: with the current code (AvailableFlag := DefaultDate
        // <> 0D) it is wrongly false, so this FAILS in RED.
        Assert.IsTrue(TempPlan.Available,
            'A genuinely available update (available=true) must yield Available=true on the plan row even when the Admin API returned no latest-selectable-date (0D); the flag must reflect the candidate''s availability, not whether a date exists.');

        // AND on apply, the request must take the AVAILABLE (released) branch for this env,
        // chosen from the Available flag — NOT from SelectedDate <> 0D (the date is 0D here).
        // Observable via the mock's recorded branch token. With the old code (IsAvailable :=
        // SelectedDate <> 0D) this would log 'unreleased', so this assertion FAILS in RED.
        TempPlan.Reset();
        TempPlan.SetRange(Result, TempPlan.Result::Pending);
        if TempPlan.FindSet(true) then
            repeat
                TempPlan."Target Version" := '27.5';
                TempPlan.Modify();
            until TempPlan.Next() = 0;

        Orchestrator.ApplyPlan(TempPlan);

        SelectCalls := MockAPI.GetSelectCalls();
        Assert.AreEqual(1, SelectCalls.Count(),
            'SelectTargetVersion must be called exactly once for the single AVAIL-NODATE env');
        Assert.IsTrue(
            StrPos(SelectCalls.Get(1), 'AVAIL-NODATE|27.5|') = 1,
            StrSubstNo('Expected the apply call to target AVAIL-NODATE at 27.5, got: %1', SelectCalls.Get(1)));
        Assert.IsTrue(
            StrPos(SelectCalls.Get(1), '|available') > 0,
            StrSubstNo('Apply must take the AVAILABLE branch for a genuinely available update even with no selectable date (0D); the branch must be driven by the Available flag, not SelectedDate. Got: %1', SelectCalls.Get(1)));

        // The applied env's row must end Succeeded (mock returns true; no forced failure).
        TempPlan.Reset();
        TempPlan.SetRange("Environment Name", 'AVAIL-NODATE');
        Assert.IsTrue(TempPlan.FindFirst(), 'Expected AVAIL-NODATE row after apply');
        Assert.AreEqual(TempPlan.Result::Succeeded, TempPlan.Result,
            'AVAIL-NODATE must be Succeeded after apply');
    end;

    // -----------------------------------------------------------------------
    //  C4 — Apply failure Reason must surface the Admin API's error detail
    //
    //  Bug: D4P BC Admin API.SelectTargetVersion discards the HTTP ResponseText on
    //  PATCH failure (exit(false)). The orchestrator's TryApply then raises a fixed
    //  generic APIFailureErr ("Admin API reported the reschedule request failed."),
    //  so EVERY apply failure's Reason is the same opaque string — the partner never
    //  sees WHY the Admin API rejected the request.
    //
    //  Requirement: a failed plan row's Reason must contain the distinctive error
    //  detail the Admin API returned for that env, not a generic placeholder.
    //
    //  RED: ForceFailWithDetailOn registers a distinctive detail and makes the mock
    //  apply fail. Under today's boolean-only contract the detail has no channel to
    //  reach the Reason, so the failed row's Reason is the generic string and the
    //  "Reason contains detail" assertion FAILS. The GREEN step wires the detail
    //  through (e.g. surfaces ResponseText) so the assertion passes.
    // -----------------------------------------------------------------------
    [Test]
    procedure BulkReschedule_ApplyFailure_ReasonSurfacesApiErrorDetail()
    var
        BCEnv: Record "D4P BC Environment";
        TempPlan: Record "D4P BC Reschedule Plan Line" temporary;
        CustNo: Code[20];
        ApiDetail: Text;
    begin
        // GIVEN an env whose apply (PATCH) fails carrying a distinctive Admin-API error body
        Initialize();
        MockAPI.Reset();
        CustNo := EnsureCustomer('TBULK-C4');
        ApiDetail := 'CONFLICT_UPDATE_WINDOW_LOCKED_xyz123';

        CreateTestEnv(BCEnv, CustNo, TenantIdA, 'DETAIL-ENV');
        MockAPI.SetFixtureForEnv('DETAIL-ENV', '27.5|true|01-06-2030|6|2030');
        MockAPI.ForceFailWithDetailOn('DETAIL-ENV', ApiDetail);

        Orchestrator.SetAdminAPI(MockAPI);

        BCEnv.SetRange("Customer No.", CustNo);
        Orchestrator.BuildPlan(BCEnv, TempPlan);

        TempPlan.SetRange(Result, TempPlan.Result::Pending);
        if TempPlan.FindSet(true) then
            repeat
                TempPlan."Target Version" := '27.5';
                TempPlan.Modify();
            until TempPlan.Next() = 0;

        // WHEN the plan is applied and the Admin API rejects the PATCH
        Orchestrator.ApplyPlan(TempPlan);

        // THEN the row is Failed AND its Reason surfaces the API's distinctive detail —
        // not the generic APIFailureErr placeholder.
        TempPlan.Reset();
        TempPlan.SetRange("Environment Name", 'DETAIL-ENV');
        Assert.IsTrue(TempPlan.FindFirst(), 'Expected a plan row for DETAIL-ENV');
        Assert.AreEqual(TempPlan.Result::Failed, TempPlan.Result,
            'DETAIL-ENV must be Failed after the Admin API rejected the apply');
        Assert.IsTrue(
            StrPos(TempPlan.Reason, ApiDetail) > 0,
            StrSubstNo('Failure Reason must surface the Admin API error detail ''%1'' (got generic/opaque: ''%2'')',
                ApiDetail, TempPlan.Reason));
    end;

    // -----------------------------------------------------------------------
    //  C3 — A default Selected Date already in the PAST must be flagged
    //
    //  Bug: BuildPlan pre-fills Selected Date := Latest Selectable Date (the
    //  deadline) without validating it. ValidateSelectedDate (which rejects a date
    //  < Today()) only runs on the dialog's user OnValidate. So when the Admin API
    //  returns an update whose latestSelectableDate is already in the past, BuildPlan
    //  leaves a Pending row carrying a silently-invalid (past) Selected Date that is
    //  later PATCHed and only discovered Failed at the summary.
    //
    //  Requirement: BuildPlan must flag such a row (Result/Reason indicating the
    //  deadline has passed) instead of leaving it an actionable Pending row.
    //
    //  RED: with a past latestSelectableDate the row is Pending today, so the
    //  "must not be a silent Pending" assertion FAILS.
    // -----------------------------------------------------------------------
    [Test]
    procedure BulkReschedule_DefaultDateInPast_RowFlaggedNotSilentlyPending()
    var
        BCEnv: Record "D4P BC Environment";
        TempPlan: Record "D4P BC Reschedule Plan Line" temporary;
        CustNo: Code[20];
    begin
        // GIVEN an env whose only available update carries a latestSelectableDate
        // that is already in the past (01-01-2020).
        Initialize();
        MockAPI.Reset();
        CustNo := EnsureCustomer('TBULK-C3');

        CreateTestEnv(BCEnv, CustNo, TenantIdA, 'PASTDATE-ENV');
        MockAPI.SetFixtureForEnv('PASTDATE-ENV', '27.5|true|01-01-2020|1|2020');

        Orchestrator.SetAdminAPI(MockAPI);

        // WHEN BuildPlan derives the default plan row.
        BCEnv.SetRange("Customer No.", CustNo);
        Orchestrator.BuildPlan(BCEnv, TempPlan);

        TempPlan.Reset();
        TempPlan.SetRange("Environment Name", 'PASTDATE-ENV');
        Assert.IsTrue(TempPlan.FindFirst(), 'Expected a plan row for PASTDATE-ENV');

        // Sanity: BuildPlan did pre-fill the deadline as the default Selected Date.
        Assert.AreEqual(DMY2Date(1, 1, 2020), TempPlan."Selected Date",
            'Pre-condition: BuildPlan pre-filled Selected Date with the (past) latest selectable date');

        // THEN the row must be flagged — NOT left as a silently-actionable Pending row
        // with a Selected Date the dialog validation would have rejected (< Today()).
        Assert.AreNotEqual(TempPlan.Result::Pending, TempPlan.Result,
            'A default Selected Date already in the past (deadline passed) must be flagged by BuildPlan, not left as a silent Pending row');

        // AND the Reason must explain that the selectable-date deadline has passed.
        Assert.IsTrue(
            (StrPos(LowerCase(TempPlan.Reason), 'date') > 0) or
            (StrPos(LowerCase(TempPlan.Reason), 'deadline') > 0) or
            (StrPos(LowerCase(TempPlan.Reason), 'past') > 0) or
            (StrPos(LowerCase(TempPlan.Reason), 'passed') > 0),
            StrSubstNo('Expected Reason to explain the selectable-date deadline has passed, got: %1', TempPlan.Reason));
    end;

    // -----------------------------------------------------------------------
    //  C2 — AnyFetchFailure distinguishes fetch-failures from genuine no-updates
    //
    //  Bug: RunBulkReschedule shows the generic NothingToRescheduleMsg and exits
    //  whenever no row is Pending — so a run where EVERY env's fetch failed looks
    //  identical to a genuine "no updates available" run, and the per-env failure
    //  Reasons are never surfaced. The decision is inline in the UI method.
    //
    //  Requirement: a pure helper must report whether the plan contains any
    //  fetch-failure Skipped row (Reason "Fetch failed: ...") so RunBulkReschedule
    //  can surface failures instead of the generic message.
    //
    //  RED: AnyFetchFailure is currently a stub returning false. The negative case
    //  (no fetch-failure rows) passes trivially; the positive case (a fetch-failure
    //  row present) FAILS. The negative assertion also guards against a trivial
    //  "always return true" GREEN implementation.
    // -----------------------------------------------------------------------
    [Test]
    procedure BulkReschedule_AnyFetchFailure_TrueOnlyWhenFetchFailedRowsPresent()
    var
        TempPlan: Record "D4P BC Reschedule Plan Line" temporary;
        TenantId1: Guid;
        TenantId2: Guid;
    begin
        Evaluate(TenantId1, '{50000000-0000-0000-0000-000000000001}');
        Evaluate(TenantId2, '{50000000-0000-0000-0000-000000000002}');

        // GIVEN a plan with only a genuine "no updates available" Skipped row → no fetch failure.
        TempPlan.Init();
        TempPlan."Entry No." := 1;
        TempPlan."Customer No." := 'TBULK-C2';
        TempPlan."Tenant ID" := TenantId1;
        TempPlan."Environment Name" := 'NOUPD-ENV';
        TempPlan.Result := TempPlan.Result::Skipped;
        TempPlan.Reason := 'No updates available';
        TempPlan.Insert();

        Assert.IsFalse(Orchestrator.AnyFetchFailure(TempPlan),
            'AnyFetchFailure must be false when the only Skipped row is a genuine no-updates row');

        // WHEN a fetch-failure Skipped row (Reason "Fetch failed: ...") is added.
        TempPlan.Init();
        TempPlan."Entry No." := 2;
        TempPlan."Customer No." := 'TBULK-C2';
        TempPlan."Tenant ID" := TenantId2;
        TempPlan."Environment Name" := 'FETCHFAIL-ENV';
        TempPlan.Result := TempPlan.Result::Skipped;
        TempPlan.Reason := 'Fetch failed: simulated HTTP error for environment FETCHFAIL-ENV';
        TempPlan.Insert();

        // THEN the helper must report a fetch failure is present.
        Assert.IsTrue(Orchestrator.AnyFetchFailure(TempPlan),
            'AnyFetchFailure must be true when the plan contains a fetch-failure Skipped row (Reason "Fetch failed: ...")');
    end;

    // -----------------------------------------------------------------------
    //  T-a — BuildPlan computes the fixture's expected DEFAULTS on a Pending row
    //
    //  Requirement: BuildPlan, for an env with a single genuinely-available update,
    //  must derive the plan row's defaults from the fetched candidate — Target
    //  Version, Selected Date (pre-filled to the deadline), Latest Selectable Date,
    //  and Available — BEFORE the user touches anything. This asserts the computed
    //  values directly (no overwrite), so a regression that left them blank/wrong
    //  would be caught. Fixture: 27.5, available, deadline 01-06-2030 (future, so
    //  the past-date guard does not fire), Expected Month/Year 0 (available path).
    // -----------------------------------------------------------------------
    [Test]
    procedure BulkReschedule_BuildPlan_ComputesFixtureDefaultsOnPendingRow()
    var
        BCEnv: Record "D4P BC Environment";
        TempPlan: Record "D4P BC Reschedule Plan Line" temporary;
        CustNo: Code[20];
    begin
        // GIVEN one env whose only update is 27.5, available, deadline 01-06-2030.
        Initialize();
        MockAPI.Reset();
        CustNo := EnsureCustomer('TBULK-TA');

        CreateTestEnv(BCEnv, CustNo, TenantIdA, 'DEFAULTS-ENV');
        MockAPI.SetFixtureForEnv('DEFAULTS-ENV', '27.5|true|01-06-2030|6|2030');

        Orchestrator.SetAdminAPI(MockAPI);

        // WHEN BuildPlan derives the default plan row.
        BCEnv.SetRange("Customer No.", CustNo);
        Orchestrator.BuildPlan(BCEnv, TempPlan);

        // THEN — assert the computed defaults BEFORE any overwrite.
        TempPlan.Reset();
        TempPlan.SetRange("Environment Name", 'DEFAULTS-ENV');
        Assert.IsTrue(TempPlan.FindFirst(), 'Expected a plan row for DEFAULTS-ENV');

        Assert.AreEqual(TempPlan.Result::Pending, TempPlan.Result,
            'An env with an available update must yield a Pending row');
        Assert.AreEqual('27.5', TempPlan."Target Version",
            'BuildPlan must pick the available candidate 27.5 as the default Target Version');
        Assert.AreEqual(DMY2Date(1, 6, 2030), TempPlan."Selected Date",
            'BuildPlan must pre-fill Selected Date with the candidate''s latest selectable date (the deadline)');
        Assert.AreEqual(DMY2Date(1, 6, 2030), TempPlan."Latest Selectable Date",
            'BuildPlan must copy the candidate''s latest selectable date onto the plan row');
        Assert.IsTrue(TempPlan.Available,
            'A genuinely available candidate (available=true) must set Available=true on the plan row');
        // Available path leaves Expected Month/Year at 0 (those belong to unreleased candidates).
        Assert.AreEqual(0, TempPlan."Expected Month",
            'Expected Month must be 0 for an available candidate');
        Assert.AreEqual(0, TempPlan."Expected Year",
            'Expected Year must be 0 for an available candidate');
    end;

    // -----------------------------------------------------------------------
    //  T-b — Apply payload carries the version/date BuildPlan computed
    //
    //  Requirement: on apply, the orchestrator must send to the Admin API exactly
    //  the Target Version and Selected Date that BuildPlan computed for the env —
    //  not a hard-coded literal. The mock logs the full apply payload as
    //  "Env|Version|Date|branch". This test reads the computed Version/Date from
    //  the Pending row (does NOT overwrite them) and asserts the logged call's
    //  "Env|Version|Date|" prefix is built from those exact computed values, so a
    //  blank/wrong version or date reaching the API would fail.
    // -----------------------------------------------------------------------
    [Test]
    procedure BulkReschedule_ApplyPayload_UsesComputedVersionAndDate()
    var
        BCEnv: Record "D4P BC Environment";
        TempPlan: Record "D4P BC Reschedule Plan Line" temporary;
        SelectCalls: List of [Text];
        CustNo: Code[20];
        ComputedVersion: Text[100];
        ComputedDate: Date;
        ExpectedPrefix: Text;
    begin
        // GIVEN one env with an available update (future deadline so it stays actionable).
        Initialize();
        MockAPI.Reset();
        CustNo := EnsureCustomer('TBULK-TB');

        CreateTestEnv(BCEnv, CustNo, TenantIdA, 'PAYLOAD-ENV');
        MockAPI.SetFixtureForEnv('PAYLOAD-ENV', '27.5|true|01-06-2030|6|2030');

        Orchestrator.SetAdminAPI(MockAPI);

        BCEnv.SetRange("Customer No.", CustNo);
        Orchestrator.BuildPlan(BCEnv, TempPlan);

        // Capture the values BuildPlan computed — DO NOT overwrite them with a literal.
        TempPlan.Reset();
        TempPlan.SetRange("Environment Name", 'PAYLOAD-ENV');
        Assert.IsTrue(TempPlan.FindFirst(), 'Expected a plan row for PAYLOAD-ENV');
        ComputedVersion := TempPlan."Target Version";
        ComputedDate := TempPlan."Selected Date";
        Assert.AreNotEqual('', ComputedVersion, 'Pre-condition: BuildPlan must have computed a non-blank version');

        // WHEN the (computed, un-overwritten) Pending plan is applied.
        Orchestrator.ApplyPlan(TempPlan);

        // THEN the logged apply payload's Env|Version|Date prefix is built from the
        // EXACT values BuildPlan computed. ExpectedPrefix is formatted with the same
        // StrSubstNo the mock uses, so locale-dependent Date formatting cancels out.
        SelectCalls := MockAPI.GetSelectCalls();
        Assert.AreEqual(1, SelectCalls.Count(),
            'SelectTargetVersion must be called exactly once for the single PAYLOAD-ENV');
        ExpectedPrefix := StrSubstNo('%1|%2|%3|', 'PAYLOAD-ENV', ComputedVersion, ComputedDate);
        Assert.AreEqual(1, StrPos(SelectCalls.Get(1), ExpectedPrefix),
            StrSubstNo('Apply payload must carry the computed version/date. Expected prefix "%1", got: "%2"',
                ExpectedPrefix, SelectCalls.Get(1)));
    end;

    // -----------------------------------------------------------------------
    //  T-d — Retry Failed: ≥2 Failed rows reset to Pending and re-applied exactly
    //        once; Succeeded and Skipped rows left untouched
    //
    //  Requirement: the "Retry Failed" gesture re-applies ONLY the rows that
    //  failed, exactly once each, and never re-touches rows that already
    //  Succeeded or were Skipped.
    //
    //  The page's RetryFailedRows is a LOCAL page procedure (page 62033) and is
    //  not directly invocable from a test, nor drivable via TestPage because its
    //  SetData/SetOrchestrator/SetAdminAPI seams take var-record/codeunit params.
    //  This test reproduces RetryFailedRows' exact production sequence — filter
    //  Result=Failed, reset those rows to Pending with Reason cleared, then call
    //  the SAME production orchestrator.ApplyPlan — so it exercises the real
    //  re-apply path the action delegates to.
    //
    //  Layout: ENV-A,ENV-D succeed; ENV-B,ENV-C fail; SKIP-ENV has no fixture so
    //  BuildPlan marks it Skipped (never Pending, never applied).
    // -----------------------------------------------------------------------
    [Test]
    procedure BulkReschedule_RetryFailed_ReappliesOnlyFailedRowsExactlyOnce()
    var
        BCEnv: Record "D4P BC Environment";
        TempPlan: Record "D4P BC Reschedule Plan Line" temporary;
        SelectCalls: List of [Text];
        CustNo: Code[20];
        TenantIdD2: Guid;
        TenantIdSkip: Guid;
        EnvACount: Integer;
        EnvBCount: Integer;
        EnvCCount: Integer;
        EnvDCount: Integer;
        SkipCount: Integer;
        I: Integer;
        Entry: Text;
    begin
        // Arrange — run 1
        Initialize();
        MockAPI.Reset();
        CustNo := EnsureCustomer('TBULK-TD');
        Evaluate(TenantIdD2, '{60000000-0000-0000-0000-000000000004}');
        Evaluate(TenantIdSkip, '{60000000-0000-0000-0000-000000000005}');

        CreateTestEnv(BCEnv, CustNo, TenantIdA, 'ENV-A');
        CreateTestEnv(BCEnv, CustNo, TenantIdB, 'ENV-B');
        CreateTestEnv(BCEnv, CustNo, TenantIdC, 'ENV-C');
        CreateTestEnv(BCEnv, CustNo, TenantIdD2, 'ENV-D');
        CreateTestEnv(BCEnv, CustNo, TenantIdSkip, 'SKIP-ENV');

        MockAPI.SetFixtureForEnv('ENV-A', '27.5|true|01-06-2030|6|2030');
        MockAPI.SetFixtureForEnv('ENV-B', '27.5|true|01-06-2030|6|2030');
        MockAPI.SetFixtureForEnv('ENV-C', '27.5|true|01-06-2030|6|2030');
        MockAPI.SetFixtureForEnv('ENV-D', '27.5|true|01-06-2030|6|2030');
        // SKIP-ENV: no fixture → BuildPlan marks it Skipped (no updates available).

        // ENV-B and ENV-C fail on the first run.
        MockAPI.ForceFailOn('ENV-B');
        MockAPI.ForceFailOn('ENV-C');

        Orchestrator.SetAdminAPI(MockAPI);

        BCEnv.SetRange("Customer No.", CustNo);
        Orchestrator.BuildPlan(BCEnv, TempPlan);

        // Accept defaults for all Pending rows (the 4 real-fixture envs).
        TempPlan.SetRange(Result, TempPlan.Result::Pending);
        if TempPlan.FindSet(true) then
            repeat
                TempPlan."Target Version" := '27.5';
                TempPlan.Modify();
            until TempPlan.Next() = 0;

        // Run 1
        Orchestrator.ApplyPlan(TempPlan);

        // Verify pre-retry state: A,D Succeeded; B,C Failed; SKIP-ENV Skipped.
        AssertEnvResult(TempPlan, 'ENV-A', TempPlan.Result::Succeeded);
        AssertEnvResult(TempPlan, 'ENV-D', TempPlan.Result::Succeeded);
        AssertEnvResult(TempPlan, 'ENV-B', TempPlan.Result::Failed);
        AssertEnvResult(TempPlan, 'ENV-C', TempPlan.Result::Failed);
        AssertEnvResult(TempPlan, 'SKIP-ENV', TempPlan.Result::Skipped);

        // Clear forced failures so the retry succeeds.
        MockAPI.ClearFailures();

        // Act — reproduce RetryFailedRows' production sequence exactly:
        //   filter Result=Failed, reset those rows to Pending + clear Reason, then ApplyPlan.
        TempPlan.Reset();
        TempPlan.SetRange(Result, TempPlan.Result::Failed);
        Assert.IsTrue(TempPlan.FindSet(), 'Pre-condition: there must be ≥1 Failed row to retry');
        repeat
            TempPlan.Result := TempPlan.Result::Pending;
            TempPlan.Reason := '';
            TempPlan.Modify(false);
        until TempPlan.Next() = 0;
        TempPlan.Reset();

        Orchestrator.ApplyPlan(TempPlan);

        // Assert — post-retry: B,C now Succeeded; A,D still Succeeded; SKIP-ENV still Skipped.
        AssertEnvResult(TempPlan, 'ENV-B', TempPlan.Result::Succeeded);
        AssertEnvResult(TempPlan, 'ENV-C', TempPlan.Result::Succeeded);
        AssertEnvResult(TempPlan, 'ENV-A', TempPlan.Result::Succeeded);
        AssertEnvResult(TempPlan, 'ENV-D', TempPlan.Result::Succeeded);
        AssertEnvResult(TempPlan, 'SKIP-ENV', TempPlan.Result::Skipped);

        // Assert — call accounting proves "re-applied exactly once" and "untouched":
        //   ENV-A,ENV-D each applied once (run 1 only — NOT retried).
        //   ENV-B,ENV-C each applied twice (run 1 fail + retry).
        //   SKIP-ENV never applied.
        SelectCalls := MockAPI.GetSelectCalls();
        for I := 1 to SelectCalls.Count() do begin
            Entry := SelectCalls.Get(I);
            if StrPos(Entry, 'ENV-A|') = 1 then
                EnvACount += 1;
            if StrPos(Entry, 'ENV-B|') = 1 then
                EnvBCount += 1;
            if StrPos(Entry, 'ENV-C|') = 1 then
                EnvCCount += 1;
            if StrPos(Entry, 'ENV-D|') = 1 then
                EnvDCount += 1;
            if StrPos(Entry, 'SKIP-ENV|') = 1 then
                SkipCount += 1;
        end;

        Assert.AreEqual(1, EnvACount, 'ENV-A must be applied exactly once (Succeeded row not retried)');
        Assert.AreEqual(1, EnvDCount, 'ENV-D must be applied exactly once (Succeeded row not retried)');
        Assert.AreEqual(2, EnvBCount, 'ENV-B must be applied exactly twice (run 1 failed + retry once)');
        Assert.AreEqual(2, EnvCCount, 'ENV-C must be applied exactly twice (run 1 failed + retry once)');
        Assert.AreEqual(0, SkipCount, 'SKIP-ENV must never be applied (it was Skipped, not Pending)');
        Assert.AreEqual(6, SelectCalls.Count(), 'Total apply calls must be 6: A,D once + B,C twice');
    end;

    // -----------------------------------------------------------------------
    //  T-f — EnvGoneErr path: a Pending row whose env no longer exists in the
    //        local D4P BC Environment table is marked Failed with a naming Reason
    //
    //  Requirement: if the (Customer No., Tenant ID, Environment Name) of a Pending
    //  plan row matches no D4P BC Environment record at apply time (deleted between
    //  BuildPlan and ApplyPlan, or fabricated), ApplyPlan must mark it Failed with a
    //  Reason that names the env and explains it no longer exists — not an opaque
    //  downstream failure. No Admin API apply call must be made for that row.
    // -----------------------------------------------------------------------
    [Test]
    procedure BulkReschedule_EnvNoLongerExists_MarkedFailedWithNamingReason()
    var
        TempPlan: Record "D4P BC Reschedule Plan Line" temporary;
        SelectCalls: List of [Text];
        TenantIdGhost: Guid;
    begin
        // GIVEN a Pending plan row for an env that is NOT in the database.
        Evaluate(TenantIdGhost, '{70000000-0000-0000-0000-000000000001}');
        MockAPI.Reset();
        Orchestrator.SetAdminAPI(MockAPI);

        TempPlan.Init();
        TempPlan."Entry No." := 1;
        TempPlan."Customer No." := 'TBULK-TF';
        TempPlan."Tenant ID" := TenantIdGhost;
        TempPlan."Environment Name" := 'GHOST-ENV';
        TempPlan."Target Version" := '27.5';
        TempPlan."Selected Date" := DMY2Date(1, 6, 2030);
        TempPlan.Available := true;
        TempPlan.Result := TempPlan.Result::Pending;
        TempPlan.Insert();

        // WHEN the plan is applied and the env cannot be Get()-ed.
        Orchestrator.ApplyPlan(TempPlan);

        // THEN the row is Failed with a Reason naming the env / "no longer exists".
        TempPlan.Reset();
        TempPlan.SetRange("Environment Name", 'GHOST-ENV');
        Assert.IsTrue(TempPlan.FindFirst(), 'Expected the GHOST-ENV plan row');
        Assert.AreEqual(TempPlan.Result::Failed, TempPlan.Result,
            'A Pending row whose env no longer exists must be marked Failed');
        Assert.IsTrue(
            StrPos(TempPlan.Reason, 'GHOST-ENV') > 0,
            StrSubstNo('Failure Reason must name the missing env GHOST-ENV, got: %1', TempPlan.Reason));
        Assert.IsTrue(
            StrPos(LowerCase(TempPlan.Reason), 'no longer exist') > 0,
            StrSubstNo('Failure Reason must explain the env no longer exists, got: %1', TempPlan.Reason));

        // AND no Admin API apply call was made for a non-existent env.
        SelectCalls := MockAPI.GetSelectCalls();
        Assert.AreEqual(0, SelectCalls.Count(),
            'SelectTargetVersion must not be called for an env that no longer exists');
    end;

    // -----------------------------------------------------------------------
    //  T-g — Multi-version fixture end-to-end: orchestrator picks the highest
    //        available version with its date, proven before any overwrite
    //
    //  Requirement: when an env's fetch returns several available versions, the
    //  full BuildPlan path (mock fetch → parser PickDefaultTargetVersion →
    //  plan row) must select the highest semantic version (27.10 > 27.9, NOT a
    //  lexicographic pick) and carry that winner's date. Proven end-to-end on the
    //  computed Pending row before the user overwrites anything.
    // -----------------------------------------------------------------------
    [Test]
    procedure BulkReschedule_MultiVersionFixture_PicksHighestEndToEnd()
    var
        BCEnv: Record "D4P BC Environment";
        TempPlan: Record "D4P BC Reschedule Plan Line" temporary;
        CustNo: Code[20];
    begin
        // GIVEN one env whose fetch returns 27.9 AND 27.10, both available, with
        // distinct deadlines (future, so the past-date guard does not fire).
        Initialize();
        MockAPI.Reset();
        CustNo := EnsureCustomer('TBULK-TG');

        CreateTestEnv(BCEnv, CustNo, TenantIdA, 'MULTI-ENV');
        MockAPI.SetFixtureForEnv('MULTI-ENV', '27.9|true|15-05-2030|0|0\n27.10|true|15-06-2030|0|0');

        Orchestrator.SetAdminAPI(MockAPI);

        // WHEN BuildPlan derives the default plan row.
        BCEnv.SetRange("Customer No.", CustNo);
        Orchestrator.BuildPlan(BCEnv, TempPlan);

        // THEN — before any overwrite — the row targets the HIGHEST version 27.10
        // with its date 15-06-2030 (a lexicographic compare would wrongly pick 27.9).
        TempPlan.Reset();
        TempPlan.SetRange("Environment Name", 'MULTI-ENV');
        Assert.IsTrue(TempPlan.FindFirst(), 'Expected a plan row for MULTI-ENV');
        Assert.AreEqual(TempPlan.Result::Pending, TempPlan.Result,
            'Multi-available env must produce a Pending row');
        Assert.AreEqual('27.10', TempPlan."Target Version",
            'BuildPlan must select the highest semantic version 27.10 (not lexicographic 27.9) end-to-end');
        Assert.AreEqual(DMY2Date(15, 6, 2030), TempPlan."Selected Date",
            'Selected Date must be the winning version 27.10''s latest selectable date');
        Assert.IsTrue(TempPlan.Available,
            '27.10 is available, so the plan row must be Available=true');
    end;

    // -----------------------------------------------------------------------
    //  Helpers
    // -----------------------------------------------------------------------

    /// <summary>
    /// Asserts the single plan row for EnvName has the expected Result. Resets the
    /// filter so callers can reuse TempPlan immediately after.
    /// </summary>
    local procedure AssertEnvResult(var TempPlan: Record "D4P BC Reschedule Plan Line" temporary; EnvName: Text; ExpectedResult: Enum "D4P Reschedule Result")
    begin
        TempPlan.Reset();
        TempPlan.SetRange("Environment Name", EnvName);
        Assert.IsTrue(TempPlan.FindFirst(), StrSubstNo('Expected a plan row for %1', EnvName));
        // Compare ordinals and keep the message free of Format(Enum) so the eagerly-evaluated
        // message text does not trip the al-runner-only Format(Enum) quirk on a passing run.
        Assert.AreEqual(ExpectedResult.AsInteger(), TempPlan.Result.AsInteger(),
            StrSubstNo('%1 has an unexpected Result (ordinal mismatch)', EnvName));
        TempPlan.Reset();
    end;

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
