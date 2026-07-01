namespace D4P.CCMS.Connector.RestClientOAuth;

using System.Security.Authentication;
codeunit 62026 "D4P Device Code Flow" implements "D4P OAuth Authorization Flow"
{
    var
        DeviceCodeFlowImpl: Codeunit "D4P Device Code Flow Impl.";

    procedure SetAuthority(Value: Interface "D4P OAuth Authority")
    begin
        DeviceCodeFlowImpl.SetAuthority(Value);
    end;

    procedure Initialize(OAuthAuthority: Interface "D4P OAuth Authority"; OAuthClientType: Enum "D4P OAuth Client Type"; PromptInteraction: Enum "Prompt Interaction");
    begin
        DeviceCodeFlowImpl.Initialize(OAuthAuthority);
    end;

    procedure GetAuthorizationHeader(OAuthClientApplication: Codeunit "D4P OAuth Appl. Config") ReturnValue: SecretText
    begin
        ReturnValue := DeviceCodeFlowImpl.GetAuthorizationHeader(OAuthClientApplication);
    end;
}