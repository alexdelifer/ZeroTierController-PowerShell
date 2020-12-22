function ConvertTo-CamelCase {
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName)]
        [string]
        $String
    )
    $String.substring(0, 1).tolower() + $String.substring(1)
}