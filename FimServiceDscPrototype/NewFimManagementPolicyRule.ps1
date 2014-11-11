
function New-FimManagementPolicyRule
{
    [CmdletBinding()]
    [OutputType([Guid])]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $DisplayName,
        [Parameter(Mandatory = $false)]
        [String]
        $Description,
        [Parameter(Mandatory = $false)]
        [Switch]
        $Enabled = $true,

        [Parameter(Mandatory = $true, ParameterSetName = "TransitionIn")]
        [Switch]
        $TransitionIn,
        [Parameter(Mandatory = $true, ParameterSetName = "TransitionOut")]
        [Switch]
        $TransitionOut,
        [Parameter(Mandatory = $true, ParameterSetName = "TransitionIn")]
        [Parameter(ParameterSetName = "TransitionOut")]
        #[ValidateScript({ ($_ -is [Guid]) -or ($_ -is [Array] -and $_.Length -eq 3) })]
        $TransitionSet,

        [Parameter(Mandatory = $true, ParameterSetName = "Request")]
        [Switch]
        $Request,
        [Parameter(Mandatory = $true, ParameterSetName = "Request")]
        [ValidateSet('Read', 'Create', 'Modify', 'Delete', 'Add', 'Remove')]
        [String[]]
        $RequestType,
        [Parameter(Mandatory = $false, ParameterSetName = "Request")]
        [Switch]
        $GrantPermission = $false,
        [Parameter(Mandatory = $false, ParameterSetName = "Request")]
        [String[]]
        $ResourceAttributeNames,

        [Parameter(Mandatory = $false, ParameterSetName = "Request")]
        #[ValidateScript({ ($_ -is [Guid]) -or ($_ -is [Array] -and $_.Length -eq 3) })]
        $RequestorSet,

        [Parameter(Mandatory = $false, ParameterSetName = "Request")]
        [String]
        [ValidateNotNullOrEmpty()]
        $RelativeToResourceAttributeName,

        [Parameter(Mandatory = $false, ParameterSetName = "Request")]
        #[ValidateScript({ ($_ -is [Guid]) -or ($_ -is [Array] -and $_.Length -eq 3) })]
        $ResourceSetBeforeRequest,
        [Parameter(Mandatory = $false, ParameterSetName = "Request")]
        #[ValidateScript({ ($_ -is [Guid]) -or ($_ -is [Array] -and $_.Length -eq 3) })]
        $ResourceSetAfterRequest,

        [Parameter(Mandatory = $false, ParameterSetName = "Request")]
        [Parameter(ParameterSetName = "TransitionIn")]
        [Parameter(ParameterSetName = "TransitionOut")]
        #[ValidateScript({ ($_ -is [Guid]) -or ($_ -is [Guid[]]) -or ($_ -is [Array] -and $_.Length -eq 3) -or ($_ -is [Array] -and $_[0].Length -eq 3) })]
        $AuthenticationWorkflowDefinition,
        [Parameter(Mandatory = $false, ParameterSetName = "Request")]
        [Parameter(ParameterSetName = "TransitionIn")]
        [Parameter(ParameterSetName = "TransitionOut")]
        #[ValidateScript({ ($_ -is [Guid]) -or ($_ -is [Guid[]]) -or ($_ -is [Array] -and $_.Length -eq 3) -or ($_ -is [Array] -and $_[0].Length -eq 3) })]
        $AuthorizationWorkflowDefinition,
        [Parameter(Mandatory = $false, ParameterSetName = "Request")]
        [Parameter(ParameterSetName = "TransitionIn")]
        [Parameter(ParameterSetName = "TransitionOut")]
        #[ValidateScript({ ($_ -is [Guid]) -or ($_ -is [Guid[]]) -or ($_ -is [Array] -and $_.Length -eq 3) -or ($_ -is [Array] -and $_[0].Length -eq 3) })]
        $ActionWorkflowDefinition,

        [Parameter(Mandatory = $false)]
        [ValidateNotNull()]
        [String]
        $Uri = "http://localhost:5725",
        [parameter(Mandatory = $false)]
        [Switch]
        $PassThru = $false
    )
    begin
    {
        if ($PSCmdlet.ParameterSetName -eq "Request")
        {
            if ((
            $RequestType.Contains("Read") -or
            $RequestType.Contains("Modify") -or
            $RequestType.Contains("Add") -or
            $RequestType.Contains("Remove") -or
            $RequestType.Contains("Delete")
            ) -eq $false)
            {
                if ($ResourceSetBeforeRequest)
                {
                    throw "-ResourceSetBeforeRequest is only necessary for Read, Modify, Add, Remove, and Delete requests"
                }

            }
            else
            {
                if (-not $ResourceSetBeforeRequest)
                {
                    throw "-ResourceSetBeforeRequest is required for Read, Modify, Add, Remove, and Delete requests"
                }
            }

            if ((
            $RequestType.Contains("Modify") -or
            $RequestType.Contains("Add") -or
            $RequestType.Contains("Remove") -or
            $RequestType.Contains("Create")
            ) -eq $false)
            {
                if ($ResourceSetAfterRequest)
                {
                    throw "-ResourceSetAfterRequest is only necessary for Create, Modify, Add, and Remove requests"
                }

            }
            else
            {
                if (-not $ResourceSetAfterRequest)
                {
                    throw "-ResourceSetAfterRequest is required for Create, Modify, Add, and Remove requests"
                }
            }

            if (($RequestType.Length -eq 1) -and ($RequestType[0] -eq "Delete"))
            {
                if ($ResourceAttributeNames)
                {
                    throw "-ResourceAttributeNames is only necessary for  Create, Modify, Add, and Remove requests"
                }
            }
            else
            {
                if (-not $ResourceAttributeNames)
                {
                    throw "-ResourceSetAfterRequest is required for Create, Modify, Add, and Remove requests"
                }
            }

            if ($RequestorSet -and $RelativeToResourceAttributeName)
            {
                throw "-RequestorSet and -RelativeToResourceAttributeName cannot both be specified"
            }

            if (($RequestorSet -eq $null) -and ($RelativeToResourceAttributeName -eq $null))
            {
                throw "Specify either -RequestorSet or -RelativeToResourceAttributeName"
            }
        }

        $changeSet = @()

        $changeSet += New-FimImportChange -Operation Replace -AttributeName "DisplayName" -AttributeValue $DisplayName
        #this is required on set transition MPRs as well as Request MPRs
        #it will always be false on set transitions (as expected) do to parameter sets
        $changeSet += New-FimImportChange -Operation Replace -AttributeName "GrantRight" -AttributeValue $GrantPermission.ToBool()

        if ($Description)
        {
            $changeSet += New-FimImportChange -Operation Replace -AttributeName "Description" -AttributeValue $Description
        }

        $disableValue = (-not $Enabled.ToBool())
        $changeSet += New-FimImportChange -Operation Replace -AttributeName "Disabled" -AttributeValue $disableValue

        if (($PSCmdlet.ParameterSetName -eq "TransitionIn") -or
        ($PSCmdlet.ParameterSetName -eq "TransitionOut")
        )
        {
            $changeSet += New-FimImportChange -Operation Replace -AttributeName "ManagementPolicyRuleType" -AttributeValue "SetTransition"
            $changeSet += New-FimImportChange -Operation Replace -AttributeName "ActionType" -AttributeValue $PSCmdlet.ParameterSetName
            $changeSet += New-FimImportChange -Operation Replace -AttributeName "ActionParameter" -AttributeValue "*"

            if ($PSCmdlet.ParameterSetName -eq "TransitionIn")
            {
                $changeSet += New-FimImportChange -Operation Replace -AttributeName "ResourceFinalSet" -AttributeValue $TransitionSet
            }
            elseif ($PSCmdlet.ParameterSetName -eq "TransitionOut")
            {
                $changeSet += New-FimImportChange -Operation Replace -AttributeName "ResourceCurrentSet" -AttributeValue $TransitionSet
            }
            else
            {
                throw "Unsupported parameter set name"
            }
        }

        if ($PSCmdlet.ParameterSetName -eq "Request")
        {
            $changeSet += New-FimImportChange -Operation Replace -AttributeName "ManagementPolicyRuleType" -AttributeValue "Request"

            foreach ($type in $RequestType)
            {
                $changeSet += New-FimImportChange -Operation Add -AttributeName "ActionType" -AttributeValue $type
            }

            $actionParameters = $ResourceAttributeNames
            if (($RequestType.Length -eq 1) -and ($RequestType[0] -eq "Delete"))
            {
                $actionParameters = @("*")
            }

            foreach ($param in $actionParameters)
            {
                $changeSet += New-FimImportChange -Operation Add -AttributeName "ActionParameter" -AttributeValue $param
            }

            if ($RelativeToResourceAttributeName)
            {
                $changeSet += New-FimImportChange -Operation Add -AttributeName "PrincipalRelativeToResource" -AttributeValue $RelativeToResourceAttributeName
            }
            elseif ($RequestorSet)
            {
                $changeSet += New-FimImportChange -Operation Add -AttributeName "PrincipalSet" -AttributeValue $RequestorSet
            }
            else
            {
                throw "Requestor not defined"
            }

            if ($ResourceSetBeforeRequest)
            {
                $changeSet += New-FimImportChange -Operation Replace -AttributeName "ResourceCurrentSet" -AttributeValue $ResourceSetBeforeRequest
            }

            if ($ResourceSetAfterRequest)
            {
                $changeSet += New-FimImportChange -Operation Replace -AttributeName "ResourceFinalSet" -AttributeValue $ResourceSetAfterRequest
            }
        }

        if ($AuthenticationWorkflowDefinition)
        {
            if (($AuthenticationWorkflowDefinition -is [Guid]) -or
            (($AuthenticationWorkflowDefinition -is [Array]) -and ($AuthenticationWorkflowDefinition.Length -eq 3))
            )
            {
                $changeSet += New-FimImportChange -Operation Add -AttributeName "AuthenticationWorkflowDefinition" -AttributeValue $AuthenticationWorkflowDefinition
            }
            elseif (($AuthenticationWorkflowDefinition -is [Guid[]]) -or
            ($AuthenticationWorkflowDefinition -is [Array])
            )
            {
                foreach ($wf in $AuthenticationWorkflowDefinition)
                {
                    $changeSet += New-FimImportChange -Operation Add -AttributeName "AuthenticationWorkflowDefinition" -AttributeValue $wf
                }
            }
            else
            {
                throw "Unsupported input for -AuthenticationWorkflowDefinition"
            }
        }

        if ($AuthorizationWorkflowDefinition)
        {
            if (($AuthorizationWorkflowDefinition -is [Guid]) -or
            (($AuthorizationWorkflowDefinition -is [Array]) -and ($AuthorizationWorkflowDefinition.Length -eq 3))
            )
            {
                $changeSet += New-FimImportChange -Operation Add -AttributeName "AuthorizationWorkflowDefinition" -AttributeValue $AuthorizationWorkflowDefinition
            }
            elseif (($AuthorizationWorkflowDefinition -is [Guid[]]) -or
            ($AuthorizationWorkflowDefinition -is [Array])
            )
            {
                foreach ($wf in $AuthorizationWorkflowDefinition)
                {
                    $changeSet += New-FimImportChange -Operation Add -AttributeName "AuthorizationWorkflowDefinition" -AttributeValue $wf
                }
            }
            else
            {
                throw "Unsupported input for -AuthorizationWorkflowDefinition"
            }
        }

        if ($ActionWorkflowDefinition)
        {
            if (($ActionWorkflowDefinition -is [Guid]) -or
            (($ActionWorkflowDefinition -is [Array]) -and ($ActionWorkflowDefinition.Length -eq 3))
            )
            {
                $changeSet += New-FimImportChange -Operation Add -AttributeName "ActionWorkflowDefinition" -AttributeValue $ActionWorkflowDefinition
            }
            elseif (($ActionWorkflowDefinition -is [Guid[]]) -or
            ($ActionWorkflowDefinition -is [Array])
            )
            {
                foreach ($wf in $ActionWorkflowDefinition)
                {
                    $changeSet += New-FimImportChange -Operation Add -AttributeName "ActionWorkflowDefinition" -AttributeValue $wf
                }
            }
            else
            {
                throw "Unsupported input for -ActionWorkflowDefinition"
            }
        }

        New-FimImportObject -ObjectType ManagementPolicyRule -State Create -Changes $changeSet -Uri $Uri -ApplyNow

        if ($PassThru.ToBool())
        {
            Write-Output (Get-FimObjectID -ObjectType ManagementPolicyRule -AttributeName DisplayName -AttributeValue $DisplayName)
        }
    }
}
