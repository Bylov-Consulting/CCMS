namespace D4P.CCMS.Connector.RestClientOAuth;

using System.Security.Authentication;
codeunit 62020 "D4P Redirect URI None" implements "D4P Redirect URI"
{
    procedure RedirectURIEditable(): Boolean
    begin
        exit(false);
    end;

    procedure GetDefaultRedirectURI(): Text
    begin
        exit('');
    end;

    procedure GetAuthorizationCode(OAuthClientApplication: Codeunit "D4P OAuth Appl. Config"; OAuthAuthority: Interface "D4P OAuth Authority"; PromptInteraction: Enum "Prompt Interaction"; PKCECodeChallenge: Text): Text
    begin
        exit('');
    end;
}