// ============================================================================
//  D4P Apply Recorder Subscriber — codeunit 62104
//  Manual-binding subscriber used by BulkRescheduleTests T2
//  (BulkReschedule_OnAfterApplyReschedule_FiresForEveryProcessedEnv).
//
//  Records one entry per OnAfterApplyReschedule call in the format:
//    "<EnvironmentName>|<Result>"
//  e.g. "PROD-A|Succeeded", "SANDBOX-MID|Failed"
//
//  EventSubscriberInstance = Manual requires the test to call
//  BindSubscription/UnbindSubscription explicitly.
// ============================================================================
codeunit 62104 "D4P Apply Recorder Subscriber"
{
    EventSubscriberInstance = Manual;

    var
        CallLog: List of [Text];

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"D4P BC Bulk Reschedule Mgt", 'OnAfterApplyReschedule', '', false, false)]
    procedure OnAfterApplyReschedule_Record(var PlanLine: Record "D4P BC Reschedule Plan Line" temporary)
    begin
        CallLog.Add(PlanLine."Environment Name" + '|' + Format(PlanLine.Result));
    end;

    /// <summary>
    /// Returns the recorded entries. Each entry is "EnvName|Result".
    /// </summary>
    procedure GetCalls(): List of [Text]
    begin
        exit(CallLog);
    end;

    /// <summary>
    /// Clears all recorded entries. Call between test runs when reusing the subscriber.
    /// </summary>
    procedure ClearCalls()
    begin
        Clear(CallLog);
    end;
}
