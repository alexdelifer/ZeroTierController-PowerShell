function ConvertTo-PascalCase {
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName)]
        [string]
        $String
    )
    # Not the best, but want to preserve AllowUpperCase inside of words, .ToTitleCase doesn't preserve that
    $String.substring(0, 1).toupper() + $String.substring(1)
}