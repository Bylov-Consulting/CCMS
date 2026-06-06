namespace D4P.CCMS.API;

using D4P.CCMS.Telemetry;

page 62068 "D4P KQL Query Store API"
{
    PageType = API;
    Caption = 'D4P KQL Query Store API', Locked = true;
    APIPublisher = 'bylov';
    APIGroup = 'ccms';
    APIVersion = 'v1.0';
    EntityName = 'kqlQueryStore';
    EntitySetName = 'kqlQueryStores';
    EntityCaption = 'KQL Query Store';
    EntitySetCaption = 'KQL Query Stores';
    SourceTable = "D4P KQL Query Store";
    DelayedInsert = true;
    ODataKeyFields = SystemId;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(systemId; Rec.SystemId)
                {
                    Caption = 'System Id';
                    Editable = false;
                }
                field(code; Rec.Code)
                {
                    Caption = 'Code';
                }
                field(name; Rec.Name)
                {
                    Caption = 'Name';
                }
                field(description; Rec.Description)
                {
                    Caption = 'Description';
                }
                field(query; QueryText)
                {
                    Caption = 'Query';
                }
                field(resultTableId; Rec."Result Table ID")
                {
                    Caption = 'Result Table ID';
                }
                field(systemModifiedAt; Rec.SystemModifiedAt)
                {
                    Caption = 'System Modified At';
                    Editable = false;
                }
            }
        }
    }

    var
        QueryText: Text;

    trigger OnAfterGetRecord()
    var
        InStr: InStream;
    begin
        Clear(QueryText);
        Rec.CalcFields(Query);
        if Rec.Query.HasValue() then begin
            Rec.Query.CreateInStream(InStr, TextEncoding::UTF8);
            InStr.ReadText(QueryText);
        end;
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        WriteQueryBlob();
    end;

    trigger OnModifyRecord(): Boolean
    begin
        WriteQueryBlob();
    end;

    local procedure WriteQueryBlob()
    var
        OutStr: OutStream;
    begin
        Clear(Rec.Query);
        Rec.Query.CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText(QueryText);
    end;
}
