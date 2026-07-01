namespace D4P.CCMS.API;

using D4P.CCMS.Extension;

page 62063 "D4P PTE Object Range API"
{
    PageType = API;
    Caption = 'D4P PTE Object Range API', Locked = true;
    APIPublisher = 'bylov';
    APIGroup = 'ccms';
    APIVersion = 'v1.0';
    EntityName = 'pteObjectRange';
    EntitySetName = 'pteObjectRanges';
    EntityCaption = 'PTE Object Range';
    EntitySetCaption = 'PTE Object Ranges';
    SourceTable = "D4P PTE Object Range";
    DelayedInsert = true;
    ODataKeyFields = SystemId;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(systemId; Rec.SystemId)
                {
                    Caption = 'System Id';
                }
                field(customerNo; Rec."Customer No.")
                {
                    Caption = 'Customer No.';
                }
                field(tenantId; Rec."Tenant ID")
                {
                    Caption = 'Tenant Id';
                }
                field(entryNo; Rec."Entry No.")
                {
                    Caption = 'Entry No.';
                }
                field(pteId; Rec."PTE ID")
                {
                    Caption = 'PTE Id';
                }
                field(pteName; Rec."PTE Name")
                {
                    Caption = 'PTE Name';
                }
                field(rangeFrom; Rec."Range From")
                {
                    Caption = 'Range From';
                }
                field(rangeTo; Rec."Range To")
                {
                    Caption = 'Range To';
                }
                field(systemModifiedAt; Rec.SystemModifiedAt)
                {
                    Caption = 'System Modified At';
                }
            }
        }
    }
}
