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

    ### Remove the parameters that have no meaning to the New-FimManagementPolicyRule function            
    $PSBoundParameters.Remove('Ensure')     | Out-Null
    $PSBoundParameters.Remove('Credential') | Out-Null
    $PSBoundParameters.Remove('Verbose')    | Out-Null
    $PSBoundParameters.Remove('Debug')      | Out-Null

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

    $fimImportChanges = @()
    foreach ($fimAttributeType in $fimAttributeTypes)
    {
        if ($fimAttributeType.Name -in 'ObjectID','CreatedTime','Creator','ResourceTime','DeletedTime','ObjectType','DetectedRulesList','ExpectedRulesList','ExpirationTime','MVObjectID')
        {
            Write-Verbose " Skipping system-owned attribute: $($fimAttributeType.Name)"
            continue
        }

        ###
        ### Process References before comparing
        ### Only do this when a value exists on the DSC side
        ###
        if ($fimAttributeType.DataType -eq 'Reference' -and $PSBoundParameters.ContainsKey($fimAttributeType.Name))
        {
            switch ($fimAttributeType.Name)
            {
                {$_ -in 'PrincipalSet','ResourceCurrentSet','ResourceFinalSet'} {$fimTargetObjectType = 'Set'}
                {$_ -in 'AuthenticationWorkflowDefinition','AuthorizationWorkflowDefinition','ActionWorkflowDefinition'} {$fimTargetObjectType = 'WorkflowDefinition'}
                Default {Write-Error "Found a reference attribute we don't know how to resolve: $($fimAttributeType.Name)."}
            }

            if ($fimAttributeType.Multivalued -eq 'True')
            {
                $fimObjectIDs = $PSBoundParameters[$fimAttributeType.Name] | 
                ForEach-Object {
                    Write-Verbose " Resolving $($fimAttributeType.Name) to a GUID: $_"
                    "urn:uuid:{0}" -F (Get-FimObjectID -ObjectType $fimTargetObjectType -AttributeName DisplayName -AttributeValue $_)
                }
                $PSBoundParameters[$fimAttributeType.Name] = $fimObjectIDs
            }
            else 
            {
                Write-Verbose " Resolving $($fimAttributeType.Name) to a GUID: $($PSBoundParameters[$fimAttributeType.Name])"
                $PSBoundParameters[$fimAttributeType.Name] = "urn:uuid:{0}" -F (Get-FimObjectID -ObjectType $fimTargetObjectType -AttributeName DisplayName -AttributeValue $PSBoundParameters[$fimAttributeType.Name])
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
                $mpr.($fimAttributeType.Name) | ForEach-Object {
                    Write-Warning "  Deleting $($fimAttributeType.Name) value: $($_)"
                    $fimImportChanges += New-FimImportChange -AttributeName $fimAttributeType.Name -AttributeValue $_ -Operation Delete
                }
            }
            elseif ($PSBoundParameters[$fimAttributeType.Name] -ne $null -and $mpr.($fimAttributeType.Name) -eq $null)
            {
                ### need to add all attribute values to FIM
                $PSBoundParameters[$fimAttributeType.Name] | ForEach-Object {
                    Write-Warning "  Adding   $($fimAttributeType.Name) value: $($_)"
                    $fimImportChanges += New-FimImportChange -AttributeName $fimAttributeType.Name -AttributeValue $_ -Operation Add
                }
            }
            else
            {
                Compare-Object $PSBoundParameters[$fimAttributeType.Name] $mpr.($fimAttributeType.Name) | ForEach-Object {
                    if ($_.SideIndicator -eq '<=')
                    {
                        Write-Warning "  Adding   $($fimAttributeType.Name) value: $($_.InputObject)"
                        $fimImportChanges += New-FimImportChange -Operation Add -AttributeName $fimAttributeType.Name -AttributeValue $_.InputObject
                    }
                    elseif ($_.SideIndicator -eq '=>')
                    {
                        Write-Warning "  Deleting $($fimAttributeType.Name) value: $($_.InputObject)"
                        $fimImportChanges += New-FimImportChange -Operation Delete -AttributeName $fimAttributeType.Name -AttributeValue $_.InputObject
                    }
                }
            }
        }
        elseif ($fimAttributeType.DataType -eq 'Boolean')
        {
            Write-Verbose "  From DSC: $($PSBoundParameters[$fimAttributeType.Name])"
            Write-Verbose "  From FIM: $($mpr.($fimAttributeType.Name))"
            if ($PSBoundParameters[$fimAttributeType.Name] -ne [Convert]::ToBoolean($mpr.($fimAttributeType.Name)) -or ($PSBoundParameters.ContainsKey($fimAttributeType.Name) -and -not $mpr.($fimAttributeType.Name)))
            {
                Write-Warning "  Updating $($fimAttributeType.Name) value: $($PSBoundParameters[$fimAttributeType.Name])"
                $fimImportChanges += New-FimImportChange -Operation Replace -AttributeName $fimAttributeType.Name -AttributeValue $PSBoundParameters[$fimAttributeType.Name]
            }
        }
        else
        {
            Write-Verbose "  From DSC: $($PSBoundParameters[$fimAttributeType.Name])"
            Write-Verbose "  From FIM: $($mpr.($fimAttributeType.Name))"

            if ($PSBoundParameters[$fimAttributeType.Name] -ne $mpr.($fimAttributeType.Name))
            {
                Write-Warning "  Updating $($fimAttributeType.Name) value: $($PSBoundParameters[$fimAttributeType.Name])"
                $fimImportChanges += New-FimImportChange -Operation Replace -AttributeName $fimAttributeType.Name -AttributeValue $PSBoundParameters[$fimAttributeType.Name]
            }
        }
    }

    $fimImportChanges | Export-Clixml C:\temp\fimImportChanges.clixml

    if ($Ensure -eq 'Present')
    {
        Write-Verbose "Ensure -eq 'Present'"

        if ($mpr -eq $null)
        {
            Write-Verbose "Management Policy Rule is missing, so adding it: $DisplayName" 
            New-FimImportObject -ObjectType ManagementPolicyRule -State Create -Changes $fimImportChanges -ApplyNow
        }
        elseif ($mpr -is [array])
        {
            Write-Verbose "Mulitple ManagementPolicy Rule objects found.  This will be corrected by deleting the MPRs then creating a new one based on the desirable state."
            foreach($m in $mpr)
            {
                Write-Verbose "  Deleting ManagementPolicy Rule: $($m.ObjectID)"
                New-FimImportObject -ObjectType ManagementPolicyRule -State Delete -TargetObjectIdentifier $m.ObjectID -ApplyNow
            }
            New-FimImportObject -ObjectType ManagementPolicyRule -State Create -Changes $fimImportChanges -ApplyNow
        }
        else
        {
            Write-Verbose "Management Policy Rule is present, so updating it: $DisplayName, $($mpr.ObjectID)"
            New-FimImportObject -ObjectType ManagementPolicyRule -State Put -TargetObjectIdentifier ($mpr.ObjectID -replace 'urn:uuid:') -Changes $fimImportChanges -ApplyNow
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
                                Write-Verbose " Resolving $($fimAttributeType.Name) to a GUID: $_"
                                "urn:uuid:{0}" -F (Get-FimObjectID -ObjectType $fimTargetObjectType -AttributeName DisplayName -AttributeValue $_)
                            }
                            $PSBoundParameters[$fimAttributeType.Name] = $fimObjectIDs
                        }
                        else
                        {
                            Write-Verbose " Resolving $($fimAttributeType.Name) to a GUID: $($PSBoundParameters[$fimAttributeType.Name])"
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
                    {
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

