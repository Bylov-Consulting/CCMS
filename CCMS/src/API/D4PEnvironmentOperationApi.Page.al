namespace D4P.CCMS.API;

using D4P.CCMS.Operations;

page 62055 "D4P Environment Operation API"
{
    PageType = API;
    Caption = 'D4P Environment Operation API', Locked = true;
    APIPublisher = 'bylov';
    APIGroup = 'ccms';
    APIVersion = 'v1.0';
    EntityName = 'environmentOperation';
    EntitySetName = 'environmentOperations';
    EntityCaption = 'Environment Operation';
    EntitySetCaption = 'Environment Operations';
    SourceTable = "D4P BC Environment Operation";
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
                field(operationId; Rec."Operation ID")
                {
                    Caption = 'Operation Id';
                }
                field(customerNo; Rec."Customer No.")
                {
                    Caption = 'Customer No.';
                }
                field(tenantId; Rec."Tenant ID")
                {
                    Caption = 'Tenant Id';
                }
                field(environmentName; Rec."Environment Name")
                {
                    Caption = 'Environment Name';
                }
                field(environmentType; Rec."Environment Type")
                {
                    Caption = 'Environment Type';
                }
                field(productFamily; Rec."Product Family")
                {
                    Caption = 'Product Family';
                }
                field(operationType; Rec."Operation Type")
                {
                    Caption = 'Operation Type';
                }
                field(status; Rec.Status)
                {
                    Caption = 'Status';
                }
                field(createdOn; Rec."Created On")
                {
                    Caption = 'Created On';
                }
                field(startedOn; Rec."Started On")
                {
                    Caption = 'Started On';
                }
                field(completedOn; Rec."Completed On")
                {
                    Caption = 'Completed On';
                }
                field(createdBy; Rec."Created By")
                {
                    Caption = 'Created By';
                }
                field(errorMessage; Rec."Error Message")
                {
                    Caption = 'Error Message';
                }
                field(systemModifiedAt; Rec.SystemModifiedAt)
                {
                    Caption = 'System Modified At';
                }
            }
        }
    }
}
