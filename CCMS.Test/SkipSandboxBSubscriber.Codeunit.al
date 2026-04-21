// ============================================================================
//  D4P Skip Sandbox B Subscriber — codeunit 62103
//  Manual-binding subscriber used by BulkRescheduleTests test 5
//  (BulkReschedule_SubscriberSkips_ApplyNotCalled).
//
//  AL0501 requires event subscribers declared inside test codeunits (Subtype =
//  Test) to use manual binding. Keeping this in a separate non-test codeunit
//  lets the test codeunit preserve default [Test] discovery semantics while
//  the test opts in/out of the subscription via BindSubscription/
//  UnbindSubscription.
// ============================================================================
codeunit 62103 "D4P Skip Sandbox B Subscriber"
{
    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"D4P BC Bulk Reschedule Mgt", 'OnBeforeApplyReschedule', '', false, false)]
    procedure OnBeforeApplyReschedule_SkipSandboxB(var PlanLine: Record "D4P BC Reschedule Plan Line" temporary; var Skip: Boolean)
    begin
        if PlanLine."Environment Name" = 'SANDBOX-B' then
            Skip := true;
    end;
}
