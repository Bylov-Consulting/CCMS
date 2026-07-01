namespace D4P.CCMS.Environment;

using D4P.CCMS.Connector;
using D4P.CCMS.Tenant;

codeunit 62050 "D4P BC Admin API" implements "D4P IBC Admin API"
{
    var
        AdminAPIClient: Codeunit D4PBCAdminAPIClient;
        Parser: Codeunit "D4P BC Update Parser";
        FailedToFetchErr: Label 'Failed to fetch available updates: %1', Comment = '%1 = Error message';

    /// <summary>
    /// Default implementation: fetches available updates via Admin API v2.28 and
    /// parses the response through D4P BC Update Parser.
    /// Raises an error on HTTP failure — orchestrator wraps the call in a TryFunction.
    /// </summary>
    procedure GetAvailableUpdates(var BCEnvironment: Record "D4P BC Environment"; var TempAvailableUpdate: Record "D4P BC Available Update" temporary; var RawResponse: Text)
    var
        BCTenant: Record "D4P BC Tenant";
        JsonResponse: JsonObject;
        Endpoint: Text;
    begin
        // Only Tenant ID + Client ID are consumed downstream by the Admin API client /
        // OAuth token acquisition. Narrow the fetch accordingly.
        BCTenant.SetLoadFields("Tenant ID", "Client ID");
        BCTenant.Get(BCEnvironment."Customer No.", BCEnvironment."Tenant ID");

        Endpoint := '/applications/' + BCEnvironment."Application Family" +
                    '/environments/' + BCEnvironment.Name + '/updates';

        AdminAPIClient.SetTenant(BCTenant);
        if not AdminAPIClient.Get(Endpoint, JsonResponse) then
            Error(FailedToFetchErr, Format(JsonResponse));

        // Hand back the raw JSON so callers can cache it and skip the re-fetch on
        // subsequent AssistEdit drilldowns for the same env.
        JsonResponse.WriteTo(RawResponse);
        Parser.ParseUpdatesJson(RawResponse, TempAvailableUpdate);
    end;

    /// <summary>
    /// Default implementation: applies target version + date via Admin API v2.28 (PATCH).
    /// Builds the same request body as the single-env path and returns false (without
    /// throwing) on HTTP failure so the orchestrator can record the reason and continue.
    /// Does NOT call Message() — the orchestrator owns all UX.
    /// </summary>
    procedure SelectTargetVersion(var BCEnvironment: Record "D4P BC Environment"; TargetVersion: Text[100]; SelectedDate: Date; ExpectedMonth: Integer; ExpectedYear: Integer; IsAvailable: Boolean; var FailureReason: Text): Boolean
    var
        BCTenant: Record "D4P BC Tenant";
        JsonObject: JsonObject;
        JsonScheduleDetails: JsonObject;
        SelectedDateTime: DateTime;
        Endpoint: Text;
        ResponseText: Text;
    begin
        FailureReason := '';
        // Only Tenant ID + Client ID are consumed downstream by the Admin API client /
        // OAuth token acquisition. Narrow the fetch accordingly.
        BCTenant.SetLoadFields("Tenant ID", "Client ID");
        BCTenant.Get(BCEnvironment."Customer No.", BCEnvironment."Tenant ID");

        // IsAvailable (the candidate's real availability) distinguishes a released-and-
        // schedulable version from an unreleased one where the caller only has Month/Year.
        // It is NOT derived from SelectedDate, because a genuinely available version can carry
        // no latestSelectableDate (0D) yet must still be scheduled via the released branch.
        JsonObject.Add('selected', true);

        if IsAvailable then begin
            SelectedDateTime := CreateDateTime(SelectedDate, 0T);
            JsonScheduleDetails.Add('selectedDateTime', SelectedDateTime);
            JsonScheduleDetails.Add('ignoreUpdateWindow', false);
            JsonObject.Add('scheduleDetails', JsonScheduleDetails);
        end;

        Endpoint := '/applications/' + BCEnvironment."Application Family" +
                    '/environments/' + BCEnvironment.Name +
                    '/updates/' + TargetVersion;

        AdminAPIClient.SetTenant(BCTenant);
        if not AdminAPIClient.Patch(Endpoint, JsonObject, ResponseText) then begin
            // Surface the Admin API's HTTP status/body so the orchestrator can record WHY the
            // apply failed in the plan row's Reason, instead of a generic placeholder.
            FailureReason := ResponseText;
            exit(false);
        end;

        // Mirror the single-env post-success record update, but without Message().
        BCEnvironment."Target Version" := TargetVersion;
        if IsAvailable then begin
            BCEnvironment."Selected DateTime" := SelectedDateTime;
            BCEnvironment."Expected Availability" := '';
        end else begin
            BCEnvironment."Selected DateTime" := 0DT;
            // Guard against PadStr negative-length runtime errors (month outside 1..12)
            // and against meaningless output (year = 0). Caller supplied invalid inputs →
            // blank the field rather than write a malformed value.
            if (ExpectedMonth in [1 .. 12]) and (ExpectedYear > 0) then
                BCEnvironment."Expected Availability" :=
                    Format(ExpectedYear) + '/' +
                    PadStr('', 2 - StrLen(Format(ExpectedMonth)), '0') + Format(ExpectedMonth)
            else
                BCEnvironment."Expected Availability" := '';
        end;
        BCEnvironment.Modify(false);

        exit(true);
    end;
}
