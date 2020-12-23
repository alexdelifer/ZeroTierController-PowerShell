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