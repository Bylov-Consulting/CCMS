namespace D4P.CCMS.Connector.RestClientOAuth;
interface "D4P OAuth Client"
{
    procedure AcquireTokenByAuthorizationCode(AuthorizationCode: SecretText; VerifierCode: SecretText; OAuthAuthority: Interface "D4P OAuth Authority"; OAuthApplicationConfig: Codeunit "D4P OAuth Appl. Config") AuthenticationResult: Codeunit "D4P OAuth Result"
    procedure AcquireTokenByRefreshToken(RefreshToken: SecretText; OAuthAuthority: Interface "D4P OAuth Authority"; OAuthApplicationConfig: Codeunit "D4P OAuth Appl. Config") AuthenticationResult: Codeunit "D4P OAuth Result"
}