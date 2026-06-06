namespace D4P.CCMS.API;

using D4P.CCMS.Environment;

page 62050 "D4P Environment API"
{
    PageType = API;
    Caption = 'D4P Environment API', Locked = true;
    APIPublisher = 'bylov';
    APIGroup = 'ccms';
    APIVersion = 'v1.0';
    EntityName = 'environment';
    EntitySetName = 'environments';
    EntityCaption = 'Environment';
    EntitySetCaption = 'Environments';
    SourceTable = "D4P BC Environment";
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
                field(name; Rec.Name)
                {
                    Caption = 'Name';
                }
                field(friendlyName; Rec."Friendly Name")
                {
                    Caption = 'Friendly Name';
                }
                field(applicationFamily; Rec."Application Family")
                {
                    Caption = 'Application Family';
                }
                field(type; Rec.Type)
                {
                    Caption = 'Type';
                }
                field(state; Rec.State)
                {
                    Caption = 'State';
                }
                field(countryRegion; Rec."Country/Region")
                {
                    Caption = 'Country/Region';
                }
                field(ringName; Rec."Ring Name")
                {
                    Caption = 'Ring Name';
                }
                field(currentVersion; Rec."Current Version")
                {
                    Caption = 'Current Version';
                }
                field(targetVersion; Rec."Target Version")
                {
                    Caption = 'Target Version';
                }
                field(targetVersionType; Rec."Target Version Type")
                {
                    Caption = 'Target Version Type';
                }
                field(rolloutStatus; Rec."Rollout Status")
                {
                    Caption = 'Rollout Status';
                }
                field(available; Rec.Available)
                {
                    Caption = 'Available';
                }
                field(platformVersion; Rec."Platform Version")
                {
                    Caption = 'Platform Version';
                }
                field(scheduledUpdateDateTime; Rec."Selected DateTime")
                {
                    Caption = 'Scheduled Update Date Time';
                }
                field(latestSelectableDate; Rec."Latest Selectable Date")
                {
                    Caption = 'Latest Selectable Date';
                }
                field(gracePeriodStartDate; Rec."Grace Period Start Date")
                {
                    Caption = 'Grace Period Start Date';
                }
                field(enforcedUpdatePeriodStart; Rec."Enforced Update Period Start")
                {
                    Caption = 'Enforced Update Period Start Date';
                }
                field(expectedAvailability; Rec."Expected Availability")
                {
                    Caption = 'Expected Availability';
                }
                field(ignoreUpdateWindow; Rec."Ignore Update Window")
                {
                    Caption = 'Ignore Update Window';
                }
                field(appSourceAppsUpdateCadence; Rec."AppSource Apps Update Cadence")
                {
                    Caption = 'AppSource Apps Update Cadence';
                }
                field(locationName; Rec."Location Name")
                {
                    Caption = 'Location Name';
                }
                field(geoName; Rec."Geo Name")
                {
                    Caption = 'Geo Name';
                }
                field(webClientLoginUrl; Rec."Web Client Login URL")
                {
                    Caption = 'Web Client Login URL';
                }
                field(webServiceUrl; Rec."Web Service URL")
                {
                    Caption = 'Web Service URL';
                }
                field(softDeletedOn; Rec."Soft Deleted On")
                {
                    Caption = 'Soft Deleted On';
                }
                field(hardDeletePendingOn; Rec."Hard Delete Pending On")
                {
                    Caption = 'Hard Delete Pending On';
                }
                field(deleteReason; Rec."Delete Reason")
                {
                    Caption = 'Delete Reason';
                }
                field(systemModifiedAt; Rec.SystemModifiedAt)
                {
                    Caption = 'System Modified At';
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        Rec.CalcFields("Customer Name");
    end;
}
