function Add-ZTMember {
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
        $Hidden,
        [parameter(
            ValueFromPipelineByPropertyName)]
        $Name,
        [parameter(
            ValueFromPipelineByPropertyName)]
        $Description,
        [parameter(
            ValueFromPipelineByPropertyName)]
        $OfflineNotifyDelay,
        [parameter(
            ValueFromPipelineByPropertyName)]
        $Config,
        [parameter(
            ValueFromPipelineByPropertyName)]
        $Authorized,
        [parameter(
            ValueFromPipelineByPropertyName)]
        $Capabilities,
        [parameter(
            ValueFromPipelineByPropertyName)]
        $IpAssignments,
        [parameter(
            ValueFromPipelineByPropertyName)]
        $NoAutoAssignIps,
        [parameter(
            ValueFromPipelineByPropertyName)]
        $NetworkId
    )

    Begin {
        Write-Debug "BEGIN: Add-ZTMember"
    }

    Process {
        Write-Debug "PROCESS: Add-ZTMember"
        $null = Set-ZTNetwork -Id $Id -AuthTokens @($Node)
        Set-ZTMember @PSBoundParameters
    }
    End {
        Write-Debug "END: Add-ZTMember"
    }
}