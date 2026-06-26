namespace D4P.CCMS.Connector.RestClientOAuth;
enum 62009 "D4P Redirect URI Type" implements "D4P Redirect URI"
{
    Extensible = true;
    DefaultImplementation = "D4P Redirect URI" = "D4P Redirect URI None";

    value(0; None)
    {
        Implementation = "D4P Redirect URI" = "D4P Redirect URI None";
    }
    value(1; "Built-in")
    {
        Implementation = "D4P Redirect URI" = "D4P Redirect URI Built-in";
    }
}