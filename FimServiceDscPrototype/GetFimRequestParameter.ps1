function Get-FimRequestParameter
{
<#
	.SYNOPSIS 
	Gets a RequestParameter from a FIM Request into a PSObject

	.DESCRIPTION
	The Get-FimRequestParameter function makes it easier to view FIM Request Parameters by converting them from XML into PSObjects
	This makes it easier view the details for reporting, and for turning a FIM Request back into a new FIM Request to repro fubars
   
	.OUTPUTS
 	a PSObject with the following properties:
		1. PropertyName
		2. Value
		3. Operation
   
   	.EXAMPLE
	$request = Export-FIMConfig -only -CustomConfig ("/Request[TargetObjectType = 'Person']") | 
    	Select -First 1 |
    	Convert-FimExportToPSObject |
		Get-FimRequestParameter
	
		OUTPUT
		------
		Value                                PropertyName                            Operation
		-----                                ------------                            ---------
        CraigMartin                          AccountName                             Create
        CraigMartin                          DisplayName                             Create
        Craig                                FirstName                               Create
        Martin                               LastName                                Create
		Person                               ObjectType                              Create   
		4ba58a6e-5953-4c03-af83-7dbfb94691d4 ObjectID                                Create   
		7fb2b853-24f0-4498-9534-4e10589723c4 Creator                                 Create   
		
		DESCRIPTION
		-----------
		Gets one Request object from FIM, converts it to a PSOBject
#>
   	param
    ( 
		<#
		A String containing the FIM RequestParameter XML
        or
        A PSObject containing the RequestParameter property
		#>
        [parameter(Mandatory=$true, ValueFromPipeline = $true)]
        [ValidateScript({
		($_ -is [String] -and $_ -like "<RequestParameter*") `
		-or  `
		($_ -is [PSObject] -and $_.RequestParameter)})]
        $RequestParameter
    )
    process
    { 
        ### If the input is a PSObject then get just the RequestParameter property
        if ($RequestParameter -is [PSObject])
        {
            $RequestParameter = $RequestParameter.RequestParameter
        }
        
        $RequestParameter | foreach-Object{
            New-Object PSObject -Property @{
                PropertyName = ([xml]$_).RequestParameter.PropertyName
                Value = ([xml]$_).RequestParameter.Value.'#text'
                Operation = ([xml]$_).RequestParameter.Operation
                Mode = ([xml]$_).RequestParameter.Mode
            } | 
            Write-Output
        }
    }
}
