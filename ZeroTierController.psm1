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

# Support Functions
# TODO: Figure out how to not expose these, I think we can do that with the manifest :)
function ConvertTo-PascalCase {
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName)]
        [string]
        $String
    )
    # Not the best, but want to preserve AllowUpperCase inside of words, .ToTitleCase doesn't preserve that
    $String.substring(0, 1).toupper() + $String.substring(1)
}

function ConvertTo-CamelCase {
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName)]
        [string]
        $String
    )
    $String.substring(0, 1).tolower() + $String.substring(1)
}


function ConvertTo-PascalCaseProperty {
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName)]
        [pscustomobject]
        $Object
    )

    $Object = [pscustomobject]$Object
    
    $Object | ForEach-Object {
        $NewObject = [ordered]@{}
        $_.psobject.properties | ForEach-Object {
            $NewPropertyName = $_.Name | ConvertTo-PascalCase
            $NewObject[$NewPropertyName] = $_.Value

            # Let's get recursive :)
            Write-Debug $_.TypeNameOfValue 
            if ($_.TypeNameOfValue -eq "System.Management.Automation.PSCustomObject" `
                    -or $_.TypeNameOfValue -eq "System.Collections.Hashtable" ) {
                $NewObject[$NewPropertyName] = $_.Value | ConvertTo-PascalCaseProperty
            }
            <#             elseif ($_.TypeNameOfValue -eq "System.Object[]" ) {
                $NewObject[$NewPropertyName] = [object[]]$_.Value | ForEach-Object { $_ | ConvertTo-PascalCaseProperty }
            } #>

        }
        # Output
        [pscustomobject]$NewObject

    }
}

function ConvertTo-CamelCaseProperty {
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName)]
        [pscustomobject]
        $Object
    )

    $Object = [pscustomobject]$Object
    
    $Object | ForEach-Object {
        $NewObject = [ordered]@{}
        $_.psobject.properties | ForEach-Object {
            $NewPropertyName = $_.Name | ConvertTo-CamelCase
            $NewObject[$NewPropertyName] = $_.Value

            # Let's get recursive :)
            Write-Debug $_.TypeNameOfValue 
            if ($_.TypeNameOfValue -eq "System.Management.Automation.PSCustomObject" `
                    -or $_.TypeNameOfValue -eq "System.Collections.Hashtable" ) {
                $NewObject[$NewPropertyName] = $_.Value | ConvertTo-CamelCaseProperty
            }
            <#             elseif ($_.TypeNameOfValue -eq "System.Object[]" ) {
                $NewObject[$NewPropertyName] = $_.Value | ForEach-Object { $_ | ConvertTo-CamelCaseProperty }
            } #>

        }
        # Output
        [pscustomobject]$NewObject

    }
}

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
    if ($Null -eq $Body -or $Body -eq "") {
        $Method = "GET"
    }
    else {
        Write-Debug "Pre $($Body | ConvertTo-Json -Depth 10)"
        $Method = "POST"
        # Sanitize our inputs
        [PSCustomObject]$Body = $Body | ForEach-Object { $_ | ConvertTo-CamelCaseProperty } 
        #$Body = $Body.SyncRoot
        $Body = $Body | ConvertTo-Json -Depth 10
        Write-Debug "Post $Body"
    }

    $apiargs = @{
        Uri         = "$Url$Path"
        Headers     = @{ "Authorization" = "Bearer $ZeroTierToken" }
        Method      = $Method
        Body        = $Body
        ContentType = 'application/json'
    }
    

    # Do the magic
    $Output = Invoke-RestMethod @apiargs
    # Clean up the output
    [PSCustomObject]$Output | ForEach-Object { $_ | ConvertTo-PascalCaseProperty }

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

        [pscustomobject]$Return = Invoke-ZeroTierAPI $Path

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

        $Body = @{}
        # Config
        if ($Null -ne $Name) { $Body.Config += @{Name = $Name } }
        if ($Null -ne $Private) { $Body.Config += @{Private = $Private } }
        if ($Null -ne $MulticastLimit) { $Body.Config += @{MulticastLimit = $MulticastLimit } }
        if ($Null -ne $Routes) { $Body.Config += @{Routes = $Routes } }
        if ($Null -ne $Rules) { $Body.Config += @{Rules = $Rules } }
        if ($Null -ne $Tags) { $Body.Config += @{Tags = $Tags } }
        if ($Null -ne $Capabilities) { $Body.Config += @{Capabilities = $Capabilities } }
        if ($Null -ne $AuthTokens) { $Body.Config += @{AuthTokens = $AuthTokens } }
        if ($Null -ne $V4AssignMode) { $Body.Config += @{V4AssignMode = $V4AssignMode } }
        if ($Null -ne $V6AssignMode) { $Body.Config += @{V6AssignMode = $V6AssignMode } }
        if ($Null -ne $Dns) { $Body.Config += @{Dns = $Dns } }
        # Main
        if ($Null -ne $Description) { $Body.Description += $Description }
        if ($Null -ne $Ui) { $Body.Ui += $Ui }
        if ($Null -ne $TagsByName) { $Body.TagsByName += $TagsByName }
        if ($Null -ne $CapabilitiesByName) { $Body.CapabilitiesByName += $CapabilitiesByName }
        if ($Null -ne $RulesSource) { $Body.RulesSource += $RulesSource }
        if ($Null -ne $Permissions) { $Body.Permissions += $Permissions }

        Write-Debug ($Body | ConvertTo-Json -Depth 10 )
        [array]$Return = Invoke-ZeroTierAPI -Path $Path -Body $Body
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
        [pscustomobject]$Return = Invoke-ZeroTierAPI -Path $Path -Body $Body

        #[PSCustomObject]$PSBoundParameters

        Return [pscustomobject]$Return

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