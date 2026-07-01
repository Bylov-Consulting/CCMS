namespace D4P.CCMS.API;

using D4P.CCMS.Capacity;

page 62061 "D4P Capacity Header API"
{
    PageType = API;
    Caption = 'D4P Capacity Header API', Locked = true;
    APIPublisher = 'bylov';
    APIGroup = 'ccms';
    APIVersion = 'v1.0';
    EntityName = 'capacityHeader';
    EntitySetName = 'capacityHeaders';
    EntityCaption = 'Capacity Header';
    EntitySetCaption = 'Capacity Headers';
    SourceTable = "D4P BC Capacity Header";
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
                field(customerName; Rec."Customer Name")
                {
                    Caption = 'Customer Name';
                }
                field(tenantId; Rec."Tenant ID")
                {
                    Caption = 'Tenant Id';
                }
                field(tenantName; Rec."Tenant Name")
                {
                    Caption = 'Tenant Name';
                }
                field(lastUpdateDate; Rec."Last Update Date")
                {
                    Caption = 'Last Update Date';
                }
                field(storageDefaultGb; Rec."Storage Default GB")
                {
                    Caption = 'Storage Default GB';
                }
                field(storageUserLicensesGb; Rec."Storage User Licenses GB")
                {
                    Caption = 'Storage User Licenses GB';
                }
                field(storageAdditionalCapacityGb; Rec."Storage Additional Capacity GB")
                {
                    Caption = 'Storage Additional Capacity GB';
                }
                field(storageTotalGb; Rec."Storage Total GB")
                {
                    Caption = 'Storage Total GB';
                }
                field(totalStorageUsedGb; Rec."Total Storage Used GB")
                {
                    Caption = 'Total Storage Used GB';
                }
                field(storageAvailableGb; Rec."Storage Available GB")
                {
                    Caption = 'Storage Available GB';
                }
                field(usagePercent; Rec."Usage %")
                {
                    Caption = 'Usage %';
                }
                field(maxProductionEnvironments; Rec."Max Production Environments")
                {
                    Caption = 'Max Production Environments';
                }
                field(maxSandboxEnvironments; Rec."Max Sandbox Environments")
                {
                    Caption = 'Max Sandbox Environments';
                }
                field(productionEnvironmentsUsed; Rec."Production Environments Used")
                {
                    Caption = 'Production Environments Used';
                }
                field(sandboxEnvironmentsUsed; Rec."Sandbox Environments Used")
                {
                    Caption = 'Sandbox Environments Used';
                }
                field(productionEnvAvailable; Rec."Production Env. Available")
                {
                    Caption = 'Production Environments Available';
                }
                field(sandboxEnvAvailable; Rec."Sandbox Env. Available")
                {
                    Caption = 'Sandbox Environments Available';
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        Rec.CalcFields("Customer Name", "Tenant Name");
    end;
}
