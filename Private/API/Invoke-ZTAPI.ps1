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
        # Sanitize our inputs
        [PSCustomObject]$Body = $Body | ForEach-Object { $_ | ConvertTo-CamelCaseProperty } 
        $Body = $Body | ConvertTo-Json -Depth 10
        Write-Debug "Post $Body"
    }

    $apiargs = @{
        Uri         = "$Url$Path"
        Headers     = @{ "Authorization" = "Bearer $(Get-ZTToken)" }
        Method      = $Method
        Body        = $Body
        ContentType = 'application/json'
        ErrorAction = 'Stop'
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