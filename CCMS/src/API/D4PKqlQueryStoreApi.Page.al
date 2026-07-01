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

                    trigger OnValidate()
                    begin
                        QueryProvided := true;
                    end;
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
        QueryProvided: Boolean;

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
        // Same guard as OnModifyRecord: only persist the Blob when `query` was supplied.
        // A create without a query leaves the Blob empty, which is acceptable.
        if QueryProvided then
            WriteQueryBlob();
    end;

    trigger OnModifyRecord(): Boolean
    begin
        // Only overwrite the Query Blob when the caller actually supplied the `query`
        // property in this PATCH. A PATCH that touches only other fields (e.g. name)
        // leaves QueryText empty on this stateless page instance, so writing it would
        // silently clear the stored query. The OnValidate flag tells us it was provided.
        if QueryProvided then
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
