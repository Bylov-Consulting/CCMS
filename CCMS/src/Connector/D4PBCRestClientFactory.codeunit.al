namespace D4P.CCMS.Connector;

using D4P.CCMS.Connector;
using D4P.CCMS.Connector.RestClientOAuth;
using D4P.CCMS.Setup;
using D4P.CCMS.Tenant;
using System.RestClient;
using System.Security.Authentication;

codeunit 62034 D4PBCRestClientFactory
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure CreateRestClientForAdminAPI(BCTenant: Record "D4P BC Tenant") RestClient: Codeunit "Rest Client"
    var
        BCSetup: Record "D4P BC Setup";
        HttpClientHandler: Codeunit "D4P Http Client Handler";
    begin
        BCSetup := BCSetup.GetSetup();
        RestClient := GetRestClient(BCTenant, BCSetup."Debug Mode");
        RestClient.SetBaseAddress(BCSetup.GetAdminAPIBaseUrl());
        exit(RestClient);
    end;

    procedure CreateRestClientForAutomationAPI(BCTenant: Record "D4P BC Tenant"; EnvironmentName: Text) RestClient: Codeunit "Rest Client"
    var
        BCSetup: Record "D4P BC Setup";
        HttpClientHandler: Codeunit "D4P Http Client Handler";
    begin
        BCSetup := BCSetup.GetSetup();
        RestClient := GetRestClient(BCTenant, BCSetup."Debug Mode");
        RestClient.SetBaseAddress(BCSetup.GetAutomationAPIBaseUrl() + '/' + EnvironmentName);
        exit(RestClient);
    end;

    local procedure GetRestClient(BCTenant: Record "D4P BC Tenant"; DebugMode: Boolean) RestClient: Codeunit "Rest Client"
    var
        HttpClientHandler: Codeunit "D4P Http Client Handler";
    begin
        HttpClientHandler.SetDebugMode(DebugMode);
        RestClient := RestClient.Create(HttpClientHandler, GetOAuthCredentials(BCTenant));
    end;

    local procedure GetOAuthCredentials(BCTenant: Record "D4P BC Tenant") HttpAuthentication: Interface "Http Authentication"
    var
        OAuthAuthority: Interface "D4P OAuth Authority";
    begin
        OAuthAuthority := CreateOAuthAuthority(BCTenant."Tenant ID");
        HttpAuthentication := CreateHttpAuthentication(BCTenant.GetOAuthClientApplication(), CreateClientCredentialsFlow(OAuthAuthority));
    end;

    local procedure CreateOAuthAuthority(TenantID: Guid) OAuthAuthority: Interface "D4P OAuth Authority"
    var
        MicrosoftEntraID: Codeunit "D4P Microsoft Entra ID";
    begin
        MicrosoftEntraID.SetTenantID(Format(TenantID, 0, 4).ToLower());
        OAuthAuthority := MicrosoftEntraID;
    end;

    local procedure CreateClientCredentialsFlow(OAuthAuthority: Interface "D4P OAuth Authority") OAuthAuthorizationFlow: Interface "D4P OAuth Authorization Flow"
    var
        ClientCredentialsFlow: Codeunit "D4P Client Credentials Flow";
    begin
        ClientCredentialsFlow.SetAuthority(OAuthAuthority);
        OAuthAuthorizationFlow := ClientCredentialsFlow;
    end;

    local procedure CreateHttpAuthentication(OAuthClientApplication: Codeunit "D4P OAuth Appl. Config"; OAuthAuthorizationFlow: Interface "D4P OAuth Authorization Flow") HttpAuthentication: Interface "Http Authentication"
    var
        HttpAuthenticationOAuth2: Codeunit "D4P Http Auth. OAuth2";
    begin
        HttpAuthenticationOAuth2.Initialize(OAuthClientApplication, OAuthAuthorizationFlow);
        HttpAuthentication := HttpAuthenticationOAuth2;
    end;
}