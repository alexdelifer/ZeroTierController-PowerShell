function ConvertTo-CamelCaseProperty {
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName)]
        [pscustomobject]
        $Object
    )

    $Object = [pscustomobject]$Object
    
    $Object | ForEach-Object {
        $NewObject = [ordered]@{}
        $_.psobject.properties | ForEach-Object {
            $NewPropertyName = $_.Name | ConvertTo-CamelCase
            $NewObject[$NewPropertyName] = $_.Value

            # Let's get recursive :)
            Write-Debug $_.TypeNameOfValue 
            if ($_.TypeNameOfValue -eq "System.Management.Automation.PSCustomObject" `
                    -or $_.TypeNameOfValue -eq "System.Collections.Hashtable" ) {
                $NewObject[$NewPropertyName] = $_.Value | ConvertTo-CamelCaseProperty
            }
            <#             elseif ($_.TypeNameOfValue -eq "System.Object[]" ) {
                $NewObject[$NewPropertyName] = $_.Value | ForEach-Object { $_ | ConvertTo-CamelCaseProperty }
            } #>

        }
        # Output
        [pscustomobject]$NewObject

    }
}