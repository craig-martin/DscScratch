function Set-FimWorkflowDefinition
{
<#
.SYNOPSIS 
Updates an existing workflow definition object in FIM

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
        [Parameter(Mandatory = $true)]
        [ValidateScript({ ($_ -is [string]) -or ($_ -is [guid]) })]
        [ValidateNotNullOrEmpty()]
        $Identifier,
        [Parameter(Mandatory=$false)]
        [String]
        $DisplayName,
        [Parameter(Mandatory=$false)]
        [String]
        $Description,
        [Parameter(Mandatory=$false)]
        [String]
        [ValidateSet("Action", "Authorization", "Authentication")]
        $RequestPhase,
        [Parameter(Mandatory=$false)]
        [Switch]
        $RunOnPolicyUpdate = $false,
        [Parameter(Mandatory=$false)]
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
    begin
    {
        $changeSet = @()
        
        Write-Verbose "Searching for workflow definition..."
        
        if ($Identifier -is [string])
        {
            $targetID = Get-FimObjectID -ObjectType WorkflowDefinition -AttributeName DisplayName -AttributeValue $Identifier -Uri $Uri -ErrorAction SilentlyContinue -ErrorVariable BadThing
            if ($BadThing)
            {
                Write-Error "Can't find workflow definition $Identifier" -ErrorAction Stop
            }
            else
            {
                $targetGUID = [Guid]$targetID
            }
        }
        
        if ($Identifier -is [Guid])
        {
            $targetID = Get-FimObjectID -ObjectType WorkflowDefinition -AttributeName ObjectID -AttributeValue $Identifier.ToString() -Uri $Uri -ErrorAction SilentlyContinue -ErrorVariable BadThing
            if ($BadThing)
            {
                Write-Error "Can't find workflow definition $($Identifier.ToString())" -ErrorAction Stop
            }
            else
            {
                $targetGUID = $Identifier
            }
        }
        
        Write-Verbose "Creating change object..."
        $importObject = New-Object Microsoft.ResourceManagement.Automation.ObjectModel.ImportObject
        $importObject.SourceObjectIdentifier = [Guid]::Empty
        $importObject.TargetObjectIdentifier = $targetGUID
        $importObject.ObjectType = 'WorkflowDefinition'
        $importObject.State = 'Put'
    }
    
    end
    {
        Write-Verbose "Processing changes..."
        
        if ($DisplayName)
        {
            $changeSet += New-FimImportChange -Operation Replace -AttributeName "DisplayName" -AttributeValue $DisplayName
        }
        
        if ($Description)
        {
            $changeSet += New-FimImportChange -Operation Replace -AttributeName "Description" -AttributeValue $Description
        }

        if ($Xoml)
        {
            $changeSet += New-FimImportChange -Operation Replace -AttributeName "XOML" -AttributeValue $Xoml
        }

        if ($RequestPhase)
        {
            $changeSet += New-FimImportChange -Operation Replace -AttributeName "RequestPhase" -AttributeValue $RequestPhase
        }

        if ($RunOnPolicyUpdate)
        {
            $changeSet += New-FimImportChange -Operation Replace -AttributeName "RunOnPolicyUpdate" -AttributeValue $RunOnPolicyUpdate.ToString()
        }
        
        
        Write-Verbose "Updating workflow definition"
        
        $importObject.Changes = $changeSet
        
        $importObject | Import-FIMConfig -Uri $Uri
    }
}
