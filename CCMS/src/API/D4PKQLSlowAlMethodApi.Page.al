namespace D4P.CCMS.API;

using D4P.CCMS.Telemetry;

page 62059 "D4P KQL Slow AL Method API"
{
    PageType = API;
    Caption = 'D4P KQL Slow AL Method API', Locked = true;
    APIPublisher = 'bylov';
    APIGroup = 'ccms';
    APIVersion = 'v1.0';
    EntityName = 'kqlSlowAlMethod';
    EntitySetName = 'kqlSlowAlMethods';
    EntityCaption = 'KQL Slow AL Method';
    EntitySetCaption = 'KQL Slow AL Methods';
    SourceTable = "D4P KQL Slow AL Method";
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
                field(executionDate; Rec."Execution Date")
                {
                    Caption = 'Execution Date';
                }
                field(executionDateTime; Rec."Execution Date/Time")
                {
                    Caption = 'Execution Date/Time';
                }
                field(tenantId; Rec."Tenant ID")
                {
                    Caption = 'Tenant Id';
                }
                field(extensionId; Rec."Extension ID")
                {
                    Caption = 'Extension Id';
                }
                field(extensionName; Rec."Extension Name")
                {
                    Caption = 'Extension Name';
                }
                field(companyName; Rec."Company Name")
                {
                    Caption = 'Company Name';
                }
                field(alObjectId; Rec."AL Object ID")
                {
                    Caption = 'AL Object Id';
                }
                field(alObjectType; Rec."AL Object Type")
                {
                    Caption = 'AL Object Type';
                }
                field(alObjectName; Rec."AL Object Name")
                {
                    Caption = 'AL Object Name';
                }
                field(methodName; Rec."Method Name")
                {
                    Caption = 'Method Name';
                }
                field(clientType; Rec."Client Type")
                {
                    Caption = 'Client Type';
                }
                field(maxExecutionTime; Rec."Max. Execution Time")
                {
                    Caption = 'Max. Execution Time';
                }
                field(publisher; Rec.Publisher)
                {
                    Caption = 'Publisher';
                }
                field(version; Rec.Version)
                {
                    Caption = 'Version';
                }
                field(noOfExecutions; Rec."No. of Executions")
                {
                    Caption = 'No. of Executions';
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
