namespace D4P.CCMS.Environment;

codeunit 62003 "D4P BC Admin API" implements "D4P IBC Admin API"
{
    /// <summary>
    /// Default implementation: fetches available updates via Admin API v2.28.
    /// </summary>
    procedure GetAvailableUpdates(var BCEnvironment: Record "D4P BC Environment"; var TempAvailableUpdate: Record "D4P BC Available Update" temporary)
    begin
        // RED stub: intentionally empty. GREEN phase wires D4P BC API Helper + D4P BC Update Parser.
    end;

    /// <summary>
    /// Default implementation: applies target version + date via Admin API v2.28 (PATCH).
    /// </summary>
    procedure SelectTargetVersion(var BCEnvironment: Record "D4P BC Environment"; TargetVersion: Text[100]; SelectedDate: Date; ExpectedMonth: Integer; ExpectedYear: Integer): Boolean
    begin
        // RED stub: return false so orchestrator tests observe "apply failed" for every row.
        exit(false);
    end;
}
