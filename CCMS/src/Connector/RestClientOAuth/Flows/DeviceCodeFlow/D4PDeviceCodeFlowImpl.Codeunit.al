namespace D4P.CCMS.Connector.RestClientOAuth;
codeunit 62027 "D4P Device Code Flow Impl."
{
    Access = Internal;

    var
        OAuthAuthenticationResult: Codeunit "D4P OAuth Result";
        OAuthAuthority: Interface "D4P OAuth Authority";
        AuthorizationCanceledMsg: Label 'The device authorization request was canceled.';

    procedure SetAuthority(Value: Interface "D4P OAuth Authority")
    begin
        OAuthAuthority := Value;
    end;

    procedure Initialize(Value: Interface "D4P OAuth Authority");
    begin
        SetAuthority(Value);
    end;

    procedure GetAuthorizationHeader(OAuthClientApplication: Codeunit "D4P OAuth Appl. Config") ReturnValue: SecretText;
    begin
        if OAuthAuthenticationResult.IsValid() then
            exit(OAuthAuthenticationResult.GetAuthorizationHeader());

        if TryAcquireTokenByRefreshToken(OAuthClientApplication) then
            exit(OAuthAuthenticationResult.GetAuthorizationHeader());

        AcquireTokenByDeviceCode(OAuthClientApplication);
        ReturnValue := OAuthAuthenticationResult.GetAuthorizationHeader();
    end;

    local procedure AcquireTokenByDeviceCode(OAuthClientApplication: Codeunit "D4P OAuth Appl. Config")
    var
        OAuthPublicClient: Codeunit "D4P OAuth Public Client";
        DeviceCodeAuthorization: Page "D4P Device Code Authorization";
        DeviceAuthorizationResponse: JsonObject;
        DeviceCode: SecretText;
        ExpiresIn: Integer;
        PollInterval: Integer;
        AuthorizationError: Text;
        MessageText: Text;
        UserCode: Text;
        VerificationUri: Text;
    begin
        if not OAuthClientApplication.GetScopes().Contains('offline_access') then
            OAuthClientApplication.AddScope('offline_access');

        DeviceAuthorizationResponse := OAuthPublicClient.AcquireDeviceAuthorization(OAuthAuthority, OAuthClientApplication);
        SetDeviceAuthorizationResponse(DeviceAuthorizationResponse, DeviceCode, UserCode, VerificationUri, ExpiresIn, PollInterval, MessageText);

        DeviceCodeAuthorization.SetDeviceAuthorization(DeviceCode, UserCode, VerificationUri, MessageText, ExpiresIn, PollInterval, OAuthAuthority, OAuthClientApplication);
        DeviceCodeAuthorization.RunModal();

        if DeviceCodeAuthorization.IsCanceledByUser() then
            Error(AuthorizationCanceledMsg);

        AuthorizationError := DeviceCodeAuthorization.GetAuthorizationError();
        if AuthorizationError <> '' then
            Error(AuthorizationError);

        OAuthAuthenticationResult := DeviceCodeAuthorization.GetAuthenticationResult();
    end;

    local procedure SetDeviceAuthorizationResponse(DeviceAuthorizationResponse: JsonObject; var DeviceCode: SecretText; var UserCode: Text; var VerificationUri: Text; var ExpiresIn: Integer; var Interval: Integer; var MessageText: Text)
    begin
        DeviceCode := GetJsonToken('device_code', DeviceAuthorizationResponse).AsValue().AsText();
        UserCode := GetJsonToken('user_code', DeviceAuthorizationResponse).AsValue().AsText();
        VerificationUri := GetJsonToken('verification_uri', DeviceAuthorizationResponse).AsValue().AsText();
        MessageText := GetJsonToken('message', DeviceAuthorizationResponse).AsValue().AsText();

        if DeviceAuthorizationResponse.Contains('expires_in') then
            ExpiresIn := GetJsonToken('expires_in', DeviceAuthorizationResponse).AsValue().AsInteger();

        if DeviceAuthorizationResponse.Contains('interval') then
            Interval := GetJsonToken('interval', DeviceAuthorizationResponse).AsValue().AsInteger();

        if Interval = 0 then
            Interval := 5;
    end;

    local procedure GetJsonToken(Path: Text; JsonObject: JsonObject) Result: JsonToken
    var
        DummyJsonValue: JsonValue;
    begin
        if not JsonObject.SelectToken(Path, Result) then begin
            DummyJsonValue.SetValue('');
            Result := DummyJsonValue.AsToken();
        end;
    end;

    [TryFunction]
    local procedure TryAcquireTokenByRefreshToken(OAuthClientApplication: Codeunit "D4P OAuth Appl. Config")
    var
        OAuthPublicClient: Codeunit "D4P OAuth Public Client";
    begin
        if OAuthAuthenticationResult.RefreshToken().IsEmpty() then
            Error('');

        OAuthAuthenticationResult := OAuthPublicClient.AcquireTokenByRefreshToken(OAuthAuthenticationResult.RefreshToken(), OAuthAuthority, OAuthClientApplication);
    end;
}