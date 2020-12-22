@{
    RootModule        = 'ZeroTierController.psm1'
    ModuleVersion     = '1.0'
    GUID              = '66556311-ed05-4b5c-95c8-5e7d027d78e3'
    Author            = 'Alex Delifer'
    Description       = 'Interact with the ZeroTier Controller API from PowerShell'
    FunctionsToExport = @(
        "Disable-ZeroTierMember",
        "Enable-ZeroTierMember",
        "Get-ZeroTierMember",
        "Get-ZeroTierNetwork",
        "Get-ZeroTierStatus",
        "Set-ZeroTierMember",
        "Set-ZeroTierNetwork"
    )
    PrivateData       = @{
        PSData = @{
            ProjectUri   = 'https://github.com/alexdelifer/ZeroTierController-PowerShell'
            ReleaseNotes = 'Version 1'
        }
    }
}