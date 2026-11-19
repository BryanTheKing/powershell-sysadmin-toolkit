# PowerShell SysAdmin Toolkit

Outils et scripts d'automatisation PowerShell concus pour l'administration systeme Windows, la supervision et la gouvernance d'environnements Microsoft 365 / Cloud.

---

## Architecture du depot

```text
powershell-sysadmin-toolkit/
├── System-Audits/          # Scripts d'audit de conformite, resilience et metriques locales
├── Cloud-M365/             # Scripts de gestion Entra ID, licences et securite M365
├── Automation-Utils/       # Modules et fonctions d'automatisation reutilisables
├── SysAdminToolkit/        # Module PowerShell distributable (.psm1 / .psd1)
├── Tests/                  # Suite de tests automatises (PSScriptAnalyzer & Pester)
├── .gitignore              # Exclusion des artefacts d'execution (CSV, JSON, logs)
└── README.md               # Documentation globale du depot
```

---

## Modules et scripts disponibles

### 1. System Audits (`System-Audits/`)

| Script | Description | Format de sortie |
| :--- | :--- | :--- |
| `Audit-MemoryConsumption.ps1` | Analyse les processus depassant un seuil memoire, genere un rapport CSV et notifie la console. | CSV + Console |
| `Get-DiskAlert.ps1` | Verifie l'espace disque disponible via CIM/WMI et evalue le statut de capacite (OK/CRITIQUE). | `[PSCustomObject]` (Pipeline) |

### 2. Automation Utils (`Automation-Utils/`)

| Script | Description | Format de sortie |
| :--- | :--- | :--- |
| `Clear-StaleTempFiles.ps1` | Purge resiliente des fichiers expires (`try/catch`) avec support natif `-WhatIf` et `-Confirm`. | Flux Console / Pipeline |

### 3. Cloud & Microsoft 365 (`Cloud-M365/`)

| Script | Description | Format de sortie |
| :--- | :--- | :--- |
| `Get-EntraUserAudit.ps1` | Extraction des comptes Entra ID (`Microsoft.Graph.Users`) avec filtrage des comptes desactives (`-OnlyDisabled`), recherche par nom (`-NameFilter`) et export CSV compatible Excel (`-ExportPath`). | `[PSCustomObject]` / CSV |
| `Get-EntraLicenseAudit.ps1` | Audit des licences Microsoft 365 (`SkuId` vers `SkuPartNumber`), detection des licences attribuees aux comptes desactives (`-OnlyDisabledWithLicense`) et export CSV (`-ExportPath`). | `[PSCustomObject]` / CSV |

---

## Prerequis et execution

- **Environnement requis :** Windows PowerShell 5.1 ou PowerShell 7+
- **Politique d'execution :** `RemoteSigned`
- **Modules Cloud / M365 :** `Microsoft.Graph.Authentication`, `Microsoft.Graph.Users`, `Microsoft.Graph.Identity.DirectoryManagement` (Permissions : `User.Read.All`, `Organization.Read.All`)

### Exemples d'execution

```powershell
# Audit de memoire vive
.\System-Audits\Audit-MemoryConsumption.ps1

# Audit d'espace disque avec parametres personnalises
.\System-Audits\Get-DiskAlert.ps1 -DriveLetter "D" -WarningThresholdPercent 20 | Format-Table

# Connexion Entra ID et audit des utilisateurs desactives
Connect-MgGraph -Scopes "User.ReadWrite.All"
. .\Cloud-M365\Get-EntraUserAudit.ps1
Get-EntraUserAudit -OnlyDisabled -ExportPath "C:\Reports\Audits.csv"
```

---

## Module PowerShell (`SysAdminToolkit/`)

Le dossier `SysAdminToolkit/` regroupe les outils sous forme de module distributable (`SysAdminToolkit.psm1` et manifeste `SysAdminToolkit.psd1`).

### Importation et utilisation rapide

```powershell
# Importer le module dans la session courante
Import-Module ".\SysAdminToolkit\SysAdminToolkit.psd1" -Force

# Lister les commandes exposees
Get-Command -Module SysAdminToolkit

# Exemple d'execution directe
"C", "D" | Get-DiskAlert | Format-Table -AutoSize
```

---

## Tests Unitaires & Qualite (`Tests/`)

Le module est audite avec `PSScriptAnalyzer` et valide via `Pester` :

```powershell
# Lancer la suite de tests automatises
Invoke-Pester ".\Tests\SysAdminToolkit.Tests.ps1"
```