// ============================================================================
//  D4P Veto All Subscriber — codeunit 62105
//  Manual-binding subscriber used by BulkRescheduleTests U4
//  (BulkReschedule_SubscriberVetoesAll_NoApiCallsAllSkipped).
//
//  Unlike D4P Skip Sandbox B Subscriber (62103) which vetoes only one named
//  environment, this subscriber unconditionally sets Skip := true for every
//  environment it is called for.  Binding it before ApplyPlan guarantees that
//  no API call is made regardless of the plan contents, letting U4 verify that
//  the skip-and-continue path produces all-Skipped rows without any
//  SelectTargetVersion invocations.
//
//  EventSubscriberInstance = Manual requires the test to call
//  BindSubscription / UnbindSubscription explicitly.
// ============================================================================
codeunit 62105 "D4P Veto All Subscriber"
{
    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"D4P BC Bulk Reschedule Mgt", 'OnBeforeApplyReschedule', '', false, false)]
    procedure OnBeforeApplyReschedule_VetoAll(var PlanLine: Record "D4P BC Reschedule Plan Line" temporary; var Skip: Boolean)
    begin
        Skip := true;
    end;
}
