function New-FimNavigationBarLink
{
    [CmdletBinding(DefaultParameterSetName="ChildLink")]
    [OutputType([Guid])]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $DisplayName,
        [parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Description, 
        [parameter(Mandatory = $true)]
        [ValidateCount(1, 100)]
        [string[]]
        $UsageKeywords,

        [parameter(Mandatory = $true, ParameterSetName = "TopLevel")]
        [switch]
        $TopLevel,
        [parameter(Mandatory = $true)]
        [Int]
        $ParentOrder,
        [parameter(Mandatory = $true, ParameterSetName = "ChildLink")]        
        [Int]
        $ChildOrder,
        
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $NavigationUrl,
        [parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ResourceCountFilter,

        [Parameter(Mandatory=$false)]
        [ValidateNotNull()]
        [String]
        $Uri = "http://localhost:5725",
        [parameter(Mandatory=$false)]
        [Switch]
        $PassThru = $false
    )
    begin
    {
        $order = -1

        if ($PSCmdlet.ParameterSetName -eq "Toplevel")
        {
            $order = 0
        }
        else
        {
            $order = $ChildOrder
        }

        $changeSet = @(
            New-FimImportChange -Operation Replace -AttributeName "DisplayName" -AttributeValue $DisplayName
            New-FimImportChange -Operation Replace -AttributeName "NavigationUrl" -AttributeValue $NavigationUrl
            New-FimImportChange -Operation Replace -AttributeName "Order" -AttributeValue $order
            New-FimImportChange -Operation Replace -AttributeName "ParentOrder" -AttributeValue $ParentOrder
            New-FimImportChange -Operation Replace -AttributeName "IsConfigurationType" -AttributeValue $true
        )

        if ($Description)
        {
            $changeSet += New-FimImportChange -Operation Replace -AttributeName "Description" -AttributeValue $Description
        }

        foreach ($keyword in $UsageKeywords)
        {
            $changeSet += New-FimImportChange -Operation Add -AttributeName "UsageKeyword" -AttributeValue $keyword
        }

        if ($ResourceCountFilter)
        {
            $changeSet += New-FimImportChange -Operation Replace -AttributeName "CountXPath" -AttributeValue $ResourceCountFilter
        }

        New-FimImportObject -ObjectType NavigationBarConfiguration -State Create -Uri $Uri -Changes $changeSet -ApplyNow

        if ($PassThru.ToBool())
        {
            Write-Output (Get-FimObjectID -ObjectType NavigationBarConfiguration -AttributeName DisplayName -AttributeValue $DisplayName)
        }
    }
}
