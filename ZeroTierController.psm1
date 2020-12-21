# Settings
[string]$Url = "https://my.zerotier.com/api"
[string]$TokenPath = "$env:USERPROFILE\.zerotier-api-token"

# Definitions
[string]$Node = ""
[string]$Id = ""


# Internal Functions

function Get-ZeroTierToken {
    
    if ( Test-Path $TokenPath ) {
        [string]$ZeroTierToken = Get-Content $TokenPath
    }
    else {
    
        Write-Host -ForegroundColor Red "No API token found, please populate $TokenPath with an API token."
        Throw (Get-Content $TokenPath)

    }

    return [string]$ZeroTierToken

}

# This function is called by basically everything else here, it's a wrapper to the REST API zerotier provides.
# TODO: Capitalize first letter of NoteProperty somehow... id -> Id, status -> Status 
function Invoke-ZeroTierAPI {
    
    param (
        [parameter(
            Mandatory)]
        [string]$Path,
        [parameter()]
        $Body
    )

    # get the token each time we access zerotier
    $ZeroTierToken = Get-ZeroTierToken

    # POST by default, GET if there's no $Body
    $Method = "POST"
    if ($Null -eq $Body -or $Body -eq "") {
        $Method = "GET"  
    }

    $apiargs = @{
        Uri         = "$Url$Path"
        Headers     = @{ "Authorization" = "Bearer $ZeroTierToken" }
        Method      = $Method
        Body        = $Body
        ContentType = 'application/json'
    }
    
    Invoke-RestMethod @apiargs

} 

# Public Functions

function Get-ZeroTierStatus {

    [array]$Return = Invoke-ZeroTierAPI '/status'

    #region Define the VISIBLE properties
    # this is the list of properties visible by default
    [string[]]$Visible = 'Online', 'ClusterNode', 'ReadOnlyMode', 'Uptime'
    [System.Management.Automation.PSMemberInfo[]]$Info = New-Object System.Management.Automation.PSPropertySet DefaultDisplayPropertySet, $Visible

    # add the information about the visible properties to the return value
    $Return | Add-Member -MemberType MemberSet -Name PSStandardMembers -Value $Info
    #endregion

    Return [array]$Return

}

function Get-ZeroTierNetwork {
    [cmdletbinding()]
    param (
        [parameter(
            ValueFromPipelineByPropertyName)]
        [string]$Id
    )

    Begin {
        Write-Debug "BEGIN: Get-ZeroTierNetwork"
    }

    Process {
        Write-Debug "PROCESS: Get-ZeroTierNetwork"

        # if no network is provided, zerotier will return all networks.
        $Path = "/network/$Id"
        if ($Id -eq "" -or $Id -eq $Null) {
            $Path = "/network"
        }

        [array]$Return = Invoke-ZeroTierAPI $Path

        #region Define the VISIBLE properties
        # this is the list of properties visible by default
        [string[]]$Visible = 'Id', 'Description', 'OnlineMemberCount', 'AuthorizedMemberCount'
        [System.Management.Automation.PSMemberInfo[]]$Info = New-Object System.Management.Automation.PSPropertySet DefaultDisplayPropertySet, $Visible

        # add the information about the visible properties to the return value
        $Return | Add-Member -MemberType MemberSet -Name PSStandardMembers -Value $Info
        #endregion


        Return [array]$Return

    }

    End {
        Write-Debug "END: Get-ZeroTierNetwork"
    }

}

function Set-ZeroTierNetwork {
    [cmdletbinding()]
    param (
        [parameter(
            Mandatory,
            ValueFromPipelineByPropertyName)]
        [string]$Id,
        [parameter(
            ValueFromPipelineByPropertyName)]
        $Name,
        [parameter(
            ValueFromPipelineByPropertyName)]
        $Private,
        [parameter(
            ValueFromPipelineByPropertyName)]
        $MulticastLimit,
        [parameter(
            ValueFromPipelineByPropertyName)]
        $Description,
        [parameter(
            ValueFromPipelineByPropertyName)]
        $Routes,
        [parameter(
            ValueFromPipelineByPropertyName)]
        $Rules,
        [parameter(
            ValueFromPipelineByPropertyName)]
        $Tags,
        [parameter(
            ValueFromPipelineByPropertyName)]
        $Capabilities,
        [parameter(
            ValueFromPipelineByPropertyName)]
        $AuthTokens,
        [parameter(
            ValueFromPipelineByPropertyName)]
        $V4AssignMode,
        [parameter(
            ValueFromPipelineByPropertyName)]
        $V6AssignMode,
        [parameter(
            ValueFromPipelineByPropertyName)]
        $Ui,
        [parameter(
            ValueFromPipelineByPropertyName)]
        $RulesSource,
        [parameter(
            ValueFromPipelineByPropertyName)]
        $Permissions,
        [parameter(
            ValueFromPipelineByPropertyName)]
        $CapabilitiesByName,
        [parameter(
            ValueFromPipelineByPropertyName)]
        $TagsByName,
        [parameter(
            ValueFromPipelineByPropertyName)]
        $Dns,
        [parameter(
            ValueFromPipelineByPropertyName)]
        $Config

    )

    Begin {
        Write-Debug "BEGIN: Set-ZeroTierNetwork"
    }

    Process {
        Write-Debug "PROCESS: Set-ZeroTierNetwork"

        # require network id to modify
        $Path = "/network/$Id"
        if ($Id -eq "" -or $Id -eq $Null) {
            Write-Host "ID Required for Set-ZeroTierNetwork"
            Break
        }
        # https://my.zerotier.com/central-api.html#network-network-post

        if ($Config) {

            # nested config options get overwritten if $Config is piped from another command
            if ($Null -ne $Name) {
                $Config.name = $Name
            }
            if ($Null -ne $Private) {
                $Config.private = $Private
            }
            if ($Null -ne $MulticastLimit) {
                $Config.multicastLimit = $MulticastLimit
            }
            if ($Null -ne $Routes) {
                $Config.routes = $Routes
            }
            if ($Null -ne $Rules) {
                $Config.rules = $Rules
            }
            if ($Null -ne $Tags) {
                $Config.tags = $Tags
            }
            if ($Null -ne $Capabilities) {
                $Config.capabilities = $Capabilities
            }
            if ($Null -ne $AuthTokens) {
                $Config.authTokens = $AuthTokens
            }
            if ($Null -ne $V4AssignMode) {
                $Config.v4AssignMode = $V4AssignMode
            }
            if ($Null -ne $V6AssignMode) {
                $Config.v6AssignMode = $V6AssignMode
            }
            if ($Null -ne $Dns) {
                $Config.dns = $Dns
            }

            $Body = @{
                config             = $Config
                description        = $Description
                ui                 = $Ui
                tagsByName         = $TagsByName
                capabilitiesByName = $CapabilitiesByName
                rulesSource        = $RulesSource
                permissions        = $Permissions
            }
        }
        else {
            $Body = @{
                config             = @{
                    name           = $Name
                    private        = $Private
                    multicastLimit = $MulticastLimit
                    routes         = $Routes
                    rules          = $Rules
                    tags           = $Tags
                    capabilities   = $Capabilities
                    authTokens     = $AuthTokens
                    v4AssignMode   = $V4AssignMode
                    v6AssignMode   = $V6AssignMode
                    dns            = $Dns
                }
                description        = $Description
                ui                 = $Ui
                tagsByName         = $TagsByName
                capabilitiesByName = $CapabilitiesByName
                rulesSource        = $RulesSource
                permissions        = $Permissions
            }
        
        }

        [array]$Return = Invoke-ZeroTierAPI $Path ($Body | ConvertTo-Json -Depth 10)
        Return [array]$Return
        

    }

    End {
        Write-Debug "END: Set-ZeroTierNetwork"
    }

}

# TODO: Fix this
function Add-ZeroTierMember {
    [cmdletbinding()]
    param (
        [parameter(
            Mandatory,
            ValueFromPipelineByPropertyName)]
        [string]$Id,
        [parameter(
            Mandatory,
            ValueFromPipelineByPropertyName)]
        [array]$Node
    )

    Begin {
        Write-Debug "BEGIN: Add-ZeroTierMember"
    }

    Process {
        Write-Debug "PROCESS: Add-ZeroTierMember"

        Set-ZeroTierNetwork -id $Id -authTokens $Node

    }

    End {
        Write-Debug "END: Add-ZeroTierMember"
    }

}

function Get-ZeroTierMember {
    [cmdletbinding()]
    param (
        [parameter(
            Mandatory,
            ValueFromPipelineByPropertyName)]
        [string]$Id,
        [parameter(
            ValueFromPipelineByPropertyName)]
        [string]$Node
    )

    Begin {
        Write-Debug "BEGIN: Get-ZeroTierMember"
    }

    Process {
        Write-Debug "PROCESS: Get-ZeroTierMember"

        # if no node is provided, zerotier will return all members.
        $Path = "/network/$Id/member/$Node"
        if ($Node -eq "" -or $Node -eq $Null) {
            $Path = "/network/$Id/member"
        }
        
        [array]$Return = Invoke-ZeroTierAPI $Path

        #region Define the VISIBLE properties
        # this is the list of properties visible by default
        [string[]]$Visible = 'NodeId', 'Description', 'Name', 'Online'
        [System.Management.Automation.PSMemberInfo[]]$Info = New-Object System.Management.Automation.PSPropertySet DefaultDisplayPropertySet, $Visible

        # add the information about the visible properties to the return value
        $Return | Add-Member -MemberType MemberSet -Name PSStandardMembers -Value $Info
        #endregion

        Return [array]$Return

    }

    End {
        Write-Debug "END: Get-ZeroTierMember"
    }


}

function Set-ZeroTierMember {
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
        Write-Debug "BEGIN: Set-ZeroTierMember"

    }

    Process {
        Write-Debug "PROCESS: Set-ZeroTierMember"

        # if we're piping from Get-ZeroTierMember, the networkId is the trusted Id as $Id will be overloaded with a contatenation of the networkid and the node id :(
        $Path = "/network/$Id/member/$Node"
        if ($NetworkID) {
            $Path = "/network/$NetworkId/member/$Node" 
        }

        if ($Config) {
            # nested config options get overwritten if $Config is piped from another command
            if ($Null -ne $Authorized) {
                $Config.authorized = $Authorized
            }
            if ($Null -ne $Capabilities) {
                $Config.capabilities = $Capabilities
            }
            if ($Null -ne $Tags) {
                $Config.tags = $Tags
            }
            if ($Null -ne $IpAssignments) {
                $Config.ipAssignments = $IpAssignments
            }
            if ($Null -ne $OfflineNotifyDelay) {
                $Config.offlineNotifyDelay = $OfflineNotifyDelay
            }

            $Body = @{
                config             = $Config
                description        = $Description
                hidden             = $Hidden
                name               = $Name
                offlineNotifyDelay = $OfflineNotifyDelay
            }
        }
        else {
            $Body = @{
                config             = @{
                    authorized      = $Authorized
                    capabilities    = $Capabilities
                    tags            = $Tags
                    ipAssignments   = $IpAssignments
                    noAutoAssignIps = $NoAutoAssignIps
                }
                description        = $Description
                hidden             = $Hidden
                name               = $Name
                offlineNotifyDelay = $OfflineNotifyDelay
            }
        
        }

        [array]$Return = Invoke-ZeroTierAPI $Path ($Body | ConvertTo-Json -Depth 10)
        Return [array]$Return

    }

    End {
        Write-Debug "END: Set-ZeroTierMember"
    }


}

# Shortcuts

function Enable-ZeroTierMember {

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

    # if we're piping from Get-ZeroTierMember, the networkId is the trusted Id as $Id will be overloaded with a contatenation of the networkid and the node id :(
    if ($NetworkID) {
        $Id = $NetworkId
    }

    Set-ZeroTierMember -id $Id -node $Node -authorized $True

}

function Disable-ZeroTierMember {

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

    # if we're piping from Get-ZeroTierMember, the networkId is the trusted Id as $Id will be overloaded with a contatenation of the networkid and the node id :(
    if ($NetworkID) {
        $Id = $NetworkId
    }

    Set-ZeroTierMember -id $Id -node $Node -authorized $False

}