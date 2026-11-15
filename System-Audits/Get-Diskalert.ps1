<#
.SYNOPSIS
    Verifie l'espace disque disponible et evalue le niveau d'alerte de stockage.

.DESCRIPTION
    Interroge l'instance CIM Win32_LogicalDisk pour calculer l'espace total, l'espace
    libre en gigaoctets (Go) et le pourcentage d'espace disponible.
    Prend en charge le traitement par pipeline (par valeur brute et par nom de propriete)
    et retourne un objet personnalise avec un indicateur de statut (OK ou CRITIQUE).

.PARAMETER DriveLetter
    Lettre du lecteur a auditer (sans deux-points ni antislash). Accepte l'entree via le pipeline.
    Valeur par defaut : "C".

.PARAMETER WarningThresholdPercent
    Pourcentage minimal d'espace libre (entre 1 et 99) en dessous duquel le statut bascule en CRITIQUE.
    Valeur par defaut : 15.

.OUTPUTS
    [PSCustomObject]
    Contient les proprietes Lecteur, TailleTotale, EspaceLibre, PourcentLibre, Statut.

.EXAMPLE
    .\System-Audits\Get-DiskAlert.ps1 -DriveLetter "C"
    Analyse le disque C: avec le seuil par defaut de 15%.

.EXAMPLE
    "C", "D" | .\System-Audits\Get-DiskAlert.ps1 -WarningThresholdPercent 20 | Format-Table
    Analyse les disques C: et D: via le pipeline avec un seuil de 20% et formate la sortie.
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

begin {
    Write-Verbose "Initialisation de l'audit de capacite disque..."
}

process {
    Write-Verbose "Verification du volume logique : $($DriveLetter):"
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

end {
    Write-Verbose "Audit de stockage termine."
}