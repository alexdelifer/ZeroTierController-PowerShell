function Remove-ZTNetwork {
    [cmdletbinding()]
    param (
        [parameter(
            Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName)]
        [string]$Id
    )
    $Path = "/network/$Id"
    if ($null -ne $NetworkID) {
        $Path = "/network/$NetworkID"
    }

    Write-Debug ($Body | ConvertTo-Json -Depth 10 )
    $null = Invoke-ZTAPI -Path $Path -Method "DELETE"
}