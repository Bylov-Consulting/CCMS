namespace D4P.CCMS.Connector.RestClientOAuth;

using System.Security.Authentication;

interface "D4P OAuth Authorization Flow"
{
    procedure Initialize(OAuthAuthority: Interface "D4P OAuth Authority"; OAuthClientType: Enum "D4P OAuth Client Type"; PromptInteraction: Enum "Prompt Interaction")
    procedure GetAuthorizationHeader(OAuthClientApplication: Codeunit "D4P OAuth Appl. Config"): SecretText
}