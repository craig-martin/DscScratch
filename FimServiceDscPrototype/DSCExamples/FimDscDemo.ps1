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

#region: Request MPR 
Configuration FimDscDemo 
{ 

    Import-DscResource -ModuleName FimPowerShellModule

    Node (hostname) 
    { 
        cFimService_ManagementPolicyRule _SampleMPR
        {
              
            DisplayName  = "_SampleMPR"
            Description  = 'bars'
            Enabled      = $false
            RequestorSet = 'Administrators' 
            RequestType  = @('Read','Modify')
            GrantPermission = $false
            Request = $true
            ResourceSetBeforeRequest = 'All People'
            ResourceSetAfterRequest = 'All People'
            ResourceAttributeNames = 'ObjectID', 'DisplayName','Manager'
            AuthorizationWorkflowDefinition = 'Requestor Validation With Owner Authorization','Owner Approval Workflow'
            #ActionWorkflowDefinition = ''
            Ensure       = "Present"
            Credential   = $fimAdminCredential
        }
    } 
} 

FimDscDemo -ConfigurationData $Global:AllNodes

Start-DscConfiguration -Wait -Verbose -Path "C:\fimdsc\FimDscDemo"

#ResourceAttributeNames = 'ObjectID', 'DisplayName','Manager'
#ResourceAttributeNames = 'ObjectID', 'DisplayName','CreatedTime','ObjectType'

#GrantPermission = $true
#GrantPermission = $false

#ActionWorkflowDefinition = ''
#ActionWorkflowDefinition = 'Group Expiration Notification Workflow','Expiration Workflow'