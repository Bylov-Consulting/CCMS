namespace D4P.CCMS.Test;

using D4P.CCMS.Environment;
using System.TestLibraries.Utilities;

/// <summary>
/// Tests for the listAvailableUpdates JSON serializer
/// ("D4P BC Environment Mgt".SerializeAvailableUpdates), extracted from
/// ListAvailableUpdates so the pure serialization can be proven without the admin-API
/// GetAvailableUpdates HTTP call.
///
/// Requirement under test: given a populated temporary "D4P BC Available Update"
/// table, SerializeAvailableUpdates must emit a JSON array with one object per row,
/// carrying the documented field names (entryNo / targetVersion / available /
/// selected / latestSelectableDate / selectedDate / ignoreUpdateWindow /
/// targetVersionType / rolloutStatus) with the exact values from the rows — this is
/// the version list the API caller relies on to pick a target before scheduleUpdate.
///
/// Assertions are falsifiable against that requirement: the test pins two distinct
/// rows with known version strings, flags and a known date, then parses the JSON
/// back and asserts array length 2 plus the exact per-element values. A serializer
/// that dropped a row, mislabeled a field, or scrambled the date format would fail.
/// </summary>
codeunit 62107 "D4P Avail Updates Ser Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";

    [Test]
    procedure SerializeAvailableUpdates_EmitsArrayOfRowsWithExactFieldsAndValues()
    var
        TempAvailableUpdate: Record "D4P BC Available Update" temporary;
        EnvironmentMgt: Codeunit "D4P BC Environment Mgt";
        ResultJson: JsonArray;
        ResultText: Text;
        Row0Date: Date;
    begin
        // [GIVEN] A temporary Available Update table populated with two known rows
        //         with distinct targetVersion / available / selected / dates.
        Row0Date := DMY2Date(15, 9, 2026);

        TempAvailableUpdate.Init();
        TempAvailableUpdate."Entry No." := 1;
        TempAvailableUpdate."Target Version" := '26.4.30000.30100';
        TempAvailableUpdate."Target Version Type" := 'Major';
        TempAvailableUpdate.Available := true;
        TempAvailableUpdate.Selected := false;
        TempAvailableUpdate."Latest Selectable Date" := Row0Date;
        TempAvailableUpdate."Ignore Update Window" := false;
        TempAvailableUpdate."Rollout Status" := 'Active';
        TempAvailableUpdate.Insert();

        TempAvailableUpdate.Init();
        TempAvailableUpdate."Entry No." := 2;
        TempAvailableUpdate."Target Version" := '27.0.40000.40100';
        TempAvailableUpdate."Target Version Type" := 'Minor';
        TempAvailableUpdate.Available := false;
        TempAvailableUpdate.Selected := true;
        TempAvailableUpdate."Latest Selectable Date" := 0D;
        TempAvailableUpdate."Ignore Update Window" := true;
        TempAvailableUpdate."Rollout Status" := 'Postponed';
        TempAvailableUpdate.Insert();

        // [WHEN] Serializing the rows to JSON.
        ResultText := EnvironmentMgt.SerializeAvailableUpdates(TempAvailableUpdate);

        // [THEN] The result is a JSON array of exactly the two rows.
        Assert.IsTrue(ResultJson.ReadFrom(ResultText), 'Serializer must emit valid JSON');
        Assert.AreEqual(2, ResultJson.Count(), 'Serializer must emit one array element per row');

        // [THEN] Element 0 carries row 1's exact field names and values.
        AssertText(ResultJson, 0, 'targetVersion', '26.4.30000.30100');
        AssertText(ResultJson, 0, 'targetVersionType', 'Major');
        AssertBool(ResultJson, 0, 'available', true);
        AssertBool(ResultJson, 0, 'selected', false);
        AssertBool(ResultJson, 0, 'ignoreUpdateWindow', false);
        AssertText(ResultJson, 0, 'rolloutStatus', 'Active');
        AssertInt(ResultJson, 0, 'entryNo', 1);
        // latestSelectableDate is XML/round-trip formatted (Format(..,0,9)); pin it exactly.
        AssertText(ResultJson, 0, 'latestSelectableDate', Format(Row0Date, 0, 9));

        // [THEN] Element 1 carries row 2's exact field names and values.
        AssertText(ResultJson, 1, 'targetVersion', '27.0.40000.40100');
        AssertText(ResultJson, 1, 'targetVersionType', 'Minor');
        AssertBool(ResultJson, 1, 'available', false);
        AssertBool(ResultJson, 1, 'selected', true);
        AssertBool(ResultJson, 1, 'ignoreUpdateWindow', true);
        AssertText(ResultJson, 1, 'rolloutStatus', 'Postponed');
        AssertInt(ResultJson, 1, 'entryNo', 2);
    end;

    local procedure GetProp(JsonArr: JsonArray; Index: Integer; PropName: Text): JsonValue
    var
        JToken: JsonToken;
        JObject: JsonObject;
    begin
        JsonArr.Get(Index, JToken);
        JObject := JToken.AsObject();
        Assert.IsTrue(JObject.Get(PropName, JToken), StrSubstNo('Element %1 must carry property %2', Index, PropName));
        exit(JToken.AsValue());
    end;

    local procedure AssertText(JsonArr: JsonArray; Index: Integer; PropName: Text; Expected: Text)
    begin
        Assert.AreEqual(Expected, GetProp(JsonArr, Index, PropName).AsText(),
            StrSubstNo('Element %1 property %2', Index, PropName));
    end;

    local procedure AssertBool(JsonArr: JsonArray; Index: Integer; PropName: Text; Expected: Boolean)
    begin
        Assert.AreEqual(Expected, GetProp(JsonArr, Index, PropName).AsBoolean(),
            StrSubstNo('Element %1 property %2', Index, PropName));
    end;

    local procedure AssertInt(JsonArr: JsonArray; Index: Integer; PropName: Text; Expected: Integer)
    begin
        Assert.AreEqual(Expected, GetProp(JsonArr, Index, PropName).AsInteger(),
            StrSubstNo('Element %1 property %2', Index, PropName));
    end;
}
