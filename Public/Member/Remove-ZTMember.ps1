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
    Begin {
        Write-Debug "BEGIN: Add-ZTMember"
    }
    Process {
        Write-Debug "PROCESS: Add-ZTMember"

        $memberargs = @{
            Hidden        = $True
            Authorized    = $False
            IpAssignments = @{}
        }
        Set-ZTMember @PSBoundParameters @memberargs
    }
    End {
        Write-Debug "END: Add-ZTMember"
    }
}