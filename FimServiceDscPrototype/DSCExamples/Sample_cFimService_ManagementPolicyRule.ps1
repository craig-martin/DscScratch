﻿md c:\fimdsc
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

#region: Request MPR with no WFs
Configuration Sample_cFimService_ManagementPolicyRule 
{ 

    Import-DscResource -ModuleName FimPowerShellModule

    Node (hostname) 
    { 
        cFimService_ManagementPolicyRule _DscTestManagementPolicyRule1
        {
              
            DisplayName  = "_DscTestManagementPolicyRule1"
            Description  = 'fooz'
            Enabled      = $true
            RequestorSet = 'Administrators' 
            #RelativeToResourceAttributeName = 'ObjectID'
            RequestType  = @('Read', 'Create')
            GrantPermission = $true
            #TransitionIn = 'Administrators' 
            #TransitionOut = 'Administrators' 
            Request = $true
            ResourceSetBeforeRequest = 'All People'
            ResourceSetAfterRequest = 'All People'
            ResourceAttributeNames = 'ObjectID', 'DisplayName','Description'
            #AuthenticationWorkflowDefinition = ''
            #AuthorizationWorkflowDefinition = ''
            #ActionWorkflowDefinition = ''
            Ensure       = "Present"
            Credential   = $fimAdminCredential
        }
    } 
} 

Sample_cFimService_ManagementPolicyRule -ConfigurationData $Global:AllNodes

Start-DscConfiguration -Wait -Verbose -Path "C:\fimdsc\Sample_cFimService_ManagementPolicyRule"

#endregion

#region: Request MPR - change the description
Configuration Sample_cFimService_ManagementPolicyRule 
{ 

    Import-DscResource -ModuleName FimPowerShellModule

    Node (hostname) 
    { 
        cFimService_ManagementPolicyRule _DscTestManagementPolicyRule1
        {
              
            DisplayName  = "_DscTestManagementPolicyRule1"
            Description  = ''
            Enabled      = $true
            RequestorSet = 'Administrators' 
            RequestType  = @('Read', 'Create')
            GrantPermission = $true
            Request = $true
            ResourceSetBeforeRequest = 'All People'
            ResourceSetAfterRequest = 'All People'
            ResourceAttributeNames = 'ObjectID', 'DisplayName','Description'
            #AuthenticationWorkflowDefinition = ''
            #AuthorizationWorkflowDefinition = ''
            #ActionWorkflowDefinition = ''
            Ensure       = "Present"
            Credential   = $fimAdminCredential
        }
    } 
} 

Sample_cFimService_ManagementPolicyRule -ConfigurationData $Global:AllNodes

Start-DscConfiguration -Wait -Verbose -Path "C:\fimdsc\Sample_cFimService_ManagementPolicyRule"

Get-FimObjectByXPath -Filter "/ManagementPolicyRule[DisplayName='_DscTestManagementPolicyRule1']"

#endregion

#region: Request MPR - change the ResourceAttributeNames
Configuration Sample_cFimService_ManagementPolicyRule 
{ 

    Import-DscResource -ModuleName FimPowerShellModule

    Node (hostname) 
    { 
        cFimService_ManagementPolicyRule _DscTestManagementPolicyRule1
        {
              
            DisplayName  = "_DscTestManagementPolicyRule1"
            Description  = 'bars'
            Enabled      = $false
            RequestorSet = 'Administrators' 
            RequestType  = @('Read', 'Create')
            GrantPermission = $true
            Request = $true
            ResourceSetBeforeRequest = 'All People'
            ResourceSetAfterRequest = 'All People'
            ResourceAttributeNames = 'ObjectID', 'DisplayName','CreatedTime','ObjectType'
            #AuthenticationWorkflowDefinition = ''
            #AuthorizationWorkflowDefinition = ''
            #ActionWorkflowDefinition = ''
            Ensure       = "Present"
            Credential   = $fimAdminCredential
        }
    } 
} 

Sample_cFimService_ManagementPolicyRule -ConfigurationData $Global:AllNodes

Start-DscConfiguration -Wait -Verbose -Path "C:\fimdsc\Sample_cFimService_ManagementPolicyRule"

#endregion

#region: Request MPR - change the RequestorSet
Configuration Sample_cFimService_ManagementPolicyRule 
{ 

    Import-DscResource -ModuleName FimPowerShellModule

    Node (hostname) 
    { 
        cFimService_ManagementPolicyRule _DscTestManagementPolicyRule1
        {
              
            DisplayName  = "_DscTestManagementPolicyRule1"
            Description  = 'bars'
            Enabled      = $false
            RequestorSet = 'All People' 
            RequestType  = @('Read', 'Create')
            GrantPermission = $true
            Request = $true
            ResourceSetBeforeRequest = 'All Contractors'
            ResourceSetAfterRequest = 'All People'
            ResourceAttributeNames = 'ObjectID', 'DisplayName','Manager'
            #AuthenticationWorkflowDefinition = ''
            #AuthorizationWorkflowDefinition = ''
            #ActionWorkflowDefinition = ''
            Ensure       = "Present"
            Credential   = $fimAdminCredential
        }
    } 
} 

Sample_cFimService_ManagementPolicyRule -ConfigurationData $Global:AllNodes

Start-DscConfiguration -Wait -Verbose -Path "C:\fimdsc\Sample_cFimService_ManagementPolicyRule"

#endregion

#region: Request MPR - change the RelativeToResourceAttributeName
Configuration Sample_cFimService_ManagementPolicyRule 
{ 

    Import-DscResource -ModuleName FimPowerShellModule

    Node (hostname) 
    { 
        cFimService_ManagementPolicyRule _DscTestManagementPolicyRule1
        {
              
            DisplayName  = "_DscTestManagementPolicyRule1"
            Description  = 'bars'
            Enabled      = $false
            #RequestorSet = 'All People'
            RelativeToResourceAttributeName = 'Manager' 
            RequestType  = @('Read', 'Create')
            GrantPermission = $true
            Request = $true
            ResourceSetBeforeRequest = 'All Contractors'
            ResourceSetAfterRequest = 'All People'
            ResourceAttributeNames = 'ObjectID', 'DisplayName','Manager'
            #AuthenticationWorkflowDefinition = ''
            #AuthorizationWorkflowDefinition = ''
            #ActionWorkflowDefinition = ''
            Ensure       = "Present"
            Credential   = $fimAdminCredential
        }
    } 
} 

Sample_cFimService_ManagementPolicyRule -ConfigurationData $Global:AllNodes

Start-DscConfiguration -Wait -Verbose -Path "C:\fimdsc\Sample_cFimService_ManagementPolicyRule"

#endregion

#region: Request MPR - change the ResourceSetBeforeRequest
Configuration Sample_cFimService_ManagementPolicyRule 
{ 

    Import-DscResource -ModuleName FimPowerShellModule

    Node (hostname) 
    { 
        cFimService_ManagementPolicyRule _DscTestManagementPolicyRule1
        {
              
            DisplayName  = "_DscTestManagementPolicyRule1"
            Description  = 'bars'
            Enabled      = $false
            RequestorSet = 'Administrators' 
            RequestType  = @('Read', 'Create')
            GrantPermission = $true
            Request = $true
            ResourceSetBeforeRequest = 'All Contractors'
            ResourceSetAfterRequest = 'All People'
            ResourceAttributeNames = 'ObjectID', 'DisplayName','Manager'
            #AuthenticationWorkflowDefinition = ''
            #AuthorizationWorkflowDefinition = ''
            #ActionWorkflowDefinition = ''
            Ensure       = "Present"
            Credential   = $fimAdminCredential
        }
    } 
} 

Sample_cFimService_ManagementPolicyRule -ConfigurationData $Global:AllNodes

Start-DscConfiguration -Wait -Verbose -Path "C:\fimdsc\Sample_cFimService_ManagementPolicyRule"

#endregion

#region: Request MPR - change the ResourceSetAfterRequest
Configuration Sample_cFimService_ManagementPolicyRule 
{ 

    Import-DscResource -ModuleName FimPowerShellModule

    Node (hostname) 
    { 
        cFimService_ManagementPolicyRule _DscTestManagementPolicyRule1
        {
              
            DisplayName  = "_DscTestManagementPolicyRule1"
            Description  = 'bars'
            Enabled      = $false
            RequestorSet = 'Administrators' 
            RequestType  = @('Read', 'Create')
            GrantPermission = $true
            Request = $true
            ResourceSetBeforeRequest = 'All Contractors'
            ResourceSetAfterRequest = 'All Contractors'
            ResourceAttributeNames = 'ObjectID', 'DisplayName','Manager'
            #AuthenticationWorkflowDefinition = ''
            #AuthorizationWorkflowDefinition = ''
            #ActionWorkflowDefinition = ''
            Ensure       = "Present"
            Credential   = $fimAdminCredential
        }
    } 
} 

Sample_cFimService_ManagementPolicyRule -ConfigurationData $Global:AllNodes

Start-DscConfiguration -Wait -Verbose -Path "C:\fimdsc\Sample_cFimService_ManagementPolicyRule"

#endregion

#region: Request MPR - change the MPR Type
Configuration Sample_cFimService_ManagementPolicyRule 
{ 

    Import-DscResource -ModuleName FimPowerShellModule

    Node (hostname) 
    { 
        cFimService_ManagementPolicyRule _DscTestManagementPolicyRule1
        {
              
            DisplayName  = "_DscTestManagementPolicyRule1"
            Description  = 'bars'
            Enabled      = $false
            RequestorSet = 'Administrators' 
            RequestType  = @('Read', 'Create')
            GrantPermission = $true
            Request = $false
            ResourceSetBeforeRequest = 'All People'
            ResourceSetAfterRequest = 'All People'
            ResourceAttributeNames = 'ObjectID', 'DisplayName','Manager'
            #AuthenticationWorkflowDefinition = ''
            #AuthorizationWorkflowDefinition = ''
            #ActionWorkflowDefinition = ''
            Ensure       = "Present"
            Credential   = $fimAdminCredential
        }
    } 
} 

Sample_cFimService_ManagementPolicyRule -ConfigurationData $Global:AllNodes

Start-DscConfiguration -Wait -Verbose -Path "C:\fimdsc\Sample_cFimService_ManagementPolicyRule"

#endregion

#region: Request MPR - change the Request Type
Configuration Sample_cFimService_ManagementPolicyRule 
{ 

    Import-DscResource -ModuleName FimPowerShellModule

    Node (hostname) 
    { 
        cFimService_ManagementPolicyRule _DscTestManagementPolicyRule1
        {
              
            DisplayName  = "_DscTestManagementPolicyRule1"
            Description  = 'bars'
            Enabled      = $false
            RequestorSet = 'Administrators' 
            RequestType  = @('Read','Add')
            GrantPermission = $true
            Request = $true
            ResourceSetBeforeRequest = 'All People'
            ResourceSetAfterRequest = 'All People'
            ResourceAttributeNames = 'ObjectID', 'DisplayName','Manager'
            #AuthenticationWorkflowDefinition = ''
            #AuthorizationWorkflowDefinition = ''
            #ActionWorkflowDefinition = ''
            Ensure       = "Present"
            Credential   = $fimAdminCredential
        }
    } 
} 

Sample_cFimService_ManagementPolicyRule -ConfigurationData $Global:AllNodes

Start-DscConfiguration -Wait -Verbose -Path "C:\fimdsc\Sample_cFimService_ManagementPolicyRule"

#endregion

#region: Request MPR - change the GrantPermission
Configuration Sample_cFimService_ManagementPolicyRule 
{ 

    Import-DscResource -ModuleName FimPowerShellModule

    Node (hostname) 
    { 
        cFimService_ManagementPolicyRule _DscTestManagementPolicyRule1
        {
              
            DisplayName  = "_DscTestManagementPolicyRule1"
            Description  = 'bars'
            Enabled      = $false
            RequestorSet = 'Administrators' 
            RequestType  = @('Read','Add')
            GrantPermission = $false
            Request = $true
            ResourceSetBeforeRequest = 'All People'
            ResourceSetAfterRequest = 'All People'
            ResourceAttributeNames = 'ObjectID', 'DisplayName','Manager'
            #AuthenticationWorkflowDefinition = ''
            #AuthorizationWorkflowDefinition = ''
            #ActionWorkflowDefinition = ''
            Ensure       = "Present"
            Credential   = $fimAdminCredential
        }
    } 
} 

Sample_cFimService_ManagementPolicyRule -ConfigurationData $Global:AllNodes

Start-DscConfiguration -Wait -Verbose -Path "C:\fimdsc\Sample_cFimService_ManagementPolicyRule"

#endregion

#region: Request MPR - change the AuthenticationWorkflowDefinition
Configuration Sample_cFimService_ManagementPolicyRule 
{ 

    Import-DscResource -ModuleName FimPowerShellModule

    Node (hostname) 
    { 
        cFimService_ManagementPolicyRule _DscTestManagementPolicyRule1
        {
              
            DisplayName  = "_DscTestManagementPolicyRule1"
            Description  = 'bars'
            Enabled      = $false
            RequestorSet = 'Administrators' 
            RequestType  = @('Read','Add')
            GrantPermission = $false
            Request = $true
            ResourceSetBeforeRequest = 'All People'
            ResourceSetAfterRequest = 'All People'
            ResourceAttributeNames = 'ObjectID', 'DisplayName','Manager'
            AuthenticationWorkflowDefinition = '_DscTestAuthnWorklow','Password Reset AuthN Workflow'
            #AuthorizationWorkflowDefinition = ''
            #ActionWorkflowDefinition = ''
            Ensure       = "Present"
            Credential   = $fimAdminCredential
        }
    } 
} 

Sample_cFimService_ManagementPolicyRule -ConfigurationData $Global:AllNodes

Start-DscConfiguration -Wait -Verbose -Path "C:\fimdsc\Sample_cFimService_ManagementPolicyRule"

#endregion

#region: Request MPR - change the AuthorizationWorkflowDefinition (single)
Configuration Sample_cFimService_ManagementPolicyRule 
{ 

    Import-DscResource -ModuleName FimPowerShellModule

    Node (hostname) 
    { 
        cFimService_ManagementPolicyRule _DscTestManagementPolicyRule1
        {
              
            DisplayName  = "_DscTestManagementPolicyRule1"
            Description  = 'bars'
            Enabled      = $false
            RequestorSet = 'Administrators' 
            RequestType  = @('Read','Add')
            GrantPermission = $false
            Request = $true
            ResourceSetBeforeRequest = 'All People'
            ResourceSetAfterRequest = 'All People'
            ResourceAttributeNames = 'ObjectID', 'DisplayName','Manager'
            AuthorizationWorkflowDefinition = 'Group Validation Workflow'
            #ActionWorkflowDefinition = ''
            Ensure       = "Present"
            Credential   = $fimAdminCredential
        }
    } 
} 

Sample_cFimService_ManagementPolicyRule -ConfigurationData $Global:AllNodes

Start-DscConfiguration -Wait -Verbose -Path "C:\fimdsc\Sample_cFimService_ManagementPolicyRule"
Get-FimObjectByXPath -Filter "/ManagementPolicyRule[DisplayName='_DscTestManagementPolicyRule1']" | select AuthorizationWorkflowDefinition
#endregion

#region: Request MPR - change the AuthorizationWorkflowDefinition (none)
Configuration Sample_cFimService_ManagementPolicyRule 
{ 

    Import-DscResource -ModuleName FimPowerShellModule

    Node (hostname) 
    { 
        cFimService_ManagementPolicyRule _DscTestManagementPolicyRule1
        {
              
            DisplayName  = "_DscTestManagementPolicyRule1"
            Description  = 'bars'
            Enabled      = $false
            RequestorSet = 'Administrators' 
            RequestType  = @('Read','Add')
            GrantPermission = $false
            Request = $true
            ResourceSetBeforeRequest = 'All People'
            ResourceSetAfterRequest = 'All People'
            ResourceAttributeNames = 'ObjectID', 'DisplayName','Manager'
            AuthorizationWorkflowDefinition = $null
            #ActionWorkflowDefinition = ''
            Ensure       = "Present"
            Credential   = $fimAdminCredential
        }
    } 
} 

Sample_cFimService_ManagementPolicyRule -ConfigurationData $Global:AllNodes

Start-DscConfiguration -Wait -Verbose -Path "C:\fimdsc\Sample_cFimService_ManagementPolicyRule"
Get-FimObjectByXPath -Filter "/ManagementPolicyRule[DisplayName='_DscTestManagementPolicyRule1']" | select AuthorizationWorkflowDefinition
#endregion

#region: Request MPR - change the AuthorizationWorkflowDefinition (multiple)
Configuration Sample_cFimService_ManagementPolicyRule 
{ 

    Import-DscResource -ModuleName FimPowerShellModule

    Node (hostname) 
    { 
        cFimService_ManagementPolicyRule _DscTestManagementPolicyRule1
        {
              
            DisplayName  = "_DscTestManagementPolicyRule1"
            Description  = 'bars'
            Enabled      = $false
            RequestorSet = 'Administrators' 
            RequestType  = @('Read','Add')
            GrantPermission = $false
            Request = $true
            ResourceSetBeforeRequest = 'All People'
            ResourceSetAfterRequest = 'All People'
            ResourceAttributeNames = 'ObjectID', 'DisplayName','Manager'
            AuthorizationWorkflowDefinition = 'Filter Validation Workflow for Administrators','Requestor Validation With Owner Authorization','Owner Approval Workflow'
            #ActionWorkflowDefinition = ''
            Ensure       = "Present"
            Credential   = $fimAdminCredential
        }
    } 
} 

Sample_cFimService_ManagementPolicyRule -ConfigurationData $Global:AllNodes

Start-DscConfiguration -Wait -Verbose -Path "C:\fimdsc\Sample_cFimService_ManagementPolicyRule"
Get-FimObjectByXPath -Filter "/ManagementPolicyRule[DisplayName='_DscTestManagementPolicyRule1']" | select AuthorizationWorkflowDefinition
#endregion

#region: Transition-In MPR with no WFs
Configuration Sample_cFimService_ManagementPolicyRule 
{ 

    Import-DscResource -ModuleName FimPowerShellModule

    Node (hostname) 
    { 
        cFimService_ManagementPolicyRule _DscTestManagementPolicyRule2
        {
              
            DisplayName  = "_DscTestManagementPolicyRule2"
            Description  = 'fooz'
            Enabled      = $true
            TransitionIn = $true  
            TransitionSet = 'Administrators'
            #ActionWorkflowDefinition = ''
            Ensure       = "Present"
            Credential   = $fimAdminCredential
        }
    } 
} 

Sample_cFimService_ManagementPolicyRule -ConfigurationData $Global:AllNodes

Start-DscConfiguration -Wait -Verbose -Path "C:\fimdsc\Sample_cFimService_ManagementPolicyRule"

#endregion

#region: Transition-In MPR - change the TransitionSet
Configuration Sample_cFimService_ManagementPolicyRule 
{ 

    Import-DscResource -ModuleName FimPowerShellModule

    Node (hostname) 
    { 
        cFimService_ManagementPolicyRule _DscTestManagementPolicyRule2
        {
              
            DisplayName  = "_DscTestManagementPolicyRule2"
            Description  = 'fooz'
            Enabled      = $true
            TransitionIn = $true  
            TransitionSet = 'All People'
            #ActionWorkflowDefinition = ''
            Ensure       = "Present"
            Credential   = $fimAdminCredential
        }
    } 
} 

Sample_cFimService_ManagementPolicyRule -ConfigurationData $Global:AllNodes

Start-DscConfiguration -Wait -Verbose -Path "C:\fimdsc\Sample_cFimService_ManagementPolicyRule"

#endregion

#region: Transition-In MPR - change TransitionIn
Configuration Sample_cFimService_ManagementPolicyRule 
{ 

    Import-DscResource -ModuleName FimPowerShellModule

    Node (hostname) 
    { 
        cFimService_ManagementPolicyRule _DscTestManagementPolicyRule2
        {
              
            DisplayName  = "_DscTestManagementPolicyRule2"
            Description  = 'fooz'
            Enabled      = $true
            TransitionOut = $true  
            TransitionSet = 'Administrators'
            #ActionWorkflowDefinition = ''
            Ensure       = "Present"
            Credential   = $fimAdminCredential
        }
    } 
} 

Sample_cFimService_ManagementPolicyRule -ConfigurationData $Global:AllNodes

Start-DscConfiguration -Wait -Verbose -Path "C:\fimdsc\Sample_cFimService_ManagementPolicyRule"

#endregion

#region: Transition-Out MPR with no WFs
Configuration Sample_cFimService_ManagementPolicyRule 
{ 

    Import-DscResource -ModuleName FimPowerShellModule

    Node (hostname) 
    { 
        cFimService_ManagementPolicyRule _DscTestManagementPolicyRule3
        {
              
            DisplayName  = "_DscTestManagementPolicyRule3"
            Description  = 'fooz'
            Enabled      = $true
            TransitionOut = $true 
            TransitionSet = 'Administrators'
            #ActionWorkflowDefinition = ''
            Ensure       = "Present"
            Credential   = $fimAdminCredential
        }
    } 
} 

Sample_cFimService_ManagementPolicyRule -ConfigurationData $Global:AllNodes

Start-DscConfiguration -Wait -Verbose -Path "C:\fimdsc\Sample_cFimService_ManagementPolicyRule"

#endregion

#region: Transition-In MPR with an Action WF
Configuration Sample_cFimService_ManagementPolicyRule 
{ 

    Import-DscResource -ModuleName FimPowerShellModule 

    Node (hostname) 
    { 
        cFimService_ManagementPolicyRule _DscTestManagementPolicyRule4
        {
              
            DisplayName  = "_DscTestManagementPolicyRule4"
            Description  = 'fooz'
            Enabled      = $true
            TransitionIn = $true  
            TransitionSet = 'Administrators'
            ActionWorkflowDefinition = 'Group Expiration Notification Workflow'
            Ensure       = "Present"
            Credential   = $fimAdminCredential
        }
    } 
} 

Sample_cFimService_ManagementPolicyRule -ConfigurationData $Global:AllNodes

Start-DscConfiguration -Wait -Verbose -Path "C:\fimdsc\Sample_cFimService_ManagementPolicyRule"

#endregion

#region: Transition-In MPR with multiple Action WFs
Configuration Sample_cFimService_ManagementPolicyRule 
{ 

    Import-DscResource -ModuleName FimPowerShellModule

    Node (hostname) 
    { 
        cFimService_ManagementPolicyRule _DscTestManagementPolicyRule5
        {
              
            DisplayName  = "_DscTestManagementPolicyRule5"
            Description  = 'fooz'
            Enabled      = $true
            TransitionIn = $true  
            TransitionSet = 'Administrators'
            ActionWorkflowDefinition = 'Group Expiration Notification Workflow','Expiration Workflow'
            Ensure       = "Present"
            Credential   = $fimAdminCredential
        }
    } 
} 

Sample_cFimService_ManagementPolicyRule -ConfigurationData $Global:AllNodes

Start-DscConfiguration -Wait -Verbose -Path "C:\fimdsc\Sample_cFimService_ManagementPolicyRule"

#endregion

#region: Transition-In MPR with multiple Action WFs, then none
Configuration Sample_cFimService_ManagementPolicyRule 
{ 

    Import-DscResource -ModuleName FimPowerShellModule

    Node (hostname) 
    { 
        cFimService_ManagementPolicyRule _DscTestManagementPolicyRule5
        {
              
            DisplayName  = "_DscTestManagementPolicyRule5"
            Description  = 'fooz'
            Enabled      = $true
            TransitionIn = $true  
            TransitionSet = 'Administrators'
            ActionWorkflowDefinition = $null
            Ensure       = "Present"
            Credential   = $fimAdminCredential
        }
    } 
} 

Sample_cFimService_ManagementPolicyRule -ConfigurationData $Global:AllNodes

Start-DscConfiguration -Wait -Verbose -Path "C:\fimdsc\Sample_cFimService_ManagementPolicyRule"

#endregion

#region Change 'Ensure' to 'Absent'
Configuration Sample_cFimService_ManagementPolicyRule 
{ 

    Import-DscResource -ModuleName FimPowerShellModule

    Node (hostname) 
    { 
        cFimService_ManagementPolicyRule _DscTestManagementPolicyRule1
        {
              
            DisplayName  = "_DscTestManagementPolicyRule1"
            Description  = 'fooz'
            Enabled      = $true
            RequestorSet = 'Administrators' 
            #RelativeToResourceAttributeName = 'ObjectID'
            RequestType  = @('Read', 'Create')
            GrantPermission = $true
            TransitionIn = 'Administrators' 
            TransitionOut = 'Administrators' 
            Request = $true
            ResourceSetBeforeRequest = 'All People'
            ResourceSetAfterRequest = 'All People'
            ResourceAttributeNames = 'ObjectID', 'DisplayName','Description'
            #AuthenticationWorkflowDefinition = ''
            #AuthorizationWorkflowDefinition = ''
            #ActionWorkflowDefinition = ''
            Ensure       = "Absent"
            Credential   = $fimAdminCredential
        }
    } 
} 

Sample_cFimService_ManagementPolicyRule -ConfigurationData $Global:AllNodes

Start-DscConfiguration -Wait -Verbose -Path "C:\fimdsc\Sample_cFimService_ManagementPolicyRule"

#endregion