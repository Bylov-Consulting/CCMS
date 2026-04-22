namespace D4P.CCMS.Environment;

interface "D4P IBC Admin API"
{
    /// <summary>
    /// Fetch available updates for one environment. Implementations populate TempAvailableUpdate.
    /// May raise on HTTP failure.
    /// </summary>
    /// <param name="BCEnvironment">The environment to fetch updates for.</param>
    /// <param name="TempAvailableUpdate">Temporary record populated with the available updates.</param>
    /// <param name="RawResponse">Out: the raw JSON payload returned by the API, so callers can
    /// cache it and avoid re-fetching for the same env (e.g. dialog AssistEdit drilldown).
    /// Implementations that synthesize data (mocks) may populate this with any representation
    /// of the fixture that could be re-parsed, or leave it empty — callers fall back to a
    /// re-fetch on cache miss.</param>
    procedure GetAvailableUpdates(var BCEnvironment: Record "D4P BC Environment"; var TempAvailableUpdate: Record "D4P BC Available Update" temporary; var RawResponse: Text);

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
