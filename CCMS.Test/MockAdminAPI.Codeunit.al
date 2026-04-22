// ============================================================================
//  D4P Mock Admin API — codeunit 62100
//  Implements the D4P IBC Admin API interface for use in test codeunits.
//
//  Fixture grammar for SetFixtureForEnv:
//    A pipe-delimited string. Separate multiple version records with the
//    two-character literal sequence \n (backslash + n — NOT a real newline).
//
//    Each record has up to 5 pipe-separated fields:
//      1. TargetVersion         e.g. "27.5"           (required)
//      2. available             "true" or "false"      (required)
//      3. LatestSelectableDate  "DD-MM-YYYY" or "0"   (optional; "0" → 0D)
//      4. ExpectedMonth         integer string         (optional; default 0)
//      5. ExpectedYear          integer string         (optional; default 0)
//
//    Date format "DD-MM-YYYY" is split on '-' and passed to DMY2Date() so
//    the result is locale-independent.
//
//    Examples:
//      Single released version:
//        '27.5|true|01-06-2026|6|2026'
//
//      Two versions (released + unreleased):
//        '27.5|true|01-06-2026|6|2026\n27.6|false|0|9|2026'
//
//  To force GetAvailableUpdates to raise an Error (simulates HTTP failure),
//  call ForceThrowOnFetch(EnvName) before running the test.
// ============================================================================
codeunit 62100 "D4P Mock Admin API" implements "D4P IBC Admin API"
{
    // -----------------------------------------------------------------------
    //  State
    // -----------------------------------------------------------------------
    var
        FixtureStrings: Dictionary of [Text, Text];  // env name → fixture string
        FailOnEnvs: List of [Text];                  // SelectTargetVersion → false
        ThrowOnFetchEnvs: List of [Text];            // GetAvailableUpdates → Error
        SelectCallLog: List of [Text];               // "EnvName|TargetVersion|Date"

    // -----------------------------------------------------------------------
    //  Test-control helpers
    // -----------------------------------------------------------------------

    /// <summary>
    /// Register a fixture string for the given environment name.
    /// See file-header comment for grammar.
    /// </summary>
    procedure SetFixtureForEnv(EnvName: Text; FixtureText: Text)
    begin
        if FixtureStrings.ContainsKey(EnvName) then
            FixtureStrings.Set(EnvName, FixtureText)
        else
            FixtureStrings.Add(EnvName, FixtureText);
    end;

    /// <summary>
    /// Makes SelectTargetVersion return false for the named environment.
    /// Simulates the Admin API reporting the reschedule failed.
    /// </summary>
    procedure ForceFailOn(EnvName: Text)
    begin
        if not FailOnEnvs.Contains(EnvName) then
            FailOnEnvs.Add(EnvName);
    end;

    /// <summary>
    /// Clears all forced-failure registrations so every subsequent
    /// SelectTargetVersion call returns true regardless of env name.
    /// Call between ApplyPlan runs when testing the Retry Failed path.
    /// </summary>
    procedure ClearFailures()
    begin
        Clear(FailOnEnvs);
    end;

    /// <summary>
    /// Makes GetAvailableUpdates raise an Error for the named environment.
    /// Simulates an HTTP failure during the fetch phase.
    /// </summary>
    procedure ForceThrowOnFetch(EnvName: Text)
    begin
        if not ThrowOnFetchEnvs.Contains(EnvName) then
            ThrowOnFetchEnvs.Add(EnvName);
    end;

    /// <summary>
    /// Returns the audit trail of SelectTargetVersion invocations.
    /// Each entry is formatted as "EnvName|TargetVersion|Date".
    /// </summary>
    procedure GetSelectCalls(): List of [Text]
    begin
        exit(SelectCallLog);
    end;

    /// <summary>
    /// Resets all mock state. Call at the start of each test when not using
    /// TestIsolation = Codeunit on the consuming test codeunit.
    /// </summary>
    procedure Reset()
    begin
        Clear(FixtureStrings);
        Clear(FailOnEnvs);
        Clear(ThrowOnFetchEnvs);
        Clear(SelectCallLog);
    end;

    // -----------------------------------------------------------------------
    //  Interface implementation: D4P IBC Admin API
    // -----------------------------------------------------------------------

    /// <summary>
    /// Populates TempAvailableUpdate directly from the registered fixture string.
    /// If no fixture is registered, zero rows are inserted (no available updates).
    /// If ForceThrowOnFetch was called for this env, an Error is raised.
    /// Populates RawResponse with the fixture string so a hypothetical future test of
    /// the caching behavior would see a non-empty payload; current tests don't inspect it.
    /// </summary>
    procedure GetAvailableUpdates(var BCEnvironment: Record "D4P BC Environment"; var TempAvailableUpdate: Record "D4P BC Available Update" temporary; var RawResponse: Text)
    var
        FixtureText: Text;
        Lines: List of [Text];
        LineText: Text;
        Parts: List of [Text];
        EntryNo: Integer;
        AvailableText: Text;
        DateStr: Text;
        MonthStr: Text;
        YearStr: Text;
        SelectableDate: Date;
        ExpectedMonth: Integer;
        ExpectedYear: Integer;
    begin
        if ThrowOnFetchEnvs.Contains(BCEnvironment.Name) then
            Error('Fetch failed: simulated HTTP error for environment %1', BCEnvironment.Name);

        if not FixtureStrings.Get(BCEnvironment.Name, FixtureText) then begin
            RawResponse := '';
            exit;  // No fixture → zero rows
        end;

        // Hand back the raw fixture text as RawResponse (non-empty for caching tests).
        RawResponse := FixtureText;

        // Split on the two-character literal \n
        Lines := FixtureText.Split('\n');
        EntryNo := 0;

        foreach LineText in Lines do begin
            LineText := LineText.Trim();
            if LineText = '' then
                continue;

            Parts := LineText.Split('|');
            if Parts.Count() < 2 then
                continue;

            EntryNo += 1;

            // Field 3: LatestSelectableDate in "DD-MM-YYYY" format, or "0"
            SelectableDate := 0D;
            if Parts.Count() >= 3 then begin
                DateStr := Parts.Get(3).Trim();
                if (DateStr <> '0') and (DateStr <> '') then
                    SelectableDate := ParseFixtureDate(DateStr);
            end;

            // Field 4: ExpectedMonth (integer)
            ExpectedMonth := 0;
            if Parts.Count() >= 4 then begin
                MonthStr := Parts.Get(4).Trim();
                if MonthStr <> '' then
                    Evaluate(ExpectedMonth, MonthStr);
            end;

            // Field 5: ExpectedYear (integer)
            ExpectedYear := 0;
            if Parts.Count() >= 5 then begin
                YearStr := Parts.Get(5).Trim();
                if YearStr <> '' then
                    Evaluate(ExpectedYear, YearStr);
            end;

            AvailableText := Parts.Get(2).Trim().ToLower();

            TempAvailableUpdate.Init();
            TempAvailableUpdate."Entry No." := EntryNo;
            TempAvailableUpdate."Target Version" :=
                CopyStr(Parts.Get(1).Trim(), 1, MaxStrLen(TempAvailableUpdate."Target Version"));
            TempAvailableUpdate.Available := (AvailableText = 'true');
            TempAvailableUpdate."Latest Selectable Date" := SelectableDate;
            TempAvailableUpdate."Expected Month" := ExpectedMonth;
            TempAvailableUpdate."Expected Year" := ExpectedYear;
            TempAvailableUpdate.Insert();
        end;
    end;

    /// <summary>
    /// Records the call and returns true unless ForceFailOn was called for this env.
    /// </summary>
    procedure SelectTargetVersion(var BCEnvironment: Record "D4P BC Environment"; TargetVersion: Text[100]; SelectedDate: Date; ExpectedMonth: Integer; ExpectedYear: Integer): Boolean
    begin
        SelectCallLog.Add(StrSubstNo('%1|%2|%3', BCEnvironment.Name, TargetVersion, SelectedDate));
        exit(not FailOnEnvs.Contains(BCEnvironment.Name));
    end;

    // -----------------------------------------------------------------------
    //  Private helpers
    // -----------------------------------------------------------------------

    /// <summary>
    /// Parses a date string in the format "DD-MM-YYYY" into a Date value using
    /// DMY2Date, which is locale-independent.
    /// </summary>
    local procedure ParseFixtureDate(DateStr: Text): Date
    var
        Parts: List of [Text];
        Day: Integer;
        Month: Integer;
        Year: Integer;
    begin
        Parts := DateStr.Split('-');
        if Parts.Count() <> 3 then
            Error('Fixture date "%1" must be in DD-MM-YYYY format', DateStr);

        Evaluate(Day, Parts.Get(1));
        Evaluate(Month, Parts.Get(2));
        Evaluate(Year, Parts.Get(3));
        exit(DMY2Date(Day, Month, Year));
    end;
}
