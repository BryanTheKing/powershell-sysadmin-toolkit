function get-entraLicenseAudit{
    [CmdletBinding()]
        param(
            [switch]$OnlyDisabledWithLicense,
            [string]$ExportPath
        )
        try{
            if($null -eq (Get-MgContext)){
                throw "Aucune session Microsoft Graph active. Exécutez : Connect-MgGraph -Scopes 'User.Read.All', 'Organization.Read.All',"
            }
            $skuMap = @{}
            $subscribedSkus = Get-MgSubscribedSku
            foreach ($sku in $subscribedSkus) {
            $skuMap[$sku.SkuId.ToString()] = $sku.SkuPartNumber
        }
        $users = Get-MgUser -All -Property DisplayName, UserPrincipalName, AccountEnabled, AssignedLicenses
        $results = foreach ($user in $users) {
            $licenseCount = $user.AssignedLicenses.Count
            if ($OnlyDisabledWithLicense -and ($user.AccountEnabled -eq $true -or $licenseCount -eq 0)) {
                continue
            }
            $licenseNames = foreach ($lic in $user.AssignedLicenses) {
                $id = $lic.SkuId.ToString()
                if ($skuMap.ContainsKey($id)) {
                    $skuMap[$id]
                } else {
                    $id
                }
            }
            [PSCustomObject]@{
                DisplayName       = $user.DisplayName
                UserPrincipalName = $user.UserPrincipalName
                AccountEnabled    = $user.AccountEnabled
                LicenseCount      = $licenseCount
                Licenses          = if ($licenseNames) { $licenseNames -join ", " } else { "Aucune" }
            }
        }
        if ($ExportPath -and $results) {
            $results | Export-Csv -Path $ExportPath -NoTypeInformation -Encoding UTF8 -Delimiter ";"
        }
        return $results
        }catch{
            Write-Error "Erreur lors de l'audit des licences : $($_.Exception.Message)"
            return
        }
        

}