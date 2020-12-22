function ConvertTo-PascalCaseProperty {
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
            $NewPropertyName = $_.Name | ConvertTo-PascalCase
            $NewObject[$NewPropertyName] = $_.Value

            # Let's get recursive :)
            Write-Debug $_.TypeNameOfValue 
            if ($_.TypeNameOfValue -eq "System.Management.Automation.PSCustomObject" `
                    -or $_.TypeNameOfValue -eq "System.Collections.Hashtable" ) {
                $NewObject[$NewPropertyName] = $_.Value | ConvertTo-PascalCaseProperty
            }
            <#             elseif ($_.TypeNameOfValue -eq "System.Object[]" ) {
                $NewObject[$NewPropertyName] = [object[]]$_.Value | ForEach-Object { $_ | ConvertTo-PascalCaseProperty }
            } #>

        }
        # Output
        [pscustomobject]$NewObject

    }
}
