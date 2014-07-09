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
		Enabled = [System.Boolean]
		RequestorSet = [System.String]
		RelativeToResourceAttributeName = [System.String]
		RequestType = [System.String[]]
		GrantPermission = [System.Boolean]
		TransitionIn = [System.Boolean]
		TransitionOut = [System.Boolean]
		Request = [System.Boolean]
		ResourceSetBeforeRequest = [System.String]
		ResourceSetAfterRequest = [System.String]
		ResourceAttributeNames = [System.String[]]
		AuthenticationWorkflowDefinition = [System.String[]]
		AuthorizationWorkflowDefinition = [System.String[]]
		ActionWorkflowDefinition = [System.String[]]
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

		[Switch]
		$Enabled,

		[System.String]
		$RequestorSet,

		[System.String]
		$RelativeToResourceAttributeName,

		[System.String[]]
		$RequestType,

		[Switch]
		$GrantPermission,

		[Switch]
		$TransitionIn,

		[Switch]
		$TransitionOut,

        [System.String]
		$TransitionSet,

		[Switch]
		$Request,

		[System.String]
		$ResourceSetBeforeRequest,

		[System.String]
		$ResourceSetAfterRequest,

		[System.String[]]
		$ResourceAttributeNames,

		[System.String[]]
		$AuthenticationWorkflowDefinition,

		[System.String[]]
		$AuthorizationWorkflowDefinition,

		[System.String[]]
		$ActionWorkflowDefinition,

		[System.Management.Automation.PSCredential]
		$Credential,

		[ValidateSet("Present","Absent")]
		[System.String]
		$Ensure
	)

    $mpr = Get-FimObjectByXPath -Filter "/ManagementPolicyRule[DisplayName='$DisplayName']" -Credential $Credential

    ### Remove the parameters that have no meaning to the New-FimManagementPolicyRule function            
    $PSBoundParameters.Remove('Ensure')     | Out-Null
    $PSBoundParameters.Remove('Credential') | Out-Null
    
    #region: translate Strings to FIM GUIDs

    ### Translate the AuthenticationWorkflowDefinition parameter from String[] to Guid[]
    if ($PSBoundParameters.ContainsKey('AuthenticationWorkflowDefinition'))
    {
        $AuthenticationWorkflowDefinitionGuids = $AuthenticationWorkflowDefinition | 
        ForEach-Object {
            Write-Verbose "Resolving Authentication WF to a GUID: $_"
            (Get-FimObjectID -ObjectType WorkflowDefinition -AttributeName DisplayName -AttributeValue $_) -as [Guid]
        }
        $PSBoundParameters['AuthenticationWorkflowDefinition'] = $AuthenticationWorkflowDefinitionGuids  
    }

    ### Translate the AuthorizationWorkflowDefinition parameter from String[] to Guid[]
    if ($PSBoundParameters.ContainsKey('AuthorizationWorkflowDefinition'))
    {
        $AuthorizationWorkflowDefinitionGuids = $AuthorizationWorkflowDefinition | 
        ForEach-Object {
            Write-Verbose "Resolving Authorization WF to a GUID: $_"
            (Get-FimObjectID -ObjectType WorkflowDefinition -AttributeName DisplayName -AttributeValue $_) -as [Guid]
        }
        $PSBoundParameters['AuthorizationWorkflowDefinition'] = $AuthorizationWorkflowDefinitionGuids  
    }

    ### Translate the ActionWorkflowDefinition parameter from String[] to Guid[]
    if ($PSBoundParameters.ContainsKey('ActionWorkflowDefinition'))
    {
        $ActionWorkflowDefinitionGuids = $ActionWorkflowDefinition | 
        ForEach-Object {
            Write-Verbose "Resolving Action WF to a GUID: $_"
            (Get-FimObjectID -ObjectType WorkflowDefinition -AttributeName DisplayName -AttributeValue $_) -as [Guid]
        }
        $PSBoundParameters['ActionWorkflowDefinition'] = $ActionWorkflowDefinitionGuids  
    }

    ### Translate the RequestorSet parameter from String to Guid
    if ($PSBoundParameters.ContainsKey('RequestorSet'))
    {
        Write-Verbose "Resolving RequestorSet to a GUID: $RequestorSet"
        $RequestorSetGuid = (Get-FimObjectID -ObjectType Set -AttributeName DisplayName -AttributeValue $RequestorSet) -as [Guid]
        $PSBoundParameters['RequestorSet'] = $RequestorSetGuid  
    }

    ### Translate the ResourceSetBeforeRequest parameter from String to Guid
    if ($PSBoundParameters.ContainsKey('ResourceSetBeforeRequest'))
    {
        Write-Verbose "Resolving ResourceSetBeforeRequest to a GUID: $ResourceSetBeforeRequest"
        $ResourceSetBeforeRequestGuid = (Get-FimObjectID -ObjectType Set -AttributeName DisplayName -AttributeValue $ResourceSetBeforeRequest) -as [Guid]
        $PSBoundParameters['ResourceSetBeforeRequest'] = $ResourceSetBeforeRequestGuid  
    }

    ### Translate the ResourceSetAfterRequest parameter from String to Guid
    if ($PSBoundParameters.ContainsKey('ResourceSetAfterRequest'))
    {
        Write-Verbose "Resolving ResourceSetAfterRequest to a GUID: $ResourceSetAfterRequest"
        $ResourceSetAfterRequestGuid = (Get-FimObjectID -ObjectType Set -AttributeName DisplayName -AttributeValue $ResourceSetAfterRequest) -as [Guid]
        $PSBoundParameters['ResourceSetAfterRequest'] = $ResourceSetAfterRequestGuid  
    }

    ### Translate the TransitionSet parameter from String to Guid
    if ($PSBoundParameters.ContainsKey('TransitionSet'))
    {
        Write-Verbose "Resolving TransitionSet to a GUID: $TransitionSet"
        $TransitionSetGuid = (Get-FimObjectID -ObjectType Set -AttributeName DisplayName -AttributeValue $TransitionSet) -as [Guid]
        $PSBoundParameters['TransitionSet'] = $TransitionSetGuid  
    }
    #endregion

    Write-Verbose "PSBoundParameters:"
    foreach($PSBoundParameter in $PSBoundParameters.GetEnumerator())
    {
        Write-Verbose ("  Key={0} Value={1}" -f $PSBoundParameter.Key,$PSBoundParameter.Value)
    }
    $PSBoundParameters | Export-Clixml -Path c:\temp\psboundparameters.clixml

    if ($Ensure -eq 'Present')
    {
        Write-Verbose "Ensure -eq 'Present'"
        if ($mpr -eq $null)
        {
            Write-Verbose "Management Policy Rule is missing, so adding it: $DisplayName" 
            New-FimManagementPolicyRule @PSBoundParameters
        }
        else
        {
            Write-Verbose "Management Policy Rule is present, so updating it: $DisplayName"
            #Set-FimWorkflowDefinition -Identifier $workflow.DisplayName -Description $Description -RequestPhase $RequestPhase -RunOnPolicyUpdate:$RunOnPolicyUpdate -XOML $Xoml -Verbose:$true
        }
    }
    elseif($Ensure -eq 'Absent')
    {
        Write-Verbose "Ensure -eq 'Absent'"
        if ($mpr -ne $null)
        {
            Write-Verbose "Management Policy Rule is present, so removing it: $DisplayName"
            New-FimImportObject -ObjectType ManagementPolicyRule -State Delete -TargetObjectIdentifier $mpr.ObjectID -ApplyNow
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

		[Switch]
		$Enabled,

		[System.String]
		$RequestorSet,

		[System.String]
		$RelativeToResourceAttributeName,

		[System.String[]]
		$RequestType,

		[Switch]
		$GrantPermission,

		[Switch]
		$TransitionIn,

		[Switch]
		$TransitionOut,

        [System.String]
		$TransitionSet,

		[Switch]
		$Request,

		[System.String]
		$ResourceSetBeforeRequest,

		[System.String]
		$ResourceSetAfterRequest,

		[System.String[]]
		$ResourceAttributeNames,

		[System.String[]]
		$AuthenticationWorkflowDefinition,

		[System.String[]]
		$AuthorizationWorkflowDefinition,

		[System.String[]]
		$ActionWorkflowDefinition,

		[System.Management.Automation.PSCredential]
		$Credential,

		[ValidateSet("Present","Absent")]
		[System.String]
		$Ensure
	)

	#Write-Verbose "Use this cmdlet to deliver information about command processing."

	#Write-Debug "Use this cmdlet to write debug information while troubleshooting."
    Write-Verbose "Credential UserName: $($Credential.UserName)"


    $mpr = Get-FimObjectByXPath -Filter "/ManagementPolicyRule[DisplayName='$DisplayName']" -Credential $Credential

    if ($Ensure -eq 'Present')
    {
        if ($mpr -eq $null)
        {
            Write-Verbose "Management Policy Rule '$DisplayName' not found."
            return $false
        }
        else
        {
            Write-Verbose "Set found, diffing the properties: $($set.ObjectID)"
            $mprsAreTheSame = $true
            foreach ($boundParameter in $PSBoundParameters.GetEnumerator())
            {
                Write-Verbose "Comparing $($boundParameter.Key)"
                switch ($boundParameter.Key)
                {
                    {$_ -in @(
                        'DisplayName'
                        'Description'                 
                    )} {
                        if ($boundParameter.Value -ne $mpr.($boundParameter.Key))
                        {
                            Write-Verbose (" Management Policy Rule property is not the same: {0}`n {1}`n {2}" -F @(
                                $boundParameter.Key
                                $mpr.($boundParameter.Key)
                                $boundParameter.Value
                            ))
                            $mprsAreTheSame = $false
                        }
                    
                    }
                    'XOML' {
                        ### Compare XOMLs after removing /r (LF) because FIM removes them
                        $xomlFromFim = $mpr.xoml -replace "`r"
                        $xomlFromDsc = $Xoml -replace "`r"
                        if ($xomlFromFim -ne $xomlFromDsc)
                        {
                            Write-Verbose (" Management Policy Rule property is not the same: {0}`n {1}`n {2}" -F @(
                                $boundParameter.Key
                                $Xoml
                                $mpr.xoml
                            ))
                            $mprsAreTheSame = $false
                        }
                    }
                    Default {}
                }
            }
            return $mprsAreTheSame
   
        }
    }
    elseif($Ensure -eq 'Absent')
    {
        if ($mpr -ne $null)
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

