namespace D4P.CCMS.API;

using D4P.CCMS.Capacity;

page 62062 "D4P Capacity Line API"
{
    PageType = API;
    Caption = 'D4P Capacity Line API', Locked = true;
    APIPublisher = 'bylov';
    APIGroup = 'ccms';
    APIVersion = 'v1.0';
    EntityName = 'capacityLine';
    EntitySetName = 'capacityLines';
    EntityCaption = 'Capacity Line';
    EntitySetCaption = 'Capacity Lines';
    SourceTable = "D4P BC Capacity Line";
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
                field(customerNo; Rec."Customer No.")
                {
                    Caption = 'Customer No.';
                }
                field(tenantId; Rec."Tenant ID")
                {
                    Caption = 'Tenant Id';
                }
                field(lineNo; Rec."Line No.")
                {
                    Caption = 'Line No.';
                }
                field(environmentName; Rec."Environment Name")
                {
                    Caption = 'Environment Name';
                }
                field(environmentType; Rec."Environment Type")
                {
                    Caption = 'Environment Type';
                }
                field(applicationFamily; Rec."Application Family")
                {
                    Caption = 'Application Family';
                }
                field(measurementDate; Rec."Measurement Date")
                {
                    Caption = 'Measurement Date';
                }
                field(databaseStorageKb; Rec."Database Storage KB")
                {
                    Caption = 'Database Storage KB';
                }
                field(databaseStorageMb; Rec."Database Storage MB")
                {
                    Caption = 'Database Storage MB';
                }
                field(databaseStorageGb; Rec."Database Storage GB")
                {
                    Caption = 'Database Storage GB';
                }
                field(systemModifiedAt; Rec.SystemModifiedAt)
                {
                    Caption = 'System Modified At';
                }
            }
        }
    }
}
