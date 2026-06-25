namespace D4P.CCMS.Connector.RestClientOAuth;
codeunit 62003 "D4P OAuth Appl. Config"
{
    var
        OAuthApplicationConfigImpl: Codeunit "D4P OAuth Appl. Config Impl.";

    #region ClientId
    procedure SetClientId(Value: Text)
    begin
        OAuthApplicationConfigImpl.SetClientId(Value);
    end;

    procedure GetClientId() Value: Text
    begin
        Value := OAuthApplicationConfigImpl.GetClientId();
    end;
    #endregion

    #region ClientSecret
    procedure SetClientSecret(Value: SecretText)
    begin
        OAuthApplicationConfigImpl.SetClientSecret(Value);
    end;

    procedure GetClientSecret() Value: SecretText
    begin
        Value := OAuthApplicationConfigImpl.GetClientSecret();
    end;
    #endregion

    #region Certificate
    procedure SetCertificate(Value: Codeunit "D4P OAuth Certificate")
    begin
        OAuthApplicationConfigImpl.SetCertificate(Value);
    end;

    procedure GetCertificate() Value: Codeunit "D4P OAuth Certificate"
    begin
        Value := OAuthApplicationConfigImpl.GetCertificate();
    end;
    #endregion

    #region RedirectUri
    procedure SetRedirectUri(Value: Text)
    begin
        OAuthApplicationConfigImpl.SetRedirectUri(Value);
    end;

    procedure GetRedirectUri() Value: Text
    begin
        Value := OAuthApplicationConfigImpl.GetRedirectUri();
    end;

    procedure SetRedirectUriType(Value: Enum "D4P Redirect URI Type")
    begin
        OAuthApplicationConfigImpl.SetRedirectUriType(Value);
    end;

    procedure GetRedirectUriType() Value: Enum "D4P Redirect URI Type"
    begin
        Value := OAuthApplicationConfigImpl.GetRedirectUriType();
    end;
    #endregion

    #region Scopes
    procedure AddScope(Scope: Text)
    begin
        OAuthApplicationConfigImpl.AddScope(Scope);
    end;

    procedure SetScopes(ScopesList: List of [Text])
    begin
        OAuthApplicationConfigImpl.SetScopes(ScopesList);
    end;

    procedure GetScopes() ReturnValue: List of [Text]
    begin
        ReturnValue := OAuthApplicationConfigImpl.GetScopes();
    end;

    procedure GetUrlEncodedScopes() UrlEncodedScopes: Text
    begin
        UrlEncodedScopes := OAuthApplicationConfigImpl.GetUrlEncodedScopes();
    end;
    #endregion
}