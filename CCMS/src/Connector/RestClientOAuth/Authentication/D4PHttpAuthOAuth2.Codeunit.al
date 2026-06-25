namespace D4P.CCMS.Connector.RestClientOAuth;

using System.RestClient;
codeunit 62006 "D4P Http Auth. OAuth2" implements "Http Authentication"
{
    var
        HttpAuthenticationOAuth2Impl: Codeunit "D4P Http Auth. OAuth2 Impl.";

    procedure Initialize(ClientApplication: Codeunit "D4P OAuth Appl. Config"; AuthorizationFlow: Interface "D4P OAuth Authorization Flow")
    begin
        HttpAuthenticationOAuth2Impl.Initialize(ClientApplication, AuthorizationFlow);
    end;

    procedure IsAuthenticationRequired(): Boolean;
    begin
        exit(HttpAuthenticationOAuth2Impl.IsAuthenticationRequired());
    end;

    procedure GetAuthorizationHeaders() Headers: Dictionary of [Text, SecretText];
    begin
        Headers := HttpAuthenticationOAuth2Impl.GetAuthorizationHeaders()
    end;
}