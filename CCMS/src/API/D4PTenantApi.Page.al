namespace D4P.CCMS.API;

using D4P.CCMS.Tenant;

page 62067 "D4P Tenant API"
{
    PageType = API;
    Caption = 'D4P Tenant API', Locked = true;
    APIPublisher = 'bylov';
    APIGroup = 'ccms';
    APIVersion = 'v1.0';
    EntityName = 'tenant';
    EntitySetName = 'tenants';
    EntityCaption = 'Tenant';
    EntitySetCaption = 'Tenants';
    SourceTable = "D4P BC Tenant";
    DelayedInsert = true;
    ODataKeyFields = SystemId;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(systemId; Rec.SystemId)
                {
                    Caption = 'System Id';
                    Editable = false;
                }
                field(customerNo; Rec."Customer No.")
                {
                    Caption = 'Customer No.';
                }
                field(tenantId; Rec."Tenant ID")
                {
                    Caption = 'Tenant Id';
                }
                field(tenantName; Rec."Tenant Name")
                {
                    Caption = 'Tenant Name';
                }
                field(clientId; Rec."Client ID")
                {
                    Caption = 'Client Id';
                }
                field(appRegistrationType; Rec."App Registration Type")
                {
                    Caption = 'App Registration Type';
                }
                field(secretExpirationDate; Rec."Secret Expiration Date")
                {
                    Caption = 'Secret Expiration Date';
                }
                field(backupSasUri; Rec."Backup SAS URI")
                {
                    Caption = 'Backup SAS URI';
                }
                field(backupContainerName; Rec."Backup Container Name")
                {
                    Caption = 'Backup Container Name';
                }
                field(backupSasTokenExpDate; Rec."Backup SAS Token Exp. Date")
                {
                    Caption = 'Backup SAS Token Expiration Date';
                }
                field(customerName; Rec."Customer Name")
                {
                    Caption = 'Customer Name';
                    Editable = false;
                }
                field(systemModifiedAt; Rec.SystemModifiedAt)
                {
                    Caption = 'System Modified At';
                    Editable = false;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        Rec.CalcFields("Customer Name");
    end;
}
