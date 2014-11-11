function New-FimImportObject
{
<#
    .SYNOPSIS
        Creates a new ImportObject for the FIM Configuration Migration Cmdlets

    .DESCRIPTION
        The New-FimImportObject function makes it easier to use Import-FimConfig by providing an easier way to create ImportObject objects.
        This makes it easier to perform CRUD operations in the FIM Service.

    .PARAMETER AllowAuthorizationException
        When specified, will swallow AuthZ exception. This will occur if the operation being attempted triggers an AuthZ workflow.

    .PARAMETER AnchorPairs
        A name:value pair used to find a target object for Put, Delete and Resolve operations.  The AchorPairs is used in conjunction with the ObjectType by the FIM Import-FimConfig cmdlet to find the target object.

    .PARAMETER ApplyNow
        When specified, will submit the request to FIM immediately.

    .PARAMETER Changes
        The changes to make to the target object.  This parameter accepts a Hashtable or FIM ImportChange objects as input. If a Hashtable is supplied as input then it will be converted into FIM ImportChange objects.  You're welcome.

    .PARAMETER ObjectType
        The object type for the target object.
        NOTE: this is case sensitive
        NOTE: this is the ResourceType's 'name' attribute, which often does NOT match what is seen in the FIM Portal.

    .PARAMETER PassThru
        When specified, will return the ImportObject as output.

    .PARAMETER SkipDuplicateCheck
        When specified, will skip the duplicate create request check.

    .PARAMETER SourceObjectIdentifier
        A description of the SourceObjectIdentifier parameter.

    .PARAMETER State
        The operation to perform on the target, must be one of:
        -Create
        -Put
        -Delete
        -Resolve
        -None

    .PARAMETER TargetObjectIdentifier
        The ObjectID of the object to operate on.
        Defaults to an empty GUID

    .PARAMETER Uri
        The Uniform Resource Identifier (URI) of FIM Portal Service. The default is "http://localhost:5725"

    .OUTPUTS
        The FIM ImportObject (Microsoft.ResourceManagement.Automation.ObjectModel.ImportObject) is returned by this function. The next logical step is take this output and feed it to Import-FimConfig.

    .EXAMPLE
        PS C:\$createRequest = New-FimImportObject -ObjectType Person -State Create -Changes @{
        AccountName='Bob'
        DisplayName='Bob the Builder'
        }
        PS C:\$createRequest | Import-FIMConfig

        DESCRIPTION
        -----------
        Creates an ImportObject for creating a new Person object with AccountName and DisplayName.
        The above sample uses a hashtable for the Changes parameter.

    .EXAMPLE
        PS C:\$createRequest = New-FimImportObject -ObjectType Person -State Create -Changes @(
        New-FimImportChange -Operation None -AttributeName 'Bob' -AttributeValue 'foobar'
        New-FimImportChange -Operation None -AttributeName 'DisplayName' -AttributeValue 'Bob the Builder'  )
        PS C:\$createRequest | Import-FIMConfig

        DESCRIPTION
        -----------
        Creates an ImportObject for creating a new Person object with AccountName and DisplayName.
        The above sample uses an array of ImportChange objects for the Changes parameter.

        NOTE: the attribute 'Operation' type of 'None' works when the object 'State' is set to 'Create'.

    .EXAMPLE
        PS C:\$updateRequest = New-FimImportObject -ObjectType Person -State Put -AnchorPairs @{AccountName='Bob'} -Changes @(
        New-FimImportChange -Operation Replace -AttributeName 'FirstName' -AttributeValue 'Bob'
        New-FimImportChange -Operation Replace -AttributeName 'LastName' -AttributeValue 'TheBuilder'  )
        PS C:\$updateRequest | Import-FIMConfig

        DESCRIPTION
        -----------
        Creates an ImportObject for updating an existing Person object with FirstName and LastName.

    .EXAMPLE
        PS C:\$deleteRequest = New-FimImportObject -ObjectType Person -State Delete -AnchorPairs @{AccountName='Bob'}
        PS C:\$deleteRequest | Import-FIMConfig

        DESCRIPTION
        -----------
        Creates an ImportObject for deleting an existing Person object.

    .NOTES
        Additional information about the function.
#>
    param
    (
    <#
    .PARAMETER ObjectType
    The object type for the target object.
    NOTE: this is case sensitive
    NOTE: this is the ResourceType's 'name' attribute, which often does NOT match what is seen in the FIM Portal.
    #>
        [parameter(Mandatory = $true)]
        [String]
        $ObjectType,

    <#
    .PARAMETER State
    The operation to perform on the target, must be one of:
    -Create
    -Put
    -Delete
    -Resolve
    -None
    #>
        [parameter(Mandatory = $true)]
        [String]
        [ValidateSet("Create", "Put", "Delete", "Resolve", "None")]
        $State,

    <#
    .PARAMETER AnchorPairs
    A name:value pair used to find a target object for Put, Delete and Resolve operations.  The AchorPairs is used in conjunction with the ObjectType by the FIM Import-FimConfig cmdlet to find the target object.
    #>
        [parameter(Mandatory = $false)]
        [ValidateScript({ $_ -is [Hashtable] -or $_ -is [Microsoft.ResourceManagement.Automation.ObjectModel.JoinPair[]] -or $_ -is [Microsoft.ResourceManagement.Automation.ObjectModel.JoinPair] })]
        $AnchorPairs,

    <#
    .PARAMETER SourceObjectIdentifier
    Not intelligently used or tested yet...
    #>
        [parameter(Mandatory = $false)]
        $SourceObjectIdentifier = [Guid]::Empty,

    <#
    .PARAMETER TargetObjectIdentifier
    The ObjectID of the object to operate on.
    Defaults to an empty GUID
    #>
        [parameter(Mandatory = $false)]
        $TargetObjectIdentifier = [Guid]::Empty,

    <#
    .PARAMETER Changes
    The changes to make to the target object.  This parameter accepts a Hashtable or FIM ImportChange objects as input. If a Hashtable is supplied as input then it will be converted into FIM ImportChange objects.  You're welcome.
    #>
        [parameter(Mandatory = $false)]
        [ValidateScript({ ($_ -is [Array] -and $_[0] -is [Microsoft.ResourceManagement.Automation.ObjectModel.ImportChange]) -or $_ -is [Hashtable] -or $_ -is [Microsoft.ResourceManagement.Automation.ObjectModel.ImportChange] })]
        $Changes,

    <#
    .PARAMETER ApplyNow
    When specified, will submit the request to FIM
    #>
        [Switch]
        $ApplyNow = $false,

    <#
    .PARAMETER PassThru
    When specified, will return the ImportObject as output
    #>
        [Switch]
        $PassThru = $false,

    <#
    .PARAMETER SkipDuplicateCheck
    When specified, will skip the duplicate create request check
    #>
        [Switch]
        $SkipDuplicateCheck = $false,

    <#
    .PARAMETER AllowAuthorizationException
    When specified, will swallow Auth Z Exception
    #>
        [Switch]
        $AllowAuthorizationException = $false,

    <#
    .PARAMETER Uri
    The Uniform Resource Identifier (URI) of themmsshortService. The following example shows how to set this parameter: -uri "http://localhost:5725"
    #>
        [String]
        $Uri = "http://localhost:5725"

    )
    end
    {
        $importObject = New-Object Microsoft.ResourceManagement.Automation.ObjectModel.ImportObject
        $importObject.SourceObjectIdentifier = $SourceObjectIdentifier
        $importObject.TargetObjectIdentifier = $TargetObjectIdentifier
        $importObject.ObjectType = $ObjectType
        $importObject.State = $State

        ###
        ### Process the Changes parameter
        ###
        if ($Changes -is [Hashtable])
        {
            foreach ($c in $changes.Keys)
            {
                try
                {
                    $importObject.Changes += New-FimImportChange -Uri $Uri -AttributeName $c -AttributeValue $changes[$c] -Operation Replace
                }
                catch
                {
                    $outerException = New-Object System.InvalidOperationException -ArgumentList "Attribute $c could not be added to the change set", ($_.Exception)
                    $PSCmdlet.ThrowTerminatingError((New-Object System.Management.Automation.ErrorRecord -ArgumentList ($outerException), "InvalidAttribute", ([System.Management.Automation.ErrorCategory]::InvalidArgument), ($changes[$c])))
                }
            }
        }
        else
        {
            $importObject.Changes = $Changes
        }

        ###
        ### Handle Reslove and Join Pairs
        ###
        if ($AnchorPairs)
        {
            if ($AnchorPairs -is [Microsoft.ResourceManagement.Automation.ObjectModel.JoinPair[]] -or $AnchorPairs -is [Microsoft.ResourceManagement.Automation.ObjectModel.JoinPair])
            {
                $importObject.AnchorPairs = $AnchorPairs
            }
            else
            {
                $AnchorPairs.GetEnumerator() |
                ForEach
                {
                    $anchorPair = New-Object Microsoft.ResourceManagement.Automation.ObjectModel.JoinPair
                    $anchorPair.AttributeName = $_.Key
                    $anchorPair.AttributeValue = $_.Value
                    $importObject.AnchorPairs += $anchorPair
                }
            }
        }

        ###
        ### Handle Put and Delete
        ###
        if (($State -ieq 'Put' -or $State -ieq 'Delete') -and $importObject.AnchorPairs.Count -eq 1)
        {
            $errorVariable = $null
            $targetID = Get-FimObjectID -ObjectType $ObjectType -Uri $Uri -AttributeName @($importObject.AnchorPairs)[0].AttributeName -AttributeValue @($importObject.AnchorPairs)[0].AttributeValue -ErrorAction SilentlyContinue -ErrorVariable errorVariable

            if ($errorVariable)
            {
                Write-Error $errorVariable[1]
            }
        }

        ###
        ### Handle Duplicate Values on a Put request
        ###
        if ($State -ieq 'Put')# -and $Operation -ieq 'Add')
        {
            ### Get the Target object
            $currentFimObject = Export-FIMConfig -Uri $Uri -OnlyBaseResources -CustomConfig ("/*[ObjectID='{0}']" -F $importObject.TargetObjectIdentifier) | Convert-FimExportToPSObject

            ### Create a new array containing only valid ADDs
            $uniqueImportChanges = @($importObject.Changes | Where-Object { $_.Operation -ne 'Add' })
            $importObject.Changes |
            Where-Object { $_.Operation -eq 'Add' } |
            ForEach-Object {
                Write-Verbose ("Checking to see if attribute '{0}' already has a value of '{1}'" -F $_.AttributeName, $_.AttributeValue)
                if ($currentFimObject.($_.AttributeName) -eq $_.AttributeValue)
                {
                    Write-Warning ("Duplicate attribute found: '{0}' '{1}'" -F $_.AttributeName, $_.AttributeValue)
                }
                else
                {
                    $uniqueImportChanges += $_
                }
            }
            ### Replace the Changes array with our validated array
            $importObject.Changes = $uniqueImportChanges
            $importObject.Changes = $importObject.Changes | Where { $_ -ne $null }

            if (-not ($importObject.Changes))
            {
                Write-Warning "No changes left on this Put request."
            }
        }

        if ($ApplyNow -eq $true)
        {
            if (-not $SkipDuplicateCheck)
            {
                $importObject = $importObject | Skip-DuplicateCreateRequest -Uri $Uri
            }

            if (-not $AllowAuthorizationException)
            {
                $importObject | Import-FIMConfig -Uri $Uri
            }
            else
            {
                try
                {
                    ###
                    ### We do this inside a try..catch because we need prevent Import-FimConfig from throwing an error
                    ### When Import-FimConfig submits a Request that hits an AuthZ policy, it raises an error
                    ### We want to eat that specific error to prevent the FIM Request from failing
                    ###

                    $importObject | Import-FIMConfig -Uri $Uri

                }
                catch
                {
                    if ($_.Exception.Message -ilike '*While creating a new object, the web service reported the object is pending authorization*')
                    {
                        Write-Verbose ("FIM reported the object is pending authorization:`n`t {0}" -f $_.Exception.Message)
                    }
                    else
                    {
                        throw
                    }
                }
            }
        }

        if ($PassThru -eq $true)
        {
            Write-Output $importObject
        }
    }
}
