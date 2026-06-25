namespace D4P.CCMS.Connector.RestClientOAuth;

using System.Security.Authentication;
codeunit 62023 "D4P Client Credentials Flow" implements "D4P OAuth Authorization Flow"
{
    var
        ClientCredentialsFlowImpl: Codeunit "D4P ClientCredentialsFlow Impl";

    procedure SetAuthority(Value: Interface "D4P OAuth Authority")
    begin
        ClientCredentialsFlowImpl.SetAuthority(Value);
    end;

    procedure Initialize(OAuthAuthority: Interface "D4P OAuth Authority"; OAuthClientType: Enum "D4P OAuth Client Type"; PromptInteraction: Enum "Prompt Interaction");
    begin
        ClientCredentialsFlowImpl.Initialize(OAuthAuthority);
    end;

    procedure GetAuthorizationHeader(OAuthClientApplication: Codeunit "D4P OAuth Appl. Config") ReturnValue: SecretText;
    begin
        ReturnValue := ClientCredentialsFlowImpl.GetAuthorizationHeader(OAuthClientApplication);
    end;
}