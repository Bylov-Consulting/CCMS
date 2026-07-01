namespace D4P.CCMS.Connector.RestClientOAuth;
codeunit 62004 "D4P OAuth Appl. Config Impl."
{
    Access = Internal;

    #region ClientId
    var
        ClientId: Text;

    procedure SetClientId(Value: Text)
    begin
        ClientId := Value;
    end;

    procedure GetClientId() Value: Text
    begin
        Value := ClientId;
    end;
    #endregion

    #region ClientSecret
    var
        ClientSecret: SecretText;

    procedure SetClientSecret(Value: SecretText)
    begin
        ClientSecret := Value;
    end;

    procedure GetClientSecret() Value: SecretText
    begin
        Value := ClientSecret;
    end;
    #endregion

    #region Certificate
    var
        Certificate: Codeunit "D4P OAuth Certificate";

    procedure SetCertificate(Value: Codeunit "D4P OAuth Certificate")
    begin
        Certificate := Value;
    end;

    procedure GetCertificate() Value: Codeunit "D4P OAuth Certificate"
    begin
        Value := Certificate;
    end;

    #endregion

    #region RedirectUri
    var
        RedirectUri: Text;
        RedirectURIType: Enum "D4P Redirect URI Type";

    procedure SetRedirectUri(Value: Text)
    begin
        RedirectUri := Value;
    end;

    procedure GetRedirectUri() Value: Text
    begin
        Value := RedirectUri;
    end;

    procedure SetRedirectUriType(Value: Enum "D4P Redirect URI Type")
    begin
        RedirectURIType := Value;
    end;

    procedure GetRedirectUriType() Value: Enum "D4P Redirect URI Type"
    begin
        Value := RedirectURIType;
    end;
    #endregion

    #region Scopes
    var
        Scopes: List of [Text];

    procedure AddScope(Scope: Text)
    begin
        Scopes.Add(Scope);
    end;

    procedure SetScopes(ScopesList: List of [Text])
    var
        Scope: Text;
    begin
        Clear(Scopes);
        foreach Scope in ScopesList do
            Scopes.Add(Scope);
    end;

    procedure GetScopes() ReturnValue: List of [Text]
    begin
        ReturnValue := Scopes;
    end;

    procedure GetUrlEncodedScopes() UrlEncodedScopes: Text
    var
        TextBuilder: TextBuilder;
        Scope: Text;
    begin
        // Historical name: keep scopes space-delimited here; pre-encoding the scope string breaks token acquisition with the current HTTP request flow.
        foreach Scope in Scopes do begin
            TextBuilder.Append(Scope);
            TextBuilder.Append(' ');
        end;
        UrlEncodedScopes := TextBuilder.ToText().Trim();
    end;
    #endregion
}