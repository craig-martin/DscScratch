md c:\fimdsc
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

Configuration Sample_cFimService_Workflow 
{ 

    Import-DscResource -ModuleName FimPowerShellModule
    #Import-DscResource -Name cFimServiceSet

    Node (hostname) 
    { 
        cFimService_Workflow _DscTestWorkflow1
        {
              
            DisplayName  = "_DscTestWorkflow1"
            Description  = 'fooz'
            RequestPhase = "Authorization"
            RunOnPolicyUpdate    = $false 
            Xoml = @"
<ns0:SequentialWorkflow 
  x:Name="SequentialWorkflow" 
  ActorId="00000000-0000-0000-0000-000000000000" 
  WorkflowDefinitionId="00000000-0000-0000-0000-000000000000" 
  RequestId="00000000-0000-0000-0000-000000000000" 
  TargetId="00000000-0000-0000-0000-000000000000" 
  xmlns="http://schemas.microsoft.com/winfx/2006/xaml/workflow" 
  xmlns:ns1="clr-namespace:System.Workflow.Activities;Assembly=System.WorkflowServices, Version=3.5.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35" 
  xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" 
  xmlns:ns0="clr-namespace:Microsoft.ResourceManagement.Workflow.Activities;Assembly=Microsoft.ResourceManagement, Version=4.1.3114.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35"
  >
  <ns0:GroupValidationActivity 
    x:Name="groupValidationActivity1" 
    ValidationSemantics="All" 
  />
  <ns0:ApprovalActivity 
    IsApproved="{x:Null}" 
    Escalation="{x:Null}" 
    ReceivedApprovals="0" 
    CurrentApprovalResponse="{x:Null}" 
    RequestTimedOut="False" 
    Approvers="[//Target/Owner];" 
    RejectedReason="{x:Null}" 
    Request="{x:Null}" 
    ApprovalObject="{x:Null}" 
    Threshold="1" 
    x:Name="approvalActivity1" 
    Duration="3.00:00:00" 
    CurrentApprovalResponseActorId="00000000-0000-0000-0000-000000000000"
  >
    <ns1:ReceiveActivity.WorkflowServiceAttributes>
      <ns1:WorkflowServiceAttributes 
        Name="ApprovalActivity" 
        ConfigurationName="Microsoft.ResourceManagement.Workflow.Activities.ApprovalActivity" 
      />
    </ns1:ReceiveActivity.WorkflowServiceAttributes>
  </ns0:ApprovalActivity>
  <ns0:GroupValidationActivity 
    x:Name="groupValidationActivity2" 
    ValidationSemantics="All" 
  />
</ns0:SequentialWorkflow>
"@
            Ensure       = "Present"
            Credential   = $fimAdminCredential
        }
    } 
} 

Sample_cFimService_Workflow -ConfigurationData $Global:AllNodes

Start-DscConfiguration -Wait -Verbose -Path "C:\fimdsc\Sample_cFimService_Workflow"

<#
Change the RequestPhase
#>
Configuration Sample_cFimService_Workflow 
{ 

    Import-DscResource -ModuleName FimPowerShellModule
    #Import-DscResource -Name cFimServiceSet

    Node (hostname) 
    { 
        cFimService_Workflow _DscTestWorkflow1
        {
              
            DisplayName  = "_DscTestWorkflow1"
            Description  = 'fooz'
            RequestPhase = "Action"
            RunOnPolicyUpdate    = $false 
            Xoml = @"
<ns0:SequentialWorkflow 
  x:Name="SequentialWorkflow" 
  ActorId="00000000-0000-0000-0000-000000000000" 
  WorkflowDefinitionId="00000000-0000-0000-0000-000000000000" 
  RequestId="00000000-0000-0000-0000-000000000000" 
  TargetId="00000000-0000-0000-0000-000000000000" 
  xmlns="http://schemas.microsoft.com/winfx/2006/xaml/workflow" 
  xmlns:ns1="clr-namespace:System.Workflow.Activities;Assembly=System.WorkflowServices, Version=3.5.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35" 
  xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" 
  xmlns:ns0="clr-namespace:Microsoft.ResourceManagement.Workflow.Activities;Assembly=Microsoft.ResourceManagement, Version=4.1.3114.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35"
  >
  <ns0:GroupValidationActivity 
    x:Name="groupValidationActivity1" 
    ValidationSemantics="All" 
  />
  <ns0:ApprovalActivity 
    IsApproved="{x:Null}" 
    Escalation="{x:Null}" 
    ReceivedApprovals="0" 
    CurrentApprovalResponse="{x:Null}" 
    RequestTimedOut="False" 
    Approvers="[//Target/Owner];" 
    RejectedReason="{x:Null}" 
    Request="{x:Null}" 
    ApprovalObject="{x:Null}" 
    Threshold="1" 
    x:Name="approvalActivity1" 
    Duration="3.00:00:00" 
    CurrentApprovalResponseActorId="00000000-0000-0000-0000-000000000000"
  >
    <ns1:ReceiveActivity.WorkflowServiceAttributes>
      <ns1:WorkflowServiceAttributes 
        Name="ApprovalActivity" 
        ConfigurationName="Microsoft.ResourceManagement.Workflow.Activities.ApprovalActivity" 
      />
    </ns1:ReceiveActivity.WorkflowServiceAttributes>
  </ns0:ApprovalActivity>
  <ns0:GroupValidationActivity 
    x:Name="groupValidationActivity2" 
    ValidationSemantics="All" 
  />
</ns0:SequentialWorkflow>
"@
            Ensure       = "Present"
            Credential   = $fimAdminCredential
        }
    } 
} 

Sample_cFimService_Workflow -ConfigurationData $Global:AllNodes

Start-DscConfiguration -Wait -Verbose -Path "C:\fimdsc\Sample_cFimService_Workflow"

<#
Change the Description
#>
Configuration Sample_cFimService_Workflow 
{ 

    Import-DscResource -ModuleName FimPowerShellModule
    #Import-DscResource -Name cFimServiceSet

    Node (hostname) 
    { 
        cFimService_Workflow _DscTestWorkflow1
        {
              
            DisplayName  = "_DscTestWorkflow1"
            Description  = 'bar'
            RequestPhase = "Action"
            RunOnPolicyUpdate    = $false 
            Xoml = @"
<ns0:SequentialWorkflow 
  x:Name="SequentialWorkflow" 
  ActorId="00000000-0000-0000-0000-000000000000" 
  WorkflowDefinitionId="00000000-0000-0000-0000-000000000000" 
  RequestId="00000000-0000-0000-0000-000000000000" 
  TargetId="00000000-0000-0000-0000-000000000000" 
  xmlns="http://schemas.microsoft.com/winfx/2006/xaml/workflow" 
  xmlns:ns1="clr-namespace:System.Workflow.Activities;Assembly=System.WorkflowServices, Version=3.5.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35" 
  xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" 
  xmlns:ns0="clr-namespace:Microsoft.ResourceManagement.Workflow.Activities;Assembly=Microsoft.ResourceManagement, Version=4.1.3114.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35"
  >
  <ns0:GroupValidationActivity 
    x:Name="groupValidationActivity1" 
    ValidationSemantics="All" 
  />
  <ns0:ApprovalActivity 
    IsApproved="{x:Null}" 
    Escalation="{x:Null}" 
    ReceivedApprovals="0" 
    CurrentApprovalResponse="{x:Null}" 
    RequestTimedOut="False" 
    Approvers="[//Target/Owner];" 
    RejectedReason="{x:Null}" 
    Request="{x:Null}" 
    ApprovalObject="{x:Null}" 
    Threshold="1" 
    x:Name="approvalActivity1" 
    Duration="3.00:00:00" 
    CurrentApprovalResponseActorId="00000000-0000-0000-0000-000000000000"
  >
    <ns1:ReceiveActivity.WorkflowServiceAttributes>
      <ns1:WorkflowServiceAttributes 
        Name="ApprovalActivity" 
        ConfigurationName="Microsoft.ResourceManagement.Workflow.Activities.ApprovalActivity" 
      />
    </ns1:ReceiveActivity.WorkflowServiceAttributes>
  </ns0:ApprovalActivity>
  <ns0:GroupValidationActivity 
    x:Name="groupValidationActivity2" 
    ValidationSemantics="All" 
  />
</ns0:SequentialWorkflow>
"@
            Ensure       = "Present"
            Credential   = $fimAdminCredential
        }
    } 
}  

Sample_cFimService_Workflow -ConfigurationData $Global:AllNodes

Start-DscConfiguration -Wait -Verbose -Path "C:\fimdsc\Sample_cFimService_Workflow"


<#
Change the XOML
#>
Configuration Sample_cFimService_Workflow 
{ 

    Import-DscResource -ModuleName FimPowerShellModule
    #Import-DscResource -Name cFimServiceSet

    Node (hostname) 
    { 
        cFimService_Workflow _DscTestWorkflow1
        {
              
            DisplayName  = "_DscTestWorkflow1"
            Description  = 'bar'
            RequestPhase = "Action"
            RunOnPolicyUpdate    = $false 
            Xoml = @"
<ns0:SequentialWorkflow 
  x:Name="SequentialWorkflow" 
  ActorId="00000000-0000-0000-0000-000000000000" 
  WorkflowDefinitionId="00000000-0000-0000-0000-000000000000" 
  RequestId="00000000-0000-0000-0000-000000000000" 
  TargetId="00000000-0000-0000-0000-000000000000" 
  xmlns="http://schemas.microsoft.com/winfx/2006/xaml/workflow" 
  xmlns:ns1="clr-namespace:System.Workflow.Activities;Assembly=System.WorkflowServices, Version=3.5.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35" 
  xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" 
  xmlns:ns0="clr-namespace:Microsoft.ResourceManagement.Workflow.Activities;Assembly=Microsoft.ResourceManagement, Version=4.1.3114.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35"
  >
  <ns0:GroupValidationActivity 
    x:Name="groupValidationActivity1" 
    ValidationSemantics="All" 
  />
  <ns0:ApprovalActivity 
    IsApproved="{x:Null}" 
    Escalation="{x:Null}" 
    ReceivedApprovals="0" 
    CurrentApprovalResponse="{x:Null}" 
    RequestTimedOut="False" 
    Approvers="[//Target/Owner];" 
    RejectedReason="{x:Null}" 
    Request="{x:Null}" 
    ApprovalObject="{x:Null}" 
    Threshold="1" 
    x:Name="approvalActivity1" 
    Duration="6.00:00:00" 
    CurrentApprovalResponseActorId="00000000-0000-0000-0000-000000000000"
  >
    <ns1:ReceiveActivity.WorkflowServiceAttributes>
      <ns1:WorkflowServiceAttributes 
        Name="ApprovalActivity" 
        ConfigurationName="Microsoft.ResourceManagement.Workflow.Activities.ApprovalActivity" 
      />
    </ns1:ReceiveActivity.WorkflowServiceAttributes>
  </ns0:ApprovalActivity>
  <ns0:GroupValidationActivity 
    x:Name="groupValidationActivity2" 
    ValidationSemantics="All" 
  />
</ns0:SequentialWorkflow>
"@
            Ensure       = "Present"
            Credential   = $fimAdminCredential
        }
    } 
}  

Sample_cFimService_Workflow -ConfigurationData $Global:AllNodes

Start-DscConfiguration -Wait -Verbose -Path "C:\fimdsc\Sample_cFimService_Workflow"

<#
Change 'Ensure' to 'Absent'
#>
Configuration Sample_cFimService_Workflow 
{ 

    Import-DscResource -ModuleName fimPowerShellModule

    Node (hostname) 
    { 
        cFimService_Workflow _DscTestWorkflow1
        {
            Ensure       = "Absent"  
            DisplayName  = "_DscTestWorkflow1"
            Credential   = $fimAdminCredential
            #SetFilter    = "/Group"
            Description  = 'fooz'
        }
    } 
} 

Sample_cFimService_Workflow -ConfigurationData $Global:AllNodes

Start-DscConfiguration -Wait -Verbose -Path "C:\fimdsc\Sample_cFimService_Workflow"