<#
    .SYNOPSIS
        A brief description of the Set-FimSet function.

    .DESCRIPTION
        A detailed description of the Set-FimSet function.

    .PARAMETER AddExplicitMember
        A description of the AddExplicitMember parameter.

    .PARAMETER Description
        A description of the Description parameter.

    .PARAMETER DisplayName
        A description of the DisplayName parameter.

    .PARAMETER Filter
        A description of the Filter parameter.

    .PARAMETER RemoveExplicitMember
        A description of the RemoveExplicitMember parameter.

    .PARAMETER Identifier
        A description of the Identifier parameter.

    .PARAMETER Uri
        A description of the Uri parameter.

    .EXAMPLE
        PS C:\> Set-FimSet -AddExplicitMember $value1 -Description $value2

    .NOTES
        Additional information about the function.
#>
function Set-FimSet
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateScript({ ($_ -is [string]) -or ($_ -is [guid]) })]
        [ValidateNotNullOrEmpty()]
        $Identifier,
        [Parameter(Mandatory = $false)]
        $DisplayName,
        [Parameter(Mandatory = $false)]
        $Description,
        [Parameter(Mandatory = $false)]
        [ValidateScript({ $_ -notmatch '[<>]' })]
        $Filter,
        [Parameter(Mandatory = $false)]
        [array]
        $AddExplicitMember,
        [Parameter(Mandatory = $false)]
        [array]
        $RemoveExplicitMember,
        [Parameter(Mandatory = $false)]
        [string]
        $Uri = "http://localhost:5725"
    )
    
    begin
    {
        $changeSet = @()
        
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
        
        if ($Filter)
        {
            if ($Filter -eq 'null')
            {
                $importChange = New-Object Microsoft.ResourceManagement.Automation.ObjectModel.ImportChange
                $importChange.Operation = 'Replace'
                $importChange.AttributeName = 'Filter'
                $importChange.FullyResolved = $true
                $importChange.Locale = 'Invariant'
                
                $changeSet += $importChange
            }
            else
            {
                # this is all one line to make the filter backwards compatible with FIM 2010 RTM
                $setXPathFilter = "<Filter xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance' xmlns:xsd='http://www.w3.org/2001/XMLSchema' Dialect='http://schemas.microsoft.com/2006/11/XPathFilterDialect' xmlns='http://schemas.xmlsoap.org/ws/2004/09/enumeration'>{0}</Filter>" -F $Filter
                
                $changeSet += New-FimImportChange -Operation Replace -AttributeName "Filter" -AttributeValue $setXPathFilter
            }
        }
        
        
        if (($AddExplicitMember -ne $null) -and ($AddExplicitMember.Count -gt 0))
        {
            foreach ($m in $AddExplicitMember)
            {
                $changeSet += New-FimImportChange -Operation Add -AttributeName "ExplicitMember" -AttributeValue $m
            }
        }
        
        if (($RemoveExplicitMember -ne $null) -and ($RemoveExplicitMember.Count -gt 0))
        {
            foreach ($m in $RemoveExplicitMember)
            {
                $changeSet += New-FimImportChange -Operation Delete -AttributeName "ExplicitMember" -AttributeValue $m
            }
        }
        
        Write-Verbose "Updating set"
        
        $importObject.Changes = $changeSet
        
        $importObject | Import-FIMConfig -Uri $Uri
    }
}

