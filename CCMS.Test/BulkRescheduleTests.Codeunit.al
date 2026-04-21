codeunit 62101 "D4P Bulk Reschedule Tests"
{
    Subtype = Test;
    TestIsolation = Codeunit;

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

        // Assert
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

        // Assert
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
