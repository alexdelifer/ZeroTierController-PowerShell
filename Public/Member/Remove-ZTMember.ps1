function Remove-ZTMember {
    [cmdletbinding()]
    param (
        [parameter(
            Mandatory,
            ValueFromPipelineByPropertyName)]
        [string]$Id,
        [parameter(
            Mandatory,
            ValueFromPipelineByPropertyName)]
        [Alias("nodeId")]
        [string]$Node,
        [parameter(
            ValueFromPipelineByPropertyName)]
        $NetworkId
    )

    $memberargs = @{
        Hidden        = $True
        Authorized    = $False
        IpAssignments = @{}
    }
    Set-ZTMember @PSBoundParameters @memberargs

}