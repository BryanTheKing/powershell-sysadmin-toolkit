<#
.SYNOPSIS
    Audite les roles d'administrateurs privilegies dans Microsoft Entra ID.

.DESCRIPTION
    Recupere tous les roles d'annuaire actives sur le tenant via Microsoft Graph,
    identifie leurs membres (utilisateurs, principaux de service, groupes) et evalue
    le niveau de criticite selon le principe du moindre privilege (RBAC).

.PARAMETER CriticalOnly
    Filtre uniquement les roles a criticite maximale (ex. Global Administrator, Privileged Role Administrator).

.PARAMETER ExportPath
    Chemin optionnel vers un fichier CSV pour exporter le rapport d'audit (encodage UTF-8).

.EXAMPLE
    Get-EntraAdminAudit | Format-Table -AutoSize

.EXAMPLE
    Get-EntraAdminAudit -CriticalOnly -ExportPath "C:\Reports\Entra-Admins-Critiques.csv"
#>
function Get-EntraAdminAudit {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [switch]$CriticalOnly,

        [Parameter(Mandatory = $false)]
        [string]$ExportPath
    )

    begin {
        # Verification de la connexion active a Microsoft Graph
        $context = Get-MgContext
        if (-not $context) {
            throw "Aucune session Microsoft Graph active. Executez d'abord : Connect-MgGraph -Scopes 'RoleManagement.Read.Directory', 'User.Read.All'"
        }

        # Liste des roles Entra ID consideres comme critiques (Tier 0)
        $criticalRoles = @(
            'Global Administrator',
            'Privileged Role Administrator',
            'Privileged Authentication Administrator',
            'Security Administrator',
            'Conditional Access Administrator',
            'Exchange Administrator',
            'SharePoint Administrator',
            'User Administrator'
        )
    }

    process {
        try {
            Write-Verbose "Recuperation des roles d'annuaire actives..."
            $activeRoles = Get-MgDirectoryRole -All

            $auditResults = foreach ($role in $activeRoles) {
                $isCritical = $criticalRoles -contains $role.DisplayName
                $riskLevel  = if ($role.DisplayName -eq 'Global Administrator') {
                    'CRITIQUE (Tier 0)'
                } elseif ($isCritical) {
                    'ELEVE'
                } else {
                    'MODERE'
                }

                if ($CriticalOnly -and -not $isCritical) {
                    continue
                }

                $members = Get-MgDirectoryRoleMember -DirectoryRoleId $role.Id -All

                foreach ($member in $members) {
                    $objectType = $member.AdditionalProperties['@odata.type'] -replace '#microsoft\.graph\.', ''
                    $displayName = $member.AdditionalProperties['displayName']
                    $upn = $member.AdditionalProperties['userPrincipalName']
                    $accountEnabled = $member.AdditionalProperties['accountEnabled']

                    # Si le membre est un utilisateur et que accountEnabled est absent des AdditionalProperties, on interroge Get-MgUser
                    if ($objectType -eq 'user' -and $null -eq $accountEnabled) {
                        $userDetail = Get-MgUser -UserId $member.Id -Property DisplayName, UserPrincipalName, AccountEnabled -ErrorAction SilentlyContinue
                        if ($userDetail) {
                            $displayName    = $userDetail.DisplayName
                            $upn            = $userDetail.UserPrincipalName
                            $accountEnabled = $userDetail.AccountEnabled
                        }
                    }

                    [PSCustomObject]@{
                        RoleName          = $role.DisplayName
                        RiskLevel         = $riskLevel
                        MemberType        = $objectType
                        DisplayName       = $displayName
                        UserPrincipalName = if ($upn) { $upn } else { 'N/A (ServicePrincipal/Group)' }
                        AccountEnabled    = if ($null -ne $accountEnabled) { $accountEnabled } else { 'N/A' }
                        MemberId          = $member.Id
                    }
                }
            }

            if ($ExportPath) {
                $parentDir = Split-Path -Path $ExportPath -Parent
                if ($parentDir -and -not (Test-Path -Path $parentDir)) {
                    New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
                }
                $auditResults | Export-Csv -Path $ExportPath -NoTypeInformation -Encoding UTF8 -Delimiter ';'
                Write-Verbose "Rapport exporte avec succes vers : $ExportPath"
            }

            return $auditResults
        }
        catch {
            Write-Error "Erreur lors de l'audit des roles privilegies Entra ID : $_"
        }
    }
}