<#
.SYNOPSIS
    Recupère les informations d'audit relatives aux utilisateurs d'Entra ID.
.DESCRIPTION
    Cette fonction récupère les informations d'audit pour les utilisateurs d'Entra ID, y compris leur nom d'affichage, leur nom principal d'utilisateur, l'etat du compte activé et la date de création. Elle peut filtrer uniquement les utilisateurs désactivés et exporter les résultats vers un fichier CSV.
.EXAMPLE
    Get-EntraUserAudit -OnlyDisabled
.EXAMPLE
    Get-EntraUserAudit -ExportPath "C:\Reports\Audits.csv"

#>
function Get-EntraUserAudit {
    param (
        [switch]$OnlyDisabled,
        [string]$ExportPath,
        [string]$NameFilter 

    )
    if (-not (get-mgContext)) {
        throw "vous n'êtes pas connecté à Microsoft Graph. Utilisez Connect-MgGraph pour vous connecter."
    }
    try {
    $users = Get-mguser -property "displayname, userprincipalname, accountenabled, createddatetime" -ErrorAction Stop | select-object displayname, userprincipalname, accountenabled, createddatetime 

    if($onlyDisabled) {
        $users = $users | Where-Object { $_.accountenabled -eq $false }
    }
    if($nameFilter) {
        $users = $users | where-object {$_.displayname -like "*$nameFilter*"}
    }
    <#
    Tous les filtres doivent s'éxecuter avant l'exportation du rapport.
    #>
    if($ExportPath) {
        $users | Export-Csv -Path $ExportPath -NoTypeInformation -Delimiter ";" -ErrorAction Stop
        write-output "rapport exporte vers $ExportPath" 
    }
    return $users
    }catch{
    write-error "$($_.Exception.Message)"
}

}