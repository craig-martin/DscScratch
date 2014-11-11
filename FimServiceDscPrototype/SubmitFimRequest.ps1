function Submit-FimRequest
{
<#
.SYNOPSIS 
Sumits a FIM ImportObject to the server using Import-FimConfig

.DESCRIPTION
The Submit-FimRequest function makes it easier to use Import-FimConfig by optionally waiting for the request to complete
The function submits the request, then searches FIM for the Request.
   
.EXAMPLE
$importCraigFoo = New-FimImportObject -ObjectType Person -State Create -Changes @{DisplayName='CraigFoo';AccountName='CraigFoo'} 
$importCraigFoo | Submit-FimRequest -Wait -Verbose

VERBOSE: FIM reported the object is pending authorization:
While creating a new object, the web service reported the object is pending authorization.  The import cannot continue until the object exists.  Please approve the object and then replace all subsequent references to this object with its object id.  Once the references are up to date, please resume the import by providing the output from this stream as input.

Request ID = urn:uuid:eff37dbb-9bdf-4c8b-8aa3-b246f28de411
ObjectType = Person
SourceObjectID = d4cfbffb-1c51-40b8-83f6-894318b6722c
VERBOSE: Number of pending requests: 1
VERBOSE: Number of pending requests: 1
VERBOSE: Number of pending requests: 1
VERBOSE: Number of pending requests: 1
	
DESCRIPTION
-----------
Creates an ImportObject then submits it to this function, and waits for the request to finish

#>

	param
	( 
	[parameter(Mandatory=$true, ValueFromPipeline = $true)]
	[Microsoft.ResourceManagement.Automation.ObjectModel.ImportObject]	
	$ImportObject,

    [switch]
    $Wait = $false,
	
	[System.Management.Automation.PSCredential]
	$Credential,

	[parameter(Mandatory=$false)]
	$RefreshIntervalInSeconds = 5 
	)
	begin
	{
		if ($Credential)
		{
			### Dirty trick for force the FIM cmdlets to use the supplied Creds
			Export-FimConfig -only -custom "/Person[DisplayName='hoofhearted']" -credential $Credential -ErrorAction SilentlyContinue | Out-Null
		}
	}
	process
	{
        try
        {
            Import-FIMConfig $ImportObject -ErrorAction Stop | Out-Null
        } ### CLOSING: Try
        catch
        {
            if ($_.Exception.Message -ilike '*While creating a new object, the web service reported the object is pending authorization*')
            {
                Write-Verbose ("FIM reported the object is pending authorization:`n`t {0}" -f $_.Exception.Message) 
                $requestGuid = $_.Exception.Message | 
                    Select-String  -pattern "Request ID = urn:uuid:[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}" |
                    Select-Object -ExpandProperty Matches |                
                    Select-Object -First 1 |
                    Select-Object -ExpandProperty value | 
                    ForEach-Object {$_ -replace 'Request ID = urn:uuid:'}
            }
        }### CLOSING: Catch               
        
        ###
        ### Get the Request
        ###
        if ($requestGuid)
        {
            $xpathFilter = @"
            /Request
            [
                    ObjectID='{0}'
                and RequestStatus != 'Denied' 
    			and RequestStatus != 'Failed' 
    			and RequestStatus != 'Canceled' 
    			and RequestStatus != 'CanceledPostProcessing' 
    			and RequestStatus != 'PostProcessingError' 
    			and RequestStatus != 'Completed' 
            ]
"@ -F $requestGuid
        }
        elseif ($ImportObject.TargetObjectIdentifier -ne [Guid]::Empty)
        {
            $xpathFilter = @" 
                /Request 
    			[ 
    			Target='{0}'
    			and RequestStatus != 'Denied' 
    			and RequestStatus != 'Failed' 
    			and RequestStatus != 'Canceled' 
    			and RequestStatus != 'CanceledPostProcessing' 
    			and RequestStatus != 'PostProcessingError' 
    			and RequestStatus != 'Completed' 
    			] 
"@ -F $ImportObject.TargetObjectIdentifier.Replace('urn:uuid:','')
        }
        else
        {
            $xpathFilter = @" 
                /Request 
    			[ 
    			TargetObjectType   = '{0}'
                and Operation      = 'Create'
    			and RequestStatus != 'Denied' 
    			and RequestStatus != 'Failed' 
    			and RequestStatus != 'Canceled' 
    			and RequestStatus != 'CanceledPostProcessing' 
    			and RequestStatus != 'PostProcessingError' 
    			and RequestStatus != 'Completed' 
    			] 
"@ -F $ImportObject.ObjectType, $ImportObject.State
        }
   
		if (-not $Wait)
		{
			Export-FIMConfig -OnlyBaseResources -CustomConfig $xpathFilter | Convert-FimExportToPSObject	
		} 
		else
		{
			###
			### Loop while the Request.RequestStatus is not any of the Final status values
			###
			do{
				###
				### Get the FIM Request object by querying for a Request using the xPath we constructed
				###            
				$requests = Export-FIMConfig -OnlyBaseResources -CustomConfig $xpathFilter

				if ($requests -ne $null)
				{
					Write-Verbose ("Number of pending requests: {0}" -f @($requests).Count)
					Start-Sleep -Seconds $RefreshIntervalInSeconds
				}
			} 
			while ($requests -ne $null)
		}
	}### CLOSING: process 
}### CLOSING: function Submit-FimRequest
