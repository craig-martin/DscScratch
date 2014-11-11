function New-FimSearchScope
{
    [CmdletBinding()]
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
        [parameter(Mandatory = $true)]
        [ValidateRange(0, 100000)]
        [Int]
        $Order,
        
        [parameter(Mandatory = $true)]
        [ValidateCount(1, 100)]
        [string[]]
        $AttributesToSearch,
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Filter, ##
        [parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ResultType = "Resource",
        [parameter(Mandatory = $false)]
        [ValidateCount(1, 100)]
        [string[]]
        $AttributesToDisplay,
        [parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]
        $RedirectingUrl,

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
        $changeSet = @(
            New-FimImportChange -Operation Replace -AttributeName "DisplayName" -AttributeValue $DisplayName
            New-FimImportChange -Operation Replace -AttributeName "Order" -AttributeValue $Order
            New-FimImportChange -Operation Replace -AttributeName "SearchScope" -AttributeValue $Filter
            New-FimImportChange -Operation Replace -AttributeName "SearchScopeResultObjectType" -AttributeValue $ResultType            
            New-FimImportChange -Operation Replace -AttributeName "SearchScopeColumn" -AttributeValue ($AttributesToDisplay -join ";")
            New-FimImportChange -Operation Replace -AttributeName "IsConfigurationType" -AttributeValue $true
        )

        if ($RedirectingUrl)
        {
            $changeSet += New-FimImportChange -Operation Replace -AttributeName "SearchScopeTargetURL" -AttributeValue $RedirectingUrl
        }

        if ($Description)
        {
            $changeSet += New-FimImportChange -Operation Replace -AttributeName "Description" -AttributeValue $Description
        }

        foreach ($keyword in $UsageKeywords)
        {
            $changeSet += New-FimImportChange -Operation Add -AttributeName "UsageKeyword" -AttributeValue $keyword
        }

        foreach ($attr in $AttributesToSearch)
        {
            $changeSet += New-FimImportChange -Operation Add -AttributeName "SearchScopeContext" -AttributeValue $attr
        }

        New-FimImportObject -ObjectType SearchScopeConfiguration -State Create -Changes $changeSet -Uri $Uri -ApplyNow

        if ($PassThru.ToBool())
        {
            Write-Output (Get-FimObjectID -ObjectType SearchScopeConfiguration -AttributeName DisplayName -AttributeValue $DisplayName)
        }
    }
}

