

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

#region: New Request MPR with no WFs
Configuration TestMpr 
{ 

    Import-DscResource -ModuleName FimPowerShellModule

    $displayName = 'Mpr001'

    Node (hostname) 
    { 
        cFimManagementPolicyRule $displayName
        {
            ActionParameter = '*' 
            ActionType = 'TransitionIn'
            ActionWorkflowDefinition = 'Group Expiration Notification Workflow' 
            Description  = 'fooz'
            Disabled     = $false
            DisplayName  = $displayName
            GrantRight   = $false
            ResourceFinalSet = 'Administrators'
            ManagementPolicyRuleType = 'SetTransition'
            Ensure       = "Present"
            Credential   = $fimAdminCredential
        }
    } 
} 

TestMpr -ConfigurationData $Global:AllNodes

Start-DscConfiguration -Wait -Verbose -Path "C:\fimdsc\TestMpr"

Get-FimObjectByXPath -Filter "/ManagementPolicyRule[DisplayName='$displayName']"

Get-FimObjectByXPath -Filter "/Request[Target = /ManagementPolicyRule[DisplayName='$displayName'] and CreatedTime >= '$([DateTime]::UtcNow.AddMinutes(-55).ToString("s"))']" | 
Select-Object -Last 1 | 
Get-FimRequestParameter |
Format-Table Mode, PropertyName, Value -AutoSize

New-FimImportObject -ObjectType ManagementPolicyRule -State Delete -TargetObjectIdentifier (Get-FimObjectID ManagementPolicyRule DisplayName $displayName) -ApplyNow

Import-Clixml C:\temp\fimImportChanges.clixml | ft -a
#endregion