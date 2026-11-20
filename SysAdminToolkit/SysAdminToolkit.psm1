# ==============================================================================
# Module : SysAdminToolkit
# Description : Fonctions d'audit systeme et d'automatisation resiliente
# ==============================================================================

function Get-DiskAlert {
    <#
    .SYNOPSIS
        Verifie l'espace disque disponible et evalue le niveau d'alerte de stockage.
    .PARAMETER DriveLetter
        Lettre du lecteur a auditer (sans deux-points). Valeur par defaut : "C".
    .PARAMETER WarningThresholdPercent
        Pourcentage minimal d'espace libre (entre 1 et 99). Valeur par defaut : 15.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$DriveLetter = "C",

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 99)]
        [int]$WarningThresholdPercent = 15
    )

    process {
        $Disk = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DeviceID = '$($DriveLetter):'"

        if ($Disk) {
            $TotalGB     = [math]::Round($Disk.Size / 1GB, 1)
            $FreeGB      = [math]::Round($Disk.FreeSpace / 1GB, 1)
            $FreePercent = [math]::Round((($Disk.FreeSpace / $Disk.Size) * 100), 1)

            [PSCustomObject]@{
                Lecteur       = "$($DriveLetter):"
                TailleTotale  = "$TotalGB Go"
                EspaceLibre   = "$FreeGB Go"
                PourcentLibre = "$FreePercent %"
                Statut        = if ($FreePercent -lt $WarningThresholdPercent) { "CRITIQUE" } else { "OK" }
            }
        }
        else {
            Write-Warning "Le lecteur '$($DriveLetter):' est introuvable sur cette machine."
        }
    }
}

function Clear-StaleTempFile {
    <#
    .SYNOPSIS
        Nettoie les fichiers temporaires expires dans un repertoire cible de maniere resiliente.
    .PARAMETER FolderPath
        Chemin complet du repertoire a nettoyer.
    .PARAMETER DaysOld
        Age minimal des fichiers en jours (1 a 365). Valeur par defaut : 7.
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

    process {
        try {
            $TargetFolder = Get-Item -Path $FolderPath -ErrorAction Stop
            $LimitDate = (Get-Date).AddDays(-$DaysOld)

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
}

# Chargement dynamique des fonctions Cloud / Microsoft 365
$CloudScripts = @(
    "$PSScriptRoot\..\Cloud-M365\Get-EntraUserAudit.ps1",
    "$PSScriptRoot\..\Cloud-M365\Get-EntraLicenseAudit.ps1",
    "$PSScriptRoot\..\Cloud-M365\Get-EntraAdminAudit.ps1"
)

foreach ($Script in $CloudScripts) {
    if (Test-Path -Path $Script) {
        . $Script
    }
    else {
        Write-Warning "Script Cloud-M365 introuvable : $Script"
    }
}

# Exposition explicite des commandes publiques du module
Export-ModuleMember -Function Get-DiskAlert, Clear-StaleTempFile, Get-EntraUserAudit, Get-EntraLicenseAudit, Get-EntraAdminAudit