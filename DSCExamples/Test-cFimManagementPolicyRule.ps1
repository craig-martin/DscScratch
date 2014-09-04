

<#

Get-FimObjectByXPath -Filter "/ManagementPolicyRule[DisplayName='$displayName']"

Get-FimObjectByXPath -Filter "/Request[Target = /ManagementPolicyRule[DisplayName='$displayName'] and CreatedTime >= '$([DateTime]::UtcNow.AddMinutes(-55).ToString("s"))']" | 
Select-Object -Last 1 | 
Get-FimRequestParameter |
Format-Table Mode, PropertyName, Value -AutoSize

New-FimImportObject -ObjectType ManagementPolicyRule -State Delete -TargetObjectIdentifier (Get-FimObjectID ManagementPolicyRule DisplayName $displayName) -ApplyNow

Import-Clixml C:\temp\fimImportChanges.clixml | ft -a

#>


Set-Location c:\fimdsc

$fimAdminCredential = New-Object System.Management.Automation.PSCredential ("$(hostname)\administrator", (ConvertTo-SecureString 'PA$$w0rd' -AsPlainText -Force))

$Global:AllNodes =
@{
    AllNodes = @( 
        @{  
            NodeName                    = (hostname)
            PSDscAllowPlainTextPassword = $true
        }
    )
}

#region: New Transition-In MPR with no Action Workflows
$displayName = "Mpr$(Get-Random -Minimum 100 -Maximum 999)"
Configuration TestMpr 
{ 

    Import-DscResource -ModuleName FimPowerShellModule

    Node (hostname) 
    { 
        cFimManagementPolicyRule $displayName
        {
            ActionParameter				= '*' 
            ActionType					= 'TransitionIn'
            Description					= 'initial description'
            Disabled					= $false
            DisplayName					= $displayName
            GrantRight					= $false
            ResourceFinalSet			= 'Administrators'
            ManagementPolicyRuleType	= 'SetTransition'
            Ensure						= 'Present'
            Credential					= $fimAdminCredential
        }
    } 
} 

TestMpr -ConfigurationData $Global:AllNodes

Start-DscConfiguration -Wait -Verbose -Path "C:\fimdsc\TestMpr"
#endregion

#region: New Transition-In MPR with one Action Workflow
$displayName = "Mpr$(Get-Random -Minimum 100 -Maximum 999)"
Configuration TestMpr 
{ 

    Import-DscResource -ModuleName FimPowerShellModule

    Node (hostname) 
    { 
        cFimManagementPolicyRule $displayName
        {
            ActionParameter				= '*' 
            ActionType					= 'TransitionIn'
            ActionWorkflowDefinition	= 'Group Expiration Notification Workflow' 
            Description					= 'initial description'
            Disabled					= $false
            DisplayName					= $displayName
            GrantRight					= $false
            ResourceFinalSet			= 'Administrators'
            ManagementPolicyRuleType	= 'SetTransition'
            Ensure						= 'Present'
            Credential					= $fimAdminCredential
        }
    } 
} 

TestMpr -ConfigurationData $Global:AllNodes

Start-DscConfiguration -Wait -Verbose -Path "C:\fimdsc\TestMpr"
#endregion

#region: New Transition-Out MPR with one Action Workflow
$displayName = "Mpr$(Get-Random -Minimum 100 -Maximum 999)"
Configuration TestMpr 
{ 

    Import-DscResource -ModuleName FimPowerShellModule

    Node (hostname) 
    { 
        cFimManagementPolicyRule $displayName
        {
            ActionParameter				= '*' 
            ActionType					= 'TransitionOut'
            ActionWorkflowDefinition	= 'Group Expiration Notification Workflow' 
            Description					= 'initial description'
            Disabled					= $false
            DisplayName					= $displayName
            GrantRight					= $false
            ResourceCurrentSet			= 'Administrators'
            ManagementPolicyRuleType	= 'SetTransition'
            Ensure						= 'Present'
            Credential					= $fimAdminCredential
        }
    } 
} 

TestMpr -ConfigurationData $Global:AllNodes

Start-DscConfiguration -Wait -Verbose -Path "C:\fimdsc\TestMpr"
#endregion

#region: New Transition MPR with multiple Action Workflows
$displayName = "Mpr$(Get-Random -Minimum 100 -Maximum 999)"
Configuration TestMpr 
{ 

    Import-DscResource -ModuleName FimPowerShellModule

    Node (hostname) 
    { 
        cFimManagementPolicyRule $displayName
        {
            ActionParameter				= '*' 
            ActionType					= 'TransitionOut'
            ActionWorkflowDefinition	= 'Group Expiration Notification Workflow', 'Expiration Workflow' 
            Description					= 'initial description'
            Disabled					= $false
            DisplayName					= $displayName
            GrantRight					= $false
            ResourceCurrentSet			= 'Administrators'
            ManagementPolicyRuleType	= 'SetTransition'
            Ensure						= 'Present'
            Credential					= $fimAdminCredential
        }
    } 
} 

TestMpr -ConfigurationData $Global:AllNodes

Start-DscConfiguration -Wait -Verbose -Path "C:\fimdsc\TestMpr"
#endregion

#region: Update Transition MPR - Disabled
$displayName = "Mpr$(Get-Random -Minimum 100 -Maximum 999)"
Configuration TestMpr 
{ 

    Import-DscResource -ModuleName FimPowerShellModule

    Node (hostname) 
    { 
        cFimManagementPolicyRule $displayName
        {
            ActionParameter				= '*' 
            ActionType					= 'TransitionOut'
            ActionWorkflowDefinition	= 'Group Expiration Notification Workflow', 'Expiration Workflow' 
            Description					= 'initial description'
            Disabled					= $false
            DisplayName					= $displayName
            GrantRight					= $false
            ResourceCurrentSet			= 'Administrators'
            ManagementPolicyRuleType	= 'SetTransition'
            Ensure						= 'Present'
            Credential					= $fimAdminCredential
        }
    } 
} 

TestMpr -ConfigurationData $Global:AllNodes

Start-DscConfiguration -Wait -Verbose -Path "C:\fimdsc\TestMpr"

Configuration TestMpr 
{ 

    Import-DscResource -ModuleName FimPowerShellModule

    Node (hostname) 
    { 
        cFimManagementPolicyRule $displayName
        {
            ActionParameter				= '*' 
            ActionType					= 'TransitionOut'
            ActionWorkflowDefinition	= 'Group Expiration Notification Workflow', 'Expiration Workflow' 
            Description					= 'initial description'
            Disabled					= $true
            DisplayName					= $displayName
            GrantRight					= $false
            ResourceCurrentSet			= 'Administrators'
            ManagementPolicyRuleType	= 'SetTransition'
            Ensure						= 'Present'
            Credential					= $fimAdminCredential
        }
    } 
} 

TestMpr -ConfigurationData $Global:AllNodes
Start-DscConfiguration -Wait -Verbose -Path "C:\fimdsc\TestMpr"
#endregion

#region: Update Transition MPR - Description
$displayName = "Mpr$(Get-Random -Minimum 100 -Maximum 999)"
Configuration TestMpr 
{ 

    Import-DscResource -ModuleName FimPowerShellModule

    Node (hostname) 
    { 
        cFimManagementPolicyRule $displayName
        {
            ActionParameter				= '*' 
            ActionType					= 'TransitionOut'
            ActionWorkflowDefinition	= 'Group Expiration Notification Workflow', 'Expiration Workflow' 
            Description					= 'initial description'
            Disabled					= $false
            DisplayName					= $displayName
            GrantRight					= $false
            ResourceCurrentSet			= 'Administrators'
            ManagementPolicyRuleType	= 'SetTransition'
            Ensure						= 'Present'
            Credential					= $fimAdminCredential
        }
    } 
} 

TestMpr -ConfigurationData $Global:AllNodes
Start-DscConfiguration -Wait -Verbose -Path "C:\fimdsc\TestMpr"

Configuration TestMpr 
{ 

    Import-DscResource -ModuleName FimPowerShellModule

    Node (hostname) 
    { 
        cFimManagementPolicyRule $displayName
        {
            ActionParameter				= '*' 
            ActionType					= 'TransitionOut'
            ActionWorkflowDefinition	= 'Group Expiration Notification Workflow', 'Expiration Workflow' 
            Description					= 'some other description'
            Disabled					= $false
            DisplayName					= $displayName
            GrantRight					= $false
            ResourceCurrentSet			= 'Administrators'
            ManagementPolicyRuleType	= 'SetTransition'
            Ensure						= 'Present'
            Credential					= $fimAdminCredential
        }
    } 
} 

TestMpr -ConfigurationData $Global:AllNodes
Start-DscConfiguration -Wait -Verbose -Path "C:\fimdsc\TestMpr"
#endregion

#region: Update Transition MPR - ResourceCurrentSet
$displayName = "Mpr$(Get-Random -Minimum 100 -Maximum 999)"
Configuration TestMpr 
{ 

    Import-DscResource -ModuleName FimPowerShellModule

    Node (hostname) 
    { 
        cFimManagementPolicyRule $displayName
        {
            ActionParameter				= '*' 
            ActionType					= 'TransitionOut'
            ActionWorkflowDefinition	= 'Group Expiration Notification Workflow', 'Expiration Workflow' 
            Description					= 'initial description'
            Disabled					= $false
            DisplayName					= $displayName
            GrantRight					= $false
            ResourceCurrentSet			= 'Administrators'
            ManagementPolicyRuleType	= 'SetTransition'
            Ensure						= 'Present'
            Credential					= $fimAdminCredential
        }
    } 
} 

TestMpr -ConfigurationData $Global:AllNodes
Start-DscConfiguration -Wait -Verbose -Path "C:\fimdsc\TestMpr"

Configuration TestMpr 
{ 

    Import-DscResource -ModuleName FimPowerShellModule

    Node (hostname) 
    { 
        cFimManagementPolicyRule $displayName
        {
            ActionParameter				= '*' 
            ActionType					= 'TransitionOut'
            ActionWorkflowDefinition	= 'Group Expiration Notification Workflow', 'Expiration Workflow' 
            Description					= 'initial description'
            Disabled					= $false
            DisplayName					= $displayName
            GrantRight					= $false
            ResourceCurrentSet			= 'All People'
            ManagementPolicyRuleType	= 'SetTransition'
            Ensure						= 'Present'
            Credential					= $fimAdminCredential
        }
    } 
} 

TestMpr -ConfigurationData $Global:AllNodes
Start-DscConfiguration -Wait -Verbose -Path "C:\fimdsc\TestMpr"
#endregion

#region: New Request MPR with no WFs
$displayName = "Mpr$(Get-Random -Minimum 100 -Maximum 999)"
Configuration TestMpr 
{ 

    Import-DscResource -ModuleName FimPowerShellModule

    Node (hostname) 
    { 
        cFimManagementPolicyRule $displayName
        {
            ActionParameter				= '*' 
            ActionType					= 'Modify'          
            Description					= 'initial description'
            Disabled					= $false
            DisplayName					= $displayName
            GrantRight					= $true
            PrincipalSet			    = 'Administrators'
            ResourceCurrentSet			= 'Administrators'
			ResourceFinalSet			= 'Administrators'
            ManagementPolicyRuleType	= 'Request'
            Ensure						= "Present"
            Credential					= $fimAdminCredential
        }
    } 
} 

TestMpr -ConfigurationData $Global:AllNodes
Start-DscConfiguration -Wait -Verbose -Path "C:\fimdsc\TestMpr"
#endregion

#region: New Request MPR with WFs
$displayName = "Mpr$(Get-Random -Minimum 100 -Maximum 999)"
Configuration TestMpr 
{ 

    Import-DscResource -ModuleName FimPowerShellModule

    Node (hostname) 
    { 
        cFimManagementPolicyRule $displayName
        {
            ActionParameter						= '*' 
            ActionType							= 'Modify'          
            Description							= 'initial description'
            Disabled							= $false
            DisplayName							= $displayName
            GrantRight							= $true
            PrincipalSet			    		= 'Administrators'
            ResourceCurrentSet					= 'Administrators'
			ResourceFinalSet					= 'Administrators'
            ManagementPolicyRuleType			= 'Request'
            AuthenticationWorkflowDefinition 	= 'Password Reset AuthN Workflow'
			AuthorizationWorkflowDefinition 	= 'Owner Approval Workflow'
			ActionWorkflowDefinition 			= 'Password Reset Action Workflow'
            Ensure								= "Present"
            Credential							= $fimAdminCredential
        }
    } 
} 

TestMpr -ConfigurationData $Global:AllNodes
Start-DscConfiguration -Wait -Verbose -Path "C:\fimdsc\TestMpr"
#endregion

#region: New Request MPR with Multiple Actions
$displayName = "Mpr$(Get-Random -Minimum 100 -Maximum 999)"
Configuration TestMpr 
{ 

    Import-DscResource -ModuleName FimPowerShellModule

    Node (hostname) 
    { 
        cFimManagementPolicyRule $displayName
        {
            ActionParameter						= '*' 
            ActionType							= 'Create','Delete','Add','Modify','Remove','Read'
            Description							= 'initial description'
            Disabled							= $false
            DisplayName							= $displayName
            GrantRight							= $true
            PrincipalRelativeToResource    		= 'Manager'
            ResourceCurrentSet					= 'Administrators'
			ResourceFinalSet					= 'Administrators'
            ManagementPolicyRuleType			= 'Request'
            Ensure								= "Present"
            Credential							= $fimAdminCredential
        }
    } 
} 

TestMpr -ConfigurationData $Global:AllNodes
Start-DscConfiguration -Wait -Verbose -Path "C:\fimdsc\TestMpr"
#endregion

#region: New Request MPR with no WFs
$displayName = "Mpr$(Get-Random -Minimum 100 -Maximum 999)"
Configuration TestMpr 
{ 

    Import-DscResource -ModuleName FimPowerShellModule

    Node (hostname) 
    { 
        cFimManagementPolicyRule $displayName
        {
            ActionParameter				= '*' 
            ActionType					= 'Modify'          
            Description					= 'initial description'
            Disabled					= $false
            DisplayName					= $displayName
            GrantRight					= $true
            PrincipalSet			    = 'Administrators'
            ResourceCurrentSet			= 'Administrators'
			ResourceFinalSet			= 'Administrators'
            ManagementPolicyRuleType	= 'Request'
            Ensure						= "Present"
            Credential					= $fimAdminCredential
        }
    } 
} 

TestMpr -ConfigurationData $Global:AllNodes
Start-DscConfiguration -Wait -Verbose -Path "C:\fimdsc\TestMpr"
#endregion


#region: Update Request MPR with Multiple Actions
$displayName = "Mpr$(Get-Random -Minimum 100 -Maximum 999)"
Configuration TestMpr 
{ 

    Import-DscResource -ModuleName FimPowerShellModule

    Node (hostname) 
    { 
        cFimManagementPolicyRule $displayName
        {
            ActionParameter						= '*' 
            ActionType							= 'Create','Delete','Add'
            Description							= 'initial description'
            Disabled							= $false
            DisplayName							= $displayName
            GrantRight							= $true
            PrincipalRelativeToResource    		= 'Manager'
            ResourceCurrentSet					= 'Administrators'
			ResourceFinalSet					= 'Administrators'
            ManagementPolicyRuleType			= 'Request'
            Ensure								= "Present"
            Credential							= $fimAdminCredential
        }
    } 
} 

TestMpr -ConfigurationData $Global:AllNodes
Start-DscConfiguration -Wait -Verbose -Path "C:\fimdsc\TestMpr"

Configuration TestMpr 
{ 

    Import-DscResource -ModuleName FimPowerShellModule

    Node (hostname) 
    { 
        cFimManagementPolicyRule $displayName
        {
            ActionParameter						= '*' 
            ActionType							= 'Create','Modify','Remove','Read'
            Description							= 'initial description'
            Disabled							= $false
            DisplayName							= $displayName
            GrantRight							= $true
            PrincipalRelativeToResource    		= 'Manager'
            ResourceCurrentSet					= 'Administrators'
			ResourceFinalSet					= 'Administrators'
            ManagementPolicyRuleType			= 'Request'
            Ensure								= "Present"
            Credential							= $fimAdminCredential
        }
    } 
} 

TestMpr -ConfigurationData $Global:AllNodes
Start-DscConfiguration -Wait -Verbose -Path "C:\fimdsc\TestMpr"
#endregion