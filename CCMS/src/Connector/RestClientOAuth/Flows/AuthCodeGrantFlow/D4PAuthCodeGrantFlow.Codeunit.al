namespace D4P.CCMS.Connector.RestClientOAuth;

using System.Security.Authentication;
codeunit 62021 "D4P Auth. Code Grant Flow" implements "D4P OAuth Authorization Flow"
{
    var
        AuthCodeGrantFlowImpl: Codeunit "D4P Auth Code Grant Flow Impl.";

    procedure SetPromptInteraction(Value: Enum "Prompt Interaction")
    begin
        AuthCodeGrantFlowImpl.SetPromptInteraction(Value);
    end;

    procedure GetPromptInteraction() ReturnValue: Enum "Prompt Interaction"
    begin
        ReturnValue := AuthCodeGrantFlowImpl.GetPromptInteraction();
    end;

    procedure SetOAuthClientType(Value: Enum "D4P OAuth Client Type")
    begin
        AuthCodeGrantFlowImpl.SetOAuthClientType(Value);
    end;

    procedure GetOAuthClientType() ReturnValue: Enum "D4P OAuth Client Type"
    begin
        ReturnValue := AuthCodeGrantFlowImpl.GetOAuthClientType();
    end;

    procedure SetAuthority(Value: Interface "D4P OAuth Authority")
    begin
        AuthCodeGrantFlowImpl.SetAuthority(Value);
    end;

    procedure GetAuthority() Value: Interface "D4P OAuth Authority"
    begin
        Value := AuthCodeGrantFlowImpl.GetAuthority();
    end;

    procedure Initialize(OAuthAuthority: Interface "D4P OAuth Authority"; OAuthClientType: Enum "D4P OAuth Client Type"; PromptInteraction: Enum "Prompt Interaction");
    begin
        AuthCodeGrantFlowImpl.Initialize(OAuthAuthority, OAuthClientType, PromptInteraction);
    end;

    procedure GetAuthorizationHeader(OAuthClientApplication: Codeunit "D4P OAuth Appl. Config") ReturnValue: SecretText
    begin
        ReturnValue := AuthCodeGrantFlowImpl.GetAuthorizationHeader(OAuthClientApplication);
    end;

    procedure GetPKCECodeChallenge() ReturnValue: Text
    begin
        ReturnValue := AuthCodeGrantFlowImpl.GetPKCECodeChallenge();
    end;
}
