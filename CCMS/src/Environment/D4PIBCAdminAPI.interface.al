namespace D4P.CCMS.Environment;

interface "D4P IBC Admin API"
{
    /// <summary>
    /// Fetch available updates for one environment. Implementations populate TempAvailableUpdate.
    /// May raise on HTTP failure.
    /// </summary>
    /// <param name="BCEnvironment">The environment to fetch updates for.</param>
    /// <param name="TempAvailableUpdate">Temporary record populated with the available updates.</param>
    procedure GetAvailableUpdates(var BCEnvironment: Record "D4P BC Environment"; var TempAvailableUpdate: Record "D4P BC Available Update" temporary);

    /// <summary>
    /// Apply a selected target version and date to one environment.
    /// Implementations MUST NOT Commit on behalf of the caller.
    /// </summary>
    /// <param name="BCEnvironment">The environment to reschedule.</param>
    /// <param name="TargetVersion">The version to schedule.</param>
    /// <param name="SelectedDate">The chosen date for the update.</param>
    /// <param name="ExpectedMonth">Expected release month (for unreleased versions).</param>
    /// <param name="ExpectedYear">Expected release year (for unreleased versions).</param>
    /// <returns>true on success, false on failure.</returns>
    procedure SelectTargetVersion(var BCEnvironment: Record "D4P BC Environment"; TargetVersion: Text[100]; SelectedDate: Date; ExpectedMonth: Integer; ExpectedYear: Integer): Boolean;
}
