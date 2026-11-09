# Builds throwaway in-memory certificates and writes the CSV the exporter would produce, for the analyzer parser to read.
param([Parameter(Mandatory)][string]$OutPath)
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot/../export-certificate-inventory.ps1"
function New-TestCert($subject, $days) {
  $rsa = [System.Security.Cryptography.RSA]::Create(2048)
  $req = [System.Security.Cryptography.X509Certificates.CertificateRequest]::new($subject, $rsa, [System.Security.Cryptography.HashAlgorithmName]::SHA256, [System.Security.Cryptography.RSASignaturePadding]::Pkcs1)
  $req.CreateSelfSigned([datetimeoffset]::UtcNow.AddDays(-1), [datetimeoffset]::UtcNow.AddDays($days))
}
$rows = @(
  ConvertTo-CertificateRow -Certificate (New-TestCert 'CN=site.example.invalid' 90) -Platform 'IIS 8.5 or later' -Purpose 'Website TLS' -RenewalLeadDays 30
  ConvertTo-CertificateRow -Certificate (New-TestCert 'CN=mail.example.invalid' 200) -Platform 'Exchange' -Purpose 'Exchange service' -RenewalLeadDays 45
)
$rows | Export-Csv -LiteralPath $OutPath -NoTypeInformation -Encoding UTF8
