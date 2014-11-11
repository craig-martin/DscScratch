##TODO: Add parameter sets and help to this
Function New-FimSynchronizationRule
{
    [CmdletBinding()]
    [OutputType([Guid])]
   	param
    (
        [parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $DisplayName,
        [parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Description,
        [parameter(Mandatory=$true)]        
		$ManagementAgentID,
        [parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [Alias("ConnectedObjectType")]
        [string]
		$ExternalSystemResourceType,
        [parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [Alias("ILMObjectType")]
        [string]
		$MetaverseResourceType,
        [parameter(Mandatory=$false)]
        [Alias("DisconnectConnectedSystemObject")]
		[Switch]
        $EnableDeprovisioning,
        [parameter(Mandatory=$false)]
        [Alias("CreateConnectedSystemObject")]
		[Switch]
		$CreateResourceInExternalSystem,
        [parameter(Mandatory=$false)]
        [Alias("CreateILMObject")]
		[Switch]
        $CreateResourceInFIM,
        [parameter(Mandatory=$true)]
        [ValidateSet("Inbound", "Outbound","InboundAndOutbound")]
        [Alias("FlowType")]
		$Direction,
        [parameter(Mandatory=$false)]	
        [ValidateRange(1, 1000)] ##TODO: Using 1000 instead of [Int32]::MaxValue because module import fails otherwise
        [int]
        $Precedence = 1,
        [parameter(Mandatory=$false)] # Thanks to Aneesh Varghese at NZ Ministry of Social Development who pointed out 
        [Alias("Dependency")]         # we need to include dependency as well
        $DependencyRef, 
        [parameter(Mandatory=$false)]
		$RelationshipCriteria = @{},
        [parameter(Mandatory=$false)]
        [Switch]
        [Alias("msidmOutboundIsFilterBased")]
        $OutboundFilterBased = $false,
        [parameter(Mandatory=$false)]
        [Alias("msidmOutboundScopingFilters")]
        $OutboundScopingFilter,
        [parameter(Mandatory=$false)]
        [Alias("ExistenceTest")]   ## Added by Aneesh Varghese, need to include ExistenceTest flow rules as well
        $ExistenceTestFlowRules =  @(),
        [parameter(Mandatory=$false)]
        [Alias("PersistentFlow")]
        [string[]]
		$PersistentFlowRules = @(),
        [parameter(Mandatory=$false)]
        [Alias("InitialFlow")]
        [string[]]
		$InitialFlowRules = @(),
        [parameter(Mandatory=$false)]
        [Alias("ConnectedSystemScope")]
        [string[]]
		$ExternalSystemScopingFilter = @(),
        [parameter(Mandatory=$false)]
        [string[]]
        [Alias("SynchronizationRuleParameters")]
        $WorkflowParameters = @(),
        <#
	    .PARAMETER Uri
	    The Uniform Resource Identifier (URI) of the FIM Service. The following example shows how to set this parameter: -uri "http://localhost:5725"
	    #>
	    [String]
	    $Uri = "http://localhost:5725",
        [parameter(Mandatory=$false)]
        [Switch]
        $PassThru
    )
    
    $changeSet = @{
	    DisplayName 						= $DisplayName	    
	    ManagementAgentID 					= $ManagementAgentID
		ConnectedObjectType 				= $ExternalSystemResourceType
	    ILMObjectType 						= $MetaverseResourceType
		Precedence 							= $Precedence
        CreateConnectedSystemObject         = $CreateResourceInExternalSystem.ToBool()
    }

    if ($Direction -eq "Inbound")
    {
        $changeSet.Add("FlowType", 0)
    }
    elseif ($Direction -eq "Outbound")
    {
        $changeSet.Add("FlowType", 1)
    }
    elseif ($Direction -eq "InboundAndOutbound")
    {
        $changeSet.Add("FlowType", 2)
    }
    else
    {
        throw "Unsupported value for `$Direction"
    }

    if ($OutboundFilterBased.ToBool() -eq $false)
    {
        $changeSet.Add("DisconnectConnectedSystemObject", $EnableDeprovisioning.ToBool())		
		$changeSet.Add("CreateILMObject", $CreateResourceInFIM.ToBool())	
        $changeSet.Add("msidmOutboundIsFilterBased", $false)
    }
    else
    {
        $changeSet.Add("DisconnectConnectedSystemObject", $false)
		$changeSet.Add("CreateILMObject", $false)
        $changeSet.Add("msidmOutboundIsFilterBased", $true)
    
        if ($OutboundScopingFilter)
    {
            $changeSet.Add("msidmOutboundScopingFilters", $OutboundScopingFilter)
        }
    }

    $srImportObject = New-FimImportObject -ObjectType SynchronizationRule -State Create -Changes $changeSet -PassThru
    
    if ($Description)
    {
        $srImportObject.Changes += New-FimImportChange -AttributeName Description -Operation None -AttributeValue $Description         						
    }
    
    if ($RelationshipCriteria -and $OutboundFilterBased.ToBool() -ne $true)
    {
        $localRelationshipCriteria = "<conditions>"
        foreach ($key in $RelationshipCriteria.Keys)
        {
            $localRelationshipCriteria += ("<condition><ilmAttribute>{0}</ilmAttribute><csAttribute>{1}</csAttribute></condition>" -f $key, $RelationshipCriteria[$key])
        }
        $localRelationshipCriteria += "</conditions>"

        $srImportObject.Changes += New-FimImportChange -AttributeName RelationshipCriteria -Operation None -AttributeValue $localRelationshipCriteria
    }
    else
    {
        $srImportObject.Changes += New-FimImportChange -AttributeName RelationshipCriteria -Operation None -AttributeValue "<conditions/>"    
    }
   
    if ($WorkflowParameters -and ($OutboundFilterBased.ToBool() -eq $false) -and ($Direction -ne "Inbound"))
    {
        foreach ($w in $WorkflowParameters)
    {
            $srImportObject.Changes += New-FimImportChange -AttributeName SynchronizationRuleParameters -Operation Add -AttributeValue $w
        }
    }
        
    if ($ExternalSystemScopingFilter)
    {
        foreach ($filter in $ExternalSystemScopingFilter)
        {
            $srImportObject.Changes += New-FimImportChange -AttributeName ConnectedSystemScope -Operation Add -AttributeValue $filter
        }
    }

    ## Added by Aneesh Varghese, need to include Dependency attribute
    if($DependencyRef)
    {
        $srImportObject.Changes += New-FimImportChange -AttributeName Dependency -Operation Add -AttributeValue $DependencyRef
    }
    
    ## Added by Aneesh Varghese, need to include ExistenceTest flow rules as well
    $ExistenceTestFlowRules | ForEach-Object {
        $srImportObject.Changes += New-FimImportChange -AttributeName ExistenceTest -Operation Add -AttributeValue $_
    }  
	
	$PersistentFlowRules | ForEach-Object {
		$srImportObject.Changes += New-FimImportChange -AttributeName PersistentFlow -Operation Add -AttributeValue $_
	}
    
    $InitialFlowRules | ForEach-Object {
		$srImportObject.Changes += New-FimImportChange -AttributeName InitialFlow -Operation Add -AttributeValue $_
	}
	
	$srImportObject | Skip-DuplicateCreateRequest -Uri $Uri | Import-FIMConfig -Uri $Uri

    if ($PassThru.ToBool())
    {
        Write-Output [guid](Get-FimObjectID -ObjectType SynchronizationRule -AttributeName DisplayName -AttributeValue $DisplayName)
    }
}

