namespace D4P.CCMS.API;

using D4P.CCMS.Customer;

page 62066 "D4P Customer API"
{
    PageType = API;
    Caption = 'D4P Customer API', Locked = true;
    APIPublisher = 'bylov';
    APIGroup = 'ccms';
    APIVersion = 'v1.0';
    EntityName = 'customer';
    EntitySetName = 'customers';
    EntityCaption = 'Customer';
    EntitySetCaption = 'Customers';
    SourceTable = "D4P BC Customer";
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
                field(no; Rec."No.")
                {
                    Caption = 'No.';
                }
                field(name; Rec.Name)
                {
                    Caption = 'Name';
                }
                field(address; Rec.Address)
                {
                    Caption = 'Address';
                }
                field(address2; Rec."Address 2")
                {
                    Caption = 'Address 2';
                }
                field(city; Rec.City)
                {
                    Caption = 'City';
                }
                field(postCode; Rec."Post Code")
                {
                    Caption = 'Post Code';
                }
                field(county; Rec.County)
                {
                    Caption = 'County';
                }
                field(countryRegionCode; Rec."Country/Region Code")
                {
                    Caption = 'Country/Region Code';
                }
                field(contactPersonName; Rec."Contact Person Name")
                {
                    Caption = 'Contact Person Name';
                }
                field(contactPersonEmail; Rec."Contact Person Email")
                {
                    Caption = 'Contact Person Email';
                }
                field(noSeries; Rec."No. Series")
                {
                    Caption = 'No. Series';
                }
                field(tenants; Rec.Tenants)
                {
                    Caption = 'Tenants';
                    Editable = false;
                }
                field(allActiveEnvironments; Rec."All Active Environments")
                {
                    Caption = 'All Active Environments';
                    Editable = false;
                }
                field(activeProdEnvironments; Rec."Active Prod. Environments")
                {
                    Caption = 'Active Production Environments';
                    Editable = false;
                }
                field(activeSandEnvironments; Rec."Active Sand. Environments")
                {
                    Caption = 'Active Sandbox Environments';
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
        Rec.CalcFields(Tenants, "All Active Environments", "Active Prod. Environments", "Active Sand. Environments");
    end;
}
