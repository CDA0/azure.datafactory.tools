function Remove-AdfObjectIfNotIncluded {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true)] [Adf] $adfSource,
        [parameter(Mandatory = $true)] $adfTargetObj,
        [parameter(Mandatory = $true)] $adfInstance
    )

    Write-Debug "BEGIN: Remove-AdfObjectIfNotInSource()"

    $name = $adfTargetObj.Name
    $type = $adfTargetObj.GetType().Name
    $simtype = Get-SimplifiedType -Type "$type"
    $src = Get-AdfObjectByName -adf $adfSource -name $name -type $type
    if (!$adfSource.PublishOptions.DeleteNotIncludedObjects) {
        Write-Verbose "Object [$simtype].[$name] hasn't been found in the source - to be deleted."
        Remove-AdfObject -adfSource $adfSource -obj $adfTargetObj -adfInstance $adfInstance
        $adfSource.DeletedObjectNames.Add("$simtype.$name")
    }
    else {
        Write-Verbose "Object [$simtype].[$name] is included - won't be delete."
    }

    Write-Debug "END: Remove-AdfObjectIfNotInSource()"
}
