
function New-FimSchemaBinding
{
    [CmdletBinding()]
   	param
  	(
        [parameter(Mandatory=$true)]
        [ValidateScript({ ($_ -is [Guid]) -or ($_ -is [String]) })]
   		$ObjectType, 
        [parameter(Mandatory=$true)]
        [ValidateScript({ ($_ -is [Guid]) -or ($_ -is [String]) })]
		$AttributeType, 
        [parameter(Mandatory=$false)]
        [Switch]
		$Required = $false,
        [parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string]
		$DisplayName = $AttributeType,
        [parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
	    [String]
		$Description,
        <#
	    .PARAMETER Uri
	    The Uniform Resource Identifier (URI) of themmsshortService. The following example shows how to set this parameter: -uri "http://localhost:5725"
	    #>
        [parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
	    [String]
	    $Uri = "http://localhost:5725"

   	)     
	if (Get-FimSchemaBinding $AttributeType $ObjectType $Uri)
	{
		Write-Warning "Binding Already Exists for $objectType and $attributeType"
        return
	}

    $changeSet = @{
        DisplayName	= $DisplayName 
        Required	= $Required.ToBool()
    }
    
    if ($Description)
    {
        $changeSet.Add("Description", $Description)
    }

    if ($ObjectType -is [Guid])
    {
        $changeSet.Add("BoundObjectType", $ObjectType)
    }
    elseif ($ObjectType -is [String])
    {
        $changeSet.Add("BoundObjectType", ('ObjectTypeDescription', 'Name', $ObjectType))
    }
    else
    {
        throw "Unsupported input format for -ObjectType"
    }

    if ($AttributeType -is [Guid])
    {
        $changeSet.Add("BoundAttributeType", $ObjectType)
    }
    elseif ($AttributeType -is [String])
    {
        $changeSet.Add("BoundAttributeType", ('AttributeTypeDescription', 'Name', $AttributeType))
    }
    else
    {
        throw "Unsupported input format for -AttributeType"
    }

    New-FimImportObject -ObjectType BindingDescription -State Create -Uri $Uri -Changes $changeSet -SkipDuplicateCheck -ApplyNow 
} 
