param (
  [Parameter(Mandatory = $true)]
  [String]$sqlServer,
  [Parameter(Mandatory = $true)]
  [String]$dbName,
  [Parameter(Mandatory = $true)]
  [String]$objectId,
  [Parameter(Mandatory = $true)]
  [String]$filePath
)

$ErrorActionPreference = 'Stop'

Write-Host $filePath
$query = Get-Content -raw $filePath

$response = Invoke-WebRequest -Uri "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fdatabase.windows.net%2F&client_id=$objectId" -Method GET -Headers @{Metadata = "true" }
$content = $response.Content | ConvertFrom-Json
$AccessToken = $content.access_token

$retryCount = 3
$retryInterval = 20
$connection = New-Object System.Data.SqlClient.SqlConnection
$connection.ConnectionString = "Server=tcp:$sqlServer,1433;Initial Catalog=$dbName;TrustServerCertificate=False;Encrypt=True;"
$connection.AccessToken = $AccessToken
$sqlCmd = New-Object System.Data.SqlClient.SqlCommand
$sqlCmd.CommandText = $query
$sqlCmd.Connection = $connection

for ($i = 0; $i -le $retryCount; $i++) {
  try {
    $connection.Open()
    break
  }
  catch [System.Management.Automation.MethodInvocationException], [System.Management.Automation.ParentContainsErrorRecordException] {
    if ($_.Exception.InnerException.Message -match 'Connection Timeout Expired' -or $_.Exception.InnerException.Message -match 'not currently available') {
      if ($i -eq $retryCount) {
        throw
      }
      else {
        Write-Host "Waiting for serverless instance to start..."
        Start-Sleep -Seconds $retryInterval
      }
    }
    else {
      Write-Host "Unhandled SQL exception."
      throw
    }
  }
}
[void]$sqlCmd.ExecuteNonQuery()
$connection.Close()

Write-Host $query
