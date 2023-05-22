function Invoke-SQLQuery {
    param (
      [Parameter(Mandatory = $true)]
      [String]$sqlServer,
      [Parameter(Mandatory = $true)]
      [String]$dbName,
      [Parameter(Mandatory = $true)]
      [String]$adminUser,
      [Parameter(Mandatory = $true)]
      [SecureString]$password,
      [Parameter(Mandatory = $true)]
      [String]$query
    )
    $credentials = New-Object System.Data.SqlClient.SqlCredential($adminUser,$password)
    $connection = New-Object System.Data.SqlClient.SqlConnection
    $connection.ConnectionString = "Server=tcp:$sqlServer,1433;Initial Catalog=$dbName;TrustServerCertificate=False;Encrypt=True;"
    $connection.Credential = $credentials
    $sqlCmd = New-Object System.Data.SqlClient.SqlCommand
    $sqlCmd.CommandText = $query
    $sqlCmd.Connection = $connection
    $connection.Open()
    [void]$sqlCmd.ExecuteNonQuery()
    $connection.Close()
  }

function Get-Sid {
  param (
      [Parameter(Mandatory = $true)]
      [string]$appId
  )
  [guid]$guid = [System.Guid]::Parse($appId)
  foreach ($byte in $guid.ToByteArray()) {
      $byteGuid += [System.String]::Format("{0:X2}", $byte)
  }
  return "0x" + $byteGuid
}
