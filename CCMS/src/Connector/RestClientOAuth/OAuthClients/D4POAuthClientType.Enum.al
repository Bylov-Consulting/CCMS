namespace D4P.CCMS.Connector.RestClientOAuth;
enum 62011 "D4P OAuth Client Type" implements "D4P OAuth Client"
{
    Extensible = false;

    value(0; Confidential)
    {
        Caption = 'Confidential';
        Implementation = "D4P OAuth Client" = "D4P OAuth Confidential Client";
    }
    value(1; Public)
    {
        Caption = 'Public';
        Implementation = "D4P OAuth Client" = "D4P OAuth Public Client";
    }
}