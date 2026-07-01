namespace D4P.CCMS.API;

using D4P.CCMS.Extension;

page 62051 "D4P Installed App API"
{
    PageType = API;
    Caption = 'D4P Installed App API', Locked = true;
    APIPublisher = 'bylov';
    APIGroup = 'ccms';
    APIVersion = 'v1.0';
    EntityName = 'installedApp';
    EntitySetName = 'installedApps';
    EntityCaption = 'Installed App';
    EntitySetCaption = 'Installed Apps';
    SourceTable = "D4P BC Installed App";
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
                field(tenantId; Rec."Tenant ID")
                {
                    Caption = 'Tenant Id';
                }
                field(environmentName; Rec."Environment Name")
                {
                    Caption = 'Environment Name';
                }
                field(appId; Rec."App ID")
                {
                    Caption = 'App Id';
                }
                field(appName; Rec."App Name")
                {
                    Caption = 'App Name';
                }
                field(appPublisher; Rec."App Publisher")
                {
                    Caption = 'App Publisher';
                }
                field(appVersion; Rec."App Version")
                {
                    Caption = 'App Version';
                }
                field(state; Rec.State)
                {
                    Caption = 'State';
                }
                field(appType; Rec."App Type")
                {
                    Caption = 'App Type';
                }
                field(canBeUninstalled; Rec."Can Be Uninstalled")
                {
                    Caption = 'Can Be Uninstalled';
                }
                field(availableUpdateVersion; Rec."Available Update Version")
                {
                    Caption = 'Available Update Version';
                }
                field(lastUpdateAttemptResult; Rec."Last Update Attempt Result")
                {
                    Caption = 'Last Update Attempt Result';
                }
                field(lastUninstallAttemptResult; Rec."Last Uninstall Attempt Result")
                {
                    Caption = 'Last Uninstall Attempt Result';
                }
                field(systemModifiedAt; Rec.SystemModifiedAt)
                {
                    Caption = 'System Modified At';
                }
            }
        }
    }
}
