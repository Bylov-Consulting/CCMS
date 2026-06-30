namespace D4P.CCMS.Connector.RestClientOAuth;
codeunit 62038 "D4P OAuth Confidential Client" implements "D4P OAuth Client"
{
    var
        OAuthConfidentialClientImpl: Codeunit "D4P OAuth Conf. Client Impl.";

    procedure AcquireTokenByAuthorizationCode(AuthorizationCode: SecretText; OAuthAuthority: Interface "D4P OAuth Authority"; OAuthClientApplication: Codeunit "D4P OAuth Appl. Config") AuthenticationResult: Codeunit "D4P OAuth Result"
    begin
        AuthenticationResult := OAuthConfidentialClientImpl.AcquireTokenByAuthorizationCode(AuthorizationCode, OAuthAuthority, OAuthClientApplication);
    end;

    procedure AcquireTokenByAuthorizationCode(AuthorizationCode: SecretText; VerifierCode: SecretText; OAuthAuthority: Interface "D4P OAuth Authority"; OAuthClientApplication: Codeunit "D4P OAuth Appl. Config") AuthenticationResult: Codeunit "D4P OAuth Result"
    begin
        AuthenticationResult := OAuthConfidentialClientImpl.AcquireTokenByAuthorizationCode(AuthorizationCode, VerifierCode, OAuthAuthority, OAuthClientApplication);
    end;

    procedure AcquireTokenByRefreshToken(RefreshToken: SecretText; OAuthAuthority: Interface "D4P OAuth Authority"; OAuthClientApplication: Codeunit "D4P OAuth Appl. Config") AuthenticationResult: Codeunit "D4P OAuth Result"
    begin
        AuthenticationResult := OAuthConfidentialClientImpl.AcquireTokenByRefreshToken(RefreshToken, OAuthAuthority, OAuthClientApplication);
    end;

    procedure AcquireTokenForClient(OAuthAuthority: Interface "D4P OAuth Authority"; OAuthClientApplication: Codeunit "D4P OAuth Appl. Config") AuthenticationResult: Codeunit "D4P OAuth Result"
    begin
        AuthenticationResult := OAuthConfidentialClientImpl.AcquireTokenForClient(OAuthAuthority, OAuthClientApplication);
    end;
}