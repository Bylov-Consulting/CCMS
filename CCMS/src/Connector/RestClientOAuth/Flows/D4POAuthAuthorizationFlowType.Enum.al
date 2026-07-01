namespace D4P.CCMS.Connector.RestClientOAuth;
enum 62010 "D4P OAuthAuthorizationFlowType" implements "D4P OAuth Authorization Flow"
{
    value(0; AuthorizationCode)
    {
        Caption = 'Authorization Code';
        Implementation = "D4P OAuth Authorization Flow" = "D4P Auth. Code Grant Flow";
    }
    value(1; ClientCredentials)
    {
        Caption = 'Client Credentials';
        Implementation = "D4P OAuth Authorization Flow" = "D4P Client Credentials Flow";
    }
    value(2; DeviceCode)
    {
        Caption = 'Device Code';
        Implementation = "D4P OAuth Authorization Flow" = "D4P Device Code Flow";
    }
}