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
		ActionParameter = [System.String[]]
		ActionType = [System.String[]]
		ActionWorkflowDefinition = [System.String[]]
		AuthenticationWorkflowDefinition = [System.String[]]
		AuthorizationWorkflowDefinition = [System.String[]]
		CreatedTime = [System.DateTime]
		Creator = [System.String]
		DeletedTime = [System.DateTime]
		Description = [System.String]
		DetectedRulesList = [System.String[]]
		Disabled = [System.Boolean]
		DisplayName = [System.String]
		ExpectedRulesList = [System.String[]]
		ExpirationTime = [System.DateTime]
		GrantRight = [System.Boolean]
		Locale = [System.String]
		ManagementPolicyRuleType = [System.String]
		MVObjectID = [System.String]
		PrincipalSet = [System.String]
		PrincipalRelativeToResource = [System.String]
		ResourceCurrentSet = [System.String]
		ResourceFinalSet = [System.String]
		ObjectID = [System.String]
		ResourceTime = [System.DateTime]
		ObjectType = [System.String]
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
		[System.String[]]
		$ActionParameter,

		[System.String[]]
		$ActionType,

		[System.String[]]
		$ActionWorkflowDefinition,

		[System.String[]]
		$AuthenticationWorkflowDefinition,

		[System.String[]]
		$AuthorizationWorkflowDefinition,

		[System.String]
		$Description,

		[System.String[]]
		$DetectedRulesList,

		[System.Boolean]
		$Disabled,

		[parameter(Mandatory = $true)]
		[System.String]
		$DisplayName,

		[System.String[]]
		$ExpectedRulesList,

		[System.DateTime]
		$ExpirationTime,

		[System.Boolean]
		$GrantRight,

		[System.String]
		$Locale,

		[System.String]
		$ManagementPolicyRuleType,

		[System.String]
		$MVObjectID,

		[System.String]
		$PrincipalSet,

		[System.String]
		$PrincipalRelativeToResource,

		[System.String]
		$ResourceCurrentSet,

		[System.String]
		$ResourceFinalSet,

		[System.Management.Automation.PSCredential]
		$Credential,

		[ValidateSet("Present","Absent")]
		[System.String]
		$Ensure
	)

    Write-Verbose "PSBoundParameters:"
    Write-VerboseHashTable $PSBoundParameters

    $mpr = Get-FimObjectByXPath -Filter "/ManagementPolicyRule[DisplayName='$DisplayName']" -Credential $Credential

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

    ### Translate the PrincipalSet parameter from String to Guid
    if ($PSBoundParameters.ContainsKey('PrincipalSet'))
    {
        Write-Verbose "Resolving PrincipalSet to a GUID: $PrincipalSet"
        $PrincipalSetGuid = (Get-FimObjectID -ObjectType Set -AttributeName DisplayName -AttributeValue $PrincipalSet) -as [Guid]
        $PSBoundParameters['PrincipalSet'] = $PrincipalSetGuid  
    }

    ### Translate the ResourceCurrentSet parameter from String to Guid
    if ($PSBoundParameters.ContainsKey('ResourceCurrentSet'))
    {
        Write-Verbose "Resolving ResourceCurrentSet to a GUID: $ResourceCurrentSet"
        $ResourceCurrentSetGuid = (Get-FimObjectID -ObjectType Set -AttributeName DisplayName -AttributeValue $ResourceCurrentSet) -as [Guid]
        $PSBoundParameters['ResourceCurrentSet'] = $ResourceCurrentSetGuid  
    }

    ### Translate the ResourceFinalSet parameter from String to Guid
    if ($PSBoundParameters.ContainsKey('ResourceFinalSet'))
    {
        Write-Verbose "Resolving ResourceFinalSet to a GUID: $ResourceFinalSet"
        $ResourceFinalSetGuid = (Get-FimObjectID -ObjectType Set -AttributeName DisplayName -AttributeValue $ResourceFinalSet) -as [Guid]
        $PSBoundParameters['ResourceFinalSet'] = $ResourceFinalSetGuid  
    }
    #endregion

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
		[System.String[]]
		$ActionParameter,

		[System.String[]]
		$ActionType,

		[System.String[]]
		$ActionWorkflowDefinition,

		[System.String[]]
		$AuthenticationWorkflowDefinition,

		[System.String[]]
		$AuthorizationWorkflowDefinition,

		[System.String]
		$Description,

		[System.String[]]
		$DetectedRulesList,

		[System.Boolean]
		$Disabled,

		[parameter(Mandatory = $true)]
		[System.String]
		$DisplayName,

		[System.String[]]
		$ExpectedRulesList,

		[System.DateTime]
		$ExpirationTime,

		[System.Boolean]
		$GrantRight,

		[System.String]
		$Locale,

		[System.String]
		$ManagementPolicyRuleType,

		[System.String]
		$MVObjectID,

		[System.String]
		$PrincipalSet,

		[System.String]
		$PrincipalRelativeToResource,

		[System.String]
		$ResourceCurrentSet,

		[System.String]
		$ResourceFinalSet,

		[System.Management.Automation.PSCredential]
		$Credential,

		[ValidateSet("Present","Absent")]
		[System.String]
		$Ensure
	)

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

            $fimObjectType = 'ManagementPolicyRule'
            $fimAttributeTypes = Get-FimObjectByXPath -Filter @"
            /BindingDescription
            [
                BoundObjectType= /ObjectTypeDescription
                [
                    Name='$fimObjectType'
                ]
            ]
            /BoundAttributeType
"@ 

            foreach ($fimAttributeType in $fimAttributeTypes)
            {
                if ($fimAttributeType.Name -in 'ObjectID','CreatedTime','Creator','ResourceTime','DeletedTime','ObjectType','DetectedRulesList','ExpectedRulesList','ExpirationTime','MVObjectID')
                {
                    Write-Verbose " Skipping system-owned attribute: $($fimAttributeType.Name)"
                    continue
                }

                ### Process References before comparing
                if ($fimAttributeType.DataType -eq 'Reference')
                {
                    switch ($fimAttributeType.Name)
                    {
                        {$_ -in 'PrincipalSet','ResourceCurrentSet','ResourceFinalSet'} {$fimTargetObjectType = 'Set'}
                        {$_ -in 'AuthenticationWorkflowDefinition','AuthorizationWorkflowDefinition','ActionWorkflowDefinition'} {$fimTargetObjectType = 'WorkflowDefinition'}
                        Default {Write-Error "Found a reference attribute we don't know how to resolve: $($fimAttributeType.Name)."}
                    }

                    ### Is there a value on both the FIM object and DSC object? if yes then we need to convert the value from DSC to an ObjectID
                    if ($mpr.($fimAttributeType.Name) -and $PSBoundParameters[$fimAttributeType.Name])
                    {
                        if ($fimAttributeType.Multivalued -eq 'True')
                        {
                            $fimObjectIDs = $PSBoundParameters[$fimAttributeType.Name] | 
                            ForEach-Object {
                                Write-Verbose "Resolving $($fimAttributeType.Name) to a GUID: $_"
                                "urn:uuid:{0}" -F (Get-FimObjectID -ObjectType $fimTargetObjectType -AttributeName DisplayName -AttributeValue $_)
                            }
                            $PSBoundParameters[$fimAttributeType.Name] = $fimObjectIDs
                        }
                        else
                        {
                            Write-Verbose "Resolving $($fimAttributeType.Name) to a GUID: $($PSBoundParameters[$fimAttributeType.Name])"
                            $PSBoundParameters[$fimAttributeType.Name] = "urn:uuid:{0}" -F (Get-FimObjectID -ObjectType $fimTargetObjectType -AttributeName DisplayName -AttributeValue $PSBoundParameters[$fimAttributeType.Name])
                        }
                    }

                }


                Write-Verbose " Comparing $($fimAttributeType.Name)"
                if ($fimAttributeType.Multivalued -eq 'True')
                {
                    Write-Verbose "  From DSC: $($PSBoundParameters[$fimAttributeType.Name] -join ',')"
                    Write-Verbose "  From FIM: $($mpr.($fimAttributeType.Name) -join ',')"

                    if ($PSBoundParameters[$fimAttributeType.Name] -eq $null -and $mpr.($fimAttributeType.Name) -eq $null)
                    {
                        ### do nothing.  done.
                    }
                    elseif ($PSBoundParameters[$fimAttributeType.Name] -eq $null -and $mpr.($fimAttributeType.Name) -ne $null)
                    {
                        ### need to delete all attribute values in FIM
                        Write-Warning "  Management Policy Rule property is not the same."
                        $mprsAreTheSame = $false
                    }
                    elseif ($PSBoundParameters[$fimAttributeType.Name] -ne $null -and $mpr.($fimAttributeType.Name) -eq $null)
                    {
                        ### need to add all attribute values in FIM
                        Write-Warning "  Management Policy Rule property is not the same."
                        $mprsAreTheSame = $false
                    }
                    elseif (Compare-Object $PSBoundParameters[$fimAttributeType.Name] $mpr.($fimAttributeType.Name))
                    {
                        Write-Warning "  Management Policy Rule property is not the same."
                        $mprsAreTheSame = $false
                    }
                }
                elseif ($fimAttributeType.DataType -eq 'Boolean')
                {
                    Write-Verbose "  From DSC: $($PSBoundParameters[$fimAttributeType.Name])"
                    Write-Verbose "  From FIM: $($mpr.($fimAttributeType.Name))"
                    if ($PSBoundParameters[$fimAttributeType.Name] -ne [Convert]::ToBoolean($mpr.($fimAttributeType.Name)))
                    {[Convert]::ToBoolean($mpr.($fimAttributeType.Name))
                        Write-Warning "  Management Policy Rule property is not the same."
                        $mprsAreTheSame = $false
                    }
                }
                else
                {
                    Write-Verbose "  From DSC: $($PSBoundParameters[$fimAttributeType.Name])"
                    Write-Verbose "  From FIM: $($mpr.($fimAttributeType.Name))"

                    if ($PSBoundParameters[$fimAttributeType.Name] -ne $mpr.($fimAttributeType.Name))
                    {
                        Write-Warning "  Management Policy Rule property is not the same."
                        $mprsAreTheSame = $false
                    }
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

