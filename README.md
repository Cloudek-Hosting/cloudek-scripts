# Cloudek Hosting free admin scripts

Read-only PowerShell exporters that pair with the free browser tools at [cloudekhosting.com/tools](https://www.cloudekhosting.com/tools.html). Run the script, load the CSV into the matching tool. The tools run in your browser and do not upload the file.

## Scripts

| Script | What it reads | Pairs with |
|---|---|---|
| `export-m365-licence-inventory.ps1` | User, enabled state, latest successful sign-in, assigned licence SKUs. Microsoft Graph, delegated scopes `User.Read.All`, `AuditLog.Read.All`, `LicenseAssignment.Read.All` only. | [Licence waste analyzer](https://www.cloudekhosting.com/tools/licence-waste-analyzer.html) |
| `export-windows-server-inventory.ps1` | OS name and version, core count, installed server roles. Run once per server. Local only. | [Server inventory analyzer](https://www.cloudekhosting.com/server-inventory-analyzer.html) and the [Windows Server 2016 migration plan](https://www.cloudekhosting.com/windows-server-2016-migration-plan.html) |
| `export-certificate-inventory.ps1` | Certificate label, subject, issuer and expiry date from the local machine Personal store. Metadata only; never touches private keys. | [Certificate inventory analyzer](https://www.cloudekhosting.com/certificate-inventory-analyzer.html) |

## What these scripts never do
- They do not change anything. No licence is assigned or removed, no server setting is changed.
- They do not read mail, files, group membership or credentials.
- They do not send data anywhere. Output is a CSV on your own machine. (The Microsoft 365 exporter signs in to Microsoft Graph to read; nothing is sent to Cloudek Hosting.)

The M365 CSV contains personal data (user principal names and sign-in times). Protect it and delete it when you are finished.

## Requirements
- M365 exporter: PowerShell 7 or Windows PowerShell 5.1, and the `Microsoft.Graph.Users` and `Microsoft.Graph.Identity.DirectoryManagement` modules. Sign-in activity needs Entra ID P1 or P2 and can take up to 24 hours to update.
- Server exporter: Windows Server with the ServerManager module (`Get-WindowsFeature`).

## Use
```powershell
# Microsoft 365 licences
.\export-m365-licence-inventory.ps1 -OutputPath .\m365-licences.csv

# Certificates, run on each server
.\export-certificate-inventory.ps1 -Platform 'IIS 8.5 or later' -Purpose 'Website TLS'

# Windows Server, run on each server
.\export-windows-server-inventory.ps1 | Out-File .\server.csv -Encoding utf8
```

Read each script before you run it. They are short on purpose.

## More free tools
Subnet, DNS and email checks, licensing calculators and more: [cloudekhosting.com/tools](https://www.cloudekhosting.com/tools.html).

## Feedback
Found a mistake or want a script added? Open an issue.

## Licence
MIT. See [LICENSE](LICENSE).

## Status
The scripts parse cleanly but have not been run against a live tenant or server yet. Read them and test on a non-production tenant first.
