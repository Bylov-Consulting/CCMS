codeunit 62102 "D4P Update Parser Tests"
{
    Subtype = Test;

    // -------------------------------------------------------------------------
    // Test 7 — Released version: latestSelectableDateTime → Date, rolloutStatus
    // -------------------------------------------------------------------------
    [Test]
    procedure Parser_ReleasedVersion_ParsesDateCorrectly()
    var
        Parser: Codeunit "D4P BC Update Parser";
        TempAvailableUpdate: Record "D4P BC Available Update" temporary;
        Json: Text;
    begin
        // Arrange — realistic Admin API response for a released, available version.
        // scheduleDetails carries latestSelectableDateTime and rolloutStatus.
        Json := '{"value":[{' +
                  '"targetVersion":"27.5",' +
                  '"available":true,' +
                  '"targetVersionType":"Production",' +
                  '"scheduleDetails":{' +
                    '"latestSelectableDateTime":"2026-06-01T00:00:00Z",' +
                    '"rolloutStatus":"Active"' +
                  '}' +
                '}]}';

        // Act
        Parser.ParseUpdatesJson(Json, TempAvailableUpdate);

        // Assert — stub body produces 0 rows; all three assertions below FAIL in RED.
        Assert.AreEqual(1, TempAvailableUpdate.Count(), 'Parser must insert exactly 1 row for a single-entry response');
        TempAvailableUpdate.FindFirst();
        Assert.AreEqual('27.5', TempAvailableUpdate."Target Version", 'Target Version must be parsed from targetVersion');
        Assert.AreEqual(true, TempAvailableUpdate.Available, 'Available must be true');
        Assert.AreEqual(DMY2Date(1, 6, 2026), TempAvailableUpdate."Latest Selectable Date", 'Latest Selectable Date must be parsed from latestSelectableDateTime');
        Assert.AreEqual('Active', TempAvailableUpdate."Rollout Status", 'Rollout Status must be parsed from scheduleDetails.rolloutStatus');
    end;

    // -------------------------------------------------------------------------
    // Test 8 — Unreleased version: expectedAvailability month/year, Available = false
    // -------------------------------------------------------------------------
    [Test]
    procedure Parser_UnreleasedVersion_ParsesMonthYear()
    var
        Parser: Codeunit "D4P BC Update Parser";
        TempAvailableUpdate: Record "D4P BC Available Update" temporary;
        Json: Text;
    begin
        // Arrange — unreleased version has no scheduleDetails but has expectedAvailability.
        Json := '{"value":[{' +
                  '"targetVersion":"27.6",' +
                  '"available":false,' +
                  '"expectedAvailability":{' +
                    '"month":8,' +
                    '"year":2026' +
                  '}' +
                '}]}';

        // Act
        Parser.ParseUpdatesJson(Json, TempAvailableUpdate);

        // Assert — stub produces 0 rows; FindFirst() fails in RED (IsTrue fires first).
        Assert.AreEqual(1, TempAvailableUpdate.Count(), 'Parser must insert exactly 1 row for a single-entry response');
        TempAvailableUpdate.FindFirst();
        Assert.AreEqual(false, TempAvailableUpdate.Available, 'Available must be false for unreleased version');
        Assert.AreEqual(8, TempAvailableUpdate."Expected Month", 'Expected Month must be parsed from expectedAvailability.month');
        Assert.AreEqual(2026, TempAvailableUpdate."Expected Year", 'Expected Year must be parsed from expectedAvailability.year');
        Assert.AreEqual(0D, TempAvailableUpdate."Latest Selectable Date", 'Latest Selectable Date must be 0D when not present in response');
    end;

    // -------------------------------------------------------------------------
    // Test 9a — Empty response: parser must not raise an error on {"value":[]}
    // (This naturally "passes" against a stub — see Test 9b for the RED constraint.)
    // -------------------------------------------------------------------------
    [Test]
    procedure Parser_EmptyResponse_ReturnsNoRows()
    var
        Parser: Codeunit "D4P BC Update Parser";
        TempAvailableUpdate: Record "D4P BC Available Update" temporary;
        Json: Text;
    begin
        // Arrange
        Json := '{"value":[]}';

        // Act — must not throw on empty input.
        Parser.ParseUpdatesJson(Json, TempAvailableUpdate);

        // Assert — empty body stub also produces 0 rows, so IsEmpty() is true.
        // This test intentionally PASSES against the stub.  Test 9b is the RED companion.
        Assert.IsTrue(TempAvailableUpdate.IsEmpty(), 'An empty value-array must produce zero rows');
    end;

    // -------------------------------------------------------------------------
    // Test 9b — RED companion: after a non-empty response the parser must yield rows.
    // A stub (empty body) produces 0 rows → the final assertion FAILS in RED.
    // -------------------------------------------------------------------------
    [Test]
    procedure Parser_NonEmptyResponse_YieldsAtLeastOneRow()
    var
        Parser: Codeunit "D4P BC Update Parser";
        TempAvailableUpdate: Record "D4P BC Available Update" temporary;
        Json: Text;
    begin
        // Arrange — same single-entry fixture as Test 7.
        Json := '{"value":[{' +
                  '"targetVersion":"27.5",' +
                  '"available":true,' +
                  '"scheduleDetails":{' +
                    '"latestSelectableDateTime":"2026-06-01T00:00:00Z",' +
                    '"rolloutStatus":"Active"' +
                  '}' +
                '}]}';

        // Act
        Parser.ParseUpdatesJson(Json, TempAvailableUpdate);

        // Assert — stub body leaves TempAvailableUpdate empty; this FAILS in RED.
        Assert.IsFalse(TempAvailableUpdate.IsEmpty(), 'A non-empty value-array must produce at least one row');
        Assert.AreEqual(1, TempAvailableUpdate.Count(), 'Exactly one row expected for a single-entry response');
    end;

    // -------------------------------------------------------------------------
    // Test 10 — Legacy date field: latestSelectableDate (no Time suffix) → Date
    // -------------------------------------------------------------------------
    [Test]
    procedure Parser_LegacyDateField_BackwardCompat()
    var
        Parser: Codeunit "D4P BC Update Parser";
        TempAvailableUpdate: Record "D4P BC Available Update" temporary;
        Json: Text;
    begin
        // Arrange — some API responses use latestSelectableDate instead of
        // latestSelectableDateTime (existing D4PBCEnvironmentMgt lines 736-745).
        // The new parser must handle both shapes.
        Json := '{"value":[{' +
                  '"targetVersion":"27.5",' +
                  '"available":true,' +
                  '"scheduleDetails":{' +
                    '"latestSelectableDate":"2026-06-01"' +
                  '}' +
                '}]}';

        // Act
        Parser.ParseUpdatesJson(Json, TempAvailableUpdate);

        // Assert — stub produces 0 rows; Count assertion FAILS in RED.
        Assert.AreEqual(1, TempAvailableUpdate.Count(), 'Parser must insert exactly 1 row for a single-entry response');
        TempAvailableUpdate.FindFirst();
        Assert.AreEqual(DMY2Date(1, 6, 2026), TempAvailableUpdate."Latest Selectable Date",
            'Latest Selectable Date must be parsed from latestSelectableDate (legacy shape without Time suffix)');
    end;

    // -------------------------------------------------------------------------
    // T1 variant A — Multi-version fixture: 27.9 vs 27.10, picker must choose 27.10
    //
    // This test directly constructs the TempAvailableUpdate temp table (no JSON
    // parsing) to isolate PickDefaultTargetVersion from the parser. It catches
    // the string-comparison bug described in Critical C1: lexicographic ordering
    // would rank "27.9" > "27.10" because '9' > '1', so a naive string compare
    // would return the OLDER version.
    // -------------------------------------------------------------------------
    [Test]
    procedure PickDefaultTargetVersion_MultipleAvailable_PicksHighestSemanticVersion()
    var
        Parser: Codeunit "D4P BC Update Parser";
        TempAvailableUpdate: Record "D4P BC Available Update" temporary;
        TargetVersion: Text[100];
        DefaultDate: Date;
        ExpectedMonth: Integer;
        ExpectedYear: Integer;
    begin
        // Arrange — populate temp table directly, bypassing JSON parser
        // Row 1: version 27.9, available, date 15-May-2026
        TempAvailableUpdate.Init();
        TempAvailableUpdate."Entry No." := 1;
        TempAvailableUpdate."Target Version" := '27.9';
        TempAvailableUpdate.Available := true;
        TempAvailableUpdate."Latest Selectable Date" := DMY2Date(15, 5, 2026);
        TempAvailableUpdate.Insert();

        // Row 2: version 27.10, available, date 15-Jun-2026
        TempAvailableUpdate.Init();
        TempAvailableUpdate."Entry No." := 2;
        TempAvailableUpdate."Target Version" := '27.10';
        TempAvailableUpdate.Available := true;
        TempAvailableUpdate."Latest Selectable Date" := DMY2Date(15, 6, 2026);
        TempAvailableUpdate.Insert();

        // Act
        Parser.PickDefaultTargetVersion(TempAvailableUpdate, TargetVersion, DefaultDate, ExpectedMonth, ExpectedYear);

        // Assert — string compare "27.9" > "27.10" (lexicographic) would incorrectly
        // pick 27.9; numeric tuple compare must pick 27.10 (the higher minor version).
        Assert.AreEqual('27.10', TargetVersion,
            'PickDefaultTargetVersion must pick the highest semantic version (27.10 > 27.9); string comparison would incorrectly pick 27.9');
        Assert.AreEqual(DMY2Date(15, 6, 2026), DefaultDate,
            'DefaultDate must match the Latest Selectable Date of the winning version (27.10)');
    end;

    // -------------------------------------------------------------------------
    // T1 variant B — Double-digit vs single-digit minor: 28.10 beats 28.1 and 28.2
    //
    // Three rows in one table: 28.1, 28.10, 28.2. Lexicographic ordering would
    // rank "28.2" > "28.10" > "28.1". Numeric tuple comparison must rank
    // 28.10 as the winner.
    // -------------------------------------------------------------------------
    [Test]
    procedure PickDefaultTargetVersion_DoubleDigitVsSingleDigit_PicksHigher()
    var
        Parser: Codeunit "D4P BC Update Parser";
        TempAvailableUpdate: Record "D4P BC Available Update" temporary;
        TargetVersion: Text[100];
        DefaultDate: Date;
        ExpectedMonth: Integer;
        ExpectedYear: Integer;
    begin
        // Arrange — 3 rows, all available. Inserted in a non-sorted order to
        // confirm there is no incidental dependency on insertion order.
        // Row 1: 28.1 — lowest minor
        TempAvailableUpdate.Init();
        TempAvailableUpdate."Entry No." := 1;
        TempAvailableUpdate."Target Version" := '28.1';
        TempAvailableUpdate.Available := true;
        TempAvailableUpdate."Latest Selectable Date" := DMY2Date(15, 1, 2027);
        TempAvailableUpdate.Insert();

        // Row 2: 28.10 — highest minor (lexicographically "less than" 28.2)
        TempAvailableUpdate.Init();
        TempAvailableUpdate."Entry No." := 2;
        TempAvailableUpdate."Target Version" := '28.10';
        TempAvailableUpdate.Available := true;
        TempAvailableUpdate."Latest Selectable Date" := DMY2Date(15, 10, 2027);
        TempAvailableUpdate.Insert();

        // Row 3: 28.2 — lexicographically "greater than" 28.10 but semantically lower
        TempAvailableUpdate.Init();
        TempAvailableUpdate."Entry No." := 3;
        TempAvailableUpdate."Target Version" := '28.2';
        TempAvailableUpdate.Available := true;
        TempAvailableUpdate."Latest Selectable Date" := DMY2Date(15, 2, 2027);
        TempAvailableUpdate.Insert();

        // Act
        Parser.PickDefaultTargetVersion(TempAvailableUpdate, TargetVersion, DefaultDate, ExpectedMonth, ExpectedYear);

        // Assert — lexicographic compare would pick 28.9 or 28.2; numeric must pick 28.10
        Assert.AreEqual('28.10', TargetVersion,
            'PickDefaultTargetVersion must pick 28.10 as highest minor even though "28.2" > "28.10" lexicographically');
        Assert.AreEqual(DMY2Date(15, 10, 2027), DefaultDate,
            'DefaultDate must correspond to the winning version 28.10');
    end;

    // -------------------------------------------------------------------------
    // U1 — Mixed available + unreleased entries in a single JSON value array
    //
    // Verifies that the parser correctly handles a realistic API response that
    // contains both a released (available=true, scheduleDetails) entry and an
    // unreleased (available=false, expectedAvailability) entry side by side.
    // Each entry must land in its own temp table row with the correct field set:
    //  - The available row has a Latest Selectable Date and no Expected Month/Year.
    //  - The unreleased row has Expected Month/Year and no Latest Selectable Date.
    // -------------------------------------------------------------------------
    [Test]
    procedure Parser_MixedAvailableAndUnreleased_InSingleResponse()
    var
        Parser: Codeunit "D4P BC Update Parser";
        TempAvailableUpdate: Record "D4P BC Available Update" temporary;
        Json: Text;
    begin
        // Arrange — two entries in the value array:
        //   Entry 1: targetVersion "27.9", available=true,
        //            scheduleDetails.latestSelectableDateTime = "2026-06-01T00:00:00Z"
        //   Entry 2: targetVersion "27.10", available=false,
        //            expectedAvailability.expectedReleaseMonth=8, expectedReleaseYear=2026
        Json := '{"value":[' +
                  '{' +
                    '"targetVersion":"27.9",' +
                    '"available":true,' +
                    '"scheduleDetails":{' +
                      '"latestSelectableDateTime":"2026-06-01T00:00:00Z"' +
                    '}' +
                  '},' +
                  '{' +
                    '"targetVersion":"27.10",' +
                    '"available":false,' +
                    '"expectedAvailability":{' +
                      '"month":8,' +
                      '"year":2026' +
                    '}' +
                  '}' +
                ']}';

        // Act
        Parser.ParseUpdatesJson(Json, TempAvailableUpdate);

        // Assert — count
        Assert.AreEqual(2, TempAvailableUpdate.Count(),
            'Parser must insert exactly 2 rows for a two-entry value array');

        // Assert — "27.9" row: available=true, LatestSelectableDate set, Month/Year zero
        TempAvailableUpdate.Reset();
        TempAvailableUpdate.SetRange("Target Version", '27.9');
        Assert.IsTrue(TempAvailableUpdate.FindFirst(), 'Expected a row with Target Version = 27.9');
        Assert.AreEqual(true, TempAvailableUpdate.Available,
            '27.9 row: Available must be true');
        Assert.AreEqual(DMY2Date(1, 6, 2026), TempAvailableUpdate."Latest Selectable Date",
            '27.9 row: Latest Selectable Date must be 2026-06-01');
        Assert.AreEqual(0, TempAvailableUpdate."Expected Month",
            '27.9 row: Expected Month must be 0 (no expectedAvailability node present)');
        Assert.AreEqual(0, TempAvailableUpdate."Expected Year",
            '27.9 row: Expected Year must be 0 (no expectedAvailability node present)');

        // Assert — "27.10" row: available=false, LatestSelectableDate = 0D, Month/Year set
        TempAvailableUpdate.Reset();
        TempAvailableUpdate.SetRange("Target Version", '27.10');
        Assert.IsTrue(TempAvailableUpdate.FindFirst(), 'Expected a row with Target Version = 27.10');
        Assert.AreEqual(false, TempAvailableUpdate.Available,
            '27.10 row: Available must be false');
        Assert.AreEqual(0D, TempAvailableUpdate."Latest Selectable Date",
            '27.10 row: Latest Selectable Date must be 0D (no scheduleDetails node present)');
        Assert.AreEqual(8, TempAvailableUpdate."Expected Month",
            '27.10 row: Expected Month must be 8');
        Assert.AreEqual(2026, TempAvailableUpdate."Expected Year",
            '27.10 row: Expected Year must be 2026');
    end;

    // -------------------------------------------------------------------------
    // U2 — Malformed JSON input: parser must swallow the error and return empty
    //
    // JsonObject.ReadFrom() returns false on malformed input; the parser must
    // exit cleanly without propagating any error to the caller.
    // -------------------------------------------------------------------------
    [Test]
    procedure Parser_MalformedJson_ReturnsEmpty()
    var
        Parser: Codeunit "D4P BC Update Parser";
        TempAvailableUpdate: Record "D4P BC Available Update" temporary;
        Json: Text;
    begin
        // Arrange — deliberately malformed: not valid JSON
        Json := '{bad json here -- this is not parseable';

        // Act — must NOT raise any error; the parser's ReadFrom guard catches this
        Parser.ParseUpdatesJson(Json, TempAvailableUpdate);

        // Assert — no rows produced, no error propagated
        Assert.IsTrue(TempAvailableUpdate.IsEmpty(),
            'Parser must return an empty result for malformed JSON input without raising an error');
    end;

    // -------------------------------------------------------------------------
    // U3 — Valid JSON but without a "value" key: parser must return empty
    //
    // The Admin API occasionally returns error envelopes (e.g. 401 Unauthorized)
    // as JSON objects that have no "value" array. The parser must handle this
    // gracefully — JsonObject.Get('value', ...) returns false, parser exits.
    // -------------------------------------------------------------------------
    [Test]
    procedure Parser_ResponseMissingValueKey_ReturnsEmpty()
    var
        Parser: Codeunit "D4P BC Update Parser";
        TempAvailableUpdate: Record "D4P BC Available Update" temporary;
        Json: Text;
    begin
        // Arrange — valid JSON structure but no "value" key at the root
        Json := '{"error":{"message":"Unauthorized","code":401}}';

        // Act — must NOT raise any error; the Get('value') guard causes an early exit
        Parser.ParseUpdatesJson(Json, TempAvailableUpdate);

        // Assert — no rows produced, no error propagated
        Assert.IsTrue(TempAvailableUpdate.IsEmpty(),
            'Parser must return an empty result when the JSON response has no "value" key');
    end;

    var
        Assert: Codeunit "Library Assert";
}
