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

    var
        Assert: Codeunit "Library Assert";
}
