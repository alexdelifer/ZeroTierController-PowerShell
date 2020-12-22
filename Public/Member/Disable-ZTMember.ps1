function Disable-ZTMember {
    param (
        [parameter(
            Mandatory,
            ValueFromPipelineByPropertyName)]
        [string]$Id,
        [parameter(
            Mandatory,
            ValueFromPipelineByPropertyName)]
        [Alias("nodeId")]
        [string]$Node,
        [parameter(
            ValueFromPipelineByPropertyName)]
        $NetworkId
    )
    # if we're piping from Get-ZTMember, the networkId is the trusted Id as $Id will be overloaded with a contatenation of the networkid and the node id :(
    if ($NetworkID) {
        $Id = $NetworkId
    }
    Set-ZTMember -id $Id -node $Node -authorized $False
}