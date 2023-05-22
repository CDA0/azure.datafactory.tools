param (
  [Parameter(Mandatory = $true)]
  [string]$sqlServer,
  [Parameter(Mandatory = $true)]
  [string]$adminUser,
  [Parameter(Mandatory = $true)]
  [string]$adminPassword,
  [Parameter(Mandatory = $true)]
  [string]$databaseName,
  [Parameter(Mandatory = $true)]
  [string]$filePath
)

$errorActionPreference = "Stop"
Import-Module $PSScriptRoot/functions.psm1

$pass = $adminPassword | ConvertTo-SecureString -AsPlainText -Force
$pass.MakeReadOnly()

Write-Host $filePath
$sqlCmd = Get-Content $filePath

Invoke-SQLQuery $sqlServer $databaseName $adminUser $pass $sqlCmd
Write-Host $sqlCmd
