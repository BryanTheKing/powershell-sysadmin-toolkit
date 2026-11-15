$ModuleManifestPath = "$PSScriptRoot\..\SysAdminToolkit\SysAdminToolkit.psd1"

Describe "Validation du module SysAdminToolkit" {

    It "Possede un manifeste valide (.psd1)" {
        { Test-ModuleManifest -Path $ModuleManifestPath -ErrorAction Stop } | Should Not Throw
    }

    It "Exporte exactement les fonctions attendues" {
        Import-Module $ModuleManifestPath -Force
        $Commandes = (Get-Command -Module SysAdminToolkit).Name
        $Commandes -contains "Get-DiskAlert" | Should Be $true
        $Commandes -contains "Clear-StaleTempFile" | Should Be $true
    }

    It "Retourne un objet valide pour le lecteur C:" {
        $Resultat = Get-DiskAlert -DriveLetter "C"
        $Resultat.Lecteur | Should Be "C:"
        $Resultat.Statut -in @("OK", "CRITIQUE") | Should Be $true
    }

    It "Bloque un seuil hors plage (> 99%) via ValidateRange" {
        { Get-DiskAlert -DriveLetter "C" -WarningThresholdPercent 150 } | Should Throw
    }
}