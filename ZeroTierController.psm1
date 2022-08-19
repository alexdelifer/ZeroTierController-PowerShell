# Settings
#custom controller
if($Global:zturl){ #if variable zturl is set, treat this as a custom controller
    [string]$Url=$zturl
    [bool]$customcontroller=$true
}else{
    [string]$Url = "https://my.zerotier.com/api"
}
#setup token paths
if($IsLinux -or $IsMacOS){
    [string]$TokenPath = "$env:HOME/.zerotier-api-token"
}else{
    #windows
    [string]$TokenPath = "$env:USERPROFILE\.zerotier-api-token"
}


# Definitions
[string]$Node = ""
[string]$Id = ""


# Internal Functions

function Get-ZTToken {
    
    if ( Test-Path $TokenPath ) {
        $ZTToken = Get-Content $TokenPath | ConvertTo-SecureString -Force
    }
    else {
        Write-Host -ForegroundColor Red "No API token found, please populate $TokenPath with an API token."
        Throw (Get-Content $TokenPath)
    }
    # Resolving securestrings is intentionally obtuse 
    $creds = New-Object System.Management.Automation.PsCredential -ArgumentList "ZEROTIER TOKEN", $ZTToken
    $creds.GetNetworkCredential().Password
}

function Set-ZTToken {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $Token
    )
    [securestring]$SecureToken = $Token | ConvertTo-SecureString -AsPlainText -Force
    $SecureToken | ConvertFrom-SecureString | Set-Content -Path $TokenPath
    
}

# Support Functions
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

function Invoke-ZTAPI {
    
    param (
        [parameter(
            Mandatory)]
        [string]$Path,
        [parameter()]
        $Body,
        [parameter()]
        [string]$Method = "GET"
    )

    if ($Body) {
        Write-Debug "Pre $($Body | ConvertTo-Json -Depth 10)"
        #$Method = "POST"
        # Sanitize our inputs
        [PSCustomObject]$Body = $Body | ForEach-Object { $_ | ConvertTo-CamelCaseProperty } 
        #$Body = $Body.SyncRoot
        $Body = $Body | ConvertTo-Json -Depth 10
        Write-Debug "Post $Body"
    }
    if($customcontroller){
        $apiargs = @{
            Uri         = "$Url$Path"
            Headers     = @{ "X-ZT1-Auth" = "$(Get-ZTToken)" } #with custom controller token from authtoken.secret is used.
            Method      = $Method
            Body        = $Body
            ContentType = 'application/json'
            ErrorAction = 'Stop'
        }
    }else{
        $apiargs = @{
            Uri         = "$Url$Path"
            Headers     = @{ "Authorization" = "Bearer $(Get-ZTToken)" }
            Method      = $Method
            Body        = $Body
            ContentType = 'application/json'
            ErrorAction = 'Stop'
        }
    }

    

    try {
        # Do the magic
        $Output = Invoke-RestMethod @apiargs
        # Clean up the output
        [PSCustomObject]$Output | ForEach-Object { $_ | ConvertTo-PascalCaseProperty }
    }
    catch {
        Write-Error "There was an issue with the ZeroTier API"
        Throw
    }


} 

# Public Functions

function Get-ZTStatus {

    [array]$Return = Invoke-ZTAPI '/status'

    #region Define the VISIBLE properties
    # this is the list of properties visible by default
    [string[]]$Visible = 'Online', 'ClusterNode', 'ReadOnlyMode', 'Uptime'
    [System.Management.Automation.PSMemberInfo[]]$Info = New-Object System.Management.Automation.PSPropertySet DefaultDisplayPropertySet, $Visible

    # add the information about the visible properties to the return value
    $Return | Add-Member -MemberType MemberSet -Name PSStandardMembers -Value $Info
    #endregion

    Return [array]$Return

}

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

function Set-ZTNetwork {
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
        Write-Debug "BEGIN: Set-ZTNetwork"
    }

    Process {
        Write-Debug "PROCESS: Set-ZTNetwork"
        # require network id to modify
        $Path = "/network/$Id"
        if ($Id -eq "" -or $Id -eq $Null) {
            Write-Host "ID Required for Set-ZTNetwork"
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
        $Return = Invoke-ZTAPI -Path $Path -Body $Body -Method "POST"
        Return $Return
        
    }

    End {
        Write-Debug "END: Set-ZTNetwork"
    }
}

function New-ZTNetwork {
    [cmdletbinding()]
    param (
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

    $Path = "/network"
    Invoke-ZTAPI -Path $Path -Method "POST"
    #$NewNetwork | Set-ZTNetwork @PSBoundParameters
}

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

function Get-ZTMember {
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
        Write-Debug "BEGIN: Get-ZTMember"
    }

    Process {
        Write-Debug "PROCESS: Get-ZTMember"

        # if no node is provided, zerotier will return all members.
        $Path = "/network/$Id/member/$Node"
        if ($Node -eq "" -or $Node -eq $Null) {
            $Path = "/network/$Id/member"
        }
        
        $Return = Invoke-ZTAPI -Path $Path -Method "GET"

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
        Write-Debug "END: Get-ZTMember"
    }


}

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

        #[PSCustomObject]$PSBoundParameters

        Return [pscustomobject]$Return

    }

    End {
        Write-Debug "END: Set-ZTMember"
    }


}

# Shortcuts

function Enable-ZTMember {

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

    # if we're piping from Get-ZTMember, the networkId is the trusted Id as $Id will be overloaded with a contatenation of the networkid and the node id :(
    if ($NetworkID) {
        $Id = $NetworkId
    }

    Set-ZTMember -id $Id -node $Node -authorized $True

}

function Disable-ZTMember {

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

    # if we're piping from Get-ZTMember, the networkId is the trusted Id as $Id will be overloaded with a contatenation of the networkid and the node id :(
    if ($NetworkID) {
        $Id = $NetworkId
    }

    Set-ZTMember -id $Id -node $Node -authorized $False

}