namespace D4P.CCMS.API;

using D4P.CCMS.Telemetry;

page 62060 "D4P AppInsights Conn API"
{
    PageType = API;
    Caption = 'D4P AppInsights Conn API', Locked = true;
    APIPublisher = 'bylov';
    APIGroup = 'ccms';
    APIVersion = 'v1.0';
    EntityName = 'appInsightsConnection';
    EntitySetName = 'appInsightsConnections';
    EntityCaption = 'AppInsights Connection';
    EntitySetCaption = 'AppInsights Connections';
    SourceTable = "D4P AppInsights Connection";
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
                field(description; Rec.Description)
                {
                    Caption = 'Description';
                }
                field(telemetryApplicationId; Rec."Telemetry Application Id")
                {
                    Caption = 'Telemetry Application Id';
                }
                field(tenantId; Rec."Tenant Id")
                {
                    Caption = 'Tenant Id';
                }
                field(systemModifiedAt; Rec.SystemModifiedAt)
                {
                    Caption = 'System Modified At';
                }
            }
        }
    }
}
