function Get-ZTToken {
    try {
        if ( Test-Path $TokenPath ) {
            $ZTToken = Get-Content $TokenPath | ConvertTo-SecureString -Force
        }
        else {
            Write-Host "Please provide an API Key"
            Write-Host "See https://my.zerotier.com/account for more info."
            Write-Error "No API token found, please provide an API token." -ErrorAction Stop
        }
        # Resolving securestrings is intentionally obtuse 
        $creds = New-Object System.Management.Automation.PsCredential -ArgumentList "ZEROTIER TOKEN", $ZTToken
        $creds.GetNetworkCredential().Password
    }
    catch {
        Set-ZTToken
        Get-ZTToken
    }
}