namespace D4P.CCMS.Connector.RestClientOAuth;
codeunit 62011 "D4P Microsoft Entra ID" implements "D4P OAuth Authority"
{
    var
        MicrosoftEntraIDImpl: Codeunit "D4P Microsoft Entra ID Impl.";

    procedure Initialize(OAuthApplicationCode: Code[20]; TargetTenantId: Text)
    begin
        MicrosoftEntraIDImpl.Initialize(OAuthApplicationCode, TargetTenantId);
    end;

    procedure GetApplicationConfig(OAuthApplicationCode: Code[20]; ScopesList: List of [Text]) OAuthApplicationConfig: Codeunit "D4P OAuth Appl. Config"
    begin
        OAuthApplicationConfig := MicrosoftEntraIDImpl.GetApplicationConfig(OAuthApplicationCode, ScopesList);
    end;

    procedure GetAuthorizationEndpoint(OAuthClientApplication: Codeunit "D4P OAuth Appl. Config"): Text;
    begin
        exit(MicrosoftEntraIDImpl.GetAuthorizationEndpoint(OAuthClientApplication));
    end;

    procedure GetDeviceAuthorizationEndpoint(): Text;
    begin
        exit(MicrosoftEntraIDImpl.GetDeviceAuthorizationEndpoint());
    end;

    procedure GetTokenEndpoint(): Text;
    begin
        exit(MicrosoftEntraIDImpl.GetTokenEndpoint());
    end;

    procedure SetTenantID(Value: Text)
    begin
        MicrosoftEntraIDImpl.SetTenantId(Value);
    end;
}