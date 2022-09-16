@{
    RootModule        = 'ZeroTierController.psm1'
    ModuleVersion     = '1.2-rc1'
    GUID              = '66556311-ed05-4b5c-95c8-5e7d027d78e3'
    Author            = 'Alex Delifer'
    Description       = 'Interact with the ZeroTier Controller API from PowerShell'
    FunctionsToExport = @(
        "Add-ZTMember",
        "Remove-ZTMember",
        "Disable-ZTMember",
        "Enable-ZTMember",
        "Get-ZTMember",
        "Get-ZTNetwork",
        "Get-ZTStatus",
        "Set-ZTMember",
        "Set-ZTNetwork",
        "Set-ZTToken"
    )
    PrivateData       = @{
        PSData = @{
            ProjectUri   = 'https://github.com/alexdelifer/ZeroTierController-PowerShell'
            ReleaseNotes = 'ZeroTier is cool'
        }
    }
}