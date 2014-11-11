$ProgressPreference = 0

function New-FimSet
{
    [CmdletBinding()]
    [OutputType([Guid])]
    param
    (
        [String]
        [Parameter(Mandatory = $True)]
        $DisplayName = $Name,
        [Parameter()]
        $Description,
        [Parameter()]
        [String]
        $Filter, ##TODO - make sure we were passed JUST the XPath filter
        [Parameter()]
        [Array]
        $ManuallyManagedMembers,
        [String]
        $Uri = "http://localhost:5725",
        [parameter(Mandatory = $false)]
        [Switch]
        $PassThru = $true
    )
    $changeSet = @()
    $changeSet += New-FimImportChange -Operation Replace -AttributeName "DisplayName" -AttributeValue $DisplayName
    
    if ([String]::IsNullOrEmpty($Description) -eq $false)
    {
        $changeSet += New-FimImportChange -Operation Replace -AttributeName "Description" -AttributeValue $Description
    }
    
    if ([String]::IsNullOrEmpty($Filter) -eq $false)
    {
        # this is all one line to make the filter backwards compatible with FIM 2010 RTM
        $setXPathFilter = "<Filter xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance' xmlns:xsd='http://www.w3.org/2001/XMLSchema' Dialect='http://schemas.microsoft.com/2006/11/XPathFilterDialect' xmlns='http://schemas.xmlsoap.org/ws/2004/09/enumeration'>{0}</Filter>" -F $Filter
        
        $changeSet += New-FimImportChange -Operation Replace -AttributeName "Filter" -AttributeValue $setXPathFilter
    }
    
    if (($ManuallyManagedMembers -ne $null) -and ($ManuallyManagedMembers.Count -gt 0))
    {
        foreach ($m in $ManuallyManagedMembers)
        {
            $changeSet += New-FimImportChange -Operation Add -AttributeName "ExplicitMember" -AttributeValue $m
        }
    }
    
    New-FimImportObject -ObjectType Set -State Create -Uri $Uri -Changes $changeSet -ApplyNow
    
    if ($PassThru.ToBool())
    {
        Write-Output (Get-FimObjectId -ObjectType Set -AttributeName DisplayName -AttributeValue $DisplayName)
    }
}
