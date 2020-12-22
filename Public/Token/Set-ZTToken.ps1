function Set-ZTToken {
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName
        )]
        [string]
        $Token
    )
    [securestring]$SecureToken = $Token | ConvertTo-SecureString -AsPlainText -Force
    $SecureToken | ConvertFrom-SecureString | Set-Content -Path $TokenPath
    
}