#TODO - fold both these resources into one
#ISSUE - it'll be difficult to set this once it is created, consider that out of scope just to get done, throw

$ConfigurationData = @{
    AllNodes = @(
        @{
            NodeName               = (hostname)
            CertificateFile        = "c:\Temp\Certificates\craigweb.corp.microsoft.com.cer"
         }
    )
}

configuration SharePointConfigForFim
{

    Import-DscResource -ModuleName cSqlPs
    Import-DsCResource -ModuleName xPendingReboot
    Import-DsCResource -ModuleName xComputerManagement
    Import-DscResource -ModuleName xPSDesiredStateConfiguration

    $saCred                 = New-Object System.Management.Automation.PSCredential sa, (ConvertTo-SecureString 'PA$$w0rd2014' -AsPlainText -Force)
    $domainCredential       = New-Object System.Management.Automation.PSCredential REDMOND\cmfim1, (ConvertTo-SecureString '12thManFactor%' -AsPlainText -Force)

    node $AllNodes.NodeName
    {
        LocalConfigurationManager 
        { 
             CertificateId = "13AA23245848B50C787D56C15595400213BA2E15" 
             RebootNodeIfNeeded = 'true'
             ConfigurationModeFrequencyMins = '15'
        } 

        Script SetupSharepointAdmin
        {
            #DependsOn = "[Package]InstallSharePointFoundation"
                 
            GetScript = {Return "SetupSharepointAdmin"}
            TestScript = {
                add-pssnapin Microsoft.SharePoint.PowerShell
                if (Get-SPServer)
                {
                    Write-Verbose "SPServer Found, returning True"
                    return $true                     
                }
                else
                {
                    Write-Verbose "SPServer Not Found, returning False"
                    return $false
                }
            }
            SetScript = {
                add-pssnapin Microsoft.SharePoint.PowerShell

                $databaseServer = (hostname)
                $configDatabase = "FIMSP_Config" 
                $adminContentDB = "FIMSP_Content_Admin" 

                $adminCredential = New-Object System.Management.Automation.PSCredential "$(hostname)\administrator",(ConvertTo-SecureString 'PA$$w0rd2014' -AsPlainText -Force)

                New-SPConfigurationDatabase -DatabaseServer $databaseServer -DatabaseName $configDatabase -AdministrationContentDatabaseName $adminContentDB -Passphrase $adminCredential.Password -FarmCredentials $adminCredential 
                Write-Verbose "ACLing SharePoint Resources..."
                Initialize-SPResourceSecurity 

                Write-Verbose "Installing Services ..." 
                Install-SPService   

                Write-Verbose "Installing Features..." 
                Install-SPFeature -AllExistingFeatures 

                Write-Verbose "Creating Central Administration..."              
                New-SPCentralAdministration -Port 8080 -WindowsAuthProvider NTLM 

                Write-Verbose "Installing Application Content..." 
                Install-SPApplicationContent 

                #REBOOT JUST BECUASE
                #$global:DSCMachineStatus = 1    
            }
        }

        Script SetupSharePointSite
        {
            
            GetScript = {Return "SetupSharePointSite"}
            TestScript = {
                add-pssnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue
                $contentService = [Microsoft.SharePoint.Administration.SPWebService]::ContentService
                $viewStateOnServer = $contentService.ViewStateOnServer

                $spSite = SpSite("Http://localhost") -ErrorAction SilentlyContinue
                $allowSelfServiceUpgrade = $spSite.AllowSelfServiceUpgrade            

                $fimSpWebApplication = Get-SPWebApplication -Identity 'FIM SharePoint Web Application' -ErrorAction SilentlyContinue

                if ($viewStateOnServer -eq $false -and $allowSelfServiceUpgrade -eq $false -and $fimSpWebApplication)
                {
                    return $true
                }
                else
                {
                    return $false
                }
            }
            SetScript = {
                add-pssnapin Microsoft.SharePoint.PowerShell
                
                Write-Verbose "Creating SharePoint Web Application" 
                New-SpWebApplication -Name "FIM SharePoint Web Application" -ApplicationPool "FIMAppPool" -AuthenticationMethod NTLM -ApplicationPoolAccount (Get-SPManagedAccount -Identity "$(hostname)\administrator") -Port 80 -URL http://localhost
                
                Write-Verbose "Creating SharePoint root Site Collection..." 
                New-SPSite -Url "http://localhost" -OwnerAlias "$(hostname)\administrator" -Template "STS#1" -CompatibilityLevel 14
                
                Write-Verbose "Configuring View State..."
                $contentService = [Microsoft.SharePoint.Administration.SPWebService]::ContentService
                $contentService.ViewStateOnServer = $false
                $contentService.Update()

                Write-Verbose "Disabling self service upgrade..."
                $spSite = SpSite("http://localhost")
                $spSite.AllowSelfServiceUpgrade = $false
                                                           
            }
            DependsOn = "[Script]SetupSharepointAdmin"
        }
    }
}

SharePointConfigForFim -ConfigurationData $ConfigurationData -OutputPath c:\temp\SharePointConfigForFim

Set-DscLocalConfigurationManager -Path c:\temp\SharePointConfigForFim
Get-DscLocalConfigurationManager
Start-DscConfiguration -Verbose -Wait -Path c:\temp\SharePointConfigForFim 