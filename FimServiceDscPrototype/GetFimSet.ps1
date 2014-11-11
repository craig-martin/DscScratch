function Get-FimSet
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $false)]
        $Identifier,
        [Parameter(Mandatory = $false)]
        $Uri = "http://localhost:5725"
    )
    end
    {
        if ($Identifier)
        {
            if ($Identifier -is [string])
            {
                if ($Identifier -match '^.+\*$')
                {
                    $startswith = $Identifier -replace '\*', ''
                    $filter = "/Set[starts-with(DisplayName,'{0}')]" -f $startswith
                }
                elseif ($Identifier -match '^\*[a-z ]+$')
                {
                    $endswith = $Identifier -replace '\*', ''
                    $filter = "/Set[ends-with(DisplayName,'{0}')]" -f $endswith
                }
                else
                {
                    $filter = "/Set[DisplayName='{0}']" -f $identifier
                }
            }
            else
            {
                $filter = '/Set'
            }
            
        }
        else
        {
            $filter = '/Set'
            
        }
        
        $sets = Get-FimObjectByXpath -Filter $filter
        
        foreach ($s in $sets)
        {
            if ($s.Filter)
            {
                $xml = [xml]$s.Filter
                $s.Filter = $xml.Filter.'#text'
            }
            if ($s.ExplicitMember)
            {
                $s.ExplicitMember = $s.ExplicitMember | ForEach-Object{ $_ -replace 'urn:uuid:', '' }
            }
        }
        Write-Output $sets
    }
}

