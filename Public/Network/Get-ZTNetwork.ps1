function Get-ZTNetwork {
    [cmdletbinding()]
    param (
        [parameter(
            ValueFromPipelineByPropertyName)]
        [string]$Id
    )

    Begin {
        Write-Debug "BEGIN: Get-ZTNetwork"
    }

    Process {
        Write-Debug "PROCESS: Get-ZTNetwork"

        # if no network is provided, zerotier will return all networks.
        $Path = "/network/$Id"
        if ($Id -eq "" -or $Id -eq $Null) {
            $Path = "/network"
        }

        [pscustomobject]$Return = Invoke-ZTAPI -Path $Path -Method "GET"

        #region Define the VISIBLE properties
        # this is the list of properties visible by default
        [string[]]$Visible = 'Id', 'Description', 'OnlineMemberCount', 'AuthorizedMemberCount'
        [System.Management.Automation.PSMemberInfo[]]$Info = New-Object System.Management.Automation.PSPropertySet DefaultDisplayPropertySet, $Visible

        # add the information about the visible properties to the return value
        $Return | Add-Member -MemberType MemberSet -Name PSStandardMembers -Value $Info
        #endregion
        Return $Return
    }
    End {
        Write-Debug "END: Get-ZTNetwork"
    }
}