namespace D4P.CCMS.Connector.RestClientOAuth;
codeunit 62040 "D4P OAuth Public Client" implements "D4P OAuth Client"
{
    var
        OAuthPublicClientImpl: Codeunit "D4P OAuth Public Client Impl.";

    internal procedure AcquireDeviceAuthorization(OAuthAuthority: Interface "D4P OAuth Authority"; OAuthClientApplication: Codeunit "D4P OAuth Appl. Config") DeviceAuthorizationResponse: JsonObject
    begin
        DeviceAuthorizationResponse := OAuthPublicClientImpl.AcquireDeviceAuthorization(OAuthAuthority, OAuthClientApplication);
    end;

    procedure AcquireTokenByAuthorizationCode(AuthorizationCode: SecretText; VerifierCode: SecretText; OAuthAuthority: Interface "D4P OAuth Authority"; OAuthClientApplication: Codeunit "D4P OAuth Appl. Config") AuthenticationResult: Codeunit "D4P OAuth Result"
    begin
        AuthenticationResult := OAuthPublicClientImpl.AcquireTokenByAuthorizationCode(AuthorizationCode, VerifierCode, OAuthAuthority, OAuthClientApplication);
    end;

    procedure AcquireTokenByDeviceCode(DeviceCode: SecretText; OAuthAuthority: Interface "D4P OAuth Authority"; OAuthClientApplication: Codeunit "D4P OAuth Appl. Config"; var ErrorCode: Text; var ErrorDescription: Text) AuthenticationResult: Codeunit "D4P OAuth Result"
    begin
        AuthenticationResult := OAuthPublicClientImpl.AcquireTokenByDeviceCode(DeviceCode, OAuthAuthority, OAuthClientApplication, ErrorCode, ErrorDescription);
    end;

    procedure AcquireTokenByRefreshToken(RefreshToken: SecretText; OAuthAuthority: Interface "D4P OAuth Authority"; OAuthClientApplication: Codeunit "D4P OAuth Appl. Config") AuthenticationResult: Codeunit "D4P OAuth Result"
    begin
        AuthenticationResult := OAuthPublicClientImpl.AcquireTokenByRefreshToken(RefreshToken, OAuthAuthority, OAuthClientApplication);
    end;
}