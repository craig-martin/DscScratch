Function Get-ManagementAgent
{
<#
   .SYNOPSIS 
   Gets the Management Agent(s) from a FIM SyncHronization Server 

   .DESCRIPTION
   The Get-ManagementAgent function uses the MIIS WMI class to get the management agent   

   .PARAMETER ManagementAgentName
   Specifies the name of the MA to be retrieved.
   
   .PARAMETER ComputerName
   Specifies the name of the MA to be retrieved.
   
   .PARAMETER Credential
   Specifies the name of the MA to be retrieved.   

   .OUTPUTS
   The WMI object containing the management agent
   
   	.EXAMPLE
   	Get-ManagementAgent -Verbose -ManagementAgent ([GUID]'C19E29D8-FD3C-4A44-9E80-BCF5924FE26B')
	
	.EXAMPLE
	Get-ManagementAgent -Verbose -ManagementAgent C19E29D8-FD3C-4A44-9E80-BCF5924FE26B
	
	.EXAMPLE
	Get-ManagementAgent -Verbose -ManagementAgent AD_MA -ComputerName MyServer -Credential (Get-Credential)
    This command will will retrieve a Management Agent called "AD_MA" on a remote server using
    alternate credentials
	
	.EXAMPLE
	Get-ManagementAgent -Verbose
    This command will will retrieve all Management Agents on the local server.

    .LINK
    https://fimpowershellmodule.codeplex.com/
#>
  Param
    (        
        [parameter(Mandatory=$false)] 
		[alias(“ManagementAgentName”)]
        $ManagementAgent,

        ##New Params added by Paul Smith 04-07-14
        [parameter(Mandatory=$false)] 
		[alias(“ManagementAgentComputerName”)]
        $ComputerName,
        
        [parameter(Mandatory=$false)] 
		[alias(“ManagementAgentCredential”)]
        $Credential		
    ) 
    End    
    {
		###
		### If MA is not supplied, return all MAs
		### Otherwise find the MA based on the type of input
		###	
        $Get_WMIObject = "Get-WmiObject"
        $ArgumentList = @("-Class MIIS_ManagementAgent", "-Namespace root/MicrosoftIdentityIntegrationServer") 
		if($ManagementAgent -is [String])
		{     
			###
			### somebody might give us a GUID string as input, so try to convert the string to a GUID
			###
            $maGuid = $ManagementAgent -as [GUID]
            if ($maGuid)
            {
                Write-Verbose ("Using the supplied STRING converted to a GUID to get the MA: {0}" -F $ManagementAgent)
                $ArgumentList += "-Filter {(" + ("Guid='{0}'" -F $maGuid.ToString('b')) + ")}"
            }
            else
            {
                Write-Verbose ("Using the supplied STRING to get the MA: {0}" -F $ManagementAgent)
                $ArgumentList += "-Filter {(Name=" + "'" + $ManagementAgent + "')}"
            }			
		}
        elseif($ManagementAgent -is [Guid])
        {
            Write-Verbose ("Using the supplied GUID to get the MA: {0}" -F $ManagementAgent.ToString('b'))
            $ArgumentList +=  "-Filter {(" + ("Guid='{0}'" -F $ManagementAgent.ToString('b')) + ")}" 
        }

        if ($ComputerName){$ArgumentList += "-ComputerName $ComputerName"}
        if ($Credential){$ArgumentList += "-Credential `$Credential"}
        Write-Verbose ("Running Command: Invoke-Expression $Get_WMIObject $ArgumentList")

        Invoke-Expression "$Get_WMIObject $ArgumentList"     
    }
}

Function Get-ManagementAgentCounts
{
<#
   .SYNOPSIS 
   Gets the Num* Counters of a Management Agent 

   .DESCRIPTION
   The Get-ManagementAgentCounts function uses the Get-Member cmdlet to find all of the Num* methods on the MA
   It then executes them all and returns a new object that has all the counts

   .PARAMETER ManagementAgent
   Specifies the MA for which the counts will be collected
   This can either be the MA name as [String]
   or the WMI object using the MicrosoftIdentityIntegrationServer:MIIS_ManagementAgent class

   .OUTPUTS
   a new PSObject containing all of the counts
#>
   Param
    (        
        [parameter(Mandatory=$true, ValueFromPipeline = $true)]              
        $ManagementAgent
    ) 
	
	if ($ManagementAgent -is [System.Management.ManagementObject])
	{
		$MAGuid = $ManagementAgent.Guid
		$MAName = $ManagementAgent.Name
	}
	elseif($ManagementAgent -is [String])
	{
		$wmiMA = [wmi]"root\MicrosoftIdentityIntegrationServer:MIIS_ManagementAgent.Name='$ManagementAgent'"
		$MAGuid = $wmiMA.Guid
		$MAName = $wmiMA.Name
	}		
	
	$ma = Get-ManagementAgent $MAName
	$maCounts = New-Object PSObject 
	foreach ($method in $ma | Get-Member -MemberType Method | Where-Object {$_.Name -Like "Num*"} | Select-Object -ExpandProperty Name)
	{
	    $maCounts | 
	        Add-Member -MemberType noteproperty -name $method -value `
	        (
	            $ma | % {$_.$method.Invoke() } | 
	            Select-Object -ExpandProperty ReturnValue
	        )
	}
	$maCounts
}

function Get-MIIS_CSObject
{  
<#
   	.SYNOPSIS 
   	Gets the a CSObject using WMI 

   	.DESCRIPTION
   	The Get-MIIS_CSObject function uses the Get-WmiObject cmdlet to query for a MIIS_CSObject in FIM Sync.
   	MSDN has good documentation for MIIS_CSObject:
   	http://msdn.microsoft.com/en-us/library/windows/desktop/ms697741(v=vs.85).aspx

   	.OUTPUTS
   	the MIIS_CSObject returned by WMI
   	If searching by MVGuid, there may be multiple CSObjects returned because an MVObject can have multiple CSObjects joined to it
   
   	.EXAMPLE
   	Get-MIIS_CSObject -Account Britta.Simon -Domain Litware -Verbose
	
	.EXAMPLE
   	Get-MIIS_CSObject -ManagementAgent Litware -DN 'CN=Britta.Simon,DC=Litware,DC=com'
   
   	.EXAMPLE
   	Get-MIIS_CSObject -MVGuid 45556324-9a22-446e-8adb-65b29eb60943 -Verbose
   
  	.EXAMPLE
   	Get-MIIS_CSObject -Account Britta.Simon -Domain Litware -ComputerName FIM01 -Verbose
#>
    param
    (     
		<#
		Specifies the Account name of the object to search for in an ADMA
		#>
        [parameter(ParameterSetName="QueryByAccountAndDomain")] 
        $Account,
		
		<#
		Specifies the Domain (netbios domain name) of the object to search for in an ADMA
		#>
        [parameter(ParameterSetName="QueryByAccountAndDomain")] 
        $Domain,

		<#
		Specifies the DistinguishedName of the object to search for
		#>
        [parameter(ParameterSetName="QueryByDNAndMA")] 
        $DN,
		
		<#
		Specifies ManagementAgent to search in
		#>
        [parameter(ParameterSetName="QueryByDNAndMA")] 
        $ManagementAgent,

		<#
		Specifies the Metaverse GUID to search for
		#>
        [parameter(ParameterSetName="QueryByMvGuid")]
        [Guid] 
        $MVGuid,
		
		<#
		Specifies the ComputerName where FIMSync is running 
		(defaults to localhost)
		#>		
        [String]
        $ComputerName = (hostname)
    )   
    switch ($PsCmdlet.ParameterSetName) 
    { 
        QueryByAccountAndDomain  
        { 
            $wmiFilter = "Account='{0}' and Domain='{1}'" -F $Account, $Domain    
        } 
        QueryByDNAndMA  
        { 
            $ma = Get-ManagementAgent $ManagementAgent
            if (-not $ma)
            {
                throw "Sorry, I was really hoping that MA would exist on this server."
            }
            $wmiFilter = "DN='{0}' and MaGuid='{1}'" -F $DN, $ma.Guid    
        } 
        QueryByMvGuid
        {            
            $wmiFilter = "MVGuid='{$MVGuid}'"    
        }
    }##Closing: switch ($PsCmdlet.ParameterSetName)
    
    Write-Verbose "Querying WMI using ComputerName: '$ComputerName'"
    Write-Verbose "Querying FIM Sync for a MIIS_CSObject using filter: $wmiFilter"
    Get-WmiObject -ComputerName $ComputerName -Class MIIS_CSObject -Namespace root/MicrosoftIdentityIntegrationServer -filter $wmiFilter  
}

function Format-XML($xmlFile, $indent=2)
{
	<#
   	.SYNOPSIS 
   	Formats an XML file
	#>
    $StringWriter = New-Object System.IO.StringWriter
    $XmlWriter = New-Object System.Xml.XmlTextWriter $StringWriter
    $xmlWriter.Formatting = "indented"
    $xmlWriter.Indentation = 4

    [XML]$xml = Get-Content $xmlFile
    $xml.WriteContentTo($XmlWriter)
    $XmlWriter.Flush()
    $StringWriter.Flush()
    $StringWriter.ToString()  | Out-File -Encoding "UTF8" -FilePath $xmlFile
}

function Format-FimSynchronizationConfigurationFiles
{
<#
   	.SYNOPSIS 
   	Formats the XML in the FIM Sync configuration files 

   	.DESCRIPTION
   	The FIM synchronization XMLs are not formatted when created by FIM.  This makes source control a little ugly when diffing the files.
	This function simply formats the XML files to make them easier to diff.

   	.OUTPUTS
   	None.  the function operates on the existing files.
   
   	.EXAMPLE
   	Format-FimSynchronizationConfigurationFiles c:\MyFimSyncConfigFolder
#>
   Param
   	(       
   		<#
		Specifies the folder containing the MA and MV XML files 
		(defaults to the current folder)
		#>		
        [parameter(Mandatory=$false)]
		[String]
		[ValidateScript({Test-Path $_})]
		$ServerConfigurationFolder = (Get-Location),
        <# Set to false if you do not want to rename files to friendly names #>
        [parameter()]
        [Switch]
        $RenameFiles = $true
   	) 
	###Change to $ServerConfigurationFolder
	Write-Verbose "Changing to the directory: $ServerConfigurationFolder" 
	Set-Location $ServerConfigurationFolder
   
	###Process each of the MA XML files
	$maFiles=(get-item "MA-*.xml")
	foreach($maFile in $maFiles)
	{
	    Write-Verbose "Processing MA XML file: $maFile"

	    ###Clear the ReadOnly Flag
	    (get-item $maFile).Set_IsReadOnly($false)

	    ###Format the XML File
	    Format-XML $maFile

        if ($RenameFiles)
        {
	        ###Match the MA Name to the MA ID
	        $maName=(select-xml $maFile -XPath "//ma-data/name").Node.InnerText
	        $maID=(select-xml $maFile -XPath "//ma-data/id").Node.InnerText

	        ###Only rename the file if it doesn't already contain the MA Name
	        if($maFile -inotcontains $maName)
	        {
	            Rename-Item $maFile -NewName "MA-$maName.XML"
	        }
        }
	}
	Write-Verbose "Processing MV.XML file"

	###Clear the ReadOnly Flag
	(get-item "MV.xml").Set_IsReadOnly($false)
	###Format the MV XML file
	Format-XML "MV.xml"   
}

Function Assert-CSAttribute
{
<#
   .SYNOPSIS 
   Asserts that a CSObject contains the expected attribute value 

   .DESCRIPTION
   The Assert-CSAttribute function checks the CSObject for an attribute
   It then asserts the attribute value

   .OUTPUTS
   Console output with the assertion results
   
   .EXAMPLE
   $CSObject = Get-MIIS_CSObject -ManagementAgent AD -DN 'CN=Britta.Simon,DC=contoso,DC=coma'
   C:\PS>Assert-CSAttribute -MIIS_CSObject $CSObject -CSAttributeName userPrincipalName -CSAttributeValue Britta.Simon@contoso.com -Hologram UnappliedExportHologram
   
   .EXAMPLE
   Get-MIIS_CSObject -ManagementAgent AD -DN 'CN=Britta.Simon,DC=contoso,DC=com' | Assert-CSAttribute userPrincipalName Britta.Simon@contoso.com
   
#>
    [CmdletBinding()]
    Param
       (        
        #The MIIS_CSObject as the WMI object from FIM     
        [parameter(Mandatory=$true, ValueFromPipeline=$true)]        
        $MIIS_CSObject,
        
        #The CS Attribute name to test
        [parameter(Mandatory=$true,Position=0)]
        [String]
        $CSAttributeName,

        #The CS Attribute value to test
    	[parameter(Mandatory=$true,Position=1)]
        $CSAttributeValue,
        
        #The location in the CSObject to look for the attribute
        #Must be one of: Hologram, EscrowedExportHologram, PendingImportHologram, UnappliedExportHologram, UnconfirmedExportHologram
        [parameter(Mandatory=$false,Position=2)]
        [ValidateSet(“Hologram”, “EscrowedExportHologram”, “PendingImportHologram”,"UnappliedExportHologram","UnconfirmedExportHologram")]
        [String[]]
        $Hologram = 'Hologram'
    ) 
	Process
	{
        [xml]$hologramXML= $MIIS_CSObject.($Hologram)

        $csAttribute = $hologramXML.entry.attr | where {$_.name -ieq $CSAttributeName}
        if (-not $csAttribute)
        {
            Write-Host "FAIL: $CSAttributeName not present." -ForegroundColor Red
            Continue
        }
        else
        {
        	Write-Verbose "$CSAttributeName found in the hologram"   
        		    
        	if ($CSAttributeValue -eq $csAttribute.value)
        	{
        		Write-Host ("PASS: $CSAttributeName has the expected value: '{0}'" -F $csAttribute.value) -ForegroundColor Green
        	}
        	else
        	{
        		Write-Host ("FAIL: $CSAttributeName expected value not equal to the actual value.`n`tExpected: '{0}'`n`tActual:   '{1}'" -F $CSAttributeValue, $csAttribute.value) -ForegroundColor Red
        	}	
        }	
	}##Closing: End
}##Closing: Function Assert-CSAttribute

Function New-ImportFileFromCSEntry
{
<#
	.SYNOPSIS 
	Creates a Drop File from a Connector Space Object 

	.DESCRIPTION
	The New-ImportFileFromCSEntry gets a CSObject and dumps its Synchronized Hologram to a drop file that can be used by a Run Profile that is configured to pick up drop files.

	.OUTPUTS
	None, but it generates a file containing the CSObject.
   
    .EXAMPLE
    Get-MIIS_CSObject -ManagementAgent AD -DN 'CN=Britta Simon,DC=contoso,DC=com' | New-ImportFileFromCSEntry -Verbose
   
    .EXAMPLE
    Get-MIIS_CSObject -ManagementAgent AD -DN 'CN=Britta Simon,DC=contoso,DC=com' | New-ImportFileFromCSEntry -Verbose -PassThru
   
    .EXAMPLE
    Get-MIIS_CSObject -ManagementAgent AD -DN 'CN=Britta Simon,DC=contoso,DC=com' | New-ImportFileFromCSEntry -Verbose -CopyToMADataFolder
   
    .EXAMPLE 
    Get-MIIS_CSObject -ManagementAgent AD -DN 'CN=Britta Simon,DC=contoso,DC=com' | New-ImportFileFromCSEntry -Hologram PendingImportHologram -Verbose
   
   
#>
    [CmdletBinding()]
    Param
       (        
        #The MIIS_CSObject as the WMI object from FIM     
        [parameter(Mandatory=$true, ValueFromPipeline=$true)]        
        $MIIS_CSObject,
        
        #Off by default. When supplied it will copy the output file to the MAData folder for the specified MA
        [Switch]
        $CopyToMADataFolder = $false,
        
        #The location in the CSObject to look for the attribute
        #Must be one of: Hologram, EscrowedExportHologram, PendingImportHologram, UnappliedExportHologram, UnconfirmedExportHologram
        [parameter(Mandatory=$false,Position=0)]
        [ValidateSet(“Hologram”, “EscrowedExportHologram”, “PendingImportHologram”,"UnappliedExportHologram","UnconfirmedExportHologram")]
        [String[]]
        $Hologram = 'Hologram',
        
        #Write the XML to output
        [Switch]
        $PassThru
    ) 
	Process
	{
        if (-not ($MIIS_CSObject.($Hologram)))
        {            
            $validHolograms = @()
            (“Hologram”, “EscrowedExportHologram”, “PendingImportHologram”,"UnappliedExportHologram","UnconfirmedExportHologram") | % { if ($MIIS_CSObject.($_)){$validHolograms += $_}}
            
            Write-Warning ("The CSObject does NOT have the specified hologram: $Hologram. Please Try Again. `nHINTING: The CSObject DOES have these holograms: {0}" -F ($validHolograms -join ', '))
            Continue ## Get outta this Process block without writing output to the pipeline
        }

        ### Construct a file name using the CS ID
        $outputFileName = "{0}-{1}.xml" -F $MIIS_CSObject.MaName,$MIIS_CSObject.MaGuid
        Write-Verbose "CSObject will output to this file name: $outputFileName"
        
        ### Change the CSEntry to look like an audit entry
        ### then output to the file
        Write-Verbose "Constructing the XML based on the CSObject's '$Hologram' Hologram..."
        $dropFileXml = @"
<?xml version="1.0" encoding="UTF-16" ?>
<mmsml xmlns="http://www.microsoft.com/mms/mmsml/v2" step-type="delta-import">
<directory-entries>
"@

        $dropFileXml += $MIIS_CSObject.($Hologram) -replace "<entry", "<delta operation='replace'" -replace "</entry>","</delta>"

        $dropFileXml += "</directory-entries></mmsml>"

        if ($PassThru)
        {
            Write-Output $dropFileXml
        }
        else
        {
            Write-Verbose "Saving the XML to file: '$outputFileName'"
            $dropFileXml | out-file -Encoding Unicode -FilePath $outputFileName
        }
        
        if ($CopyToMADataFolder)
        {
            $fimRegKey = Get-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Services\FIMSynchronizationService\Parameters 
            $maDataFileName = "{0}MaData\{1}\{2}" -F $fimRegKey.Path, $MIIS_CSObject.MaName, $outputFileName
            Write-Verbose "Saving the XML to file: '$maDataFileName'"           
            $dropFileXml | out-file -Encoding Unicode -FilePath $maDataFileName
        }

	}##Closing: Process
}##Closing: Function Create-ImportfileFromCSEntry

function Start-ManagementAgent
{
<#
.Synopsis
   Executes a Run Profile on a FIM Management Agent
.DESCRIPTION
   Uses WMI to call the Execute method on the WMI MIIS_ManagementAgent Class
.EXAMPLE
   Start-ManagementAgent corp 'TEST-DISO-DROPFILE (africa)'
.EXAMPLE
   Start-ManagementAgent myReallyBigMAOne 'FullImport' -AsJob
   Start-ManagementAgent myReallyBigMATwo 'FullImport' -AsJob
   Get-Job | Receive-Job
.EXAMPLE
   @(
    ('corp','TEST-DISO-DROPFILE (redmond)'),
    ('corp','TEST-DISO-DROPFILE (europed)'),
    ('corp','TEST-DISO-DROPFILE (africa)')
) | Start-ManagementAgent
.EXAMPLE
   @(
    ('corp','TEST-DISO-DROPFILE (redmond)'),
    ('corp','TEST-DISO-DROPFILE (europed)'),
    ('corp','TEST-DISO-DROPFILE (africa)')
) | Start-ManagementAgent -StopOnError
.EXAMPLE
   @(
    ('corp','TEST-DISO-DROPFILE (redmond)'),
    ('corp','TEST-DISO-DROPFILE (europed)'),
    ('corp','TEST-DISO-DROPFILE (africa)')
) | Start-ManagementAgent -AsJob
.EXAMPLE
try{
    Start-ManagementAgent CORP      'DISO (redmond)'     -StopOnError
    Start-ManagementAgent CORP      'DS (redmond)'       -StopOnError
    Start-ManagementAgent HOME  	'DISO (All Domains) '-StopOnError

    ### FIM Export, Import and Sync
    Start-ManagementAgent FIM   	'Export'             -StopOnError
    Start-ManagementAgent FIM   	'Delta Import'       -StopOnError
    Start-ManagementAgent FIM   	'Delta Sync'         -StopOnError
}
catch
{    
    ### Assign the Exception to a variable to play with
    $maRunException = $_

    ### Show the MA returnValue
    $maRunException.FullyQualifiedErrorId

    ### Show the details of the MA that failed
    $maRunException.TargetObject.MaGuid
    $maRunException.TargetObject.MaName
    $maRunException.TargetObject.RunNumber
    $maRunException.TargetObject.RunProfile
}
.EXAMPLE
try
{
    Start-ManagementAgent AD_MA 'full import' -StopOnError
}
catch
{
    $_.TargetObject
}
.INPUTS
   Inputs to this cmdlet (if any)
.OUTPUTS
   String ReturnValue - returned by the Execute() method of the WMI MIIS_ManagementAgent Class
#>
    [CmdletBinding()]
    [OutputType([String])]
    Param
    (
        # Management Agent Name
        [Parameter(Position = 0,ParameterSetName='SingleRunProfile')]    
        [Alias("MA")] 
        [String]
        $ManagementAgentName,

        # RunProfile Name
        [Parameter(Position = 1,ParameterSetName='SingleRunProfile')]
        [ValidateNotNull()]
        [String]
        $RunProfile,

        # List of Management Agent Names and Run Profile Names
        [Parameter(ParameterSetName='MultipleRunProfiles',ValueFromPipeline = $true)]
        [Array]
        $RunProfileList,

        # StopOnError
        [Switch]
        $StopOnError,

        # Run the Management as a PowerShell Job
        [Switch]
        $AsJob

    )
    Process
    {
        switch ($PsCmdlet.ParameterSetName) 
        { 
            SingleRunProfile 
            {
                ### No action required here yet because the inputs are as we need them to be in this parameter set             
            }
            MultipleRunProfiles
            {
                ### Get the MA Name and Run Profile name from the array item
                $ManagementAgentName = $RunProfileList[0]
                $RunProfile = $RunProfileList[1]          
            }
        }##Closing: switch ($PsCmdlet.ParameterSetName)
		
        Write-Verbose "Using $ManagementAgentName as the MA name."
        Write-Verbose "Using $RunProfile as the RunProfile name."

        ### Get the WMI MA
        $ManagementAgent = Get-ManagementAgent $ManagementAgentName
        if (-not (Get-ManagementAgent $ManagementAgentName))
        {
            throw ("MA not found.{0}" -F $ManagementAgentName)
        }

        if ($AsJob)
        {
            Start-Job -Name "Start-ManagementAgent-$ManagementAgentName-$RunProfile" -ArgumentList $ManagementAgentName,$RunProfile  -ScriptBlock {
					### Use gwmi to get the MA - we already verified that the MA exists so this should be safe.  What could possibly go wrong?
                    $ManagementAgent = Get-WmiObject -Class MIIS_ManagementAgent -Namespace root/MicrosoftIdentityIntegrationServer -Filter ("Name='{0}'" -f $args[0]) 
                    $RunProfile = $args[1]
					
                    ### Execute the Run Profile on the MA
                    $ReturnValue = $ManagementAgent.Execute($RunProfile).ReturnValue 
        
                    ### Construct a nice little parting gift for our callers
                    $ReturnObject = New-Object PSObject -Property @{            
                        MaName = $ManagementAgent.Name            
                        RunProfile = $ManagementAgent.RunProfile().ReturnValue
                        ReturnValue = $ReturnValue
                        RunNumber = $ManagementAgent.RunNumber().ReturnValue
                        #MaGuid = $ManagementAgent.Guid
                    }    
        			
					### Return our output - this will be held in the job until the caller does Receive-Job
                    Write-Output $ReturnObject   
            }##Closing: Start-Job -ScriptBlow
        }##Closing if($AssJob)
        else
        {
            ### Execute the Run Profile on the MA
            $ReturnValue = $ManagementAgent.Execute($RunProfile).ReturnValue 
        
            ### Construct a nice little parting gift for our callers
            $ReturnObject = New-Object PSObject -Property @{            
                MaName = $ManagementAgent.Name            
                RunProfile = $ManagementAgent.RunProfile().ReturnValue
                ReturnValue = $ReturnValue
                RunNumber = $ManagementAgent.RunNumber().ReturnValue
                #MaGuid = $ManagementAgent.Guid
            }       

			### Return our output - this will get sent to the caller when the MA finishes
            Write-output $ReturnObject

		    ### Throw according to $StopOnError
		    if ($StopOnError -and $ReturnValue -ne 'success')
            {            
                throw New-Object Management.Automation.ErrorRecord @(
                    New-Object InvalidOperationException "Stopping because the MA status was not 'success': $ReturnValue"
                    $ReturnValue
                    [Management.Automation.ErrorCategory]::InvalidResult
                    $ReturnObject
                )
            }##Closing: if ($StopOnError...
        }##Closing: else - from if($AsJob)
    }##Closing: Process
}##Closing: fucntion Start-ManagementAgent

function Confirm-ManagementAgentCounts
{
<#
.Synopsis
   Validate the counters of a Management Agent's Connector Space
.DESCRIPTION
   Uses the WMI object of the MA to validate based on number and/or percentage
.EXAMPLE
   $managementAgentTolerances = @{
	    MaxNumImportAdd    	= 0
	    MaxNumExportAdd 	= 0
	    MaxPercentImportAdd = 0
	}
	'MyMAName' | Confirm-ManagementAgentCounts @managementAgentTolerances -ThrowWhenMaxExceeded -Verbose
.EXAMPLE
   	$managementAgentTolerances = @{
	    MaxNumImportAdd    	= 0
	    MaxNumExportAdd 	= 0
	    MaxPercentImportAdd = 0
	}
	Start-ManagementAgent MyMaName 'Export' | Confirm-ManagementAgentCounts @managementAgentTolerances -ThrowWhenMaxExceeded -Verbose
.EXAMPLE
	$managementAgentTolerances = @{
	    MaxNumImportDelete        = 1000
	    MaxNumExportDelete        = 1000
	    MaxPercentExportUpdateAdd = 10
	}

	Start-ManagementAgent MA1  	'Delta Import' -AsJob	
	Start-ManagementAgent MA2 	'Delta Import' -AsJob 	
	Start-ManagementAgent MA3 	'Delta Import' -AsJob	
	Get-Job | Wait-Job | Receive-Job | Confirm-ManagementAgentCounts @managementAgentTolerances -ThrowWhenMaxExceeded -Verbose

#>
    [CmdletBinding()]
    [OutputType([PSObject])]
    Param
    (
		[Parameter(Mandatory=$true, ValueFromPipelineByPropertyName = $true,ValueFromPipeline = $true)] 
        [Alias("MaName")]
        [String]             
        $ManagementAgentName,

        [Switch]
        $ThrowWhenMaxExceeded,

        [int]
        $MaxNumExportAdd,

        [int]
        $MaxNumExportUpdate,

        [int]
        $MaxNumExportDelete,

        [int]
        $MaxNumImportAdd,

        [int]
        $MaxNumImportUpdate,

        [int]
        $MaxNumImportDelete,

        [int]
        $MaxPercentExportAdd,

        [int]
        $MaxPercentExportUpdate,

        [int]
        $MaxPercentExportDelete,

        [int]
        $MaxPercentImportAdd,

        [int]
        $MaxPercentImportUpdate,

        [int]
        $MaxPercentImportDelete
    )
    Process
    {
	    ###
        ### Get the MA
        ###
        $ma = Get-ManagementAgent $ManagementAgentName
        if (-not $ma)
        {
           throw "Sorry, I was really hoping that MA would exist on this server."
        }
        Write-Verbose ("Using MA: {0}" -F $ma.Name)
	
        ###
        ### Get the current MA ConnectorSpace counters
        ###
		Write-Verbose "Getting the MA counters (this may take a while on a large MA..."
        $maCounts = $ma | Get-ManagementAgentCounts
        
        ###
        ### Use a PSObject to track the values that exceeded our expectations
        ###
        $violations = New-Object PSObject

        ###
        ### Loop thru the supplied tolerances, check each supplied tolerance
        ###
        $PSBoundParameters.GetEnumerator() | Where-Object {$_.Key -like 'Max*'} | ForEach-Object {
        
            ### For each supplied tolerance, derive the Name and Value
            ### Doing it this way means we don't have logic for EACH of the tolerances
            $ToleranceValue = $_.Value
            $ToleranceName =  $_.Key        
            Write-Verbose ("Todlerance Name '{0}' Max Value '{1}'" -F $ToleranceName,$ToleranceValue)

         	###
            ### Handle MaxNum* Tolerances
            ###
            if ($ToleranceName -like 'MaxNum*')
            {
                $WmiCounterName = $ToleranceName -replace 'Max'
                $ToleranceActualValue = [int]$maCounts.($WmiCounterName)
                Write-Verbose ("Todlerance Actual Value '{0}'" -F $ToleranceActualValue)

                if ($ToleranceActualValue -gt $ToleranceValue)        
                {
                    $violations | Add-Member -MemberType NoteProperty -Name ($ToleranceName -replace 'Max', 'Actual') -Value $maCounts.($WmiCounterName)
                }
            }
            ###
            ### Handle MaxPercent* Tolerances
            ###
            elseif ($ToleranceName -like 'MaxPercent*')
            {
                if ([int]$maCounts.NumCSObjects -gt 0)
                {
                    $WmiCounterName = $ToleranceName -replace 'MaxPercent', 'Num'
                    $ToleranceActualValue = ([int]$maCounts.($WmiCounterName) / [int]$maCounts.NumCSObjects * 100)
                    Write-Verbose ("Todlerance Actual Value '{0}'" -F $ToleranceActualValue)

                    if ($ToleranceActualValue -gt $ToleranceValue)        
                    {
                        $violations | Add-Member -MemberType NoteProperty -Name ($ToleranceName -replace 'Max', 'Actual') -Value $ToleranceActualValue
                    }
                }
            }
            ###
            ### Spaz out on unexpected Parameters
            ###
            else
            {
                throw ("Hey, how'd this get in here? We're not supposed to have a parameter named '{0}'. WTF?" -F $ToleranceName)
            }
        }##Closing $PSBoundParameters.GetEnumerator() | Where-Object...
        
        Write-Output $violations

        ###
        ### Throw if asked AND something worth throwing
        ###
        if ($ThrowWhenMaxExceeded -and ($violations | Get-Member -MemberType NoteProperty))
        {
            throw "Violators!"
        }
    }##Closing: Process
}##Closing: function Confirm-ManagementAgentCounts

function Get-FimRegistryKey
{
<#
.Synopsis
   Gets the FIM Registry Key
.DESCRIPTION
   The FIM registry contains some useful detail for automation, such as the file path, logging level, database name, etc
.EXAMPLE
   Get-FimRegistryKey
#>
    [CmdletBinding()]
    Param
    (
        # param1 help description
        [Parameter(Position=0)]
        [ValidateSet('FIMSynchronization', 'FIMService', 'Via')]
        $Component = 'FIMSynchronization'
    )

    switch ($Component)
    {
        FIMSynchronization 
        {
	        ### The registry location depends on the version of the sync engine (it changed in FIM2010)
	        $fimRegKey = Get-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Services\miiserver -ErrorAction silentlycontinue
	        if (-not $fimRegKey )
	        {
	            $fimRegKey = Get-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Services\FIMSynchronizationService -ErrorAction silentlycontinue
	        }    
        }
        FIMService
        {
            $fimRegKey = Get-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Services\FIMService -ErrorAction silentlycontinue
        }
        Via
        {
            Write-Warning "Time to upgrade, perhaps?"
        }
    }

    ### Only output if we found what we were looking for
	if ($fimRegKey)
    {
        Write-Verbose ("Found the key: {0}" -F $fimRegKey.PSPath)
        Write-Output $fimRegKey
    }
    else
	{
	    Write-Warning "FIMSync does not seem to be installed on this system."	    
	}
}##Closing: function Get-FimRegistryKey

function Get-FimSyncPath
{
<#
.Synopsis
   Get the Path for the FIM Synchronization Service
.DESCRIPTION
   Long description
.EXAMPLE
   Get-FimSyncPath
#>
    $fimRegKey = Get-FimRegistryKey -Component FIMSynchronization
    Get-ItemProperty -Path (Join-Path $fimRegKey.PSPath Parameters) | select -ExpandProperty Path
}##Closing: function Get-FimSyncPath

function Get-ManagementAgentXml
{
<#
.Synopsis
   Gets the MA XML
.DESCRIPTION
   Uses maexport.exe to return the MA XML
.EXAMPLE
   Get-ManagementAgentXml myMAName
.EXAMPLE
   Get-ManagementAgent | Get-ManagementAgentXml myMAName
.EXAMPLE
   Get-ManagementAgent myMAName | Get-ManagementAgentXml myMAName
#>
    [CmdletBinding()]
    Param
    (
        # param1 help description
        [Parameter(Position=0, ValueFromPipelineByPropertyName=$true)]
        $Name
    )
    Process
    {
        ##TODO - do this better such that we handle failures in the command
        ##TODO - output the command output and send to Write-Verbose
        ##TODO - add a -Force parameter which will overwrite an existing file
        & (join-path (Get-FimSyncPath) \bin\maexport.exe) $Name 
    }
}##Closing: function Get-ManagementAgentXml

function Get-RunHistoryDetailCounters
{
<#
.Synopsis
   Gets the MA Counters from Run History
.DESCRIPTION
	Each Management Agent run results in Run History details stored in the FIM Sync database.  The detail is available via WMI.  This function returns just the counters from the Run History Detail
.EXAMPLE
   	Get-MIIS_RunHistory | Get-RunHistoryDetailCounters
.EXAMPLE
	Get-MIIS_RunHistory -RunProfile 'Full Import' | Get-RunHistoryDetailCounters -StepType 'full-import'
.EXAMPLE
	Get-MIIS_RunHistory -RunProfile 'Delta Import' | Get-RunHistoryDetailCounters | ft Partition,StageAdd,StageNoChange,StageUpdate,StageDelete -a
#>
    [CmdletBinding()]
    Param
    (
        # RunHistory help description
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   Position=0)]
        [System.Management.ManagementObject]
        $RunHistory,
		[Parameter()]
		[ValidateSet("full-import", "delta-import", "apply-rules", "export")]
		[String]
		$StepType
    )
    Process
    {
        [xml]$RunHistoryDetail = $RunHistory.RunDetails().ReturnValue

        foreach ($StepDetail in $RunHistoryDetail.'run-history'.'run-details'.'step-details')
        {
        $stepDetailPSObject = New-Object PSObject -Property @{
            <#
            <step-details>
		    Stores run information about one step of the management agent run.
		    http://technet.microsoft.com/en-us/library/ms698762.aspx
            #>
            Partition 		= $StepDetail.'step-description'.partition
            StepType 		= $StepDetail.'step-description'.'step-type'.type
            StepResult 		= $StepDetail.'step-result'
            StartDate 		= Get-Date $StepDetail.'start-date'
            EndDate 		= Get-Date $StepDetail.'end-date' #This element is present only if the step has completed
	    }
	
	    switch -Wildcard ($StepDetail.'step-description'.'step-type'.type)
	    {
    	    '*-import' 		{
			    $stepSpecificCounters = @{
				    <#
				    <ma-discovery-counters>
				    Contains the values of some management agent discovery counters
				    http://technet.microsoft.com/en-us/library/ms696557.aspx
				    #>
				    FilteredDeletions 			= $StepDetail.'ma-discovery-counters'.'filtered-deletions'.'#text'
				    FilteredObjects 			= $StepDetail.'ma-discovery-counters'.'filtered-objects'.'#text'

				    <#
				    <staging-counters>
				    Contains statistics on the staging of the entries that were imported
				    http://technet.microsoft.com/en-us/library/ms698759.aspx
				    #>
		            StageNoChange 				= $StepDetail.'staging-counters'.'stage-no-change'.'#text'
		            StageAdd 					= $StepDetail.'staging-counters'.'stage-add'.'#text'
		            StageUpdate 				= $StepDetail.'staging-counters'.'stage-update'.'#text'
		            StageRename 				= $StepDetail.'staging-counters'.'stage-rename'.'#text'
		            StageDelete 				= $StepDetail.'staging-counters'.'stage-delete'.'#text'
		            StageDeleteAdd 				= $StepDetail.'staging-counters'.'stage-delete-add'.'#text'
		            StageFailure 				= $StepDetail.'staging-counters'.'stage-failure'.'#text'
			    }##Closing: $stepSpecificCounters = @{
		    }##Closing: '*-import'
		
		    'export' 		{
			    $stepSpecificCounters = @{
				    <#
				    <export-counters>
				    Contains information about object changes that occur during a management agent export
				    http://technet.microsoft.com/en-us/library/ms696480.aspx
				    #>
		            ExportNoChange 				= $StepDetail.'export-counters'.'export-no-change'.'#text'
		            ExportAdd 					= $StepDetail.'export-counters'.'export-add'.'#text'
		            ExportUpdate 				= $StepDetail.'export-counters'.'export-update'.'#text'
		            ExportRename 				= $StepDetail.'export-counters'.'export-rename'.'#text'
		            ExportDelete 				= $StepDetail.'export-counters'.'export-delete'.'#text'
		            ExportDeleteAdd 			= $StepDetail.'export-counters'.'export-delete-add'.'#text'
		            ExportFailure 				= $StepDetail.'export-counters'.'export-failure'.'#text'	
			    }##Closing: $stepSpecificCounters = @{
		    }##Closing: 'export'
		
    	    'apply-rules' 	{
			    $stepSpecificCounters = @{
				    <#
				    <inbound-flow-counters>
				    Contains information about the number of disconnectors that became connectors during this run, and the disposition of existing connectors.
				    http://technet.microsoft.com/en-us/library/ms696531.aspx
				    #>
		            DisconnectorFiltered 		= $StepDetail.'inbound-flow-counters'.'disconnector-filtered'.'#text'
		            DisconnectorJoinedNoFlow 	= $StepDetail.'inbound-flow-counters'.'disconnector-joined-no-flow'.'#text'
		            DisconnectorJoinedFlow 		= $StepDetail.'inbound-flow-counters'.'disconnector-joined-flow'.'#text'
		            DisconnectorProjectedNoFlow = $StepDetail.'inbound-flow-counters'.'disconnector-projected-no-flow'.'#text'
		            DisconnectorProjectedFlow 	= $StepDetail.'inbound-flow-counters'.'disconnector-projected-flow'.'#text'
		            DisconnectorRemains 		= $StepDetail.'inbound-flow-counters'.'disconnector-remains'.'#text'
		            ConnectorFilteredRemoveMv 	= $StepDetail.'inbound-flow-counters'.'connector-filtered-remove-mv'.'#text'
		            ConnectorFilteredLeaveMv 	= $StepDetail.'inbound-flow-counters'.'connector-filtered-leave-mv'.'#text'
		            ConnectorFlow 				= $StepDetail.'inbound-flow-counters'.'connector-flow'.'#text'
		            ConnectorNoFlow 			= $StepDetail.'inbound-flow-counters'.'connector-no-flow'.'#text'
		            ConnectorDeleteRemoveMv 	= $StepDetail.'inbound-flow-counters'.'connector-delete-remove-mv'.'#text'
		            ConnectorDeleteLeaveMv 		= $StepDetail.'inbound-flow-counters'.'connector-delete-leave-mv'.'#text'
		            ConnectorDeleteAddProcessed = $StepDetail.'inbound-flow-counters'.'connector-delete-add-processed'.'#text'
		            FlowFailure 				= $StepDetail.'inbound-flow-counters'.'flow-failure'.'#text'

				    <#
				    <outbound-flow-counters>
				    Contains information about the number of provisioning changes and exported attributes.
				    http://technet.microsoft.com/en-us/library/ms698355.aspx
				    #>
		            OutboundConnectorFlow 		= $StepDetail.'outbound-flow-counters'.'connector-flow'.'#text'
		            OutboundConnectorNoFlow 	= $StepDetail.'outbound-flow-counters'.'connector-no-flow'.'#text'
				    ProvisionedAddFlow 			= $StepDetail.'outbound-flow-counters'.'provisioned-add-flow'.'#text'
				    ProvisionedAddNoFlow 		= $StepDetail.'outbound-flow-counters'.'provisioned-add-no-flow'.'#text'
				    ProvisionedDeleteAddFlow 	= $StepDetail.'outbound-flow-counters'.'provisioned-delete-add-flow'.'#text'
				    ProvisionedDeleteAddNoFlow 	= $StepDetail.'outbound-flow-counters'.'provisioned-delete-add-no-flow'.'#text'
				    ProvisionedDisconnect 		= $StepDetail.'outbound-flow-counters'.'provisioned-disconnect'.'#text'
				    ProvisionedRenameFlow 		= $StepDetail.'outbound-flow-counters'.'provisioned-rename-flow'.'#text'
				    ProvisionedRenameNoFlow 	= $StepDetail.'outbound-flow-counters'.'provisioned-rename-no-flow'.'#text'
			    }##Closing: $stepSpecificCounters = @{
		    }##Closing: 'apply-rules'    	
	    }##Closing: switch -Wildcard ($StepDetail.'step-description'.'step-type'.type)
	
	    $stepSpecificCounters.GetEnumerator() | ForEach-Object {
		    $stepDetailPSObject | Add-Member -MemberType NoteProperty -Name $_.Name -Value $_.Value
	    }
	
		if ($StepType)
		{
			$stepDetailPSObject | Where-Object {$_.StepType -eq $StepType} | Write-Output
		}
		else
		{
	    	Write-Output $stepDetailPSObject
		}
    }

    }##Closing: Process
}##Closing: function Get-RunHistoryDetailCounters

function Get-RunHistoryDetailErrors
{
<#
.Synopsis
   Gets the MA Errors from Run History
.DESCRIPTION
	Each Management Agent run results in Run History details stored in the FIM Sync database.  The detail is available via WMI.  This function returns just the errors from the Run History Detail
.EXAMPLE
   	Get-MIIS_RunHistory | Get-RunHistoryDetailErrors
.EXAMPLE
	Get-MIIS_RunHistory -RunStatus 'completed-sync-errors' | Get-RunHistoryDetailErrors
.EXAMPLE
	Get-MIIS_RunHistory -RunStatus 'completed-sync-errors' | Get-RunHistoryDetailErrors | Group-Object ErrorType
#>
    [CmdletBinding()]
    Param
    (
        # RunHistory help description
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   Position=0)]
        [System.Management.ManagementObject]
        $RunHistory
    )
    Process
    {
        [xml]$RunHistoryDetail = $RunHistory.RunDetails().ReturnValue

        foreach ($StepDetail in $RunHistoryDetail.'run-history'.'run-details'.'step-details')
        {
			###
			### If the MA did not connect successfully, then output a PSObject containing the details
			###
		    if ($StepDetail.'ma-connection'.'connection-result' -ne 'successful-connection')
            {
            New-Object PSObject -Property @{
                    StepNumber = $StepDetail.'step-number'
                    StartDate = $StepDetail.'start-date'  
                    EndDate = $StepDetail.'end-date'
                    StepResult = $StepDetail.'step-result'
                    StepType = $StepDetail.'step-description'.'step-type'.'type'
                    Partition = $StepDetail.'step-description'.'partition'
                    ConnectionResult = $StepDetail.'ma-connection'.'connection-result'
                    Server = $StepDetail.'ma-connection'.'server'
                    ConnectionLog = $StepDetail.'ma-connection'.'connection-log'.'#text'
                    CDErrorCode = $StepDetail.'ma-connection'.'connection-log'.'incident'.'cd-error'.'error-code'
                    CDErrorLiteral = $StepDetail.'ma-connection'.'connection-log'.'incident'.'cd-error'.'error-literal'
                }
            }
			
            $StepDetail.'synchronization-errors'.'import-error' | ForEach-Object{
                $ImportError = $_ 
                if ($ImportError)
                {          
                New-Object PSObject -Property @{
                    CSGuid = $ImportError.'cs-guid'
                    DN = $ImportError.dn
                    AlgorithmStep = $ImportError.'algorithm-step'
                    ChangeNotReimported = $ImportError.'change-not-reimported'
                    DateOccurred = $ImportError.'date-occurred'
                    FirstOccurred = $ImportError.'first-occurred'
                    RetryCount = $ImportError.'retry-count'
                    ErrorType = $ImportError.'error-type'
                    ExtensionErrorInfoExtensionName = $ImportError.'extension-error-info'.'extension-name'
                    ExtensionErrorInfoExtensionCallsite = $ImportError.'extension-error-info'.'extension-callsite'
                    ExtensionErrorInfoExtensionContext = $ImportError.'extension-error-info'.'extension-context'
                    ExtensionErrorInfoExtensionCallStack = $ImportError.'extension-error-info'.'call-stack'
                }
                }
            }##Closing: ForEach-Object

            $StepDetail.'synchronization-errors'.'export-error' | ForEach-Object{
                $ExportError = $_
                if ($ExportError)
                {          
                New-Object PSObject -Property @{
                    CSGuid = $ExportError.'cs-guid'
                    DN = $ExportError.dn
                    ErrorType = $ExportError.'error-type'
                    FirstOccurred = $ExportError.'first-occurred'
                    DateOccurred = $ExportError.'date-occurred'
                    RetryCount = $ExportError.'retry-count'
                    CDErrorErrorCode = $ExportError.'cd-error'.'error-code'
                    CDErrorErrorLiteral = $ExportError.'cd-error'.'error-literal'                    
                    CDErrorServerErrorDetail = $ExportError.'cd-error'.'server-error-detail'
                }
                }
            }##Closing: ForEach-Object

            $StepDetail.'mv-retry-errors'.'retry-error' | ForEach-Object{
                $RetryError = $_
                if ($RetryError)
                {
                    New-Object PSObject -Property @{
                        MVGuid = $RetryError.'mv-guid'
                        DisplayName = $RetryError.displayname
                        AlgorithmStep = $RetryError.'algorithm-step'
                        MAGuid = $RetryError.'algorithm-step'.'ma-id'
                        DN = $RetryError.'algorithm-step'.dn
                        ErrorType = $RetryError.'error-type'
                        RulesErrorInfoExtensionName = $RetryError.'rules-error-info'.innertext                    
                    }
                }
            }##Closing: ForEach-Object
	    }##Closing: foreach ($StepDetail in $RunHistoryDetail...	    

    }##Closing: Process
}##Closing: function Get-RunHistoryDetailErrors

function Get-MIIS_RunHistory
{  
<#
   	.SYNOPSIS 
   	Gets the Run History from the Sync Engine using WMI 

   	.DESCRIPTION
   	The Get-MIIS_RunHistory function uses the Get-WmiObject cmdlet to query for MIIS_RunHistory in FIM Sync.
   	MSDN has good documentation for MIIS_RunHistory:
   	http://technet.microsoft.com/en-us/library/ms697834.aspx

   	.OUTPUTS
   	the MIIS_RunHistory returned by WMI
   
   	.EXAMPLE
   	Get-MIIS_RunHistory
    
    .EXAMPLE
    Get-MIIS_RunHistory -StartedBefore (Get-Date '6/19') -verbose
	
	.EXAMPLE
    Get-MIIS_RunHistory -StartedBefore ([DateTime]::Now.AddDays(-1)) -verbose
    
    .EXAMPLE
    Get-MIIS_RunHistory -MaName FIM -verbose
	
	.EXAMPLE
    Get-MIIS_RunHistory | Group-Object RunStatus
#>
    param
    (     
		<#
		The sequence number of the management agent run
		#>
        [Parameter(ValueFromPipelineByPropertyName = $true)] 
        [int]
        $RunNumber,
		
		<#
		The display name of the run profile used in this run
		#>
        [Parameter(ValueFromPipelineByPropertyName = $true)] 
		[String]
        $RunProfile,
		
		<#
		The status of the run
		#>
        [Parameter(ValueFromPipelineByPropertyName = $true)] 
		[String]
        $RunStatus,
		
		<#
		The name of the management agent that generated the run history
		#>
        [Parameter(ValueFromPipelineByPropertyName = $true)] 
		[String]
        $MaName,

		<#
		The GUID of the management agent that is associated with this run history
		#>
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        $MaGuid,
		
		<#
		Gets only the run history where the run profile started before the specified date and time. Enter a DateTime object, such as the one returned by the Get-Date cmdlet.
        This input is converted to UTC!!!
		#>   
		[DateTime]
        $StartedBefore,
		
		<#
		Gets only the run history where the run profile started after the specified date and time. Enter a DateTime object, such as the one returned by the Get-Date cmdlet.
        This input is converted to UTC!!!
		#>
        [DateTime]
        $StartedAfter,
		
		<#
		Specifies the ComputerName where FIMSync is running 
		(defaults to localhost)
		#>		
        [String]
        $ComputerName = (hostname)
    )   
	Process
	{
		Write-Verbose "Querying WMI using ComputerName: '$ComputerName'"
	
		### If any of these parameters are present, we'll build a Filter
		if ($RunNumber -or $RunProfile -or $MaName -or $MaGuid -or $RunStatus -or $StartedBefore -or $StartedAfter)
		{
			$filterParts = @()
			
			$PSBoundParameters.GetEnumerator() | ForEach-Object {
                Write-Verbose ("Parameter '{0}' has a value of '{1}'" -F $_.Key, $_.Value)
                $parameterValue = $_.Value
				switch ($_.Key)
				{
				    RunNumber 		{$filterParts += "RunNumber = '$parameterValue'" }
					RunStatus 		{$filterParts += "RunStatus = '$parameterValue'" }
				    RunProfile 		{$filterParts += "RunProfile = '$parameterValue'" }
					MaName 			{$filterParts += "MaName = '$parameterValue'" }
					MaGuid 			{$filterParts += "MaGuid = '$parameterValue'" }
					StartedBefore 	{$filterParts += ("RunStartTime < '{0}'" -F $parameterValue.ToUniversalTime().ToString('yyyy-MM-dd hh:mm:ss'))}
					StartedAfter 	{$filterParts += ("RunStartTime > '{0}'" -F $parameterValue.ToUniversalTime().ToString('yyyy-MM-dd hh:mm:ss'))}
				}##Closing: switch ($_.Name)
			}##Closing: $PSBoundParameters.GetEnumerator() | ForEach-Object {
			
			$wmiFilter = $filterParts -join ' and '
			Write-Verbose "Querying FIM Sync for MIIS_RunHistory using filter: $wmiFilter"
    		Get-WmiObject -ComputerName $ComputerName -Class MIIS_RunHistory -Namespace root/MicrosoftIdentityIntegrationServer -filter $wmiFilter
		}
		else
		{
			Write-Verbose "Querying FIM Sync for all MIIS_RunHistory (no filter) "
    		Get-WmiObject -ComputerName $ComputerName -Class MIIS_RunHistory -Namespace root/MicrosoftIdentityIntegrationServer
	    
    	}
    }##Closing: Process
}##Closing: function Get-MIIS_RunHistory

#backwards compat   
New-Alias -Name Create-ImportfileFromCSEntry -Value New-ImportFileFromCSEntry   
        
Export-ModuleMember -Function @(   
    "Assert-CSAttribute",   
    "Confirm-ManagementAgentCounts",   
    "New-ImportFileFromCSEntry",   
    "Format-FimSynchronizationConfigurationFiles",   
    "Get-FimRegistryKey",   
    "Get-FimSyncPath",   
    "Get-ManagementAgent",   
    "Get-ManagementAgentCounts",   
    "Get-ManagementAgentXml",   
    "Get-MIIS_CSObject",   
    "Get-MIIS_RunHistory",   
    "Get-RunHistoryDetailCounters",   
    "Get-RunHistoryDetailErrors",   
    "Start-ManagementAgent"   
) -Alias @("Create-ImportfileFromCSEntry")  