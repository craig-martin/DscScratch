function Get-FimObjectByXPath
{
    param
    (
        [parameter(Mandatory = $true)]
        [string]
        $Filter,
        [string]
        $Uri = "http://localhost:5725",
        $Credential
    )
    if ($PSBoundParameters.ContainsKey('Credential'))
    {
        Export-FimConfig -Only -Custom $Filter -Uri $Uri -Credential $Credential | Convert-FimExportToPSObject
    }
    else
    {
        Export-FimConfig -Only -Custom $Filter -Uri $Uri | Convert-FimExportToPSObject
    }
}
