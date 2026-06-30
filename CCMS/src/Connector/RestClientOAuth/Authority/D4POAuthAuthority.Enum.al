namespace D4P.CCMS.Connector.RestClientOAuth;
enum 62008 "D4P OAuth Authority" implements "D4P OAuth Authority"
{
    Extensible = true;

    value(1; MicrosoftEntraID)
    {
        Caption = 'Microsoft Entra ID';
        Implementation = "D4P OAuth Authority" = "D4P Microsoft Entra ID";
    }
}