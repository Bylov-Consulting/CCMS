namespace D4P.CCMS.API;

using D4P.CCMS.Backup;

page 62053 "D4P Environment Backup API"
{
    PageType = API;
    Caption = 'D4P Environment Backup API', Locked = true;
    APIPublisher = 'bylov';
    APIGroup = 'ccms';
    APIVersion = 'v1.0';
    EntityName = 'environmentBackup';
    EntitySetName = 'environmentBackups';
    EntityCaption = 'Environment Backup';
    EntitySetCaption = 'Environment Backups';
    SourceTable = "D4P BC Environment Backup";
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
                field(exportId; Rec."Export ID")
                {
                    Caption = 'Export Id';
                }
                field(customerNo; Rec."Customer No.")
                {
                    Caption = 'Customer No.';
                }
                field(tenantId; Rec."Tenant ID")
                {
                    Caption = 'Tenant Id';
                }
                field(environmentName; Rec."Environment Name")
                {
                    Caption = 'Environment Name';
                }
                field(applicationType; Rec."Application Type")
                {
                    Caption = 'Application Type';
                }
                field(applicationVersion; Rec."Application Version")
                {
                    Caption = 'Application Version';
                }
                field(countryCode; Rec."Country Code")
                {
                    Caption = 'Country Code';
                }
                field(exportStatus; Rec."Export Status")
                {
                    Caption = 'Export Status';
                }
                field(exportTime; Rec."Export Time")
                {
                    Caption = 'Export Time';
                }
                field(container; Rec."Container")
                {
                    Caption = 'Container';
                }
                field(blob; Rec."Blob")
                {
                    Caption = 'Blob';
                }
                field(exportedBy; Rec."Exported By")
                {
                    Caption = 'Exported By';
                }
                field(exportsPerMonth; Rec."Exports Per Month")
                {
                    Caption = 'Exports Per Month';
                }
                field(exportsRemainingThisMonth; Rec."Exports Remaining This Month")
                {
                    Caption = 'Exports Remaining This Month';
                }
                field(systemModifiedAt; Rec.SystemModifiedAt)
                {
                    Caption = 'System Modified At';
                }
            }
        }
    }
}
