namespace D4P.CCMS.Environment;

codeunit 62006 "D4P BC Update Parser"
{
    /// <summary>
    /// Pure parser: JSON response text to temporary "D4P BC Available Update" rows.
    /// Handles the latestSelectableDateTime (nested, new) vs latestSelectableDate
    /// (legacy flat shape) API quirk. Both forms populate "Latest Selectable Date".
    /// </summary>
    procedure ParseUpdatesJson(ResponseText: Text; var TempAvailableUpdate: Record "D4P BC Available Update" temporary)
    var
        JsonResponse: JsonObject;
        JsonArray: JsonArray;
        JsonObjectLoop: JsonObject;
        JsonScheduleDetails: JsonObject;
        JsonExpectedAvailability: JsonObject;
        JsonToken: JsonToken;
        JsonTokenLoop: JsonToken;
        JsonValue: JsonValue;
        ParsedDateTime: DateTime;
        ParsedDate: Date;
        EntryNo: Integer;
    begin
        TempAvailableUpdate.Reset();
        TempAvailableUpdate.DeleteAll(false);

        if ResponseText = '' then
            exit;

        if not JsonResponse.ReadFrom(ResponseText) then
            exit;

        if not JsonResponse.Get('value', JsonToken) then
            exit;

        JsonArray := JsonToken.AsArray();
        EntryNo := 0;

        foreach JsonTokenLoop in JsonArray do begin
            JsonObjectLoop := JsonTokenLoop.AsObject();
            EntryNo += 1;

            TempAvailableUpdate.Init();
            TempAvailableUpdate."Entry No." := EntryNo;

            // Target Version
            if JsonObjectLoop.Get('targetVersion', JsonToken) then begin
                JsonValue := JsonToken.AsValue();
                if not JsonValue.IsNull() then
                    TempAvailableUpdate."Target Version" := CopyStr(JsonValue.AsText(), 1, MaxStrLen(TempAvailableUpdate."Target Version"));
            end;

            // Availability
            if JsonObjectLoop.Get('available', JsonToken) then begin
                JsonValue := JsonToken.AsValue();
                if not JsonValue.IsNull() then
                    TempAvailableUpdate.Available := JsonValue.AsBoolean();
            end;

            // Selected flag
            if JsonObjectLoop.Get('selected', JsonToken) then begin
                JsonValue := JsonToken.AsValue();
                if not JsonValue.IsNull() then
                    TempAvailableUpdate.Selected := JsonValue.AsBoolean();
            end;

            // Target version type
            if JsonObjectLoop.Get('targetVersionType', JsonToken) then begin
                JsonValue := JsonToken.AsValue();
                if not JsonValue.IsNull() then
                    TempAvailableUpdate."Target Version Type" := CopyStr(JsonValue.AsText(), 1, MaxStrLen(TempAvailableUpdate."Target Version Type"));
            end;

            // Nested scheduleDetails (released / schedulable versions)
            if JsonObjectLoop.Get('scheduleDetails', JsonToken) then begin
                JsonScheduleDetails := JsonToken.AsObject();

                // selectedDateTime
                if JsonScheduleDetails.Get('selectedDateTime', JsonToken) then begin
                    JsonValue := JsonToken.AsValue();
                    if not JsonValue.IsNull() then
                        TempAvailableUpdate."Selected DateTime" := JsonValue.AsDateTime().Date();
                end;

                // Latest selectable date — API quirk: either latestSelectableDateTime (full ISO
                // DateTime, new nested shape) or legacy latestSelectableDate (date-only string
                // like "2026-06-01"). Both map to the same Date field, but require different
                // parsing: NavDateTime rejects date-only strings, so AsDate() must be used for
                // the legacy flat key while AsDateTime().Date() is used for the full ISO value.
                if JsonScheduleDetails.Get('latestSelectableDateTime', JsonToken) then begin
                    JsonValue := JsonToken.AsValue();
                    if not JsonValue.IsNull() then begin
                        ParsedDateTime := JsonValue.AsDateTime();
                        TempAvailableUpdate."Latest Selectable Date" := ParsedDateTime.Date();
                    end;
                end else
                    if JsonScheduleDetails.Get('latestSelectableDate', JsonToken) then begin
                        JsonValue := JsonToken.AsValue();
                        if not JsonValue.IsNull() then begin
                            ParsedDate := JsonValue.AsDate();
                            TempAvailableUpdate."Latest Selectable Date" := ParsedDate;
                        end;
                    end;

                // ignoreUpdateWindow
                if JsonScheduleDetails.Get('ignoreUpdateWindow', JsonToken) then begin
                    JsonValue := JsonToken.AsValue();
                    if not JsonValue.IsNull() then
                        TempAvailableUpdate."Ignore Update Window" := JsonValue.AsBoolean();
                end;

                // rolloutStatus
                if JsonScheduleDetails.Get('rolloutStatus', JsonToken) then begin
                    JsonValue := JsonToken.AsValue();
                    if not JsonValue.IsNull() then
                        TempAvailableUpdate."Rollout Status" := CopyStr(JsonValue.AsText(), 1, MaxStrLen(TempAvailableUpdate."Rollout Status"));
                end;
            end;

            // Nested expectedAvailability (unreleased versions)
            if JsonObjectLoop.Get('expectedAvailability', JsonToken) then begin
                JsonExpectedAvailability := JsonToken.AsObject();

                if JsonExpectedAvailability.Get('month', JsonToken) then begin
                    JsonValue := JsonToken.AsValue();
                    if not JsonValue.IsNull() then
                        TempAvailableUpdate."Expected Month" := JsonValue.AsInteger();
                end;

                if JsonExpectedAvailability.Get('year', JsonToken) then begin
                    JsonValue := JsonToken.AsValue();
                    if not JsonValue.IsNull() then
                        TempAvailableUpdate."Expected Year" := JsonValue.AsInteger();
                end;
            end;

            TempAvailableUpdate.Insert(false);
        end;
    end;

    /// <summary>
    /// Pure: chooses the most recent Available=true row (highest Target Version string);
    /// falls back to the most recent unreleased row (max Expected Year then Month) if
    /// none are available. Leaves out-params at their default values if the temp table is empty.
    /// </summary>
    procedure PickDefaultTargetVersion(var TempAvailableUpdate: Record "D4P BC Available Update" temporary; var TargetVersion: Text[100]; var DefaultDate: Date; var ExpectedMonth: Integer; var ExpectedYear: Integer)
    var
        TempBestAvailable: Record "D4P BC Available Update" temporary;
        TempBestUnreleased: Record "D4P BC Available Update" temporary;
        HasAvailable: Boolean;
        HasUnreleased: Boolean;
    begin
        TargetVersion := '';
        DefaultDate := 0D;
        ExpectedMonth := 0;
        ExpectedYear := 0;

        TempAvailableUpdate.Reset();
        if not TempAvailableUpdate.FindSet() then
            exit;

        repeat
            if TempAvailableUpdate.Available then
                RankAvailable(TempAvailableUpdate, TempBestAvailable, HasAvailable)
            else
                RankUnreleased(TempAvailableUpdate, TempBestUnreleased, HasUnreleased);
        until TempAvailableUpdate.Next() = 0;

        if HasAvailable then begin
            TargetVersion := TempBestAvailable."Target Version";
            DefaultDate := TempBestAvailable."Latest Selectable Date";
            exit;
        end;

        if HasUnreleased then begin
            TargetVersion := TempBestUnreleased."Target Version";
            ExpectedMonth := TempBestUnreleased."Expected Month";
            ExpectedYear := TempBestUnreleased."Expected Year";
        end;
    end;

    local procedure RankAvailable(var Candidate: Record "D4P BC Available Update" temporary; var TempBest: Record "D4P BC Available Update" temporary; var HasBest: Boolean)
    begin
        if (not HasBest) or (CompareVersions(Candidate."Target Version", TempBest."Target Version") > 0) then begin
            TempBest := Candidate;
            HasBest := true;
        end;
    end;

    local procedure RankUnreleased(var Candidate: Record "D4P BC Available Update" temporary; var TempBest: Record "D4P BC Available Update" temporary; var HasBest: Boolean)
    var
        VersionCompare: Integer;
    begin
        if not HasBest then begin
            TempBest := Candidate;
            HasBest := true;
            exit;
        end;

        // Month/Year is the primary ranking for unreleased candidates because the Admin API
        // may return identical "Target Version" placeholders for several upcoming months.
        // Only fall back to version comparison on an exact month/year tie.
        if Candidate."Expected Year" > TempBest."Expected Year" then begin
            TempBest := Candidate;
            exit;
        end;
        if Candidate."Expected Year" < TempBest."Expected Year" then
            exit;

        if Candidate."Expected Month" > TempBest."Expected Month" then begin
            TempBest := Candidate;
            exit;
        end;
        if Candidate."Expected Month" < TempBest."Expected Month" then
            exit;

        VersionCompare := CompareVersions(Candidate."Target Version", TempBest."Target Version");
        if VersionCompare > 0 then
            TempBest := Candidate;
    end;

    /// <summary>
    /// Returns 1 if A > B, -1 if A < B, 0 if equal. Splits both strings on '.' and compares
    /// each segment numerically, so "27.10" correctly outranks "27.9". Non-numeric segments
    /// (e.g. pre-release tags the Admin API may return) sort as -1 — below any numeric
    /// segment — to keep the ordering predictable and deterministic.
    /// </summary>
    local procedure CompareVersions(A: Text[100]; B: Text[100]): Integer
    var
        SegA: Integer;
        SegB: Integer;
        i: Integer;
        MaxParts: Integer;
        PartsA: List of [Text];
        PartsB: List of [Text];
    begin
        PartsA := SplitVersion(A);
        PartsB := SplitVersion(B);

        if PartsA.Count() > PartsB.Count() then
            MaxParts := PartsA.Count()
        else
            MaxParts := PartsB.Count();

        for i := 1 to MaxParts do begin
            SegA := SegmentAsInt(PartsA, i);
            SegB := SegmentAsInt(PartsB, i);
            if SegA > SegB then
                exit(1);
            if SegA < SegB then
                exit(-1);
        end;
        exit(0);
    end;

    local procedure SplitVersion(V: Text[100]) Result: List of [Text]
    var
        Part: Text;
        i: Integer;
        Ch: Char;
    begin
        Part := '';
        for i := 1 to StrLen(V) do begin
            Ch := V[i];
            if Ch = '.' then begin
                Result.Add(Part);
                Part := '';
            end else
                Part += Format(Ch);
        end;
        Result.Add(Part);
    end;

    local procedure SegmentAsInt(Parts: List of [Text]; Index: Integer): Integer
    var
        Segment: Text;
        Value: Integer;
    begin
        // Missing segments (e.g. "27" vs "27.10") are treated as 0 so "27.0" = "27".
        if Index > Parts.Count() then
            exit(0);

        Segment := Parts.Get(Index);
        if Segment = '' then
            exit(-1);
        if Evaluate(Value, Segment) then
            exit(Value);
        // Non-numeric (pre-release tag) sorts below any numeric segment.
        exit(-1);
    end;
}
