function Set-ZTMember {
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
        Write-Debug "BEGIN: Set-ZTMember"
    }
    Process {
        Write-Debug "PROCESS: Set-ZTMember"
        # if we're piping from Get-ZTMember, the networkId is the trusted Id as $Id will be overloaded with a contatenation of the networkid and the node id :(
        $Path = "/network/$Id/member/$Node"
        if ($NetworkID) {
            $Path = "/network/$NetworkId/member/$Node" 
        }
        $Body = @{}
        # Config
        if ($Null -ne $Authorized) { $Body.Config += @{Authorized = $Authorized } }
        if ($Null -ne $Capabilities) { $Body.Config += @{Capabilities = $Capabilities } }
        if ($Null -ne $Tags) { $Body.Config += @{Tags = $Tags } }
        if ($Null -ne $IpAssignments) { $Body.Config += @{IpAssignments = $IpAssignments } }
        if ($Null -ne $NoAutoAssignIps) { $Body.Config += @{NoAutoAssignIps = $NoAutoAssignIps } }
        # Main
        if ($Null -ne $Description) { $Body.Description += $Description }
        if ($Null -ne $Hidden) { $Body.Hidden += $Hidden }
        if ($Null -ne $Name) { $Body.Name += $Name }
        if ($Null -ne $OfflineNotifyDelay) { $Body.OfflineNotifyDelay += $OfflineNotifyDelay }
        Write-Debug ($Body | ConvertTo-Json)
        [pscustomobject]$Return = Invoke-ZTAPI -Path $Path -Body $Body -Method "POST"
        Return [pscustomobject]$Return
    }
    End {
        Write-Debug "END: Set-ZTMember"
    }
}