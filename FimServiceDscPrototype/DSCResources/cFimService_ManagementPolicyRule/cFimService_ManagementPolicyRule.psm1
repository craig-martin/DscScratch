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

    Write-Verbose "PSBoundParameters:"
    Write-VerboseHashTable $PSBoundParameters

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

    $PSBoundParameters | Export-Clixml -Path c:\temp\psboundparameters.clixml

    if ($Ensure -eq 'Present')
    {
        Write-Verbose "Ensure -eq 'Present'"
        if ($mpr -eq $null)
        {
            Write-Verbose "Management Policy Rule is missing, so adding it: $DisplayName" 
            New-FimManagementPolicyRule @PSBoundParameters
        }
        elseif ($mpr -is [array])
        {
            Write-Verbose "Mulitple ManagementPolicy Rule objects found.  This will be corrected by deleting the MPRs then creating a new one based on the desirable state."
            foreach($m in $mpr)
            {
                Write-Verbose "  Deleting ManagementPolicy Rule: $($m.ObjectID)"
                New-FimImportObject -ObjectType ManagementPolicyRule -State Delete -TargetObjectIdentifier $m.ObjectID -ApplyNow
            }
            New-FimManagementPolicyRule @PSBoundParameters
        }
        else
        {
            Write-Verbose "Management Policy Rule is present, so updating it: $DisplayName, $($mpr.ObjectID)"
            Set-FimManagementPolicyRule -ObjectID ($mpr.ObjectID -replace 'urn:uuid:') @PSBoundParameters
            ##TODO: look at the properties on the current MPR, if properties exist on the current MPR but not on the DSC resource, then remove

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

    Write-Verbose "PSBoundParameters:"
    Write-VerboseHashTable $PSBoundParameters

    $mpr = Get-FimObjectByXPath -Filter "/ManagementPolicyRule[DisplayName='$DisplayName']" -Credential $Credential

    if ($Ensure -eq 'Present')
    {
        if ($mpr -eq $null)
        {
            Write-Verbose "Management Policy Rule '$DisplayName' not found."
            return $false
        }
        elseif ($mpr -is [array])
        {
            Write-Verbose "Mulitple ManagementPolicy Rule objects found.  This will be corrected by deleting the MPRs then creating a new one based on the desirable state."
            return $false
        }
        else
        {
            Write-Verbose "Management Policy Rule found, diffing the properties: $($mpr.ObjectID)"
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
                    'Enabled' {
                        if ([bool]$Enabled -eq [Convert]::ToBoolean($mpr.Disabled))
                        {
                            Write-Verbose (" Management Policy Rule property is not the same: {0}`n {1}`n {2}" -F @(
                                $boundParameter.Key
                                (-not $mpr.Disabled)
                                $Enabled
                            ))
                            $mprsAreTheSame = $false
                        }
                    }
                    {$_ -in @(
                        'TransitionIn'
                        'TransitionOut'                 
                    )} {
                        Write-Verbose " From DSC: $($boundParameter.Key)"
                        Write-Verbose " From FIM: $($mpr.ActionType | Out-String)"
                        if ($mpr.ActionType -notcontains $boundParameter.Key)
                        {
                            throw "The Management Policy Rule type cannot be changed.  The MPR must be deleted then created again."
                        }
                    }
                    'Request'
                    {
                        Write-Verbose " From DSC: $Request"
                        Write-Verbose " From FIM: $($mpr.ManagementPolicyRuleType)"
                        if ($mpr.ManagementPolicyRuleType -eq 'Request' -ne $Request)
                        {
                            throw "The Management Policy Rule type cannot be changed.  The MPR must be deleted then created again."
                        }
                    }
                    'RequestorSet'
                    {
                        $RequestorSetGuid = "urn:uuid:{0}" -F (Get-FimObjectID -ObjectType Set -AttributeName DisplayName -AttributeValue $RequestorSet)
                        Write-Verbose " From DSC: $RequestorSetGuid, ($RequestorSet)"
                        Write-Verbose " From FIM: $($mpr.PrincipalSet)"
                        if ($RequestorSetGuid -ne $mpr.PrincipalSet )
                        {
                           Write-Verbose " Management Policy Rule property is not the same."
                           $mprsAreTheSame = $false
                        }
                    }
                    'RelativeToResourceAttributeName'
                    {
                        Write-Verbose " From DSC: $RelativeToResourceAttributeName"
                        Write-Verbose " From FIM: $($mpr.PrincipalRelativeToResource)"
                        if ($mpr.PrincipalRelativeToResource -ne $RelativeToResourceAttributeName)
                        {
                           Write-Verbose " Management Policy Rule property is not the same."
                           $mprsAreTheSame = $false
                        }
                    }
                    'ResourceSetBeforeRequest'
                    {
                        $ResourceSetBeforeRequestGuid = "urn:uuid:{0}" -F (Get-FimObjectID -ObjectType Set -AttributeName DisplayName -AttributeValue $ResourceSetBeforeRequest)
                        Write-Verbose " From DSC: $ResourceSetBeforeRequestGuid, ($ResourceSetBeforeRequest)"
                        Write-Verbose " From FIM: $($mpr.ResourceCurrentSet)"
                        if ($ResourceSetBeforeRequestGuid -ne $mpr.ResourceCurrentSet )
                        {
                            Write-Verbose (" Management Policy Rule property is not the same: {0}`n {1}`n {2}" -F @(
                                $boundParameter.Key
                                $mpr.ResourceCurrentSet
                                $ResourceSetBeforeRequestGuid
                            ))
                            $mprsAreTheSame = $false
                        }
                    }
                    'ResourceSetAfterRequest'
                    {
                        $ResourceSetAfterRequestGuid = "urn:uuid:{0}" -F (Get-FimObjectID -ObjectType Set -AttributeName DisplayName -AttributeValue $ResourceSetAfterRequest)
                        Write-Verbose " From DSC: $ResourceSetAfterRequestGuid, ($ResourceSetAfterRequest)"
                        Write-Verbose " From FIM: $($mpr.ResourceFinalSet)"
                        if ($ResourceSetBeforeRequestGuid -ne $mpr.ResourceFinalSet )
                        {
                            Write-Verbose (" Management Policy Rule property is not the same: {0}`n {1}`n {2}" -F @(
                                $boundParameter.Key
                                $mpr.ResourceFinalSet
                                $ResourceSetAfterRequestRequestGuid
                            ))
                            $mprsAreTheSame = $false
                        }
                    }
                    'TransitionSet'
                    {
                        $TransitionSetGuid = "urn:uuid:{0}" -F (Get-FimObjectID -ObjectType Set -AttributeName DisplayName -AttributeValue $TransitionSet)
                        Write-Verbose " From DSC: $TransitionSetGuid, ($TransitionSet)"
                        Write-Verbose " From FIM: $($mpr.ResourceFinalSet)"
                        if ($TransitionSetGuid -ne $mpr.ResourceFinalSet )
                        {
                            Write-Verbose (" Management Policy Rule property is not the same: {0}`n {1}`n {2}" -F @(
                                $boundParameter.Key
                                $mpr.ResourceFinalSet
                                $TransitionSetGuid
                            ))
                            $mprsAreTheSame = $false
                        }
                    }
                    'RequestType'
                    {
                        Write-Verbose " From DSC: $($RequestType -join ',')"
                        Write-Verbose " From FIM: $($mpr.ActionType -join ',')"
                        if (Compare-Object $RequestType $mpr.ActionType)
                        {
                            Write-Verbose " Management Policy Rule property is not the same."
                            $mprsAreTheSame = $false
                        }
                    }
                    'GrantPermission'
                    {
                        Write-Verbose " From DSC: $GrantPermission"
                        Write-Verbose " From FIM: $($mpr.GrantRight)"
                        if ([bool]$GrantPermission -ne [Convert]::ToBoolean($mpr.GrantRight))
                        {
                            Write-Verbose " Management Policy Rule property is not the same."
                            $mprsAreTheSame = $false
                        }
                    }
                    'ResourceAttributeNames'
                    {
                        Write-Verbose " From DSC: $($ResourceAttributeNames -join ',')"
                        Write-Verbose " From FIM: $($mpr.ActionParameter -join ',')"
                        if (Compare-Object $ResourceAttributeNames $mpr.ActionParameter)
                        {
                            Write-Verbose " Management Policy Rule property is not the same."
                            $mprsAreTheSame = $false
                        }
                    }
                    'AuthenticationWorkflowDefinition'
                    {
                        $AuthenticationWorkflowDefinitionGuids = $AuthenticationWorkflowDefinition | 
                        ForEach-Object {
                            Write-Verbose "Resolving WF to a GUID: $_"
                            "urn:uuid:{0}" -F (Get-FimObjectID -ObjectType WorkflowDefinition -AttributeName DisplayName -AttributeValue $_) 
                        }
                        Write-Verbose " From DSC: `n`t$($AuthenticationWorkflowDefinitionGuids -join "`n`t")"
                        Write-Verbose " From FIM: `n`t$($mpr.AuthenticationWorkflowDefinition -join "`n`t")"
                        if (-not $mpr.AuthenticationWorkflow -or (Compare-Object $AuthenticationWorkflowDefinitionGuids $mpr.AuthenticationWorkflow))
                        {
                            Write-Verbose " Management Policy Rule property is not the same."
                            $mprsAreTheSame = $false
                        }
                    }
                    'AuthorizationWorkflowDefinition'
                    {
                        $AuthorizationWorkflowDefinitionGuids = $AuthorizationWorkflowDefinition | 
                        ForEach-Object {
                            Write-Verbose "Resolving WF to a GUID: $_"
                            "urn:uuid:{0}" -F (Get-FimObjectID -ObjectType WorkflowDefinition -AttributeName DisplayName -AttributeValue $_) 
                        }
                        Write-Verbose " From DSC: `n`t$($AuthorizationWorkflowDefinitionGuids -join "`n`t")"
                        Write-Verbose " From FIM: `n`t$($mpr.AuthorizationWorkflowDefinition -join "`n`t")"
                        if (-not $mpr.AuthorizationWorkflowDefinition -or (Compare-Object $AuthorizationWorkflowDefinitionGuids $mpr.AuthorizationWorkflowDefinition))
                        {
                            Write-Verbose " Management Policy Rule property is not the same."
                            $mprsAreTheSame = $false
                        }
                    }
                    'ActionWorkflowDefinition'
                    {
                        $ActionWorkflowDefinitionGuids = $ActionWorkflowDefinition | 
                        ForEach-Object {
                            Write-Verbose "Resolving WF to a GUID: $_"
                            "urn:uuid:{0}" -F (Get-FimObjectID -ObjectType WorkflowDefinition -AttributeName DisplayName -AttributeValue $_) 
                        }
                        Write-Verbose " From DSC: `n`t$($ActionWorkflowDefinitionGuids -join "`n`t")"
                        Write-Verbose " From FIM: `n`t$($mpr.ActionWorkflowDefinition -join "`n`t")"
                        if (-not $mpr.ActionWorkflowDefinition -or (Compare-Object $ActionWorkflowDefinitionGuids $mpr.ActionWorkflowDefinition))
                        {
                            Write-Verbose " Management Policy Rule property is not the same."
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

