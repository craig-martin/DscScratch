$ConfigurationData = @{
    AllNodes = @(
        @{
            NodeName               = (hostname)
            CertificateFile        = "D:\Certificates\craigweb.corp.microsoft.com.cer"
         }
    )
}

configuration FimOneBox
{

    Import-DscResource -ModuleName cSqlPs
    Import-DsCResource -ModuleName xPendingReboot
    Import-DsCResource -ModuleName xComputerManagement
    Import-DscResource -ModuleName xPSDesiredStateConfiguration

    $saCred                 = New-Object System.Management.Automation.PSCredential sa,                   (ConvertTo-SecureString 'PA$$w0rd2014' -AsPlainText -Force)
    $localAdminCred         = New-Object System.Management.Automation.PSCredential administrator,        (ConvertTo-SecureString 'PA$$w0rd2014' -AsPlainText -Force)
    $fimMaCred              = New-Object System.Management.Automation.PSCredential "$(hostname)\fimma",  (ConvertTo-SecureString 'PA$$w0rd2014' -AsPlainText -Force)
    $fimSvcCred             = New-Object System.Management.Automation.PSCredential "$(hostname)\fimsvc", (ConvertTo-SecureString 'PA$$w0rd2014' -AsPlainText -Force)
    $domainCredential       = New-Object System.Management.Automation.PSCredential REDMOND\cmfim1,       (ConvertTo-SecureString 'PA$$w0rd2014' -AsPlainText -Force)

    node $AllNodes.NodeName
    {
        LocalConfigurationManager 
        { 
             CertificateId = "13AA23245848B50C787D56C15595400213BA2E15" 
             RebootNodeIfNeeded = 'true'
             ConfigurationModeFrequencyMins = '15'
        } 

        #region Join the Domain
        xComputer JoinDomain
        {
            Name             = $Node.NodeName
            DomainName       = 'redmond.corp.microsoft.com'
            Credential       = $domainCredential 
        }

        xGroup AddCredentialUserToAdmins
        {
            GroupName        = "Administrators"
            Ensure           = "Present"
            MembersToInclude = 'redmond\v-crmart'
            Credential       = $domainCredential
            DependsOn        = "[xComputer]JoinDomain"
        }
        #endregion

        #region Windows Features
        WindowsFeature  WindowsIdentityFoundation
        {
            Ensure = "Present"
            Name   = "Windows-Identity-Foundation"
            IncludeAllSubFeature = $true   
        }

        WindowsFeature NetFramework35Core
        {
            Name = "NET-Framework-Core"
            Ensure = "Present"   
        }
 
        WindowsFeature NetFramework45Full
        {
            Name = "NET-Framework-45-Features"
            Ensure = "Present"
            IncludeAllSubFeature = $true
        }

        WindowsFeature WebMgmtTools
        {
            Ensure = "Present"
            Name   = "Web-Mgmt-Tools"
            IncludeAllSubFeature = $true  
        }

        WindowsFeature WebWebServer
        {
            Name = "Web-WebServer"
            Ensure = "Present"
            IncludeAllSubFeature = $true
        }

        WindowsFeature ApplicationServer
        {
            Ensure = "Present"
            Name   = "Application-Server"
            IncludeAllSubFeature = $true           
        }
 
        #endregion

        #region SharePoint Prerequisites
        Package MicrosoftIdentityExtensions
        {
            Ensure    = "Present"  
            Path      = "D:\SharePointPreReqs\MicrosoftIdentityExtensions-64.msi"
            Name      = "Microsoft Identity Extensions"
            ProductId = "F99F24BF-0B90-463E-9658-3FD2EFC3C992"
            LogPath   = "C:\Windows\Temp\MicrosoftIdentityExtensions.log"
            DependsOn = "[WindowsFeature]WindowsIdentityFoundation"
        }

        Package MSIPC
        {
            Ensure    = "Present"  
            Path      = "D:\SharepointPreReqs\setup_msipc_x64.msi"
            Name      = "Active Directory Rights Management Services Client 2.0"
            ProductId = "C293A044-3603-4CA3-B8FC-BA3F86F9F169"
            LogPath   = "C:\Windows\Temp\setup_msipc_x64.log"
            DependsOn = "[Package]MicrosoftIdentityExtensions"
        }
        <#
        Package SqlNCli
        {
            Ensure    = "Present"   
            Name      = "Microsoft SQL Server 2012 Native Client "
            #Path      = "D:\SharepointPreReqs\sqlncli.msi"
            #ProductId = "49D665A2-4C2A-476E-9AB8-FCC425F526FC"
            Path      = "C:\Temp\SQL\1033_ENU_LP\x64\Setup\x64\sqlncli.msi"
            ProductId = "D411E9C9-CE62-4DBF-9D92-4CB22B750ED5"
            LogPath   = "C:\Windows\Temp\sqlncli.log"
            Arguments = "IACCEPTSQLNCLILICENSETERMS=YES"
        }
        #>
        Package Synchronization
        {
            Ensure    = "Present"  
            Path      = "D:\SharepointPreReqs\Synchronization.msi"
            Name      = "Microsoft Sync Framework Runtime v1.0 SP1 (x64)"
            ProductId = "8438EC02-B8A9-462D-AC72-1B521349C001"
            LogPath   = "C:\Windows\Temp\Synchronization.log"
            #DependsOn = "[Package]SqlNCli"
        }

        Package WcfDataServices5
        {
            Ensure    = "Present"  
            Path      = "D:\SharePointPreReqs\WCF-5.0\WcfDataServices.exe"
            Name      = "WCF Data Services 5.0 (OData v3)"
            ProductId = "ad60454d-9edf-4100-8342-06830732be63"
            LogPath   = "C:\Windows\Temp\WcfDataServices.log"
            Arguments = "/quiet"
            DependsOn = "[Package]Synchronization"
        }

        Package WcfDataServices56
        {
            Ensure    = "Present"  
            Path      = "D:\SharePointPreReqs\WCF-5.6\WcfDataServices.exe"
            Name      = "WCF Data Services 5.6.0 Runtime"
            ProductId = "46910786-E4AC-41E4-A4A0-C086EA85242D"
            LogPath   = "C:\Windows\Temp\WcfDataServices.log"
            Arguments = "/quiet"
            DependsOn = "[Package]Synchronization"
        }
        
        Package AppFabric
        {
            <#
                This package will fail if the PSModulePath contains a quote:
                    https://social.msdn.microsoft.com/Forums/vstudio/en-US/8cf55972-e441-4107-8c0d-1692ad03213d/error-with-installation-of-appfabric-11-on-psmodulepath?forum=velocity
                Use this to test: 
                    [System.Environment]::GetEnvironmentVariable("PSModulePath", [System.EnvironmentVariableTarget]::Machine) -like '*"*'
            #>
            Ensure    = "Present"  
            Path      = "D:\SharepointPreReqs\WindowsServerAppFabricSetup_x64.exe"
            Name      = "AppFabric 1.1 for Windows Server"
            ProductId = "96E70525-4CD1-4920-9C0B-91055C79A962"
            #LogPath   = "C:\Windows\Temp\WindowsServerAppFabricSetup_x64.log" # note: this does not work with an EXE and the Package Resource
            Arguments = "/i cacheclient,cachingService,cacheadmin /gac /l C:\Windows\Temp\WindowsServerAppFabricSetup_x64.log"
        }

        Script AppFabricUpdate
        {
            GetScript = { Return "AppFabricUpdate" }
            TestScript = {
                $regKeyForUpdateKB2671763 = Get-ChildItem "HKLM:\Software\Wow6432Node\Microsoft\Updates\AppFabric 1.1 for Windows Server\KB2671763" -ErrorAction SilentlyContinue
                if ($regKeyForUpdateKB2671763) {
                    Write-Verbose "AppFabric Update already installed"
                    return $true
                } else {
                    Write-Verbose "AppFabric Update not installed"
                    return $false
                }
            }
            SetScript = {               
                Start-Process -FilePath 'D:\SharepointPreReqs\AppFabric1.1-RTM-KB2671763-x64-ENU.exe' -ArgumentList '/quiet' -Wait | Write-verbose 
            }
            DependsOn = "[Package]AppFabric"
        }
        #endregion

        #NOTE - this warning can be safely ignored : "Unable to query CCM_ClientUtilities: Invalid namespace"
        xPendingReboot BeforeSharePointInstall
        {
            Name = "BeforeSharePointInstall"
        }

        #region SQL Server Install
        cSqlServerInstall InstallSQLServer
        {
            InstanceName = "MSSQLSERVER"
            SourcePath = "D:\SQL"           
            SqlAdministratorCredential = $saCred
            PID = "7TFR8-FMK2W-MWDXP-J224F-JTR8F"
            SysAdminAccounts = 'administrator'
            Features = 'SQLENGINE,FULLTEXT'
            #DependsOn = "[File]SQLServerIso"
        }

        Package InstallSharePointFoundation
        {
            Ensure             = "Present"
            Name               = "Microsoft SharePoint Foundation 2013 Core"
            Path               = "D:\SharePointFoundation2013\Setup.exe"
            Arguments          = "/config C:\Temp\SharePointFoundation2013\files\setupsilent\config.xml"
            ProductID          = "90150000-1014-0000-1000-0000000FF1CE"
            ReturnCode         = 0
            DependsOn          = "[Script]AppFabricUpdate","[WindowsFeature]ApplicationServer","[WindowsFeature]WebWebServer","[WindowsFeature]NetFramework45Full","[Package]WcfDataServices5","[Package]WcfDataServices56", "[xPendingReboot]BeforeSharePointInstall", "[cSqlServerInstall]InstallSQLServer"
        }

        Script FimSharePointConfiguration
        {
            DependsOn = "[Package]InstallSharePointFoundation"
                 
            GetScript = {Return "SetupSharepointAdmin"}
            TestScript = {
                add-pssnapin Microsoft.SharePoint.PowerShell
                if (Get-SPContentDatabase -WebApplication 'FIM SharePoint Web Application' -ErrorAction SilentlyContinue)
                {
                    Write-Verbose "FIM Content Database found, returning True"
                    return $true                     
                }
                else
                {
                    Write-Verbose "FIM Content Database not found, returning False"
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

                #REBOOT JUST BECUASE
                #$global:DSCMachineStatus = 1    
            }
        }

        User FimMA
        {
            Ensure   = "Present"
            UserName = $fimMaCred.GetNetworkCredential().UserName
            Password = $fimMaCred 
        }

        User FimSvc
        {
            Ensure   = "Present"
            UserName = $fimSvcCred.GetNetworkCredential().UserName
            Password = $fimSvcCred 
        }

        Service SQLAgentService
        {
            Name = "SQLSERVERAGENT"
            StartupType = "Automatic"
            State = "Running"
        }

        Service SPAdminV4Service
        {
            Name = "SPAdminV4"
            StartupType = "Automatic"
            State = "Running"
        }

        #NOTE - this warning can be safely ignored : "Unable to query CCM_ClientUtilities: Invalid namespace"
        xPendingReboot BeforeFimInstall
        {
            Name = "BeforeFimInstall"
        }

        <#
        xPackage InstallFimSync
        {
            Ensure             = "Present"
            Name               = "Forefront Identity Manager Synchronization Service"
            Path               = "D:\fim\synchronization Service\synchronization Service.msi"
            RunAsCredential    = $credential
            ProductId          = '51F4677B-5C3F-49AA-87F8-2B58ABA98301'
            Arguments          = "ACCEPT_EULA=1 serviceaccount=anbecvar servicepassword=$( [System.Runtime.InteropServices.marshal]::PtrToStringAuto([System.Runtime.InteropServices.marshal]::SecureStringToBSTR($credential.password))) servicedomain=$($Node.domain) storeserver=$($Node.NodeName) reboot=reallysuppress groupadmins=FIMSyncAdmins GROUPOPERATORS=FIMSyncOperators GROUPACCOUNTJOINERS=FIMSyncJoiners GROUPBROWSE=FIMSyncBrowse GROUPPASSWORDSET=FIMSyncPasswordSet"
            LogPath            = "C:\Windows\Temp\fimsync-install.log"
            DependsOn          = "[Service]StartSQLAgent"

        }
        #>

        xPackage FimService
        {
            Ensure             = "Present"
            Name               = "Forefront Identity Manager Service and Portal"
            Path               = "D:\fim\Service and Portal\service and portal.msi"
            RunAsCredential    = $localAdminCred
            Arguments          = "ADDLOCAL=CommonServices,WebPortals ACCEPT_EULA=1 SQLSERVER_SERVER=localhost SERVICE_ACCOUNT_NAME=$($fimSvcCred.UserName) SERVICE_ACCOUNT_PASSWORD=$($fimSvcCred.GetNetworkCredential().Password) SERVICE_ACCOUNT_DOMAIN=$($fimSvcCred.GetNetworkCredential().Domain) SERVICE_ACCOUNT_EMAIL=foo@bar.baz SYNCHRONIZATION_SERVER=$(hostname) SYNCHRONIZATION_SERVER_ACCOUNT=$($fimMaCred.UserName) MAIL_SERVER=localhost MAIL_SERVER_USE_SSL=0 MAIL_SERVER_IS_EXCHANGE=0 SERVICEADDRESS=$(hostname) SHAREPOINT_URL=http://localhost"
            LogPath            = "C:\Windows\Temp\fimservice-install.log"
            ProductID          = "8EB24D93-91BA-435D-BF88-9339C1C46362"
            DependsOn          = "[xPendingReboot]BeforeFimInstall","[Service]SQLAgentService","[Service]SPAdminV4Service","[User]FimMA"         
        }
    }
}

FimOneBox -ConfigurationData $ConfigurationData -OutputPath C:\Windows\Temp\FimOneBox

Set-DscLocalConfigurationManager -Path C:\Windows\Temp\FimOneBox

Start-DscConfiguration -Verbose -Wait -Path C:\Windows\Temp\FimOneBox -Force