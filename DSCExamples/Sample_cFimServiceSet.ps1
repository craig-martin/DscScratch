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

Configuration Sample_cFimServiceSet 
{ 

    Import-DscResource -ModuleName FimPowerShellModule
    #Import-DscResource -Name cFimServiceSet

    Node (hostname) 
    { 
        cFimServiceSet _DscTestSet1
        {
            Ensure       = "Present"  
            DisplayName  = "_DscTestSet"
            Credential   = $fimAdminCredential
            SetFilter    = "/Person"
            Description  = 'fooz'
        }
    } 
} 

Sample_cFimServiceSet -ConfigurationData $Global:AllNodes

Start-DscConfiguration -Wait -Verbose -Path "C:\fimdsc\Sample_cFimServiceSet"

<#
Change the Filter
#>
Configuration Sample_cFimServiceSet 
{ 

    Import-DscResource -ModuleName fimPowerShellModule

    Node (hostname) 
    { 
        cFimServiceSet _DscTestSet1
        {
            Ensure       = "Present"  
            DisplayName  = "_DscTestSet"
            Credential   = $fimAdminCredential
            SetFilter    = "/Group"
            Description  = 'fooz'
        }
    } 
} 

Sample_cFimServiceSet -ConfigurationData $Global:AllNodes

Start-DscConfiguration -Wait -Verbose -Path "C:\fimdsc\Sample_cFimServiceSet"

<#
Change the Description
#>
Configuration Sample_cFimServiceSet 
{ 

    Import-DscResource -ModuleName fimPowerShellModule

    Node (hostname) 
    { 
        cFimServiceSet _DscTestSet1
        {
            Ensure       = "Present"  
            DisplayName  = "_DscTestSet"
            Credential   = $fimAdminCredential
            SetFilter    = "/Person"
            Description  = 'changed foo'
        }
    } 
} 

Sample_cFimServiceSet -ConfigurationData $Global:AllNodes

Start-DscConfiguration -Wait -Verbose -Path "C:\fimdsc\Sample_cFimServiceSet"


<#
Change 'Ensure' to 'Absent'
#>
Configuration Sample_cFimServiceSet 
{ 

    Import-DscResource -ModuleName fimPowerShellModule

    Node (hostname) 
    { 
        cFimServiceSet _DscTestSet1
        {
            Ensure       = "Absent"  
            DisplayName  = "_DscTestSet"
            Credential   = $fimAdminCredential
            SetFilter    = "/Group"
            Description  = 'fooz'
        }
    } 
} 

Sample_cFimServiceSet -ConfigurationData $Global:AllNodes

Start-DscConfiguration -Wait -Verbose -Path "C:\fimdsc\Sample_cFimServiceSet"