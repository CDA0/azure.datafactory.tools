[CmdletBinding()]
Param(
    [Parameter(Mandatory)][string] $DataFactoryCodePath,
    [Parameter(Mandatory)][string] $ResourceGroupName,
    [Parameter(Mandatory)][string] $DataFactoryName,
    [Parameter(Mandatory)][string] $Location,
    [Parameter()][bool] $CreateNewInstance = $true,
    [Parameter()][bool] $DeleteNotInSource = $false,
    [Parameter()][bool] $DeployGlobalParams = $true,
    [Parameter()][bool] $DoNotDeleteExcludedObjects = $true,
    [Parameter()][bool] $DoNotStopStartExcludedTriggers = $false,
    [Parameter()][bool] $FailsWhenConfigItemNotFound = $true,
    [Parameter()][bool] $FailsWhenPathNotFound = $true,
    [Parameter()][bool] $IgnoreLackOfReferencedObject = $false,
    [Parameter()][bool] $IncrementalDeployment = $false,
    [Parameter()][bool] $StopStartTriggers = $true,
    [Parameter(Mandatory)][string] $StageConfigFile,
    [Parameter(Mandatory)][string] $FilterTextFile,
    [Parameter()][string] $PublishMethod = "AzResource",
    [Parameter()][bool] $DryRun = $false
)

Install-Module Az.DataFactory -MinimumVersion "1.10.0" -Force
Install-Module azure.datafactory.tools -MinimumVersion "1.4.0" -Force
Import-Module azure.datafactory.tools

$global:ErrorActionPreference = "Stop"

$options = New-AdfPublishOption
$options.CreateNewInstance = $CreateNewInstance
$options.DeleteNotInSource = $DeleteNotInSource
$options.DeployGlobalParams = $DeployGlobalParams
$options.DoNotDeleteExcludedObjects = $DoNotDeleteExcludedObjects
$options.DoNotStopStartExcludedTriggers = $DoNotStopStartExcludedTriggers
$options.FailsWhenConfigItemNotFound = $FailsWhenConfigItemNotFound
$options.FailsWhenPathNotFound = $FailsWhenPathNotFound
$options.IgnoreLackOfReferencedObject = $IgnoreLackOfReferencedObject
$options.IncrementalDeployment = $IncrementalDeployment
$options.StopStartTriggers = $StopStartTriggers

$filterText = Get-Content $FilterTextFile -Raw -Encoding 'UTF8'
$filterArray = $filterText.Replace(',', "`n").Replace("`r`n", "`n").Split("`n");
$included = [System.Collections.ArrayList]@()

$filterArray | Where-Object { ($_.Trim().Length -gt 0 -or $_.Trim().StartsWith('+')) -and (!$_.Trim().StartsWith('-')) } | ForEach-Object {
    $i = $_.Trim().Replace('+', '')
    Write-Verbose "- Include: $i"
    $options.Includes.Add($i, "");
    $included.Add($i)
}
Write-Host "$($options.Includes.Count) rule(s)/object(s) added to be included in deployment."

$filterArray | Where-Object { $_.Trim().StartsWith('-') } | ForEach-Object {
    $e = $_.Trim().Substring(1)
    Write-Verbose "- Exclude: $e"
    $options.Excludes.Add($e, "");
}
Write-Host "$($options.Excludes.Count) rule(s)/object(s) added to be excluded from deployment."

$toDeleteLS = [System.Collections.ArrayList]@()
$toDeleteP = [System.Collections.ArrayList]@()
$toDeleteDS = [System.Collections.ArrayList]@()
$toDeleteDF = [System.Collections.ArrayList]@()
$toDeleteIR = [System.Collections.ArrayList]@()
$toDeleteT = [System.Collections.ArrayList]@()
$toDeleteC = [System.Collections.ArrayList]@()
$adfIns = Get-AdfFromService -FactoryName "$DataFactoryName" -ResourceGroupName "$ResourceGroupName"
$adfIns.AllObjects() | ForEach-Object {
    $name = $_.Name
    $type = $_.GetType().Name
    $simtype = $type
    if ($type -like 'PS*') { $simtype = $type.Substring(2) }
    if ($type -like 'AdfPS*') { $simtype = $type.Substring(5) }     # New internal type
    if ($simtype -like '*IntegrationRuntime') { $simtype = 'IntegrationRuntime' }
    if ($simtype -like '*managedPrivateEndpoint') { $simtype = 'managedPrivateEndpoint' }
    $simtype = $simtype.toLower()
    Write-Host $name $simtype
    $byName = $included -Contains "$simtype.$name"
    $byWildCard = $included -Contains "$simtype.*" -or $included -Contains "*.*"
    $delete = !$byName -and !$byWildCard

    if ($delete) {
        Write-Host "Deleting $simtype.$name"
        switch -Exact ($simtype) {
            "dataset" {
                $toDeleteDS.Add("$name")
            }
            "dataflow" {
                $toDeleteDF.Add("$name")
            }
            "pipeline" {
                $toDeleteP.Add("$name")
            }
            "linkedservice" {
                $toDeleteLS.Add("$name")
            }
            "integrationruntime" {
                $toDeleteIR.Add("$name")
            }
            "trigger" {
                $toDeleteT.Add("$name")
            }
            "credential" {
                $toDeleteC.Add("$name")
            }
            default {
                Write-Error "ADFT0018: Type $simtype is not supported."
            }
        }
    }
}

$toDeleteDS | ForEach-Object {
    Write-Host "Deleting $_"
    Remove-AzDataFactoryV2Dataset `
        -ResourceGroupName $ResourceGroupName `
        -DataFactoryName $DataFactoryName `
        -Name $_ `
        -Force -ErrorVariable err -ErrorAction Stop | Out-Null
}

$toDeleteDF | ForEach-Object {
    Write-Host "Deleting $_"
    Remove-AzDataFactoryV2DataFlow `
        -ResourceGroupName $ResourceGroupName `
        -DataFactoryName $DataFactoryName `
        -Name $_ `
        -Force -ErrorVariable err -ErrorAction Stop | Out-Null
}

$toDeleteP | ForEach-Object {
    Write-Host "Deleting $_"
    Remove-AzDataFactoryV2Pipeline `
        -ResourceGroupName $ResourceGroupName `
        -DataFactoryName $DataFactoryName `
        -Name $_ `
        -Force -ErrorVariable err -ErrorAction Stop | Out-Null
}

$toDeleteLS | ForEach-Object {
    Write-Host "Deleting $_"
    Remove-AzDataFactoryV2LinkedService `
        -ResourceGroupName $ResourceGroupName `
        -DataFactoryName $DataFactoryName `
        -Name $_ `
        -Force -ErrorVariable err -ErrorAction Stop | Out-Null
}

$toDeleteIR | ForEach-Object {
    Write-Host "Deleting $_"
    Remove-AzDataFactoryV2IntegrationRuntime `
        -ResourceGroupName $ResourceGroupName `
        -DataFactoryName $DataFactoryName `
        -Name $_ `
        -Force -ErrorVariable err -ErrorAction Stop | Out-Null
}

$toDeleteT | ForEach-Object {
    Write-Host "Deleting $_"
    Remove-AzDataFactoryV2Trigger `
        -ResourceGroupName $ResourceGroupName `
        -DataFactoryName $DataFactoryName `
        -Name $_ `
        -Force -ErrorVariable err -ErrorAction Stop | Out-Null
}

$null = Publish-AdfV2FromJson `
    -RootFolder "$DataFactoryCodePath" `
    -ResourceGroupName "$ResourceGroupName" `
    -DataFactoryName "$DataFactoryName" `
    -Location "$Location" `
    -Stage "$StageConfigFile" `
    -Option $options `
    -Method "$PublishMethod"
