namespace D4P.CCMS.Environment;

/// <summary>
/// Phase-2 dialog of the bulk-reschedule flow. Presents one row per selected
/// environment, with inline edit of Target Version (AssistEdit drilldown to
/// page 62025) and Selected Date. Accept/Cancel expose via WasAccepted() after
/// RunModal — PageType = List (not StandardDialog) because StandardDialog with
/// a repeater raises AW0008 (see page 62025).
/// </summary>
page 62032 "D4P Bulk Reschedule Dialog"
{
    ApplicationArea = All;
    Caption = 'Bulk Reschedule Updates';
    PageType = List;
    SourceTable = "D4P BC Reschedule Plan Line";
    SourceTableTemporary = true;
    Editable = true;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = true;

    layout
    {
        area(Content)
        {
            repeater(Plan)
            {
                Caption = 'Plan';
                field("Environment Name"; Rec."Environment Name")
                {
                    Editable = false;
                    StyleExpr = RowStyleExpr;
                    ToolTip = 'Specifies the environment name.';
                }
                field("Customer No."; Rec."Customer No.")
                {
                    Editable = false;
                    StyleExpr = RowStyleExpr;
                    ToolTip = 'Specifies the customer number that owns the environment.';
                }
                field("Current Version"; Rec."Current Version")
                {
                    Editable = false;
                    StyleExpr = RowStyleExpr;
                    ToolTip = 'Specifies the environment''s current version.';
                }
                field("Target Version"; Rec."Target Version")
                {
                    Editable = RowEditable;
                    StyleExpr = RowStyleExpr;
                    ToolTip = 'Specifies the target version to schedule. Choose from the AssistEdit to see all updates available for this environment.';

                    trigger OnAssistEdit()
                    begin
                        PickTargetVersion();
                    end;
                }
                field("Selected Date"; Rec."Selected Date")
                {
                    Editable = RowEditable;
                    StyleExpr = RowStyleExpr;
                    ToolTip = 'Specifies the date to apply the update (between today and the latest selectable date).';

                    trigger OnValidate()
                    begin
                        ValidateSelectedDate();
                    end;
                }
                field("Latest Selectable Date"; Rec."Latest Selectable Date")
                {
                    Editable = false;
                    StyleExpr = RowStyleExpr;
                    ToolTip = 'Specifies the latest date on which this environment can accept the target version.';
                }
                field("Expected Month"; Rec."Expected Month")
                {
                    Editable = false;
                    Visible = not Rec.Available;
                    StyleExpr = RowStyleExpr;
                    ToolTip = 'Specifies the expected release month when the target version is unreleased.';
                }
                field("Expected Year"; Rec."Expected Year")
                {
                    Editable = false;
                    Visible = not Rec.Available;
                    StyleExpr = RowStyleExpr;
                    ToolTip = 'Specifies the expected release year when the target version is unreleased.';
                }
                field(Result; Rec.Result)
                {
                    Editable = false;
                    StyleExpr = ResultStyleExpr;
                    ToolTip = 'Specifies the current result state for this environment.';
                }
                field(Reason; Rec.Reason)
                {
                    Editable = false;
                    StyleExpr = RowStyleExpr;
                    ToolTip = 'Specifies the reason this environment is Skipped or Failed, if any.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(OK)
            {
                ApplicationArea = All;
                Caption = 'OK';
                Image = Approve;
                InFooterBar = true;
                ToolTip = 'Accept the plan and apply the reschedule to the listed environments.';

                trigger OnAction()
                begin
                    Accepted := true;
                    CurrPage.Close();
                end;
            }
            action(CancelAction)
            {
                ApplicationArea = All;
                Caption = 'Cancel';
                Image = Cancel;
                InFooterBar = true;
                ToolTip = 'Discard the plan and exit without applying any reschedule.';

                trigger OnAction()
                begin
                    Accepted := false;
                    CurrPage.Close();
                end;
            }
        }
    }

    var
        Accepted: Boolean;
        RowEditable: Boolean;
        RowStyleExpr: Text;
        ResultStyleExpr: Text;
        NoUpdatesAvailableErr: Label 'No updates are available for environment %1.', Comment = '%1 = Environment Name';
        DateTooEarlyErr: Label 'Selected date cannot be earlier than today.';
        DateTooLateErr: Label 'Selected date cannot be later than %1.', Comment = '%1 = Latest selectable date';

    trigger OnAfterGetRecord()
    begin
        UpdateRowState();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        UpdateRowState();
    end;

    /// <summary>
    /// Copy caller-provided plan rows into the page's temporary record. Called before RunModal.
    /// </summary>
    procedure SetData(var TempSourcePlan: Record "D4P BC Reschedule Plan Line" temporary)
    begin
        Rec.Reset();
        Rec.DeleteAll(false);

        TempSourcePlan.Reset();
        if TempSourcePlan.FindSet() then
            repeat
                Rec := TempSourcePlan;
                Rec.Insert(false);
            until TempSourcePlan.Next() = 0;
    end;

    /// <summary>
    /// Copy the page's (possibly user-edited) plan rows back into the caller's temp record.
    /// Called after RunModal when WasAccepted() is true.
    /// </summary>
    procedure GetData(var TempTargetPlan: Record "D4P BC Reschedule Plan Line" temporary)
    begin
        TempTargetPlan.Reset();
        TempTargetPlan.DeleteAll(false);

        Rec.Reset();
        if Rec.FindSet() then
            repeat
                TempTargetPlan := Rec;
                TempTargetPlan.Insert(false);
            until Rec.Next() = 0;
    end;

    /// <summary>
    /// Returns true if the user clicked OK (accepted the plan). Callers check this
    /// after RunModal instead of Action::OK because PageType = List exposes neither.
    /// </summary>
    procedure WasAccepted(): Boolean
    begin
        exit(Accepted);
    end;

    local procedure UpdateRowState()
    begin
        // Pending rows are editable (user can still pick a different version or date).
        // Succeeded / Skipped / Failed rows are locked and styled.
        RowEditable := Rec.Result = Rec.Result::Pending;

        case Rec.Result of
            Rec.Result::Pending:
                RowStyleExpr := Format(PageStyle::Standard);
            Rec.Result::Succeeded:
                RowStyleExpr := Format(PageStyle::Favorable);
            Rec.Result::Skipped,
            Rec.Result::Failed:
                RowStyleExpr := Format(PageStyle::Unfavorable);
        end;

        // Result column gets stronger styling so the state is scannable at a glance.
        case Rec.Result of
            Rec.Result::Succeeded:
                ResultStyleExpr := Format(PageStyle::Favorable);
            Rec.Result::Skipped,
            Rec.Result::Failed:
                ResultStyleExpr := Format(PageStyle::Unfavorable);
            else
                ResultStyleExpr := Format(PageStyle::Standard);
        end;
    end;

    local procedure ValidateSelectedDate()
    begin
        if Rec."Selected Date" = 0D then
            exit;

        if Rec."Selected Date" < Today() then
            Error(DateTooEarlyErr);

        if (Rec."Latest Selectable Date" <> 0D) and (Rec."Selected Date" > Rec."Latest Selectable Date") then
            Error(DateTooLateErr, Rec."Latest Selectable Date");
    end;

    /// <summary>
    /// AssistEdit handler for Target Version — re-fetches the env's available updates
    /// through the default Admin API codeunit (simple but robust per solution plan §2;
    /// alternative caching was judged not worth the complexity for a one-off drilldown)
    /// and opens page 62025 for selection. On OK, writes the user's choice back.
    /// </summary>
    local procedure PickTargetVersion()
    var
        BCEnv: Record "D4P BC Environment";
        TempAvailableUpdate: Record "D4P BC Available Update" temporary;
        AdminAPIImpl: Codeunit "D4P BC Admin API";
        UpdateSelectionDialog: Page "D4P Update Selection Dialog";
        AdminAPI: Interface "D4P IBC Admin API";
        TargetVersion: Text[100];
        SelectedDate: Date;
        ExpectedMonth: Integer;
        ExpectedYear: Integer;
    begin
        if Rec.Result <> Rec.Result::Pending then
            exit;

        if not BCEnv.Get(Rec."Customer No.", Rec."Tenant ID", Rec."Environment Name") then
            exit;

        AdminAPI := AdminAPIImpl;
        AdminAPI.GetAvailableUpdates(BCEnv, TempAvailableUpdate);

        if TempAvailableUpdate.IsEmpty() then
            Error(NoUpdatesAvailableErr, Rec."Environment Name");

        UpdateSelectionDialog.SetData(TempAvailableUpdate);
        if UpdateSelectionDialog.RunModal() <> Action::OK then
            exit;

        UpdateSelectionDialog.GetSelectedVersion(TargetVersion, SelectedDate, ExpectedMonth, ExpectedYear);

        Rec."Target Version" := TargetVersion;
        Rec."Selected Date" := SelectedDate;
        Rec."Expected Month" := ExpectedMonth;
        Rec."Expected Year" := ExpectedYear;
        Rec.Available := (SelectedDate <> 0D);
        if SelectedDate <> 0D then
            Rec."Latest Selectable Date" := SelectedDate;
        Rec.Modify(false);
        CurrPage.Update(false);
    end;
}
