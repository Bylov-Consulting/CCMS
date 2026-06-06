namespace D4P.CCMS.API;

using D4P.CCMS.Telemetry;

page 62057 "D4P KQL Page Execution API"
{
    PageType = API;
    Caption = 'D4P KQL Page Execution API', Locked = true;
    APIPublisher = 'bylov';
    APIGroup = 'ccms';
    APIVersion = 'v1.0';
    EntityName = 'kqlPageExecution';
    EntitySetName = 'kqlPageExecutions';
    EntityCaption = 'KQL Page Execution';
    EntitySetCaption = 'KQL Page Executions';
    SourceTable = "D4P KQL Page Execution";
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
                field(pageName; Rec."Page Name")
                {
                    Caption = 'Page Name';
                }
                field(executionDate; Rec."Execution Date")
                {
                    Caption = 'Execution Date';
                }
                field(executionDateTime; Rec."Execution Date/Time")
                {
                    Caption = 'Execution Date/Time';
                }
                field(averageExecutionTime; Rec."Average Execution Time")
                {
                    Caption = 'Average Execution Time';
                }
                field(maxExecutionTime; Rec."Max. Execution Time")
                {
                    Caption = 'Max. Execution Time';
                }
                field(noOfExecutions; Rec."No. Of Executions")
                {
                    Caption = 'No. of Executions';
                }
                field(pageId; Rec."Page ID")
                {
                    Caption = 'Page Id';
                }
                field(companyName; Rec."Company Name")
                {
                    Caption = 'Company Name';
                }
                field(tenantId; Rec."Tenant ID")
                {
                    Caption = 'Tenant Id';
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
