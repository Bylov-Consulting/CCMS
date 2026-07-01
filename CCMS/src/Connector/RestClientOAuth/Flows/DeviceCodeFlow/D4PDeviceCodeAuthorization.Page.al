namespace D4P.CCMS.Connector.RestClientOAuth;
page 62046 "D4P Device Code Authorization"
{
    PageType = NavigatePage;
    Extensible = false;
    Caption = 'Device Code Authorization';
    ApplicationArea = All;
    UsageCategory = None;
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    LinksAllowed = false;
    ModifyAllowed = false;
    InherentEntitlements = X;
    InherentPermissions = X;

    layout
    {
        area(Content)
        {
            group(BodyGroup)
            {
                Caption = 'Authentication';
                InstructionalText = 'Complete sign in on another device. This page will close when authorization is complete.';

                field(InstructionText; InstructionText)
                {
                    ApplicationArea = All;
                    Caption = 'Instructions';
                    MultiLine = true;
                    ToolTip = 'Specifies the device authorization instructions from the authority.';
                }
                field(UserCode; UserCode)
                {
                    ApplicationArea = All;
                    Caption = 'User Code';
                    ToolTip = 'Specifies the code to enter on the verification page.';
                }
                field(VerificationUri; VerificationUri)
                {
                    ApplicationArea = All;
                    Caption = 'Verification URI';
                    ExtendedDatatype = URL;
                    ToolTip = 'Specifies the verification page where the user code must be entered.';
                }
                field(StatusText; StatusText)
                {
                    ApplicationArea = All;
                    Caption = 'Status';
                    ToolTip = 'Specifies the current device authorization polling status.';
                }
            }
            usercontrol(DeviceCodePollingTimer; "D4P Device Code Polling Timer")
            {
                ApplicationArea = All;

                trigger ControlAddInReady()
                begin
                    ControlAddInReady := true;
                    ScheduleNextPoll(StrSubstNo(WaitingForAuthorizationMsg, PollInterval));
                end;

                trigger PollingTick()
                begin
                    PollTokenEndpoint();
                end;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Cancel)
            {
                Caption = 'Cancel';
                InFooterBar = true;

                trigger OnAction()
                begin
                    CanceledByUser := true;
                    CloseDialog();
                end;
            }
        }
    }

    var
        OAuthAuthenticationResult: Codeunit "D4P OAuth Result";
        OAuthClientApplication: Codeunit "D4P OAuth Appl. Config";
        OAuthPublicClient: Codeunit "D4P OAuth Public Client";
        OAuthAuthority: Interface "D4P OAuth Authority";
        DeviceCode: SecretText;
        ExpiresAt: DateTime;
        AuthorizationCompleted: Boolean;
        CanceledByUser: Boolean;
        ControlAddInReady: Boolean;
        PollInterval: Integer;
        AuthorizationError: Text;
        InstructionText: Text;
        StatusText: Text;
        UserCode: Text;
        VerificationUri: Text;
        AuthorizationDeclinedErr: Label 'The device authorization request was declined.';
        BadVerificationCodeErr: Label 'The device authorization code was not recognized.';
        DeviceCodeErrorErr: Label 'The device authorization request failed. Error: %1. Description: %2', Comment = '%1 = The OAuth error code, %2 = The OAuth error description';
        DeviceCodeExpiredErr: Label 'The device authorization code expired.';
        DeviceCodeInstructionMsg: Label 'To sign in, open %1 and enter code %2.', Comment = '%1 = The verification URI, %2 = The user code';
        SlowDownMsg: Label 'The authorization server asked to slow down. The next status check runs in %1 seconds.', Comment = '%1 = The polling interval in seconds';
        WaitingForAuthorizationMsg: Label 'Waiting for authorization. The next status check runs in %1 seconds.', Comment = '%1 = The polling interval in seconds';

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if (not AuthorizationCompleted) and (AuthorizationError = '') then
            CanceledByUser := true;
    end;

    internal procedure SetDeviceAuthorization(DeviceCodeValue: SecretText; UserCodeValue: Text; VerificationUriValue: Text; MessageText: Text; ExpiresInValue: Integer; PollIntervalValue: Integer; Authority: Interface "D4P OAuth Authority"; ClientApplication: Codeunit "D4P OAuth Appl. Config")
    begin
        DeviceCode := DeviceCodeValue;
        UserCode := UserCodeValue;
        VerificationUri := VerificationUriValue;
        InstructionText := MessageText;
        ExpiresAt := CurrentDateTime + (ExpiresInValue * 1000);
        PollInterval := PollIntervalValue;
        OAuthAuthority := Authority;
        OAuthClientApplication := ClientApplication;

        if InstructionText = '' then
            InstructionText := StrSubstNo(DeviceCodeInstructionMsg, VerificationUri, UserCode);
    end;

    internal procedure GetAuthenticationResult() ReturnValue: Codeunit "D4P OAuth Result"
    begin
        ReturnValue := OAuthAuthenticationResult;
    end;

    internal procedure GetAuthorizationError() ReturnValue: Text
    begin
        ReturnValue := AuthorizationError;
    end;

    internal procedure IsCanceledByUser() ReturnValue: Boolean
    begin
        ReturnValue := CanceledByUser;
    end;

    local procedure PollTokenEndpoint()
    var
        ErrorCode: Text;
        ErrorDescription: Text;
    begin
        if CurrentDateTime >= ExpiresAt then begin
            AuthorizationError := DeviceCodeExpiredErr;
            CloseDialog();
            exit;
        end;

        OAuthAuthenticationResult := OAuthPublicClient.AcquireTokenByDeviceCode(DeviceCode, OAuthAuthority, OAuthClientApplication, ErrorCode, ErrorDescription);

        if OAuthAuthenticationResult.IsValid() then begin
            AuthorizationCompleted := true;
            CloseDialog();
            exit;
        end;

        case ErrorCode of
            'authorization_pending':
                ScheduleNextPoll(StrSubstNo(WaitingForAuthorizationMsg, PollInterval));
            'slow_down':
                begin
                    PollInterval += 5;
                    ScheduleNextPoll(StrSubstNo(SlowDownMsg, PollInterval));
                end;
            'authorization_declined', 'access_denied':
                begin
                    AuthorizationError := AuthorizationDeclinedErr;
                    CloseDialog();
                end;
            'bad_verification_code':
                begin
                    AuthorizationError := BadVerificationCodeErr;
                    CloseDialog();
                end;
            'expired_token':
                begin
                    AuthorizationError := DeviceCodeExpiredErr;
                    CloseDialog();
                end;
            else begin
                AuthorizationError := StrSubstNo(DeviceCodeErrorErr, ErrorCode, ErrorDescription);
                CloseDialog();
            end;
        end;
    end;

    local procedure ScheduleNextPoll(NewStatusText: Text)
    begin
        StatusText := NewStatusText;
        CurrPage.Update(false);

        if ControlAddInReady then
            CurrPage.DeviceCodePollingTimer.StartPolling(PollInterval);
    end;

    local procedure CloseDialog()
    begin
        if ControlAddInReady then
            CurrPage.DeviceCodePollingTimer.StopPolling();

        CurrPage.Close();
    end;
}