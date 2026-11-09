<#
.SYNOPSIS
    Verifie l'espace disque disponible et evalue le niveau d'alerte de stockage.

.DESCRIPTION
    Interroge l'instance CIM Win32_LogicalDisk pour calculer l'espace total, l'espace
    libre en gigaoctets (Go) et le pourcentage d'espace disponible.
    Retourne un objet personnalise avec un indicateur de statut (OK ou CRITIQUE).

.PARAMETER DriveLetter
    Lettre du lecteur a auditer (sans deux-points ni antislash). Valeur par defaut : "C".

.PARAMETER WarningThresholdPercent
    Pourcentage minimal d'espace libre en dessous duquel le statut bascule en CRITIQUE. 
    Valeur par defaut : 15.

.OUTPUTS
    [PSCustomObject]
    Contient les proprietes Lecteur, TailleTotale, EspaceLibre, PourcentLibre, Statut.

.EXAMPLE
    .\System-Audits\Get-DiskAlert.ps1 -DriveLetter "C"
    Analyse le disque C: avec le seuil par defaut de 15%.

.EXAMPLE
    .\System-Audits\Get-DiskAlert.ps1 -DriveLetter "D" -WarningThresholdPercent 20 | Format-Table
    Analyse le disque D: avec un seuil de 20% et formate la sortie sous forme de tableau.
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$DriveLetter = "C",

    [Parameter(Mandatory = $false)]
    [int]$WarningThresholdPercent = 15
)

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
