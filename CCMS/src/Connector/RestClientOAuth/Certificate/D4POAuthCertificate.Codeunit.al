namespace D4P.CCMS.Connector.RestClientOAuth;
codeunit 62013 "D4P OAuth Certificate"
{
    var
        OAuthCertificateImpl: Codeunit "D4P OAuth Certificate Impl.";

    procedure SetCertificate(Value: Text)
    begin
        OAuthCertificateImpl.SetCertificate(Value);
    end;

    procedure GetCertificate() ReturnValue: Text
    begin
        ReturnValue := OAuthCertificateImpl.GetCertificate();
    end;

    procedure SetPrivateKey(Value: SecretText)
    begin
        OAuthCertificateImpl.SetPrivateKey(Value);
    end;

    procedure GetPrivateKey() ReturnValue: SecretText
    begin
        ReturnValue := OAuthCertificateImpl.GetPrivateKey();
    end;

    procedure HasValue(): Boolean
    begin
        exit(OAuthCertificateImpl.HasValue());
    end;

    procedure ThumbprintBase64() ReturnValue: Text
    begin
        ReturnValue := OAuthCertificateImpl.ThumbprintBase64();
    end;
}