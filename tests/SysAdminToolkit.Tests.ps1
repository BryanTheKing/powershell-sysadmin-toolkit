$ModuleManifestPath = "$PSScriptRoot\..\SysAdminToolkit\SysAdminToolkit.psd1"

Remove-Item Function:\Get-DiskAlert -ErrorAction SilentlyContinue
Remove-Item Function:\Clear-StaleTempFile -ErrorAction SilentlyContinue
Remove-Item Function:\Get-EntraAdminAudit -ErrorAction SilentlyContinue

Import-Module $ModuleManifestPath -Force

Describe "Validation du module SysAdminToolkit" {

    It "Possede un manifeste valide (.psd1)" {
        { Test-ModuleManifest -Path $ModuleManifestPath -ErrorAction Stop } | Should Not Throw
    }

    It "Exporte exactement les fonctions attendues" {
        $Commandes = (Get-Command -Module SysAdminToolkit).Name
        $Commandes -contains "Get-DiskAlert" | Should Be $true
        $Commandes -contains "Clear-StaleTempFile" | Should Be $true
        $Commandes -contains "Get-EntraUserAudit" | Should Be $true
        $Commandes -contains "Get-EntraLicenseAudit" | Should Be $true
        $Commandes -contains "Get-EntraAdminAudit" | Should Be $true
    }

    It "Retourne un objet valide pour le lecteur C:" {
        $Resultat = Get-DiskAlert -DriveLetter "C"
        $Resultat.Lecteur | Should Be "C:"
        $Resultat.Statut -in @("OK", "CRITIQUE") | Should Be $true
    }

    It "Bloque un seuil hors plage (> 99%) via ValidateRange" {
        $ExceptionLevee = $false
        try {
            Get-DiskAlert -DriveLetter "C" -WarningThresholdPercent 150 -ErrorAction Stop
        }
        catch {
            $ExceptionLevee = $true
        }
        $ExceptionLevee | Should Be $true
    }
}

Describe "Tests unitaires Cloud-M365 (Mocks Graph)" {

    InModuleScope SysAdminToolkit {

        It "Leve une erreur explicite si aucune session Graph n'est active" {
            Mock Get-MgContext { return $null }

            $ExceptionLevee = $false
            try {
                Get-EntraAdminAudit -ErrorAction Stop
            }
            catch {
                $ExceptionLevee = $true
            }
            $ExceptionLevee | Should Be $true
        }

        It "Classe un Global Administrator comme CRITIQUE (Tier 0)" {
            Mock Get-MgContext { return [PSCustomObject]@{ TenantId = "00000000-0000-0000-0000-000000000000" } }
            Mock Get-MgDirectoryRole {
                return @(
                    [PSCustomObject]@{ Id = "role-1"; DisplayName = "Global Administrator" }
                )
            }
            Mock Get-MgDirectoryRoleMember {
                return @(
                    [PSCustomObject]@{
                        Id = "user-1"
                        AdditionalProperties = @{
                            '@odata.type'     = '#microsoft.graph.user'
                            displayName       = 'Admin Test'
                            userPrincipalName = 'admin@contoso.com'
                            accountEnabled    = $true
                        }
                    }
                )
            }

            $Audit = Get-EntraAdminAudit
            $Audit.RoleName | Should Be "Global Administrator"
            $Audit.RiskLevel | Should Be "CRITIQUE (Tier 0)"
            $Audit.UserPrincipalName | Should Be "admin@contoso.com"
        }
    }
}