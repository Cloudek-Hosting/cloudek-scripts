<#
.SYNOPSIS
  Read-only Microsoft 365 licence inventory for the Cloudek Hosting Licence waste analyzer.

.DESCRIPTION
  Writes one CSV row per user per assigned licence (one blank-licence row for unlicensed users):
  UserPrincipalName, AccountEnabled, LastSuccessfulSignInDateTime, LicenseSkuId, LicenseSkuPartNumber.
  Reads only. It assigns, removes or changes nothing, and sends nothing anywhere.
  Microsoft Graph delegated scopes requested: User.Read.All, AuditLog.Read.All, LicenseAssignment.Read.All.
  Sign-in activity needs Entra ID P1 or P2 and can lag by up to 24 hours.
  The CSV contains personal data (user principal names, sign-in times). Protect it and delete it when done.

.PARAMETER OutputPath
  Where to write the CSV. Defaults to .\m365-licences.csv. An existing file is not overwritten.
#>
[CmdletBinding()]
param([string]$OutputPath = '.\m365-licences.csv')

$ErrorActionPreference = 'Stop'
if (Test-Path -LiteralPath $OutputPath) { throw "Refusing to overwrite existing file: $OutputPath" }

Connect-MgGraph -Scopes 'User.Read.All', 'AuditLog.Read.All', 'LicenseAssignment.Read.All' -NoWelcome | Out-Null

$skuNames = @{}
foreach ($sku in Get-MgSubscribedSku -All) { $skuNames[[string]$sku.SkuId] = $sku.SkuPartNumber }

$properties = 'id', 'userPrincipalName', 'accountEnabled', 'assignedLicenses', 'signInActivity'
$rows = foreach ($user in Get-MgUser -All -Property $properties) {
  $signIn = $user.SignInActivity.LastSuccessfulSignInDateTime
  $signInText = if ($signIn) { ([datetime]$signIn).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ') } else { '' }
  $base = [ordered]@{
    UserPrincipalName            = $user.UserPrincipalName
    AccountEnabled               = [string][bool]$user.AccountEnabled
    LastSuccessfulSignInDateTime = $signInText
  }
  if (-not $user.AssignedLicenses) {
    [pscustomobject]($base + @{ LicenseSkuId = ''; LicenseSkuPartNumber = '' })
    continue
  }
  foreach ($license in $user.AssignedLicenses) {
    $id = [string]$license.SkuId
    $name = $skuNames[$id]
    if (-not $name) { $name = 'UNKNOWN_SKU' }
    [pscustomobject]($base + @{ LicenseSkuId = $id; LicenseSkuPartNumber = $name })
  }
}

$rows | Select-Object UserPrincipalName, AccountEnabled, LastSuccessfulSignInDateTime, LicenseSkuId, LicenseSkuPartNumber |
  Export-Csv -LiteralPath $OutputPath -NoTypeInformation -Encoding UTF8
Disconnect-MgGraph | Out-Null
Write-Host "Wrote $(@($rows).Count) rows to $OutputPath. Load it into the Licence waste analyzer; it stays in your browser."
