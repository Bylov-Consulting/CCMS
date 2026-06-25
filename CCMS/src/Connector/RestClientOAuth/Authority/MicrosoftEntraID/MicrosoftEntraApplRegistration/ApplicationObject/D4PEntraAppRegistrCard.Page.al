namespace D4P.CCMS.Connector.RestClientOAuth;
page 62033 "D4P Entra App Registr. Card"
{
    Caption = 'Microsoft Entra App Registration';
    ApplicationArea = All;
    SourceTable = "D4P Entra App Registration";
    PageType = Card;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';
                field(Code; Rec.Code) { }
                field("Display Name"; Rec."Display Name") { }
                field("App ID"; Rec."App ID") { }
                field("Supported Account Types"; Rec."Supported Account Types") { }
                field("Publisher Tenant Id"; Rec."Publisher Tenant Id") { }
                field("Redirect Uri Type"; Rec."Redirect Uri Type") { }
                field("Redirect Uri"; Rec."Redirect Uri")
                {
                    Editable = RedirectURIEditable;
                    MultiLine = true;
                }
                field("Certificate Code"; Rec."Certificate Code") { }
            }
            part(Secrets; "D4P Entra Secret Subform")
            {
                SubPageLink = "Application Code" = field(Code);
            }
        }
    }

    var
        RedirectURIEditable: Boolean;

    trigger OnAfterGetRecord()
    var
        RedirectURI: Interface "D4P Redirect URI";
    begin
        RedirectURI := Rec."Redirect Uri Type";
        RedirectURIEditable := RedirectURI.RedirectURIEditable();
    end;
}