function New-FimWorkflowDefinition
{
<#
.SYNOPSIS 
Creates a new workflow definition object inFIM

.PARAMETER DisplayName
The DisplayName value to set for the workflow.

.PARAMETER Description
The description of the workflow.

.PARAMETER RequestPhase
The type of workflow to create (Action, Authorization, or Authentication)

.PARAMETER RunOnPolicyUpdate
Whether or not to enable ROPU for an action workflow

.PARAMETER Xoml
The workflow definition XOML data

.PARAMETER Uri
The URI to the FIM Service. Defaults to localhost. 
#>
    [CmdletBinding()]
    [OutputType([Guid])]
    param
    (
        [Parameter(Mandatory=$true)]
        [String]
        $DisplayName,
        [Parameter(Mandatory=$false)]
        [String]
        $Description,
        [Parameter(Mandatory=$true)]
        [String]
        [ValidateSet("Action", "Authorization", "Authentication")]
        $RequestPhase,
        ##TODO Figure out how to exclude this switch except for Action WFs
        [Parameter(Mandatory=$false)]
        [Switch]
        $RunOnPolicyUpdate = $false,
        [Parameter(Mandatory=$true)]
        [String]
        $Xoml,
        [Parameter(Mandatory=$false)]
        [ValidateNotNull()]
        [String]
        $Uri = "http://localhost:5725",
        [parameter(Mandatory=$false)]
        [Switch]
        $PassThru = $true              
    )
    process
    {
        $changeSet = @{
	        DisplayName 			= $DisplayName	        
	        RequestPhase 			= $RequestPhase	        
	        XOML 					= $XOML
        }

        if ([String]::IsNullOrEmpty($Description) -eq $false)
        {
            $changeSet.Add("Description", $Description)
        }

        if ($RequestPhase -eq "Action")
        {
            $changeSet.Add("RunOnPolicyUpdate", $RunOnPolicyUpdate.ToString())
        }

        New-FimImportObject -ObjectType WorkflowDefinition -State Create -Uri $Uri -Changes $changeSet -ApplyNow

        if ($PassThru.ToBool())
        {
            $objectID = Get-FimObjectID -ObjectType WorkflowDefinition -AttributeName DisplayName -AttributeValue $DisplayName
            Write-Output $objectID
        }
    }
}
