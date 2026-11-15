<#
.SYNOPSIS
    Nettoie les fichiers temporaires expires dans un repertoire cible de maniere resiliente.

.DESCRIPTION
    Analyse un dossier donne pour identifier les fichiers dont la date de derniere modification
    depasse un seuil en jours (DaysOld). Integre une gestion d'erreurs a deux niveaux
    (acces au repertoire et fichiers verrouilles) ainsi que le support natif des modes de
    simulation (-WhatIf) et de confirmation (-Confirm).

.PARAMETER FolderPath
    Chemin complet du repertoire a nettoyer. Accepte l'entree via le pipeline.

.PARAMETER DaysOld
    Age minimal des fichiers en jours (entre 1 et 365) avant suppression. Valeur par defaut : 7.

.OUTPUTS
    [System.String]
    Messages de suivi des operations effectuees ou des avertissements rencontres.

.EXAMPLE
    .\Automation-Utils\Clear-StaleTempFiles.ps1 -FolderPath $env:TEMP -DaysOld 30 -WhatIf
    Simule le nettoyage des fichiers de plus de 30 jours dans le dossier temporaire utilisateur.

.EXAMPLE
    "C:\Temp", "D:\Logs" | .\Automation-Utils\Clear-StaleTempFiles.ps1 -DaysOld 14
    Purge les fichiers de plus de 14 jours sur plusieurs repertoires via le pipeline.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$FolderPath,

    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 365)]
    [int]$DaysOld = 7
)

begin {
    Write-Verbose "Initialisation de la procedure de maintenance des fichiers temporaires..."
}

process {
    try {
        $TargetFolder = Get-Item -Path $FolderPath -ErrorAction Stop
        $LimitDate = (Get-Date).AddDays(-$DaysOld)

        Write-Verbose "Analyse du repertoire '$($TargetFolder.FullName)' (seuil : avant le $LimitDate)"
        $OldFiles = Get-ChildItem -Path $TargetFolder.FullName -File -ErrorAction Stop |
                    Where-Object { $_.LastWriteTime -lt $LimitDate }

        if (-not $OldFiles) {
            Write-Output "Aucun fichier de plus de $DaysOld jours dans '$FolderPath'."
            return
        }

        foreach ($File in $OldFiles) {
            if ($PSCmdlet.ShouldProcess($File.FullName, "Suppression du fichier expire")) {
                try {
                    Remove-Item -Path $File.FullName -Force -ErrorAction Stop
                    Write-Output "Supprime : $($File.Name)"
                }
                catch {
                    Write-Warning "Fichier verrouille ou acces refuse pour '$($File.Name)' : $($_.Exception.Message)"
                }
            }
        }
    }
    catch {
        Write-Warning "Impossible d'acceder au dossier '$FolderPath' : $($_.Exception.Message)"
    }
}

end {
    Write-Verbose "Procedure de maintenance terminee."
}