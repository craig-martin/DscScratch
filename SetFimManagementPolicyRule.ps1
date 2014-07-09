<#
    .SYNOPSIS
        A brief description of the Set-FimManagementPolicyRule function.

    .DESCRIPTION
        A detailed description of the Set-FimManagementPolicyRule function.

    .PARAMETER ActionWorkflowDefinition
        A description of the ActionWorkflowDefinition parameter.

    .PARAMETER AuthenticationWorkflowDefinition
        A description of the AuthenticationWorkflowDefinition parameter.

    .PARAMETER AuthorizationWorkflowDefinition
        A description of the AuthorizationWorkflowDefinition parameter.

    .PARAMETER Description
        A description of the Description parameter.

    .PARAMETER DisplayName
        A description of the DisplayName parameter.

    .PARAMETER Enabled
        A description of the Enabled parameter.

    .PARAMETER GrantPermission
        A description of the GrantPermission parameter.

    .PARAMETER ObjectID
        A description of the ObjectID parameter.

    .PARAMETER PassThru
        A description of the PassThru parameter.

    .PARAMETER PipelineVariable
        A description of the PipelineVariable parameter.

    .PARAMETER RelativeToResourceAttributeName
        A description of the RelativeToResourceAttributeName parameter.

    .PARAMETER Request
        A description of the Request parameter.

    .PARAMETER RequestorSet
        A description of the RequestorSet parameter.

    .PARAMETER RequestType
        A description of the RequestType parameter.

    .PARAMETER ResourceAttributeNames
        A description of the ResourceAttributeNames parameter.

    .PARAMETER ResourceSetAfterRequest
        A description of the ResourceSetAfterRequest parameter.

    .PARAMETER ResourceSetBeforeRequest
        A description of the ResourceSetBeforeRequest parameter.

    .PARAMETER TransitionIn
        A description of the TransitionIn parameter.

    .PARAMETER TransitionOut
        A description of the TransitionOut parameter.

    .PARAMETER TransitionSet
        A description of the TransitionSet parameter.

    .PARAMETER Uri
        A description of the Uri parameter.

    .EXAMPLE
        PS C:\> Set-FimManagementPolicyRule -ActionWorkflowDefinition $value1 -AuthenticationWorkflowDefinition $value2

    .OUTPUTS
        System.Guid

    .NOTES
        Additional information about the function.
#>
function Set-FimManagementPolicyRule
{
    [CmdletBinding()]
    [OutputType([Guid])]
    param
    (
        [Parameter(Mandatory = $true)]
        [Guid]
        $ObjectID,

        [String]
        [ValidateNotNullOrEmpty()]
        $DisplayName,

        [String]
        [ValidateNotNullOrEmpty()]
        $Description,

        [Switch]
        $Enabled = $true,

        [Switch]
        $TransitionIn,

        [Switch]
        $TransitionOut,

        [Guid]
        $TransitionSet,

        [Switch]
        $Request,

        [ValidateSet('Read', 'Create', 'Modify', 'Delete', 'Add', 'Remove')]
        [ValidateNotNullOrEmpty()]
        [String[]]
        $RequestType,

        [Switch]
        $GrantPermission = $false,

        [String[]]
        $ResourceAttributeNames,

        [Guid]
        $RequestorSet,

        [String]
        [ValidateNotNullOrEmpty()]
        $RelativeToResourceAttributeName,

        [Guid]
        $ResourceSetBeforeRequest,

        [Guid]
        $ResourceSetAfterRequest,

        [Guid[]]
        $AuthenticationWorkflowDefinition,

        [Guid[]]
        $AuthorizationWorkflowDefinition,

        [Guid[]]
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

        $currentMpr = export-fimConfig -only -Custom "/ManagementPolicyRule[ObjectID='$ObjectID']" | Convert-FimExportToPSObject
        if (-not $currentMpr)
        {
            Throw "Cannot update the MPR because it does not exist or it can't be viewed by the requestor."
        }

        $changeSet = @()

        if ($PSBoundParameters.ContainsKey('DisplayName') -and $currentMpr.DisplayName -ne $DisplayName)
        {
            $changeSet += New-FimImportChange -Operation Replace -AttributeName "DisplayName" -AttributeValue $DisplayName
        }

        if ($PSBoundParameters.ContainsKey('Description') -and $currentMpr.Description -ne $Description)
        {
            $changeSet += New-FimImportChange -Operation Replace -AttributeName "Description" -AttributeValue $Description
        }

        if ($PSBoundParameters.ContainsKey('Enabled') -and $currentMpr.Disabled -eq $Enabled.ToBool())
        {
            $changeSet += New-FimImportChange -Operation Replace -AttributeName "Disabled" -AttributeValue (-not $Enabled.ToBool())
        }

        if ($PSBoundParameters.ContainsKey('Request') -and $currentMpr.Request -ne $Request)
        {
            $changeSet += New-FimImportChange -Operation Replace -AttributeName "ActionType" -AttributeValue "Request"
        }

        if ($PSBoundParameters.ContainsKey('RequestType'))
        {
            Compare-Object $RequestType $currentMpr.ActionType | ForEach-Object {
                if ($_.SideIndicator -eq '=>')
                {
                    $changeSet += New-FimImportChange -Operation Add -AttributeName "ActionType" -AttributeValue $_.InputObject
                }
                elseif ($_.SideIndicator -eq '<=')
                {
                    $changeSet += New-FimImportChange -Operation Delete -AttributeName "ActionType" -AttributeValue $_.InputObject
                }
            }
        }


        if ($PSBoundParameters.ContainsKey('GrantPermission') -and $currentMpr.GrantRight -ne $GrantPermission.ToBool())
        {
            $changeSet += New-FimImportChange -Operation Replace -AttributeName "GrantRight" -AttributeValue $GrantPermission.ToBool()
        }

        ### ResourceAttributeNames
        if ($PSBoundParameters.ContainsKey('ResourceAttributeNames'))
        {
            Compare-Object $ResourceAttributeNames $currentMpr.ActionParameter | ForEach-Object {
                if ($_.SideIndicator -eq '=>')
                {
                    $changeSet += New-FimImportChange -Operation Add -AttributeName "ActionParameter" -AttributeValue $_.InputObject
                }
                elseif ($_.SideIndicator -eq '<=')
                {
                    $changeSet += New-FimImportChange -Operation Delete -AttributeName "ActionParameter" -AttributeValue $_.InputObject
                }
            }
        }

        if ($PSBoundParameters.ContainsKey('RelativeToResourceAttributeName') -and $currentMpr.PrincipalRelativeToResource -ne $RelativeToResourceAttributeName)
        {
            $changeSet += New-FimImportChange -Operation Replace -AttributeName "PrincipalRelativeToResource" -AttributeValue $RelativeToResourceAttributeName
        }

        if ($PSBoundParameters.ContainsKey('RequestorSet') -and $currentMpr.PrincipalSet -ne $RequestorSet)
        {
            $changeSet += New-FimImportChange -Operation Replace -AttributeName "PrincipalSet" -AttributeValue $RequestorSet
        }

        if ($PSBoundParameters.ContainsKey('ResourceSetBeforeRequest') -and $currentMpr.ResourceCurrentSet -ne $ResourceSetBeforeRequest)
        {
            $changeSet += New-FimImportChange -Operation Replace -AttributeName "ResourceCurrentSet" -AttributeValue $ResourceSetBeforeRequest
        }

        if ($PSBoundParameters.ContainsKey('ResourceSetAfterRequest') -and $currentMpr.ResourceFinalSet -ne $ResourceSetAfterRequest)
        {
            $changeSet += New-FimImportChange -Operation Replace -AttributeName "ResourceFinalSet" -AttributeValue $ResourceSetAfterRequest
        }

        ###TODO: AuthenticationWorkflowDefinition

        ###TODO: AuthorizationWorkflowDefinition

        ###TODO: ActionWorkflowDefinition


        if ($PSBoundParameters.ContainsKey('TransitionIn') -or $PSBoundParameters.ContainsKey('TransitionOut'))
        {
            if ($currentMpr.ManagementPolicyRuleType -ne "SetTransition")
            {
                $changeSet += New-FimImportChange -Operation Replace -AttributeName "ManagementPolicyRuleType" -AttributeValue "SetTransition"
            }
            if ($PSBoundParameters.ContainsKey('TransitionIn') -and $currentMpr.ActionType -ne 'TransitionIn')
            {
                $changeSet += New-FimImportChange -Operation Replace -AttributeName "ActionType" -AttributeValue 'TransitionIn'
            }
            if ($PSBoundParameters.ContainsKey('TransitionOut') -and $currentMpr.ActionType -ne 'TransitionOut')
            {
                $changeSet += New-FimImportChange -Operation Replace -AttributeName "ActionType" -AttributeValue 'TransitionOut'
            }
            if ($currentMpr.ActionParameter -ne "*")
            {
                ### TODO
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

        New-FimImportObject -ObjectType ManagementPolicyRule -State Put -TargetObjectIdentifier $ObjectID -Changes $changeSet -Uri $Uri -ApplyNow

        if ($PassThru.ToBool())
        {
            Write-Output (Get-FimObjectID -ObjectType ManagementPolicyRule -AttributeName DisplayName -AttributeValue $DisplayName)
        }
    }
}
