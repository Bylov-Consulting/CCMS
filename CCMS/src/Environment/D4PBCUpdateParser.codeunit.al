namespace D4P.CCMS.Environment;

codeunit 62006 "D4P BC Update Parser"
{
    /// <summary>
    /// Pure parser: JSON response text to temporary "D4P BC Available Update" rows.
    /// Handles the latestSelectableDateTime vs latestSelectableDate API quirk.
    /// </summary>
    /// <param name="ResponseText">Raw JSON response from the Admin API.</param>
    /// <param name="TempAvailableUpdate">Temporary record to populate.</param>
    procedure ParseUpdatesJson(ResponseText: Text; var TempAvailableUpdate: Record "D4P BC Available Update" temporary)
    begin
        // RED stub: intentionally empty. Tests observe zero rows inserted and fail.
    end;

    /// <summary>
    /// Pure: chooses the most recent Available=true row; falls back to latest
    /// unreleased (month/year) if none available.
    /// </summary>
    /// <param name="TempAvailableUpdate">Temporary record holding candidate updates.</param>
    /// <param name="TargetVersion">Chosen target version.</param>
    /// <param name="DefaultDate">Chosen default date.</param>
    /// <param name="ExpectedMonth">Chosen expected month (for unreleased).</param>
    /// <param name="ExpectedYear">Chosen expected year (for unreleased).</param>
    procedure PickDefaultTargetVersion(var TempAvailableUpdate: Record "D4P BC Available Update" temporary; var TargetVersion: Text[100]; var DefaultDate: Date; var ExpectedMonth: Integer; var ExpectedYear: Integer)
    begin
        // RED stub: intentionally empty. Tests observe unchanged out params and fail.
    end;
}
