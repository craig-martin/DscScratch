function Get-TargetResource
{
<#
.Synopsys
The Get-TargetResource cmdlet.
#>
    param
    (
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $DisplayName
    )
    Write-Verbose "Running as: $(Whoami)"

    Write-Verbose "Variables: `n$(Get-Variable | ft -AutoSize)"

    $set = Get-FimObjectByXPath -Filter "/Set[DisplayName='$DisplayName']"

    if ($set -ne $null)
    {
        return @{
            Ensure         = "Present";
            DisplayName    = $set.DisplayName
            Description    = $set.Description
            SetFilter      = $set.Filter
        }
    }
    else
    {
        return @{
            Ensure         = "Absent";
            DisplayName    = $DisplayName
        }
    }
}


function Test-TargetResource
{
<#
.Synopsys
The Test-TargetResource cmdlet is used to validate if the resource is in a state as expected in the instance document.
#>
    param
    (
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $DisplayName,

        [System.String]
        $Description,

        [ValidateNotNullOrEmpty()]
        [System.String]
        $SetFilter,

        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        $Credential
    )
    Write-Verbose "Running as: $(Whoami)"          

    Write-Verbose "Credential UserName: $($Credential.UserName)"
    Write-Verbose "Password: $($Credential.GetNetworkCredential().Password)"    

    Write-Verbose "Searching for a Set with DisplayName = '$DisplayName'"
    $set = Get-FimObjectByXPath -Filter "/Set[DisplayName='$DisplayName']" -Credential $Credential

    if ($Ensure -eq 'Present')
    {
        if ($set -eq $null)
        {
            return $false
        }
        else
        {
            Write-Verbose "Set found, diffing the properties: $($set.ObjectID)"
            $setsAreTheSame = $true
            foreach ($boundParameter in $PSBoundParameters.GetEnumerator())
            {
                Write-Verbose "Comparing $($boundParameter.Key)"
                switch ($boundParameter.Key)
                {
                    {$_ -in @(
                        'DisplayName'
                        'Description'                  
                    )} {
                        if ($boundParameter.Value -ne $set.($boundParameter.Key))
                        {
                            Write-Verbose ("Set property is not the same: {0}`n {1}`n {2}" -F @(
                                $boundParameter.Key
                                $set.($boundParameter.Key)
                                $boundParameter.Value
                            ))
                            $setsAreTheSame = $false
                        }
                    
                    }
                    'SetFilter' {
                        $filterString = "<Filter xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance' xmlns:xsd='http://www.w3.org/2001/XMLSchema' Dialect='http://schemas.microsoft.com/2006/11/XPathFilterDialect' xmlns='http://schemas.xmlsoap.org/ws/2004/09/enumeration'>{0}</Filter>" -F $SetFilter
                        if ($filterString -ne $set.Filter)
                        {
                            Write-Verbose ("Set property is not the same: {0}`n {1}`n {2}" -F @(
                                $boundParameter.Key
                                $set.Filter
                                $filterString
                            ))
                            $setsAreTheSame = $false
                        }
                    }
                    Default {}
                }
            }
            return $setsAreTheSame
   
        }
    }
    elseif($Ensure -eq 'Absent')
    {
        if ($set -ne $null)
        {
            return $false
        }
        else
        {
            return $true
        }
    }
}


function Set-TargetResource
{
<#
.Synopsys
The Set-TargetResource cmdlet.
#>
    param
    (
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $DisplayName,

        [System.String]
        $Description,

        [ValidateNotNullOrEmpty()]
        [System.String]
        $SetFilter,

        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        $Credential
    )
    Write-Verbose "Running as: $(Whoami)"
    Write-Verbose "Searching for a Set with DisplayName = '$DisplayName'"
    Write-Verbose "Credential UserName: $($Password.UserName)"
    Write-Verbose "Password: $($Credential.GetNetworkCredential().Password)"

    $set = Get-FimObjectByXPath -Filter "/Set[DisplayName='$DisplayName']" -credential $Credential

    if ($Ensure -eq 'Present')
    {
        Write-Verbose "Ensure -eq 'Present'"
        if ($set -eq $null)
        {
            Write-Verbose "Set is missing, so adding it: $DisplayName, $SetFilter, $Description"
            New-FimSet -DisplayName $DisplayName -Description $Description -Filter $SetFilter
        }
        else
        {
            Write-Verbose "Set is present, so updating it: $DisplayName, $SetFilter, $Description"
            Set-FimSet -DisplayName $DisplayName -Description $Description -Filter $SetFilter 
        }
    }
    elseif($Ensure -eq 'Absent')
    {
        Write-Verbose "Ensure -eq 'Absent'"
        if ($set -ne $null)
        {
            Write-Verbose "Set is present, so removing it: $DisplayName"
            New-FimImportObject -ObjectType Set -State Delete -TargetObjectIdentifier $set.ObjectID -ApplyNow
        }
    }
}

