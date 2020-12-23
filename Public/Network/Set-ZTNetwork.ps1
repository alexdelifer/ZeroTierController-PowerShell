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
    # require network id to modify
    $Path = "/network/$Id"
    if ($null -ne $NetworkID) {
        $Path = "/network/$NetworkID"
    }
    
    # https://my.zerotier.com/central-api.html#network-network-post

    $Body = @{}
    # Config
    if ($Null -ne $Config) { $Body.Config = $Config }
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
    if ($Null -ne $Description) { $Body.Description = $Description }
    if ($Null -ne $Ui) { $Body.Ui = $Ui }
    if ($Null -ne $TagsByName) { $Body.TagsByName = $TagsByName }
    if ($Null -ne $CapabilitiesByName) { $Body.CapabilitiesByName = $CapabilitiesByName }
    if ($Null -ne $RulesSource) { $Body.RulesSource = $RulesSource }
    if ($Null -ne $Permissions) { $Body.Permissions = $Permissions }

    Write-Debug ($Body | ConvertTo-Json -Depth 10 )
    Invoke-ZTAPI -Path $Path -Body $Body -Method "POST"

}