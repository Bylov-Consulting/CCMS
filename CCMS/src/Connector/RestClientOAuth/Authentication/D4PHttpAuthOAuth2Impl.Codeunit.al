namespace D4P.CCMS.Connector.RestClientOAuth;
codeunit 62007 "D4P Http Auth. OAuth2 Impl."
{
    Access = Internal;

    var
        OAuthClientApplication: Codeunit "D4P OAuth Appl. Config";
        OAuthAuthorizationFlow: Interface "D4P OAuth Authorization Flow";

    procedure Initialize(ClientApplication: Codeunit "D4P OAuth Appl. Config"; AuthorizationFlow: Interface "D4P OAuth Authorization Flow")
    begin
        OAuthClientApplication := ClientApplication;
        OAuthAuthorizationFlow := AuthorizationFlow;
    end;

    procedure IsAuthenticationRequired(): Boolean;
    begin
        exit(true);
    end;

    procedure GetAuthorizationHeaders() Headers: Dictionary of [Text, SecretText];
    begin
        Headers.Add('Authorization', OAuthAuthorizationFlow.GetAuthorizationHeader(OAuthClientApplication));
    end;
}