# Settings
[string]$Url = "http://my.zerotier.com/api"
[string]$TokenPath = "$env:USERPROFILE\.zerotier-api-token"

# Definitions
[string]$node = ""
[string]$id   = ""

# Internal Functions

function Get-ZeroTierToken {
    
    if ( Test-Path $TokenPath ) {
        [string]$ZeroTierToken =  Get-Content $TokenPath
    }
    else {
    
        Write-Host -ForegroundColor Red "No API token found, please populate $TokenPath with an API token."
        Break

    }

    return [string]$ZeroTierToken

}

# This function is called by basically everything else here, it's a wrapper to the REST API zerotier provides.
function Invoke-ZeroTierAPI {
    
    param (
        [parameter(
            Mandatory = $true)]
        [string]$Path,
        [parameter(
            Mandatory = $false)]
        $Body
    )

    # get the token each time we access zerotier
    $ZeroTierToken = Get-ZeroTierToken

    # PUT by default, GET if there's no $Body
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

    Invoke-ZeroTierAPI '/status'

}

function Get-ZeroTierNetwork {
    [cmdletbinding()]
    param (
        [parameter(
            Mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        [string]$id
    )

    Begin {
        Write-Debug "BEGIN: Get-ZeroTierNetwork"
    }

    Process {
        Write-Debug "PROCESS: Get-ZeroTierNetwork"

        # if no network is provided, zerotier will return all networks.
        $Path = "/network/$id"
        if ($id -eq "" -or $id -eq $Null) {
            $Path = "/network"
        }

        [array]$Return = Invoke-ZeroTierAPI $Path
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
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true)]
        [string]$id,
        [parameter(
            Mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        $name,
        [parameter(
            Mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        $private,
        [parameter(
            Mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        $multicastLimit,
        [parameter(
            Mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        $description,
        [parameter(
            Mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        $routes,
        [parameter(
            Mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        $rules,
        [parameter(
            Mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        $tags,
        [parameter(
            Mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        $capabilities,
        [parameter(
            Mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        $authTokens,
        [parameter(
            Mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        $v4AssignMode,
        [parameter(
            Mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        $v6AssignMode,
        [parameter(
            Mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        $ui,
        [parameter(
            Mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        $rulesSource,
        [parameter(
            Mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        $permissions,
        [parameter(
            Mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        $capabilitiesByName,
        [parameter(
            Mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        $tagsByName,
        [parameter(
            Mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        $dns,
        [parameter(
            Mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        $config

    )

    Begin {
        Write-Debug "BEGIN: Set-ZeroTierNetwork"
    }

    Process {
        Write-Debug "PROCESS: Set-ZeroTierNetwork"

        # require network id to modify
        $Path = "/network/$id"
        if ($id -eq "" -or $id -eq $Null) {
            Write-Host "ID Required for Set-ZeroTierNetwork"
            Break
        }
        # https://my.zerotier.com/central-api.html#network-network-post

        if ($config) {

            # nested config options get overwritten if $config is piped from another command
            if ($name -ne $Null) {
                $config.name = $name
            }
            if ($private -ne $Null) {
                $config.private = $private
            }
            if ($multicastLimit -ne $Null) {
                $config.multicastLimit = $multicastLimit
            }
            if ($routes -ne $Null) {
                $config.routes = $routes
            }
            if ($rules -ne $Null) {
                $config.rules = $rules
            }
            if ($tags -ne $Null) {
                $config.tags = $tags
            }
            if ($capabilities -ne $Null) {
                $config.capabilities = $capabilities
            }
            if ($authTokens -ne $Null) {
                $config.authTokens = $authTokens
            }
            if ($v4AssignMode -ne $Null) {
                $config.v4AssignMode = $v4AssignMode
            }
            if ($v6AssignMode -ne $Null) {
                $config.v6AssignMode = $v6AssignMode
            }
            if ($dns -ne $Null) {
                $config.dns = $dns
            }

            $Body = @{
                config = $config
                description = $description
                ui = $ui
                tagsByName = $tagsByName
                capabilitiesByName = $capabilitiesByName
                rulesSource = $rulesSource
                permissions = $permissions
            }
        }
        else{
            $Body = @{
                config = @{
                       name = $name
                       private = $private
                       multicastLimit = $multicastLimit
                       routes = $routes
                       rules = $rules
                       tags = $tags
                       capabilities = $capabilities
                       authTokens = $authTokens
                       v4AssignMode = $v4AssignMode
                       v6AssignMode = $v6AssignMode
                       dns = $dns
                       }
                description = $description
                ui = $ui
                tagsByName = $tagsByName
                capabilitiesByName = $capabilitiesByName
                rulesSource = $rulesSource
                permissions = $permissions
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
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true)]
        [string]$id,
        [parameter(
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true)]
        [array]$node
    )

    Begin {
        Write-Debug "BEGIN: Add-ZeroTierMember"
    }

    Process {
        Write-Debug "PROCESS: Add-ZeroTierMember"

        Set-ZeroTierNetwork -id $id -authTokens $node

    }

    End {
        Write-Debug "END: Add-ZeroTierMember"
    }

}

function Get-ZeroTierMember {
    [cmdletbinding()]
    param (
        [parameter(
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true)]
        [string]$id,
        [parameter(
            Mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        [string]$node
    )

    Begin {
        Write-Debug "BEGIN: Get-ZeroTierMember"
    }

    Process {
        Write-Debug "PROCESS: Get-ZeroTierMember"

        # if no node is provided, zerotier will return all members.
        $Path = "/network/$id/member/$node"
        if ($node -eq "" -or $node -eq $Null) {
            $Path = "/network/$id/member"
        }
        
        [array]$Return = Invoke-ZeroTierAPI $Path
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
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true)]
        [string]$id,
        [parameter(
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true)]
        [Alias("nodeId")]
        [string]$node,
        [parameter(
            Mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        $hidden,
        [parameter(
            Mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        $name,
        [parameter(
            Mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        $description,
        [parameter(
            Mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        $offlineNotifyDelay,
        [parameter(
            Mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        $config,
        [parameter(
            Mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        $authorized,
        [parameter(
            Mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        $capabilities,
        [parameter(
            Mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        $ipAssignments,
        [parameter(
            Mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        $noAutoAssignIps,
        [parameter(
            Mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        $networkId
    )

    Begin {
        Write-Debug "BEGIN: Set-ZeroTierMember"

    }

    Process {
        Write-Debug "PROCESS: Set-ZeroTierMember"

        # if we're piping from Get-ZeroTierMember, the networkId is the trusted Id as $id will be overloaded with a contatenation of the networkid and the node id :(
        $Path = "/network/$id/member/$node"
        if ($networkID) {
            $Path = "/network/$networkId/member/$node" 
        }

        if ($config) {
            # nested config options get overwritten if $config is piped from another command
            if ($authorized -ne $Null) {
                $config.authorized = $authorized
            }
            if ($capabilities -ne $Null) {
                $config.capabilities = $capabilities
            }
            if ($tags -ne $Null) {
                $config.tags = $tags
            }
            if ($ipAssignments -ne $Null) {
                $config.ipAssignments = $ipAssignments
            }
            if ($offlineNotifyDelay -ne $Null) {
                $config.offlineNotifyDelay = $offlineNotifyDelay
            }

            $Body = @{
                config = $config
                description = $description
                hidden = $hidden
                name = $name
                offlineNotifyDelay = $offlineNotifyDelay
            }
        }
        else{
            $Body = @{
                config = @{
                       authorized = $authorized
                       capabilities = $capabilities
                       tags = $tags
                       ipAssignments = $ipAssignments
                       noAutoAssignIps = $noAutoAssignIps
                       }
                description = $description
                hidden = $hidden
                name = $name
                offlineNotifyDelay = $offlineNotifyDelay
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
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true)]
        [string]$id,
        [parameter(
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true)]
        [Alias("nodeId")]
        [string]$node,
        [parameter(
            Mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        $networkId
        )

        # if we're piping from Get-ZeroTierMember, the networkId is the trusted Id as $id will be overloaded with a contatenation of the networkid and the node id :(
        if ($networkID) {
            $id = $networkId
        }

        Set-ZeroTierMember -id $id -node $node -authorized $true

}

function Disable-ZeroTierMember {

    param (
        [parameter(
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true)]
        [string]$id,
        [parameter(
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true)]
        [Alias("nodeId")]
        [string]$node,
        [parameter(
            Mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        $networkId
        )

        # if we're piping from Get-ZeroTierMember, the networkId is the trusted Id as $id will be overloaded with a contatenation of the networkid and the node id :(
        if ($networkID) {
            $id = $networkId
        }

        Set-ZeroTierMember -id $id -node $node -authorized $false

}