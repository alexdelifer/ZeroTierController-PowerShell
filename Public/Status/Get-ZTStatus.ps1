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