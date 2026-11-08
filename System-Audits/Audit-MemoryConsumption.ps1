<#
.SYNOPSIS
    Audite la consommation mémoire des processus et génère un rapport CSV d'incident.

.DESCRIPTION
    Script d'audit système qui filtre les processus dépassant un seuil de mémoire vive,
    calcule la RAM consommée en Mo arrondis, exporte un fichier CSV de conformité
    et déclenche une alerte formatée dans la console.

.PARAMETER ThresholdMB
    Seuil mémoire déclenchant l'alerte (défaut : 80MB).

.EXAMPLE
    .\Audit-MemoryConsumption.ps1
#>

$Threshold = 80MB
$ReportFile = ".\audit-critique.csv"

Write-Host "Collecte des processus actifs en cours..." -ForegroundColor Cyan

$CriticalProcesses = Get-Process | 
    Where-Object WS -gt $Threshold | 
    Sort-Object WS -Descending | 
    Select-Object -First 5 Name, Id, @{n='RAM_Mo'; e={[math]::Round($_.WS / 1MB, 1)}}

# Export de conformité CSV
$CriticalProcesses | Export-Csv -Path $ReportFile -Delimiter ';' -NoTypeInformation -Encoding utf8

# Affichage des alertes opérateurs
$CriticalProcesses | ForEach-Object {
    Write-Host "[CRITIQUE] $($_.Name) (PID: $($_.Id)) utilise $($_.RAM_Mo) Mo de mémoire" -ForegroundColor Red
}

Write-Host "Audit terminé. Rapport exporté dans $ReportFile" -ForegroundColor Green
