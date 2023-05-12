[CmdletBinding()]
Param(
    [Parameter(Mandatory)][string] $DataFactoryCodePath
)

Install-Module Az.DataFactory -MinimumVersion "1.10.0" -Force
Install-Module azure.datafactory.tools -MinimumVersion "1.4.0" -Force
Import-Module azure.datafactory.tools

$global:ErrorActionPreference = "Continue"

$result = Test-AdfCode -RootFolder "$DataFactoryCodePath"

if ($result.WarningCount -gt 0) {
    Write-Host "##vso[task.complete result=SucceededWithIssues;]"
}

if ($result.ErrorCount -gt 0) {
    Write-Host "##vso[task.complete result=Failed;]"
}
