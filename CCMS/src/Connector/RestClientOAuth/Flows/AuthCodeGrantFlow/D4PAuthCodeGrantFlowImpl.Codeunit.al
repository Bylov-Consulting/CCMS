namespace D4P.CCMS.Connector.RestClientOAuth;

using System.Security.Authentication;
using System.Security.Encryption;
codeunit 62022 "D4P Auth Code Grant Flow Impl."
{
    Access = Internal;

    var
        OAuthAuthenticationResult: Codeunit "D4P OAuth Result";
        OAuthAuthority: Interface "D4P OAuth Authority";
        AuthorizationCanceledMsg: Label 'The authorization was canceled.';
        PKCECodeVerifier: Text[128];
        OAuthClientType: Enum "D4P OAuth Client Type";
        PromptInteraction: Enum "Prompt Interaction";

    procedure SetPromptInteraction(Value: Enum "Prompt Interaction")
    begin
        PromptInteraction := Value;
    end;

    procedure GetPromptInteraction() Value: Enum "Prompt Interaction"
    begin
        Value := PromptInteraction;
    end;

    procedure SetOAuthClientType(Value: Enum "D4P OAuth Client Type")
    begin
        OAuthClientType := Value;
    end;

    procedure GetOAuthClientType() Value: Enum "D4P OAuth Client Type"
    begin
        Value := OAuthClientType;
    end;

    procedure SetAuthority(Value: Interface "D4P OAuth Authority")
    begin
        OAuthAuthority := Value;
    end;

    procedure GetAuthority() Value: Interface "D4P OAuth Authority"
    begin
        Value := OAuthAuthority;
    end;

    procedure Initialize(OAuthAuthorityValue: Interface "D4P OAuth Authority"; OAuthClientTypeValue: Enum "D4P OAuth Client Type"; PromptInteractionValue: Enum "Prompt Interaction");
    begin
        OAuthAuthority := OAuthAuthorityValue;
        OAuthClientType := OAuthClientTypeValue;
        PromptInteraction := PromptInteractionValue;
    end;

    procedure GetAuthorizationHeader(OAuthClientApplication: Codeunit "D4P OAuth Appl. Config"): SecretText
    begin
        if OAuthAuthenticationResult.IsValid() then
            exit(OAuthAuthenticationResult.GetAuthorizationHeader());

        if TryAcquireTokenByRefreshToken(OAuthClientApplication) then
            exit(OAuthAuthenticationResult.GetAuthorizationHeader());

        AcquireTokenByAuthorizationCode(OAuthClientApplication);
        exit(OAuthAuthenticationResult.GetAuthorizationHeader());
    end;

    local procedure AcquireTokenByAuthorizationCode(OAuthClientApplication: Codeunit "D4P OAuth Appl. Config")
    var
        OAuthClient: Interface "D4P OAuth Client";
        AuthorizationCode: Text;
        RedirectURIType: Enum "D4P Redirect URI Type";
        RedirectURI: Interface "D4P Redirect URI";
    begin
        if not OAuthClientApplication.GetScopes().Contains('offline_access') then
            OAuthClientApplication.AddScope('offline_access');

        RedirectURIType := OAuthClientApplication.GetRedirectUriType();
        if RedirectURIType = RedirectURIType::None then
            RedirectURIType := RedirectURIType::"Built-in";

        RedirectURI := RedirectURIType;
        AuthorizationCode := RedirectURI.GetAuthorizationCode(OAuthClientApplication, OAuthAuthority, PromptInteraction, GetPKCECodeChallenge());
        OAuthClient := OAuthClientType;
        OAuthAuthenticationResult := OAuthClient.AcquireTokenByAuthorizationCode(AuthorizationCode, PKCECodeVerifier, OAuthAuthority, OAuthClientApplication);
    end;

    [TryFunction]
    local procedure TryAcquireTokenByRefreshToken(OAuthClientApplication: Codeunit "D4P OAuth Appl. Config")
    var
        OAuthClient: Interface "D4P OAuth Client";
    begin
        if OAuthAuthenticationResult.RefreshToken().IsEmpty() then
            Error('');

        OAuthClient := OAuthClientType;
        OAuthAuthenticationResult := OAuthClient.AcquireTokenByRefreshToken(OAuthAuthenticationResult.RefreshToken(), OAuthAuthority, OAuthClientApplication);
    end;

    procedure GetPKCECodeChallenge() ReturnValue: Text
    var
        CryptographyMgt: Codeunit "Cryptography Management";
        HashAlgorithmType: Option MD5,SHA1,SHA256,SHA384,SHA512;
    begin
        // Verifier = BASE64URL(SHA256(two random GUIDs)).
        // Produces a 43-char string using the full Base64Url alphabet (A-Z / a-z / 0-9 / - / _),
        // all of which are RFC 7636 unreserved characters, with ~244 bits of input entropy.
        PKCECodeVerifier := CopyStr(
            CryptographyMgt.GenerateHashAsBase64String(
                Format(CreateGuid(), 0, 3) + Format(CreateGuid(), 0, 3),
                HashAlgorithmType::SHA256)
            .Replace('+', '-').Replace('/', '_').Replace('=', ''),
            1, MaxStrLen(PKCECodeVerifier));
        ReturnValue := CryptographyMgt.GenerateHashAsBase64String(PKCECodeVerifier, HashAlgorithmType::SHA256).Replace('+', '-').Replace('/', '_').Replace('=', '');
    end;
}