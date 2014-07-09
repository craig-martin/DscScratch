function New-FimImportChange
{
    Param
    (
        [parameter(Mandatory = $true)]
        [String]
        $AttributeName,

        [parameter(Mandatory = $false)]
        [ValidateScript({ ($_ -is [Array] -and $_.Count -eq 3) -or $_ -is [String] -or $_ -is [DateTime] -or $_ -is [Bool] -or $_ -is [Int] -or ($_ -is [Guid]) })]
        $AttributeValue,

        [parameter(Mandatory = $true)]
        [ValidateSet("Add", "Replace", "Delete", "None")]
        $Operation,

        [parameter(Mandatory = $false)]
        [Boolean]
        $FullyResolved = $true,

        [parameter(Mandatory = $false)]
        [String]
        $Locale = "Invariant",

        [String]
        $Uri = "http://localhost:5725"
    )
    END
    {
        $importChange = New-Object Microsoft.ResourceManagement.Automation.ObjectModel.ImportChange
        $importChange.Operation = $Operation
        $importChange.AttributeName = $AttributeName
        $importChange.FullyResolved = $FullyResolved
        $importChange.Locale = $Locale

        ###
        ### Process the AttributeValue Parameter
        ###
        if ($AttributeValue -is [String])
        {
            $importChange.AttributeValue = $AttributeValue
        }
        elseif ($AttributeValue -is [DateTime])
        {
            $importChange.AttributeValue = $AttributeValue.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.000")
        }
        elseif (($AttributeValue -is [Boolean]) -or ($AttributeValue -is [Int]) -or ($AttributeValue -is [Guid]))
        {
            $importChange.AttributeValue = $AttributeValue.ToString()
        }
        elseif ($AttributeValue -is [Array])
        {
            ###
            ### Resolve Resolve Resolve
            ###
            if ($AttributeValue.Count -ne 3)
            {
                Write-Error "For the 'Resolve' option to work, the AttributeValue parameter requires 3 values in this order: ObjectType, AttributeName, AttributeValue"
            }
            $objectId = Get-FimObjectID -Uri $Uri -ObjectType $AttributeValue[0] -AttributeName $AttributeValue[1] -AttributeValue $AttributeValue[2]

            if (-not $objectId)
            {
                Throw (@"
                FIM Resolve operation failed for: {0}:{1}:{2}
                Could not find an object of type '{0}' with an attribute '{1}' value equal to '{2}'
"@ -F $AttributeValue[0], $AttributeValue[1], $AttributeValue[2])
            }
            else
            {
                $importChange.AttributeValue = $objectId
            }
        }
        else
        {
            Write-Verbose "Null or unsupported `$attributeValue provided"
        }
        $importChange
    }
}
