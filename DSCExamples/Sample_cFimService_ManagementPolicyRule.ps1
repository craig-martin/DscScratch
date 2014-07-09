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
            Ensure       = "Present"
            Credential   = $fimAdminCredential
        }
    } 
} 

Sample_cFimService_ManagementPolicyRule -ConfigurationData $Global:AllNodes

Start-DscConfiguration -Wait -Verbose -Path "C:\fimdsc\Sample_cFimService_ManagementPolicyRule"





<#
Change 'Ensure' to 'Absent'
#>
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