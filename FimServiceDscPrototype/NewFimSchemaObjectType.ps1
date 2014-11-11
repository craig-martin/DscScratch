function New-FimSchemaObjectType
{
    [CmdletBinding()]
    [OutputType([Guid])]
    param
    (
    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $Name, 
    [parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [String]
    $DisplayName = $Name,
    [parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]
    $Description,
    <#
    .PARAMETER Uri
    The Uniform Resource Identifier (URI) of themmsshortService. The following example shows how to set this parameter: -uri "http://localhost:5725"
    #>
    [parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [String]
    $Uri = "http://localhost:5725",
    [parameter(Mandatory=$false)]
    [Switch]
    $PassThru = $false    
    )             

    $changeSet = @{
        DisplayName = $DisplayName
        Name		= $Name
    }

    if ($Description)
    {
        $changeSet.Add("Description", $Description)
    }
    

    New-FimImportObject -ObjectType ObjectTypeDescription -State Create -Uri $Uri -Changes $changeSet -ApplyNow   
    
    if ($PassThru.ToBool())
    {
        Write-Output ([guid](Get-FimObjectID -ObjectType ObjectTypeDescription -AttributeName Name -AttributeValue $Name))
    }
} 

function Get-FimSchemaBinding
{
  	Param
   	(        
	    [parameter(Mandatory=$false)]
        [String]		
        $AttributeType,
		
	    [parameter(Mandatory=$false)]
        [String]		
        $ObjectType,
        <#
	    .PARAMETER Uri
	    The Uniform Resource Identifier (URI) of the FIM Service; defaults to -uri "http://localhost:5725"
	    #>
	    [String]
	    $Uri = "http://localhost:5725"

    )
    if ($PSBoundParameters.ContainsKey("AttributeType"))
    {  
	    $attributeTypeID 	= Get-FimObjectID AttributeTypeDescription 	Name $AttributeType
    }
    if ($PSBoundParameters.ContainsKey("ObjectType"))
    {
        $objectTypeID 		= Get-FimObjectID ObjectTypeDescription 	Name $ObjectType
    }
	
    if ($PSBoundParameters.ContainsKey("AttributeType") -and $PSBoundParameters.ContainsKey("ObjectType"))
    {
        $xPathFilter = "/BindingDescription[BoundObjectType='{0}' and BoundAttributeType='{1}']" -f $objectTypeID, $attributeTypeID
    }
    elseif ($PSBoundParameters.ContainsKey("AttributeType"))
    {
        $xPathFilter = "/BindingDescription[BoundAttributeType='{0}']" -f $attributeTypeID
    }
    elseif ($PSBoundParameters.ContainsKey("ObjectType"))
    {
        $xPathFilter = "/BindingDescription[BoundObjectType='{0}']" -f $objectTypeID
    }
    else
    {
        $xPathFilter = "/BindingDescription"
    }

    Export-FIMConfig -OnlyBaseResources -CustomConfig $xPathFilter -Uri $Uri | Convert-FimExportToPSObject           
}
