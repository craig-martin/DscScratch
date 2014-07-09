function Get-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$DisplayName
	)

	#Write-Verbose "Use this cmdlet to deliver information about command processing."

	#Write-Debug "Use this cmdlet to write debug information while troubleshooting."


	<#
	$returnValue = @{
		DisplayName = [System.String]
		Description = [System.String]
		RunOnPolicyUpdate = [System.Boolean]
		RequestPhase = [System.String]
		Xoml = [System.String]
		Credential = [System.Management.Automation.PSCredential]
		Ensure = [System.String]
	}

	$returnValue
	#>
}


function Set-TargetResource
{
	[CmdletBinding()]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$DisplayName,

		[System.String]
		$Description,

		[System.Boolean]
		$RunOnPolicyUpdate,

		[ValidateSet("Action","Authorization","Authentication")]
		[System.String]
		$RequestPhase,

		[System.String]
		$Xoml,

		[System.Management.Automation.PSCredential]
		$Credential,

		[ValidateSet("Present","Absent")]
		[System.String]
		$Ensure
	)

	#Write-Verbose "Use this cmdlet to deliver information about command processing."

	#Write-Debug "Use this cmdlet to write debug information while troubleshooting."

    $workflow = Get-FimObjectByXPath -Filter "/WorkflowDefinition[DisplayName='$DisplayName']" -Credential $Credential

    if ($Ensure -eq 'Present')
    {
        Write-Verbose "Ensure -eq 'Present'"
        if ($workflow -eq $null)
        {
            Write-Verbose "Workflow is missing, so adding it: $DisplayName"            
            New-FimWorkflowDefinition -DisplayName $DisplayName -Description $Description -RequestPhase $RequestPhase -RunOnPolicyUpdate:$RunOnPolicyUpdate -XOML $Xoml 
        }
        else
        {
            Write-Verbose "Workflow is present, so updating it: $DisplayName"
            #Set-FimSet -Identifier $set.DisplayName -DisplayName $DisplayName -Description $Description -Filter $SetFilter 
        }
    }
    elseif($Ensure -eq 'Absent')
    {
        Write-Verbose "Ensure -eq 'Absent'"
        if ($workflow -ne $null)
        {
            Write-Verbose "Workflow is present, so removing it: $DisplayName"
            New-FimImportObject -ObjectType WorkflowDefinition -State Delete -TargetObjectIdentifier $workflow.ObjectID -ApplyNow
        }
    }


}


function Test-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Boolean])]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$DisplayName,

		[System.String]
		$Description,

		[System.Boolean]
		$RunOnPolicyUpdate,

		[ValidateSet("Action","Authorization","Authentication")]
		[System.String]
		$RequestPhase,

		[System.String]
		$Xoml,

		[System.Management.Automation.PSCredential]
		$Credential,

		[ValidateSet("Present","Absent")]
		[System.String]
		$Ensure
	)

	#Write-Verbose "Use this cmdlet to deliver information about command processing."

	#Write-Debug "Use this cmdlet to write debug information while troubleshooting."
    Write-Verbose "Credential UserName: $($Credential.UserName)"


    $workflow = Get-FimObjectByXPath -Filter "/WorkflowDefinition[DisplayName='$DisplayName']" -Credential $Credential

    if ($Ensure -eq 'Present')
    {
        if ($workflow -eq $null)
        {
            Write-Verbose "Workflow '$DisplayName' not found."
            return $false
        }
        else
        {
            Write-Verbose "Set found, diffing the properties: $($set.ObjectID)"
            $workflowsAreTheSame = $true
            foreach ($boundParameter in $PSBoundParameters.GetEnumerator())
            {
                Write-Verbose "Comparing $($boundParameter.Key)"
                switch ($boundParameter.Key)
                {
                    {$_ -in @(
                        'DisplayName'
                        'Description' 
                        'RequestPhase'
                        'XOML'                 
                    )} {
                        if ($boundParameter.Value -ne $set.($boundParameter.Key))
                        {
                            Write-Verbose (" Workflow property is not the same: {0}`n {1}`n {2}" -F @(
                                $boundParameter.Key
                                $workflow.($boundParameter.Key)
                                $boundParameter.Value
                            ))
                            $workflowsAreTheSame = $false
                        }
                    
                    }
                    'SetFilter' {
                        $filterString = "<Filter xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance' xmlns:xsd='http://www.w3.org/2001/XMLSchema' Dialect='http://schemas.microsoft.com/2006/11/XPathFilterDialect' xmlns='http://schemas.xmlsoap.org/ws/2004/09/enumeration'>{0}</Filter>" -F $SetFilter
                        if ($filterString -ne $set.Filter)
                        {
                            Write-Verbose (" Set property is not the same: {0}`n {1}`n {2}" -F @(
                                $boundParameter.Key
                                $set.Filter
                                $filterString
                            ))
                            $setsAreTheSame = $false
                        }
                    }
                    Default {}
                }
            }
            return $workflowsAreTheSame
   
        }
    }
    elseif($Ensure -eq 'Absent')
    {
        if ($workflow -ne $null)
        {
            return $false
        }
        else
        {
            return $true
        }
    }
}


Export-ModuleMember -Function *-TargetResource

