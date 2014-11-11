$ProgressPreference = 0

function New-FimSchemaAttribute
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
        [parameter(Mandatory=$true)]
        [ValidateSet("Binary","Boolean","DateTime","Integer","String","Reference","Text")]
        [String]
		$DataType,
        [parameter(Mandatory=$false)]
        [switch]
		$Multivalued = $false,
        [parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Description,
        [parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
	    [String]
	    $Uri = "http://localhost:5725",
        [parameter(Mandatory=$false)]
        [Switch]
        $PassThru = $false
   	)     

    $changeSet= @{
		DisplayName = $DisplayName
		Name		= $Name
		DataType	= $DataType
		Multivalued	= $Multivalued.ToBool()
    }

    if ($Description)
    {
        $changeSet.Add("Description", $Description)
    }

    New-FimImportObject -ObjectType AttributeTypeDescription -State Create -Uri $Uri -Changes $changeSet -ApplyNow

    if ($PassThru.ToBool())
    {
        Write-Output ([guid](Get-FimObjectID -ObjectType AttributeTypeDescription -AttributeName Name -AttributeValue $Name -Uri $Uri))
    }
} 
 
