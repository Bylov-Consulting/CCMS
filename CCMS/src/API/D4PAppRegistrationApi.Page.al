namespace D4P.CCMS.API;

using D4P.CCMS.Auth;

page 62065 "D4P App Registration API"
{
    PageType = API;
    Caption = 'D4P App Registration API', Locked = true;
    APIPublisher = 'bylov';
    APIGroup = 'ccms';
    APIVersion = 'v1.0';
    EntityName = 'appRegistration';
    EntitySetName = 'appRegistrations';
    EntityCaption = 'App Registration';
    EntitySetCaption = 'App Registrations';
    SourceTable = "D4P BC App Registration";
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
                field(clientId; Rec."Client ID")
                {
                    Caption = 'Client Id';
                }
                field(description; Rec.Description)
                {
                    Caption = 'Description';
                }
                field(secretExpirationDate; Rec."Secret Expiration Date")
                {
                    Caption = 'Secret Expiration Date';
                }
                field(systemModifiedAt; Rec.SystemModifiedAt)
                {
                    Caption = 'System Modified At';
                }
            }
        }
    }
}
