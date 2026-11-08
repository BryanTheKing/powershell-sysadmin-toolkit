# PowerShell SysAdmin Toolkit

Outils et scripts d'automatisation PowerShell concus pour l'administration systeme Windows, la supervision et la gouvernance d'environnements Microsoft 365 / Cloud.

---

## Architecture du depot

powershell-sysadmin-toolkit/
├── System-Audits/          # Scripts d'audit de conformite, resilience et metriques locales
├── Cloud-M365/             # Scripts de gestion Entra ID, licences et securite M365 (a venir)
├── Automation-Utils/       # Modules et fonctions d'automatisation reutilisables
├── .gitignore              # Exclusion des artefacts d'execution (CSV, JSON, logs)
└── README.md               # Documentation globale du depot

---

## Modules et scripts disponibles

### 1. System Audits (System-Audits/)

| Script | Description | Format de sortie |
| :--- | :--- | :--- |
| Audit-MemoryConsumption.ps1 | Analyse les processus depassant un seuil memoire, genere un rapport CSV conforme et notifie la console. | CSV (delimiteur ;) + Console |

---

## Prerequis et execution

* Environnement requis : Windows PowerShell 5.1 ou PowerShell 7+
* Politique d'execution : RemoteSigned

### Exemple d'execution

.\System-Audits\Audit-MemoryConsumption.ps1

---

## Bonnes pratiques appliquees

* Documentation integree : Commentaires d'aide conformes aux standards Microsoft (.SYNOPSIS, .DESCRIPTION, .EXAMPLE).
* Traitement en pipeline : Optimisation des requetes avec filtrage amont (Where-Object) et projection precise (Select-Object).
* Hygiene Git : Segregation stricte du code source et des rapports d'audit via .gitignore.
