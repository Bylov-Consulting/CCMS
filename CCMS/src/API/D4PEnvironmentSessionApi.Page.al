namespace D4P.CCMS.API;

using D4P.CCMS.Session;

page 62054 "D4P Environment Session API"
{
    PageType = API;
    Caption = 'D4P Environment Session API', Locked = true;
    APIPublisher = 'bylov';
    APIGroup = 'ccms';
    APIVersion = 'v1.0';
    EntityName = 'environmentSession';
    EntitySetName = 'environmentSessions';
    EntityCaption = 'Environment Session';
    EntitySetCaption = 'Environment Sessions';
    SourceTable = "D4P BC Environment Session";
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
                field(sessionId; Rec."Session ID")
                {
                    Caption = 'Session Id';
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
                field(applicationFamily; Rec."Application Family")
                {
                    Caption = 'Application Family';
                }
                field(userId; Rec."User ID")
                {
                    Caption = 'User Id';
                }
                field(clientType; Rec."Client Type")
                {
                    Caption = 'Client Type';
                }
                field(loginDate; Rec."Login Date")
                {
                    Caption = 'Login Date';
                }
                field(entryPointOperation; Rec."Entry Point Operation")
                {
                    Caption = 'Entry Point Operation';
                }
                field(entryPointObjectName; Rec."Entry Point Object Name")
                {
                    Caption = 'Entry Point Object Name';
                }
                field(entryPointObjectId; Rec."Entry Point Object ID")
                {
                    Caption = 'Entry Point Object Id';
                }
                field(entryPointObjectType; Rec."Entry Point Object Type")
                {
                    Caption = 'Entry Point Object Type';
                }
                field(currentObjectName; Rec."Current Object Name")
                {
                    Caption = 'Current Object Name';
                }
                field(currentObjectId; Rec."Current Object ID")
                {
                    Caption = 'Current Object Id';
                }
                field(currentObjectType; Rec."Current Object Type")
                {
                    Caption = 'Current Object Type';
                }
                field(currentOperationDuration; Rec."Current Operation Duration")
                {
                    Caption = 'Current Operation Duration (ms)';
                }
                field(systemModifiedAt; Rec.SystemModifiedAt)
                {
                    Caption = 'System Modified At';
                }
            }
        }
    }
}
