namespace D4P.CCMS.API;

using D4P.CCMS.Features;

page 62052 "D4P Environment Feature API"
{
    PageType = API;
    Caption = 'D4P Environment Feature API', Locked = true;
    APIPublisher = 'bylov';
    APIGroup = 'ccms';
    APIVersion = 'v1.0';
    EntityName = 'environmentFeature';
    EntitySetName = 'environmentFeatures';
    EntityCaption = 'Environment Feature';
    EntitySetCaption = 'Environment Features';
    SourceTable = "D4P BC Environment Feature";
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
                field(environmentName; Rec."Environment Name")
                {
                    Caption = 'Environment Name';
                }
                field(featureName; Rec."Feature Name")
                {
                    Caption = 'Feature Name';
                }
                field(featureKey; Rec."Feature Key")
                {
                    Caption = 'Feature Key';
                }
                field(isEnabled; Rec."Is Enabled")
                {
                    Caption = 'Enabled Status';
                }
                field(featureDescription; Rec."Feature Description")
                {
                    Caption = 'Feature Description';
                }
                field(descriptionInEnglish; Rec."Description In English")
                {
                    Caption = 'Description In English';
                }
                field(canTry; Rec."Can Try")
                {
                    Caption = 'Can Try';
                }
                field(isOneWay; Rec."Is One Way")
                {
                    Caption = 'Is One Way';
                }
                field(dataUpdateRequired; Rec."Data Update Required")
                {
                    Caption = 'Data Update Required';
                }
                field(mandatoryBy; Rec."Mandatory By")
                {
                    Caption = 'Mandatory By';
                }
                field(mandatoryByVersion; Rec."Mandatory By Version")
                {
                    Caption = 'Mandatory By Version';
                }
                field(learnMoreLink; Rec."Learn More Link")
                {
                    Caption = 'Learn More Link';
                }
                field(lastModified; Rec."Last Modified")
                {
                    Caption = 'Last Modified';
                }
                field(systemModifiedAt; Rec.SystemModifiedAt)
                {
                    Caption = 'System Modified At';
                }
            }
        }
    }

    /// <summary>
    /// DESTRUCTIVE (one-way for many features): activates the bound feature on its
    /// environment. Gated behind Confirm=true. UpdateInBackground defaults to true and
    /// StartDateTime to now. Re-read the feature entity (Is Enabled) for the result.
    /// </summary>
    [ServiceEnabled]
    procedure ActivateFeature(Confirm: Boolean; var ActionContext: WebServiceActionContext)
    var
        FeaturesHelper: Codeunit "D4P BC Features Helper";
        ConfirmRequiredErr: Label 'Activating a feature can be irreversible (one-way). This action is gated. Re-send with Confirm = true to proceed.';
    begin
        if not Confirm then
            Error(ConfirmRequiredErr);

        // SkipDialog=true => GUI-free.
        FeaturesHelper.ActivateFeature(Rec, true, CurrentDateTime(), true);

        SetFeatureActionResult(ActionContext);
    end;

    /// <summary>
    /// DESTRUCTIVE: deactivates the bound feature on its environment.
    /// Gated behind Confirm=true. Re-read the feature entity (Is Enabled) for the result.
    /// </summary>
    [ServiceEnabled]
    procedure DeactivateFeature(Confirm: Boolean; var ActionContext: WebServiceActionContext)
    var
        FeaturesHelper: Codeunit "D4P BC Features Helper";
        ConfirmRequiredErr: Label 'Deactivating a feature changes a real environment. This action is gated. Re-send with Confirm = true to proceed.';
    begin
        if not Confirm then
            Error(ConfirmRequiredErr);

        FeaturesHelper.DeactivateFeature(Rec);

        SetFeatureActionResult(ActionContext);
    end;

    local procedure SetFeatureActionResult(var ActionContext: WebServiceActionContext)
    begin
        ActionContext.SetObjectType(ObjectType::Page);
        ActionContext.SetObjectId(Page::"D4P Environment Feature API");
        ActionContext.AddEntityKey(Rec.FieldNo(SystemId), Rec.SystemId);
        ActionContext.SetResultCode(WebServiceActionResultCode::Get);
    end;
}
