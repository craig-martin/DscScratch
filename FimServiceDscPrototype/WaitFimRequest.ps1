Function Wait-FimRequest
{
   	Param
    ( 
        [parameter(Mandatory=$true, ValueFromPipeline = $true)]
        [Microsoft.ResourceManagement.Automation.ObjectModel.ImportObject]
        [ValidateScript({$_.TargetObjectIdentifier -like "urn:uuid:*"})]
        $ImportObject,
        
        [parameter(Mandatory=$false)]
        $RefreshIntervalInSeconds = 5,
        
        <#
	    .PARAMETER Uri
	    The Uniform Resource Identifier (URI) of themmsshortService. The following example shows how to set this parameter: -uri "http://localhost:5725"
	    #>
	    [String]
	    $Uri = "http://localhost:5725"   
    )
    Process
    { 
        ###
    	### Loop while the Request.RequestStatus is not any of the Final status values
        ###
    	Do{
            ###
            ### Get the FIM Request object by querying for a Request by Target
            ###
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
            
    	    $requests = Export-FIMConfig -Uri $Uri -OnlyBaseResources -CustomConfig $xpathFilter
    	    
    	    if ($requests -ne $null)
    	    {
    	        Write-Verbose ("Number of pending requests: {0}" -F $requests.Count)
    	        Start-Sleep -Seconds $RefreshIntervalInSeconds
    	    }
    	} 
    	While ($requests -ne $null)
    } 
}
