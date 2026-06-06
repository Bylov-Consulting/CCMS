namespace D4P.CCMS.API;

using D4P.CCMS.Backup;
using D4P.CCMS.Environment;
using D4P.CCMS.Operations;
using D4P.CCMS.Tenant;

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

    /// <summary>
    /// Safe refresh: re-pulls the tenant's environments from the admin API.
    /// No confirmation required. Re-read the environments entity set for the result.
    /// </summary>
    [ServiceEnabled]
    procedure RefreshEnvironments(var ActionContext: WebServiceActionContext)
    var
        BCTenant: Record "D4P BC Tenant";
        EnvironmentMgt: Codeunit "D4P BC Environment Mgt";
    begin
        GetTenantForRec(BCTenant);
        EnvironmentMgt.GetEnvironments(BCTenant);

        SetEnvironmentActionResult(ActionContext);
    end;

    /// <summary>
    /// Safe refresh of the bound environment's operations list (the poll primitive).
    /// No confirmation required. Re-read the operations entity set for the result.
    /// </summary>
    [ServiceEnabled]
    procedure RefreshOperations(var ActionContext: WebServiceActionContext)
    var
        OperationsHelper: Codeunit "D4P BC Operations Helper";
    begin
        OperationsHelper.GetEnvironmentOperations(Rec."Customer No.", Rec."Tenant ID", Rec.Name);

        SetEnvironmentActionResult(ActionContext);
    end;

    /// <summary>
    /// Safe discovery: fetches the available target versions for the bound environment
    /// so a caller can pick a valid version before scheduleUpdate. No confirmation
    /// required. Returns a JSON array of the available target versions directly to the
    /// caller (the version list).
    ///
    /// Implemented as a returning bound OData Function (non-void return, NO
    /// WebServiceActionContext parameter). A [ServiceEnabled] procedure that has BOTH a
    /// non-void return AND a var ActionContext: WebServiceActionContext parameter is
    /// silently dropped from $metadata, so this deliberately omits ActionContext and
    /// returns the JSON text instead of an environment ref.
    /// </summary>
    [ServiceEnabled]
    procedure ListAvailableUpdates(): Text
    var
        EnvironmentMgt: Codeunit "D4P BC Environment Mgt";
    begin
        exit(EnvironmentMgt.ListAvailableUpdates(Rec));
    end;

    /// <summary>
    /// DESTRUCTIVE/BILLABLE: schedules a real production upgrade of the bound
    /// environment to TargetVersion. Gated behind Confirm=true. After the call,
    /// poll via refreshOperations + the operations entity to retrieve the cloud
    /// operationId/status.
    /// </summary>
    [ServiceEnabled]
    procedure ScheduleUpdate(TargetVersion: Text[100]; ScheduledDate: Date; Confirm: Boolean; var ActionContext: WebServiceActionContext)
    var
        EnvironmentMgt: Codeunit "D4P BC Environment Mgt";
        ConfirmRequiredErr: Label 'This action schedules a real production upgrade and is gated. Re-send with Confirm = true to proceed.';
        TargetVersionRequiredErr: Label 'TargetVersion is required. Call listAvailableUpdates first to discover a valid version.';
    begin
        if not Confirm then
            Error(ConfirmRequiredErr);
        if TargetVersion = '' then
            Error(TargetVersionRequiredErr);

        // SkipDialog=true => GUI-free. The cloud operation is recorded against the
        // environment's operations list; poll refreshOperations to read its id/status.
        EnvironmentMgt.SelectTargetVersion(Rec, TargetVersion, ScheduledDate, 0, 0, true);

        SetEnvironmentActionResult(ActionContext);
    end;

    /// <summary>
    /// DESTRUCTIVE: schedules an update of the given installed app on the bound
    /// environment. Gated behind Confirm=true. Requires a prior available-updates fetch
    /// (the app must carry an Available Update Version). Poll refreshOperations for the
    /// resulting cloud operationId/status.
    /// </summary>
    [ServiceEnabled]
    procedure UpdateApp(AppId: Text; Confirm: Boolean; var ActionContext: WebServiceActionContext)
    var
        EnvironmentMgt: Codeunit "D4P BC Environment Mgt";
        AppIdGuid: Guid;
        ConfirmRequiredErr: Label 'This action schedules an app update on a real environment and is gated. Re-send with Confirm = true to proceed.';
        InvalidAppIdErr: Label 'AppId %1 is not a valid GUID.', Comment = '%1 = supplied AppId';
    begin
        if not Confirm then
            Error(ConfirmRequiredErr);
        if not Evaluate(AppIdGuid, AppId) then
            Error(InvalidAppIdErr, AppId);

        // showNotification=false, SkipDialog=true => GUI-free. Poll refreshOperations
        // to read the resulting cloud operation id/status.
        EnvironmentMgt.UpdateApp(Rec, AppIdGuid, false, true);

        SetEnvironmentActionResult(ActionContext);
    end;

    /// <summary>
    /// BILLABLE: starts a database export (bacpac) of the bound Production environment.
    /// Gated behind Confirm=true. Retains the Production-only + SAS/Container guards.
    /// Poll the export-history entity for the started blob (the durable handle).
    /// </summary>
    [ServiceEnabled]
    procedure StartDatabaseExport(Confirm: Boolean; var ActionContext: WebServiceActionContext)
    var
        BackupHelper: Codeunit "D4P BC Backup Helper";
        ConfirmRequiredErr: Label 'This action starts a billable database export and is gated. Re-send with Confirm = true to proceed.';
    begin
        if not Confirm then
            Error(ConfirmRequiredErr);

        // GUI-free overload (no interactive Confirm); '' => generate a fresh blob name.
        // The started blob is recorded in the export history; poll it for the handle.
        BackupHelper.StartEnvironmentDatabaseExport(Rec, '');

        SetEnvironmentActionResult(ActionContext);
    end;

    local procedure GetTenantForRec(var BCTenant: Record "D4P BC Tenant")
    var
        TenantNotFoundErr: Label 'Tenant %1 / %2 not found.', Comment = '%1 = Customer No., %2 = Tenant ID';
    begin
        if not BCTenant.Get(Rec."Customer No.", Rec."Tenant ID") then
            Error(TenantNotFoundErr, Rec."Customer No.", Rec."Tenant ID");
    end;

    local procedure SetEnvironmentActionResult(var ActionContext: WebServiceActionContext)
    begin
        ActionContext.SetObjectType(ObjectType::Page);
        ActionContext.SetObjectId(Page::"D4P Environment API");
        ActionContext.AddEntityKey(Rec.FieldNo(SystemId), Rec.SystemId);
        ActionContext.SetResultCode(WebServiceActionResultCode::Get);
    end;
}
