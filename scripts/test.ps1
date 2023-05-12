[CmdletBinding()]
Param(
    [Parameter(Mandatory)][string] $DataFactoryCodePath
)

Install-Module azure.datafactory.tools -Force
Import-Module azure.datafactory.tools

$global:ErrorActionPreference = 'Continue'

$result = Test-AdfCode -RootFolder "$DataFactoryCodePath"

if ($result.WarningCount -gt 0) {
    Write-Host "##vso[task.complete result=SucceededWithIssues;]"
}

if ($result.ErrorCount -gt 0) {
    Write-Host "##vso[task.complete result=Failed;]"
}
