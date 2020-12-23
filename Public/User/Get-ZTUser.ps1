function Get-ZTUser {
    [cmdletbinding()]
    param (
        [parameter(
            Mandatory,
            ValueFromPipelineByPropertyName)]
        [string]$Id,
        [parameter(
            ValueFromPipelineByPropertyName)]
        $UserId
    )
    $Path = "/network/$Id/users"
    # if no user is provided, zerotier will return all users,
    # you cannot specify a user on the per network users endpoint
    #$Path = "/network/$Id/users/$UserId"

    try { $Return = Invoke-ZTAPI -Path $Path -Method "GET" -ErrorAction Stop }
    catch {throw}
    

    # The users seem to be stored in a weird table where the userId is a property.
    # Let's expand that to make it more usable.
    $Return.Users.PSObject.Properties | ForEach-Object { 
        $Obj = $_.Value
        # Replace Id with UserId for sanity
        $Obj | Add-Member -MemberType NoteProperty -Name UserId -Value $Obj.Id
        $obj.PSObject.Properties.Remove('Id')
        # Add the NetworkId as Id so we can work with it later
        $Obj | Add-Member -MemberType NoteProperty -Name Id -Value $Id
        # Permissions have the same deal but they're in a different table
        $Return.Permissions.PSObject.Properties | ForEach-Object { 
            if ($_.Name -eq $Obj.UserId) {
                $Obj | Add-Member -MemberType NoteProperty -Name Permissions -Value $_.Value
            } 
        }

        [string[]]$Visible = 'Email', 'UserId', 'Permissions', 'Id'
        [System.Management.Automation.PSMemberInfo[]]$Info = New-Object System.Management.Automation.PSPropertySet DefaultDisplayPropertySet, $Visible
        $Obj | Add-Member -MemberType MemberSet -Name PSStandardMembers -Value $Info
        
        # Since we can't snipe the user we want, only return the user we requested here
        if ($null -ne $UserId) {
            if ($UserId -eq $Obj.UserId) { $Obj }
        }
        else { $Obj }
        
        #$Obj
    }
}