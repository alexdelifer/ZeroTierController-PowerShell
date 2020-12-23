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

    $CurrentPermissions = (Get-ZTUser -Id $Id -UserId $UserId).Permissions

    $Body = @{
        Id = $UserId
    }

    if ($null -eq $Permissions) {
        if ($null -ne $CurrentPermissions) { $Permissions = $CurrentPermissions }
        else {
            # Default Permissions
            $Permissions = [pscustomobject]@{
                #string          = "something"
                addUserDisabled = $false
                A               = $true 
                D               = $true
                M               = $true
                R               = $true 
            } 
        }
    }

    # Expand the passed properties in the $body
    $Permissions.PSObject.Properties | ForEach-Object {
        #$_
        $Body.($_.Name) = $_.Value
    }  

    if ($Null -ne $AllowRead) { $Body.R = $AllowRead }
    if ($Null -ne $AllowAuthorize) { $Body.A = $AllowAuthorize } 
    if ($Null -ne $AllowModify) { $Body.M = $AllowModify }
    if ($Null -ne $AllowDelete) { $Body.D = $AllowDelete } 

    # The returned value is just what we sent it...
    $null = Invoke-ZTAPI -Path $Path -Method "POST" -Body $Body

    # Lie and get the latest user thru get, just like the webui
    Get-ZTUser -Id $Id -UserId $UserId
}