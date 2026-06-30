namespace D4P.CCMS.Connector.RestClientOAuth;
codeunit 62008 "D4P OAuth Result"
{
    var
        OAuthAuthenticationRsltImpl: Codeunit "D4P OAuth Result Impl.";

    // [NonDebuggable]
    procedure SetResponse(NewAuthenticationResponse: JsonObject)
    begin
        OAuthAuthenticationRsltImpl.SetResponse(NewAuthenticationResponse);
    end;

    procedure TokenType() ReturnValue: Text
    begin
        ReturnValue := OAuthAuthenticationRsltImpl.GetTokenType();
    end;

    procedure GetAuthorizationHeader() ReturnValue: SecretText
    begin
        ReturnValue := OAuthAuthenticationRsltImpl.GetAuthorizationHeader();
    end;

    procedure RefreshToken() ReturnValue: SecretText
    begin
        ReturnValue := OAuthAuthenticationRsltImpl.GetRefreshToken();
    end;

    procedure IsValid() ReturnValue: Boolean
    begin
        ReturnValue := OAuthAuthenticationRsltImpl.IsValid();
    end;
}