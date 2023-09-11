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

$filterArray | Where-Object { ($_.Trim().Length -gt 0 -or $_.Trim().StartsWith('+')) -and (!$_.Trim().StartsWith('-')) } | ForEach-Object {
    $i = $_.Trim().Replace('+', '')
    Write-Verbose "- Include: $i"
    $options.Includes.Add($i, "");
}
Write-Host "$($options.Includes.Count) rule(s)/object(s) added to be included in deployment."

$filterArray | Where-Object { $_.Trim().StartsWith('-') } | ForEach-Object {
    $e = $_.Trim().Substring(1)
    Write-Verbose "- Exclude: $e"
    $options.Excludes.Add($e, "");
}
Write-Host "$($options.Excludes.Count) rule(s)/object(s) added to be excluded from deployment."

$null = Publish-AdfV2FromJson `
    -RootFolder "$DataFactoryCodePath" `
    -ResourceGroupName "$ResourceGroupName" `
    -DataFactoryName "$DataFactoryName" `
    -Location "$Location" `
    -Stage "$StageConfigFile" `
    -Option $options `
    -Method "$PublishMethod"

$adfIns = Get-AdfFromService -FactoryName "$DataFactoryName" -ResourceGroupName "$ResourceGroupName"
$adfIns.AllObjects() | ForEach-Object {
    Write-Host $_
    Write-Host $options.Includes
    $options.Includes -Contains $_
}
