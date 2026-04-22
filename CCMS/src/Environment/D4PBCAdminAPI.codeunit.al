namespace D4P.CCMS.Environment;

using D4P.CCMS.General;
using D4P.CCMS.Tenant;

codeunit 62003 "D4P BC Admin API" implements "D4P IBC Admin API"
{
    var
        APIHelper: Codeunit "D4P BC API Helper";
        Parser: Codeunit "D4P BC Update Parser";

    /// <summary>
    /// Default implementation: fetches available updates via Admin API v2.28 and
    /// parses the response through D4P BC Update Parser.
    /// Raises an error on HTTP failure — orchestrator wraps the call in a TryFunction.
    /// </summary>
    procedure GetAvailableUpdates(var BCEnvironment: Record "D4P BC Environment"; var TempAvailableUpdate: Record "D4P BC Available Update" temporary)
    var
        BCTenant: Record "D4P BC Tenant";
        FailedToFetchErr: Label 'Failed to fetch available updates: %1', Comment = '%1 = Error message';
        Endpoint: Text;
        ResponseText: Text;
    begin
        BCTenant.Get(BCEnvironment."Customer No.", BCEnvironment."Tenant ID");

        Endpoint := '/applications/' + BCEnvironment."Application Family" +
                    '/environments/' + BCEnvironment.Name + '/updates';
        if not APIHelper.SendAdminAPIRequest(BCTenant, 'GET', Endpoint, '', ResponseText) then
            Error(FailedToFetchErr, ResponseText);

        Parser.ParseUpdatesJson(ResponseText, TempAvailableUpdate);
    end;

    /// <summary>
    /// Default implementation: applies target version + date via Admin API v2.28 (PATCH).
    /// Builds the same request body as the single-env path and returns false (without
    /// throwing) on HTTP failure so the orchestrator can record the reason and continue.
    /// Does NOT call Message() — the orchestrator owns all UX.
    /// </summary>
    procedure SelectTargetVersion(var BCEnvironment: Record "D4P BC Environment"; TargetVersion: Text[100]; SelectedDate: Date; ExpectedMonth: Integer; ExpectedYear: Integer): Boolean
    var
        BCTenant: Record "D4P BC Tenant";
        JsonObject: JsonObject;
        JsonScheduleDetails: JsonObject;
        IsAvailable: Boolean;
        SelectedDateTime: DateTime;
        Endpoint: Text;
        RequestBody: Text;
        ResponseText: Text;
    begin
        BCTenant.Get(BCEnvironment."Customer No.", BCEnvironment."Tenant ID");

        // A selectable Date distinguishes a released-and-schedulable version from an
        // unreleased one where the caller only has Month/Year. Mirrors the single-env path.
        IsAvailable := (SelectedDate <> 0D);

        JsonObject.Add('selected', true);

        if IsAvailable then begin
            SelectedDateTime := CreateDateTime(SelectedDate, 0T);
            JsonScheduleDetails.Add('selectedDateTime', SelectedDateTime);
            JsonScheduleDetails.Add('ignoreUpdateWindow', false);
            JsonObject.Add('scheduleDetails', JsonScheduleDetails);
        end;

        JsonObject.WriteTo(RequestBody);

        Endpoint := '/applications/' + BCEnvironment."Application Family" +
                    '/environments/' + BCEnvironment.Name +
                    '/updates/' + TargetVersion;

        if not APIHelper.SendAdminAPIRequest(BCTenant, 'PATCH', Endpoint, RequestBody, ResponseText) then
            exit(false);

        // Mirror the single-env post-success record update, but without Message().
        BCEnvironment."Target Version" := TargetVersion;
        if IsAvailable then begin
            BCEnvironment."Selected DateTime" := SelectedDateTime;
            BCEnvironment."Expected Availability" := '';
        end else begin
            BCEnvironment."Selected DateTime" := 0DT;
            BCEnvironment."Expected Availability" :=
                Format(ExpectedYear) + '/' +
                PadStr('', 2 - StrLen(Format(ExpectedMonth)), '0') + Format(ExpectedMonth);
        end;
        BCEnvironment.Modify(false);

        exit(true);
    end;
}
