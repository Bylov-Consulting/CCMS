namespace D4P.CCMS.API;

using D4P.CCMS.Telemetry;

page 62070 "D4P KQL Ext Lifecycle API"
{
    PageType = API;
    Caption = 'D4P KQL Ext Lifecycle API', Locked = true;
    APIPublisher = 'bylov';
    APIGroup = 'ccms';
    APIVersion = 'v1.0';
    EntityName = 'kqlExtensionLifecycle';
    EntitySetName = 'kqlExtensionLifecycles';
    EntityCaption = 'KQL Extension Lifecycle';
    EntitySetCaption = 'KQL Extension Lifecycles';
    SourceTable = "D4P KQL Extension Lifecycle";
    DelayedInsert = true;
    ODataKeyFields = SystemId;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(systemId; Rec.SystemId)
                {
                    Caption = 'System Id';
                }
                field(environmentCode; Rec."Environment Code")
                {
                    Caption = 'Environment Code';
                }
                field(entryNo; Rec."Entry No.")
                {
                    Caption = 'Entry No.';
                }
                field(userId; Rec."User ID")
                {
                    Caption = 'User Id';
                }
                field(extensionName; Rec."Extension Name")
                {
                    Caption = 'Extension Name';
                }
                field(extensionId; Rec."Extension ID")
                {
                    Caption = 'Extension Id';
                }
                field(publisher; Rec.Publisher)
                {
                    Caption = 'Publisher';
                }
                field(version; Rec.Version)
                {
                    Caption = 'Version';
                }
                field(eventId; Rec."Event ID")
                {
                    Caption = 'Event Id';
                }
                field(message; Rec.Message)
                {
                    Caption = 'Message';
                }
                field(result; Rec.Result)
                {
                    Caption = 'Result';
                }
                field(execDateTime; Rec."Exec. Date/Time")
                {
                    Caption = 'Exec. Date/Time';
                }
                field(tenantId; Rec."Tenant ID")
                {
                    Caption = 'Tenant Id';
                }
                field(syncMode; Rec."Sync. Mode")
                {
                    Caption = 'Sync. Mode';
                }
                field(executionTime; Rec."Execution Time")
                {
                    Caption = 'Execution Time';
                }
                field(failureReason; Rec."Failure Reason")
                {
                    Caption = 'Failure Reason';
                }
                field(environmentType; Rec."Environment Type")
                {
                    Caption = 'Environment Type';
                }
                field(environmentName; Rec."Environment Name")
                {
                    Caption = 'Environment Name';
                }
                field(systemModifiedAt; Rec.SystemModifiedAt)
                {
                    Caption = 'System Modified At';
                }
            }
        }
    }
}
