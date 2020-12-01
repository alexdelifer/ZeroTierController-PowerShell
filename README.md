# ZeroTierController-PowerShell
A PowerShell library to interact with the ZeroTier Network Controller API

## Getting Started
1. Get an API Token from [ZeroTier](https://my.zerotier.com/account)
1. Enter that API Token into a new file you create in your home directory called `.zerotier-api-token`
    ```PowerShell
    notepad $env:USERPROFILE\.zerotier-api-token
    ```
1. Use `Import-Module .\ZeroTierController.psm1` in a PowerShell window or a script to use the included commands.

## Commands

- Get-ZeroTierStatus
- Get-ZeroTierNetwork
- Set-ZeroTierNetwork
- Get-ZeroTierMember
- Set-ZeroTierMember
- Enable-ZeroTierMember
- Disable-ZeroTierMember

## References

[ZeroTier API Help](https://my.zerotier.com/help/api)
