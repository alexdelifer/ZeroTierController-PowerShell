function Remove-ZTUser {
    [cmdletbinding()]
    param (
        [parameter(
            Mandatory,
            ValueFromPipelineByPropertyName)]
        [string]$Id,
        [parameter(
            Mandatory,
            ValueFromPipelineByPropertyName)]
        $UserId
    )
    $Path = "/network/$Id/users/$UserId"

    $null = Invoke-ZTAPI -Path $Path -Method "DELETE"
    
}