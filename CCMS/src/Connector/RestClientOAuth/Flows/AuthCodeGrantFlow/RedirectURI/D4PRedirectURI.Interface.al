namespace D4P.CCMS.Connector.RestClientOAuth;

using System.Security.Authentication;
interface "D4P Redirect URI"
{
    procedure RedirectURIEditable(): Boolean;
    procedure GetDefaultRedirectURI(): Text;
    procedure GetAuthorizationCode(OAuthClientApplication: Codeunit "D4P OAuth Appl. Config"; OAuthAuthority: Interface "D4P OAuth Authority"; PromptInteraction: Enum "Prompt Interaction"; PKCECodeChallenge: Text): Text;
}