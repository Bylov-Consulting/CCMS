namespace D4P.CCMS.Connector.RestClientOAuth;
page 62035 "D4P Entra App Registr. List"
{
    PageType = List;
    Caption = 'Microsoft Entra App Registrations';
    SourceTable = "D4P Entra App Registration";
    CardPageId = "D4P Entra App Registr. Card";
    ApplicationArea = All;
    UsageCategory = Administration;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(records)
            {
                field(Code; Rec.Code) { }
                field(AppId; Rec."App ID") { }
                field(DisplayName; Rec."Display Name") { }
                field(PublisherDomain; Rec."Publisher Tenant Id") { }
                field(SupportedAccountTypes; Rec."Supported Account Types") { }
            }
        }
    }
}