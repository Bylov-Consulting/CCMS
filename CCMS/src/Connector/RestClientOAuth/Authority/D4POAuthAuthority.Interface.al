namespace D4P.CCMS.Connector.RestClientOAuth;
interface "D4P OAuth Authority"
{
    procedure Initialize(OAuthApplicationCode: Code[20]; TargetTenantId: Text)
    procedure GetApplicationConfig(OAuthApplicationCode: Code[20]; ScopesList: List of [Text]) OAuthApplicationConfig: Codeunit "D4P OAuth Appl. Config"
    procedure GetAuthorizationEndpoint(OAuthClientApplication: Codeunit "D4P OAuth Appl. Config"): Text
    procedure GetDeviceAuthorizationEndpoint(): Text
    procedure GetTokenEndpoint(): Text
}