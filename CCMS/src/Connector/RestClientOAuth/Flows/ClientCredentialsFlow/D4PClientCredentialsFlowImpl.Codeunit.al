namespace D4P.CCMS.Connector.RestClientOAuth;
codeunit 62024 "D4P ClientCredentialsFlow Impl"
{
    Access = Internal;

    var
        OAuthAuthenticationResult: Codeunit "D4P OAuth Result";
        OAuthAuthority: Interface "D4P OAuth Authority";

    procedure SetAuthority(Value: Interface "D4P OAuth Authority")
    begin
        OAuthAuthority := Value;
    end;

    procedure Initialize(Value: Interface "D4P OAuth Authority");
    begin
        SetAuthority(Value);
    end;

    procedure GetAuthorizationHeader(OAuthClientApplication: Codeunit "D4P OAuth Appl. Config") ReturnValue: SecretText;
    var
        OAuthConfidentialClient: Codeunit "D4P OAuth Confidential Client";
    begin
        if OAuthAuthenticationResult.IsValid() then
            exit(OAuthAuthenticationResult.GetAuthorizationHeader);

        OAuthAuthenticationResult := OAuthConfidentialClient.AcquireTokenForClient(OAuthAuthority, OAuthClientApplication);
        ReturnValue := OAuthAuthenticationResult.GetAuthorizationHeader();
    end;
}