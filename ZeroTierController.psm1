# Settings
[string]$Url = "https://my.zerotier.com/api"
[string]$TokenPath = "$env:USERPROFILE\.zerotier-api-token"

# Definitions
[string]$Node = ""
[string]$Id   = ""

# Internal Functions

function Get-ZeroTierToken {
    
    if ( Test-Path $TokenPath ) {
        [string]$ZeroTierToken =  Get-Content $TokenPath
    }
    else {
    
        Write-Host -ForegroundColor Red "No API token found, please populate $TokenPath with an API token."
        Throw (Get-Content $TokenPath)

    }

    return [string]$ZeroTierToken

}

# This function is called by basically everything else here, it's a wrapper to the REST API zerotier provides.
function Invoke-ZeroTierAPI {
    
    param (
        [parameter(
            Mandatory = $True)]
        [string]$Path,
        [parameter(
            Mandatory = $False)]
        $Body
    )

    # get the token each time we access zerotier
    $ZeroTierToken = Get-ZeroTierToken

    # POST by default, GET if there's no $Body
    $Method = "POST"
    if ($Body -eq $Null -or $Body -eq "") {
        $Method = "GET"  
    }

    $args = @{
        Uri         = "$Url$Path"
        Headers     = @{ "Authorization" = "Bearer $ZeroTierToken" }
        Method      = $Method
        Body        = $Body
        ContentType = 'application/json'
    }
    
    Invoke-RestMethod @args

} 

# Public Functions

function Get-ZeroTierStatus {

    [array]$Return = Invoke-ZeroTierAPI '/status'

    #region Define the VISIBLE properties
    # this is the list of properties visible by default
    [string[]]$Visible = 'Online','ClusterNode','ReadOnlyMode','Uptime'
    [System.Management.Automation.PSMemberInfo[]]$Info = New-Object System.Management.Automation.PSPropertySet DefaultDisplayPropertySet,$Visible
  
    # add the information about the visible properties to the return value
    $Return | Add-Member -MemberType MemberSet -Name PSStandardMembers -Value $Info
    #endregion

    Return [array]$Return

}

function Get-ZeroTierNetwork {
    [cmdletbinding()]
    param (
        [parameter(
            Mandatory = $False,
            ValueFromPipelineByPropertyName = $True)]
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
        [string[]]$Visible = 'Id','Description','OnlineMemberCount','AuthorizedMemberCount'
        [System.Management.Automation.PSMemberInfo[]]$Info = New-Object System.Management.Automation.PSPropertySet DefaultDisplayPropertySet,$Visible
  
        # add the information about the visible properties to the return value
        $Return | Add-Member -MemberType MemberSet -Name PSStandardMembers -Value $Info
        #endregion


        Return [array]$Return

    }

    End {
        Write-Debug "END: Get-ZeroTierNetwork"
    }

}

# TODO: Split into Set-ZeroTierNetwork and Set-ZeroTierNetworkConfig or not?
function Set-ZeroTierNetwork {
    [cmdletbinding()]
    param (
        [parameter(
            Mandatory = $True,
            ValueFromPipelineByPropertyName = $True)]
        [string]$Id,
        [parameter(
            Mandatory = $False,
            ValueFromPipelineByPropertyName = $True)]
        $Name,
        [parameter(
            Mandatory = $False,
            ValueFromPipelineByPropertyName = $True)]
        $Private,
        [parameter(
            Mandatory = $False,
            ValueFromPipelineByPropertyName = $True)]
        $MulticastLimit,
        [parameter(
            Mandatory = $False,
            ValueFromPipelineByPropertyName = $True)]
        $Description,
        [parameter(
            Mandatory = $False,
            ValueFromPipelineByPropertyName = $True)]
        $Routes,
        [parameter(
            Mandatory = $False,
            ValueFromPipelineByPropertyName = $True)]
        $Rules,
        [parameter(
            Mandatory = $False,
            ValueFromPipelineByPropertyName = $True)]
        $Tags,
        [parameter(
            Mandatory = $False,
            ValueFromPipelineByPropertyName = $True)]
        $Capabilities,
        [parameter(
            Mandatory = $False,
            ValueFromPipelineByPropertyName = $True)]
        $AuthTokens,
        [parameter(
            Mandatory = $False,
            ValueFromPipelineByPropertyName = $True)]
        $V4AssignMode,
        [parameter(
            Mandatory = $False,
            ValueFromPipelineByPropertyName = $True)]
        $V6AssignMode,
        [parameter(
            Mandatory = $False,
            ValueFromPipelineByPropertyName = $True)]
        $Ui,
        [parameter(
            Mandatory = $False,
            ValueFromPipelineByPropertyName = $True)]
        $RulesSource,
        [parameter(
            Mandatory = $False,
            ValueFromPipelineByPropertyName = $True)]
        $Permissions,
        [parameter(
            Mandatory = $False,
            ValueFromPipelineByPropertyName = $True)]
        $CapabilitiesByName,
        [parameter(
            Mandatory = $False,
            ValueFromPipelineByPropertyName = $True)]
        $TagsByName,
        [parameter(
            Mandatory = $False,
            ValueFromPipelineByPropertyName = $True)]
        $Dns,
        [parameter(
            Mandatory = $False,
            ValueFromPipelineByPropertyName = $True)]
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
            if ($Name -ne $Null) {
                $Config.name = $Name
            }
            if ($Private -ne $Null) {
                $Config.private = $Private
            }
            if ($MulticastLimit -ne $Null) {
                $Config.multicastLimit = $MulticastLimit
            }
            if ($Routes -ne $Null) {
                $Config.routes = $Routes
            }
            if ($Rules -ne $Null) {
                $Config.rules = $Rules
            }
            if ($Tags -ne $Null) {
                $Config.tags = $Tags
            }
            if ($Capabilities -ne $Null) {
                $Config.capabilities = $Capabilities
            }
            if ($AuthTokens -ne $Null) {
                $Config.authTokens = $AuthTokens
            }
            if ($V4AssignMode -ne $Null) {
                $Config.v4AssignMode = $V4AssignMode
            }
            if ($V6AssignMode -ne $Null) {
                $Config.v6AssignMode = $V6AssignMode
            }
            if ($Dns -ne $Null) {
                $Config.dns = $Dns
            }

            $Body = @{
                config = $Config
                description = $Description
                ui = $Ui
                tagsByName = $TagsByName
                capabilitiesByName = $CapabilitiesByName
                rulesSource = $RulesSource
                permissions = $Permissions
            }
        }
        else{
            $Body = @{
                config = @{
                       name = $Name
                       private = $Private
                       multicastLimit = $MulticastLimit
                       routes = $Routes
                       rules = $Rules
                       tags = $Tags
                       capabilities = $Capabilities
                       authTokens = $AuthTokens
                       v4AssignMode = $V4AssignMode
                       v6AssignMode = $V6AssignMode
                       dns = $Dns
                       }
                description = $Description
                ui = $Ui
                tagsByName = $TagsByName
                capabilitiesByName = $CapabilitiesByName
                rulesSource = $RulesSource
                permissions = $Permissions
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
            Mandatory = $True,
            ValueFromPipelineByPropertyName = $True)]
        [string]$Id,
        [parameter(
            Mandatory = $True,
            ValueFromPipelineByPropertyName = $True)]
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
            Mandatory = $True,
            ValueFromPipelineByPropertyName = $True)]
        [string]$Id,
        [parameter(
            Mandatory = $False,
            ValueFromPipelineByPropertyName = $True)]
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
        [string[]]$Visible = 'NodeId','Description','Name','Online'
        [System.Management.Automation.PSMemberInfo[]]$Info = New-Object System.Management.Automation.PSPropertySet DefaultDisplayPropertySet,$Visible
  
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
            Mandatory = $True,
            ValueFromPipelineByPropertyName = $True)]
        [string]$Id,
        [parameter(
            Mandatory = $True,
            ValueFromPipelineByPropertyName = $True)]
        [Alias("nodeId")]
        [string]$Node,
        [parameter(
            Mandatory = $False,
            ValueFromPipelineByPropertyName = $True)]
        $Hidden,
        [parameter(
            Mandatory = $False,
            ValueFromPipelineByPropertyName = $True)]
        $Name,
        [parameter(
            Mandatory = $False,
            ValueFromPipelineByPropertyName = $True)]
        $Description,
        [parameter(
            Mandatory = $False,
            ValueFromPipelineByPropertyName = $True)]
        $OfflineNotifyDelay,
        [parameter(
            Mandatory = $False,
            ValueFromPipelineByPropertyName = $True)]
        $Config,
        [parameter(
            Mandatory = $False,
            ValueFromPipelineByPropertyName = $True)]
        $Authorized,
        [parameter(
            Mandatory = $False,
            ValueFromPipelineByPropertyName = $True)]
        $Capabilities,
        [parameter(
            Mandatory = $False,
            ValueFromPipelineByPropertyName = $True)]
        $IpAssignments,
        [parameter(
            Mandatory = $False,
            ValueFromPipelineByPropertyName = $True)]
        $NoAutoAssignIps,
        [parameter(
            Mandatory = $False,
            ValueFromPipelineByPropertyName = $True)]
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
            if ($Authorized -ne $Null) {
                $Config.authorized = $Authorized
            }
            if ($Capabilities -ne $Null) {
                $Config.capabilities = $Capabilities
            }
            if ($Tags -ne $Null) {
                $Config.tags = $Tags
            }
            if ($IpAssignments -ne $Null) {
                $Config.ipAssignments = $IpAssignments
            }
            if ($OfflineNotifyDelay -ne $Null) {
                $Config.offlineNotifyDelay = $OfflineNotifyDelay
            }

            $Body = @{
                config = $Config
                description = $Description
                hidden = $Hidden
                name = $Name
                offlineNotifyDelay = $OfflineNotifyDelay
            }
        }
        else{
            $Body = @{
                config = @{
                       authorized = $Authorized
                       capabilities = $Capabilities
                       tags = $Tags
                       ipAssignments = $IpAssignments
                       noAutoAssignIps = $NoAutoAssignIps
                       }
                description = $Description
                hidden = $Hidden
                name = $Name
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
            Mandatory = $True,
            ValueFromPipelineByPropertyName = $True)]
        [string]$Id,
        [parameter(
            Mandatory = $True,
            ValueFromPipelineByPropertyName = $True)]
        [Alias("nodeId")]
        [string]$Node,
        [parameter(
            Mandatory = $False,
            ValueFromPipelineByPropertyName = $True)]
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
            Mandatory = $True,
            ValueFromPipelineByPropertyName = $True)]
        [string]$Id,
        [parameter(
            Mandatory = $True,
            ValueFromPipelineByPropertyName = $True)]
        [Alias("nodeId")]
        [string]$Node,
        [parameter(
            Mandatory = $False,
            ValueFromPipelineByPropertyName = $True)]
        $NetworkId
        )

        # if we're piping from Get-ZeroTierMember, the networkId is the trusted Id as $Id will be overloaded with a contatenation of the networkid and the node id :(
        if ($NetworkID) {
            $Id = $NetworkId
        }

        Set-ZeroTierMember -id $Id -node $Node -authorized $False

}