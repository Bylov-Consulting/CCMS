namespace D4P.CCMS.API;

using D4P.CCMS.Telemetry;

page 62058 "D4P KQL Report Execution API"
{
    PageType = API;
    Caption = 'D4P KQL Report Execution API', Locked = true;
    APIPublisher = 'bylov';
    APIGroup = 'ccms';
    APIVersion = 'v1.0';
    EntityName = 'kqlReportExecution';
    EntitySetName = 'kqlReportExecutions';
    EntityCaption = 'KQL Report Execution';
    EntitySetCaption = 'KQL Report Executions';
    SourceTable = "D4P KQL Report Execution";
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
                field(reportName; Rec."Report Name")
                {
                    Caption = 'Report Name';
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
                field(averageRows; Rec."Average Rows")
                {
                    Caption = 'Average Rows';
                }
                field(maxExecutionTime; Rec."Max. Execution Time")
                {
                    Caption = 'Max. Execution Time';
                }
                field(maxRows; Rec."Max. Rows")
                {
                    Caption = 'Max. Rows';
                }
                field(noOfExecutions; Rec."No. of Executions")
                {
                    Caption = 'No. of Executions';
                }
                field(reportId; Rec."Report ID")
                {
                    Caption = 'Report Id';
                }
                field(extensionName; Rec."Extension Name")
                {
                    Caption = 'Extension Name';
                }
                field(companyName; Rec."Company Name")
                {
                    Caption = 'Company Name';
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
