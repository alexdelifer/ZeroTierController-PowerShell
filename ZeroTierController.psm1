﻿# Definitions
#[string]$Node = ""
#[string]$Id = ""

#Get public and private function definition files.
$Public = @( Get-ChildItem -Path $PSScriptRoot\Public\*\*.ps1 -ErrorAction SilentlyContinue )
$Private = @( Get-ChildItem -Path $PSScriptRoot\Private\*\*.ps1 -ErrorAction SilentlyContinue )

#Dot source the files
Foreach ($import in @($Public + $Private)) {
    Try {
        . $import.fullname
    }
    Catch {
        Write-Error -Message "Failed to import function $($import.fullname): $_"
    }
}

# Here I might...
# Read in or create an initial config file and variable
# Export Public functions ($Public.BaseName) for WIP modules
# Set variables visible to the module and its functions only

[string]$Url = "https://my.zerotier.com/api"
[string]$TokenPath = "$env:USERPROFILE\.zerotier-api-token"

# Control what's exposed thru the psd1
Export-ModuleMember -Function $Public.Basename
Export-ModuleMember -Function $Private.Basename