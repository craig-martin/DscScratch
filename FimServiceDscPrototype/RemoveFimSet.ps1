<#
    .SYNOPSIS
        A brief description of the Remove-FimSet function.

    .DESCRIPTION
        A detailed description of the Remove-FimSet function.

    .PARAMETER Force
        A description of the Force parameter.

    .PARAMETER PipelineVariable
        A description of the PipelineVariable parameter.

    .PARAMETER Identifier
        A description of the SetIdentifier parameter.

    .PARAMETER Uri
        A description of the Uri parameter.

    .EXAMPLE
        PS C:\> Remove-FimSet -Force -PipelineVariable $value2

    .NOTES
        Additional information about the function.
#>
function Remove-FimSet
{
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateScript({ ($_ -is [string]) -or ($_ -is [guid]) })]
        [ValidateNotNullOrEmpty()]
        $Identifier,
        [switch]
        $Force = $false,
        [string]
        $Uri = "http://localhost:5725"
    )
    
    begin
    {
        Write-Verbose "Searching for set..."
        
        if ($Identifier -is [string])
        {
            $targetID = Get-FimObjectID -ObjectType Set -AttributeName DisplayName -AttributeValue $Identifier -Uri $Uri -ErrorAction SilentlyContinue -ErrorVariable BadThing
            if ($BadThing)
            {
                Write-Error "Can't find set $Identifier" -ErrorAction Stop
            }
            else
            {
                $targetGUID = [Guid]$targetID
            }
        }
        
        if ($Identifier -is [Guid])
        {
            $targetID = Get-FimObjectID -ObjectType Set -AttributeName ObjectID -AttributeValue $Identifier.ToString() -Uri $Uri -ErrorAction SilentlyContinue -ErrorVariable BadThing
            if ($BadThing)
            {
                Write-Error "Can't find set $($Identifier.ToString())" -ErrorAction Stop
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
        $importObject.ObjectType = 'Set'
        $importObject.State = 'Delete'
    }
    
    end
    {
        if ($Force -or $PSCmdlet.ShouldProcess($Identifier.ToString(), "Remove?"))
        {
            Write-Verbose "Removing set"
            $importObject | Import-FIMConfig -Uri $Uri
        }
    }
}
