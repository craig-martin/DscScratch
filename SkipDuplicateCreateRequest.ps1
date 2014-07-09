Function Skip-DuplicateCreateRequest
{
<#
    .SYNOPSIS
    Detects a duplicate 'Create' request then removes it from the pipeline

    .DESCRIPTION
    The Skip-DuplicateCreateRequest function makes it easier to use Import-FimConfig by providing preventing a duplicate Create request.
    In most cases FIM allows the creation of duplicate objects since it mostly does not enforce uniqueness.  When loading configuration objects this can easily lead to the accidental duplication of MPRs, Sets, Workflows, etc.

    .PARAMETER ObjectType
    The object type for the target object.
    NOTE: this is case sensitive
    NOTE: this is the ResourceType's 'name' attribute, which often does NOT match what is seen in the FIM Portal.

    .OUTPUTS
    the FIM ImportObject is returned by this function ONLY if a duplicate was not fount.

    .EXAMPLE
    PS C:\$createRequest = New-FimImportObject -ObjectType Person -State Create -Changes @{
        AccountName='Bob'
        DisplayName='Bob the Builder'
        }
    PS C:\$createRequest | Skip-DuplicateCreateRequest | Import-FIMConfig

    DESCRIPTION
    -----------
    Creates an ImportObject for creating a new Person object with AccountName and DisplayName.
    If an object with the DisplayName 'Bob the Builder' already exists, then a warning will be displayed, and no input will be provided to Import-FimConfig because the Skip-DuplicateCreateRequest would have filtered it from the pipeline.
#>
    Param
    (
        <#
        AnchorAttributeName is used to detect the duplicate in the FIM Service.  It defaults to the 'DisplayName' attribute.
        #>
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]
        $ImportObject,
        [String]
        $AnchorAttributeName = 'DisplayName',
        <#
        .PARAMETER Uri
        The Uniform Resource Identifier (URI) of themmsshortService. The following example shows how to set this parameter: -uri "http://localhost:5725"
        #>
        [String]
        $Uri = "http://localhost:5725"
    )
    Process
    {
        if ($ImportObject.State -ine 'Create')
        {
            Write-Output $ImportObject
            return
        }

        $anchorAttributeValue = $ImportObject.Changes | where { $_.AttributeName -eq $AnchorAttributeName } | select -ExpandProperty AttributeValue

        ###
        ### If the anchor attribute is not present on the ImportObject, then we can't detect a duplicate
        ### Behavior in this case is to NOT filter
        ###
        if (-not $anchorAttributeValue)
        {
            Write-Warning "Skipping duplicate detection for this Create Request because we do not have an anchor attribute to search with."
            Write-Output $ImportObject
            return
        }

        $objectId = Get-FimObjectID -Uri $Uri -ObjectType $ImportObject.ObjectType -AttributeName $AnchorAttributeName -AttributeValue $anchorAttributeValue -ErrorAction SilentlyContinue

        if ($objectId)
        {
            ### This DID resolve to an object on the target system
            ### so it is NOT safe to create
            ### do NOT put the object back on the pipeline
            Write-Warning "An object matches this object in the target system, so skipping the Create request"
        }
        else
        {
            ### This did NOT resolve to an object on the target system
            ### so it is safe to create
            ### put the object back on the pipeline
            Write-Output $ImportObject
        }
    }
}
