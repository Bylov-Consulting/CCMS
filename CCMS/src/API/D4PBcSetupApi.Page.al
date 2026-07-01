namespace D4P.CCMS.API;

using D4P.CCMS.Setup;

page 62064 "D4P BC Setup API"
{
    PageType = API;
    Caption = 'D4P BC Setup API', Locked = true;
    APIPublisher = 'bylov';
    APIGroup = 'ccms';
    APIVersion = 'v1.0';
    EntityName = 'setup';
    EntitySetName = 'setups';
    EntityCaption = 'Setup';
    EntitySetCaption = 'Setups';
    SourceTable = "D4P BC Setup";
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
                field(primaryKey; Rec."Primary Key")
                {
                    Caption = 'Primary Key';
                }
                field(debugMode; Rec."Debug Mode")
                {
                    Caption = 'Debug Mode';
                }
                field(adminApiBaseUrl; Rec."Admin API Base URL")
                {
                    Caption = 'Admin API Base URL';
                }
                field(automationApiBaseUrl; Rec."Automation API Base URL")
                {
                    Caption = 'Automation API Base URL';
                }
                field(customerNos; Rec."Customer Nos.")
                {
                    Caption = 'Customer Nos.';
                }
                field(systemModifiedAt; Rec.SystemModifiedAt)
                {
                    Caption = 'System Modified At';
                }
            }
        }
    }
}
