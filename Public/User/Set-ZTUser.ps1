function Set-ZTUser {
    [cmdletbinding()]
    param (
        [parameter(
            Mandatory,
            ValueFromPipelineByPropertyName)]
        [string]$Id,
        [parameter(
            Mandatory,
            ValueFromPipelineByPropertyName)]
        $UserId,
        [parameter(
            ValueFromPipelineByPropertyName)]
        $Permissions,
        [parameter(
            ValueFromPipelineByPropertyName)]
        $AllowRead,
        [parameter(
            ValueFromPipelineByPropertyName)]
        $AllowAuthorize,
        [parameter(
            ValueFromPipelineByPropertyName)]
        $AllowModify,
        [parameter(
            ValueFromPipelineByPropertyName)]
        $AllowDelete
    )
    $Path = "/network/$Id/users"

    $Body = @{
        Id = $UserId
    }

    if (!$Permissions) {
        $Permissions = (Get-ZTUser -Id $Id -UserId $UserId).Permissions
    }

    # Expand the passed properties in the $body
    $Permissions.PSObject.Properties | ForEach-Object {
        $Body.($_.Name) = $_.Value
    }  

    if ($Null -ne $AllowRead) { $Body.R = $AllowRead }
    if ($Null -ne $AllowAuthorize) { $Body.A = $AllowAuthorize } 
    if ($Null -ne $AllowModify) { $Body.M = $AllowModify }
    if ($Null -ne $AllowDelete) { $Body.D = $AllowDelete } 

    $null = Invoke-ZTAPI -Path $Path -Method "POST" -Body $Body

    # Lie and get the latest user thru get, just like the webui
    Get-ZTUser -Id $Id -UserId $UserId
}