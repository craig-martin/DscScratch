function Get-ObjectSid
{
<#
.SYNOPSIS 
Gets the ObjectSID as Base64 Encoded String

.DESCRIPTION
GetSidAsBase64 tries to find the object, then translate it into a Base64 encoded string

.OUTPUTS
a string containing the Base64 encoded ObjectSID

.EXAMPLE
Get-ObjectSid -AccountName v-crmart -Verbose

OUTPUT
------
VERBOSE: Finding the SID for account: v-crmart
AQUAAAXXXAUVAAAAoGXPfnyLm1/nfIdwyoM6AA==  
	
DESCRIPTION
-----------
Gets the objectSID for 'v-crmart'
Does not supply a value for Domain

.EXAMPLE
Get-ObjectSid -AccountName v-crmart -Domain Redmond -Verbose

OUTPUT
------
VERBOSE: Finding the SID for account: Redmond\v-crmart
AQUAAAXXXAUVAAAAoGXPfnyLm1/nfIdwyoM6AA==  
	
DESCRIPTION
-----------
Gets the objectSID for 'v-crmart'
Does not supply a value for Domain
#>
    param
    (
		<#
		A String containing the SamAccountName
		#>
        [parameter(Mandatory = $true)]
        [String]
        $AccountName,
		<#
		A String containing the NetBIOS Domain Name
		#>
        [parameter(Mandatory = $false)]
        [String]
        $Domain
    )
    END
    {
        ###
        ### Construct the Account
        ###
        if ([String]::IsNullOrEmpty($Domain))
        {
            $account = $AccountName
        }
        else
        {
            $account = "{0}\{1}" -f $Domain, $AccountName
        }
        
        Write-Verbose "Finding the SID for account: $account"
        ###
        ### Get the ObjectSID
        ###
        $ntaccount = New-Object System.Security.Principal.NTAccount $account
        try
        {
            $binarySid = $ntaccount.Translate([System.Security.Principal.SecurityIdentifier])
        }
        catch
        {
            Throw @"
		Account could not be resolved to a SecurityIdentifier
"@
        }
        
        $bytes = new-object System.Byte[] -argumentList $binarySid.BinaryLength
        $binarySid.GetBinaryForm($bytes, 0)
        $stringSid = [System.Convert]::ToBase64String($bytes)
        
        Write-Output $stringSid
    }
}

