function Add-ZTUser {
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
    
    Set-ZTUser @PSBoundParameters
}