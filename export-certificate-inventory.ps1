<#
.SYNOPSIS
  Read-only certificate inventory for the Cloudek Hosting certificate inventory analyzer.

.DESCRIPTION
  Lists certificates in the local machine Personal store and writes a CSV with the exact columns the
  analyzer expects. It reads metadata only (label, subject, issuer, expiry date). It never exports,
  reads or writes a private key, and it changes nothing. Run it on each server you want to include.
  Expired certificates are skipped unless -IncludeExpired is set.
  Platform and purpose apply to every row, so edit the CSV afterwards where a certificate differs.
  Self-signed is set when subject and issuer match; everything else is marked externally-issued.

.PARAMETER Platform
  One of: 'IIS 8.5 or later','IIS earlier or unknown','Exchange','RDS','AD FS','Azure Application Gateway','Other load balancer','Appliance'.
.PARAMETER Purpose
  One of: 'Website TLS','Exchange service','RDS deployment','AD FS token-signing','AD FS token-decryption',
  'AD FS service-communication TLS','Azure Application Gateway listener TLS','Other'.
.PARAMETER OutputPath
  CSV path. Defaults to .\certificates.csv. An existing file is not overwritten.
#>
[CmdletBinding()]
param(
  [ValidateSet('IIS 8.5 or later', 'IIS earlier or unknown', 'Exchange', 'RDS', 'AD FS', 'Azure Application Gateway', 'Other load balancer', 'Appliance')]
  [string]$Platform = 'IIS earlier or unknown',
  [ValidateSet('Website TLS', 'Exchange service', 'RDS deployment', 'AD FS token-signing', 'AD FS token-decryption', 'AD FS service-communication TLS', 'Azure Application Gateway listener TLS', 'Other')]
  [string]$Purpose = 'Website TLS',
  [int]$RenewalLeadDays = 30,
  [switch]$IncludeExpired,
  [string]$OutputPath = '.\certificates.csv'
)

function ConvertTo-CertificateRow {
  param($Certificate, [string]$Platform, [string]$Purpose, [int]$RenewalLeadDays)
  $subject = [string]$Certificate.Subject
  $issuer = [string]$Certificate.Issuer
  $label = if ($Certificate.FriendlyName) { [string]$Certificate.FriendlyName } else { $subject }
  if ($label.Length -gt 100) { $label = $label.Substring(0, 100) }
  [pscustomobject][ordered]@{
    certificateLabel        = $label
    platform                = $Platform
    certificatePurpose      = $Purpose
    subject                 = $subject
    issuer                  = $issuer
    notAfter                = $Certificate.NotAfter.ToUniversalTime().ToString('yyyy-MM-dd')
    renewalLeadDays         = $RenewalLeadDays
    certificateOrigin       = if ($subject -eq $issuer) { 'self-signed' } else { 'externally-issued' }
    autoCertificateRollover = 'unknown'
    applicationGatewaySku   = 'unknown'
    keyVaultReference       = 'unknown'
  }
}

if ($MyInvocation.InvocationName -ne '.') {
  $ErrorActionPreference = 'Stop'
  if (Test-Path -LiteralPath $OutputPath) { throw "Refusing to overwrite existing file: $OutputPath" }
  $now = [datetime]::UtcNow
  $rows = Get-ChildItem -Path Cert:\LocalMachine\My |
    Where-Object { $IncludeExpired -or $_.NotAfter.ToUniversalTime() -gt $now } |
    ForEach-Object { ConvertTo-CertificateRow -Certificate $_ -Platform $Platform -Purpose $Purpose -RenewalLeadDays $RenewalLeadDays }
  if (-not $rows) { throw 'No certificates found in LocalMachine\My (after the expiry filter).' }
  $rows | Export-Csv -LiteralPath $OutputPath -NoTypeInformation -Encoding UTF8
  Write-Host "Wrote $(@($rows).Count) rows to $OutputPath. Load it into the certificate inventory analyzer."
}
