<#
.SYNOPSIS
  Read-only Windows Server inventory row for the Cloudek Hosting server inventory analyzer.
.DESCRIPTION
  Run once on each server. Prints one CSV row to the console (serverName, osCaption, osVersion,
  osBuild, reportedCores, roles). It reads system inventory only. It saves nothing, uploads nothing
  and changes nothing. Needs the ServerManager module (Get-WindowsFeature). Redirect to a file if wanted:
    .\export-windows-server-inventory.ps1 | Out-File .\server.csv -Encoding utf8
#>
# Read-only, local Windows Server inventory row. Run once on each server.
# Only Get-* cmdlets below read system inventory. ConvertTo-Csv serializes
# the result to the console; it does not save, upload, or change the server.
$os = Get-CimInstance -ClassName Win32_OperatingSystem -Property Caption, Version, BuildNumber
$computer = Get-CimInstance -ClassName Win32_ComputerSystem -Property Name
$processors = Get-CimInstance -ClassName Win32_Processor -Property NumberOfCores
$installedFeatures = Get-WindowsFeature

$roleMap = @{
  'AD-Domain-Services' = 'domain-controller'
  'FS-FileServer' = 'file-server'
  'Hyper-V' = 'hyperv-cluster'
  'ADFS-Federation' = 'adfs'
  'ADCS-Cert-Authority' = 'adcs'
  'NPAS' = 'nps'
  'DHCP' = 'dhcp'
  'DNS' = 'dns'
  'UpdateServices-Services' = 'wsus'
  'Print-Services' = 'print'
  'RDS-RD-Server' = 'rds'
  'RDS-Gateway' = 'rds'
  'RDS-Web-Access' = 'rds'
  'RDS-Licensing' = 'rds'
  'RDS-Connection-Broker' = 'rds'
}

$roles = [System.Collections.Generic.List[string]]::new()
foreach ($feature in $installedFeatures) {
  if ($feature.Installed -and $roleMap.ContainsKey($feature.Name)) {
    $mappedRole = $roleMap[$feature.Name]
    if (-not $roles.Contains($mappedRole)) { $roles.Add($mappedRole) }
  }
}
if ($roles.Count -eq 0) { $roles.Add('application') }
$totalCores = 0
foreach ($processor in $processors) { $totalCores += [int]$processor.NumberOfCores }

[pscustomobject]@{
  serverName    = $computer.Name
  osCaption     = $os.Caption
  osVersion     = $os.Version
  osBuild       = $os.BuildNumber
  reportedCores = $totalCores
  roles         = ($roles -join ';')
} | ConvertTo-Csv -NoTypeInformation
