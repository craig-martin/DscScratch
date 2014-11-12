$ConfigurationData = @{
    AllNodes = @(
        @{
            NodeName               = (hostname)
            CertificateFile        = "c:\Temp\Certificates\craigweb.corp.microsoft.com.cer"
         }
    )
}

configuration SqlAndSharePoint
{

    Import-DscResource -ModuleName cSqlPs
    Import-DsCResource -ModuleName xPendingReboot

    $saCred                 = New-Object System.Management.Automation.PSCredential sa, (ConvertTo-SecureString 'PA$$w0rd2014' -AsPlainText -Force)
    
    node $AllNodes.NodeName
    {
        LocalConfigurationManager 
        { 
             CertificateId = "13AA23245848B50C787D56C15595400213BA2E15" 
             RebootNodeIfNeeded = 'true'
             ConfigurationModeFrequencyMins = '15'
        } 

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
            Path      = "C:\Temp\SharePointPreReqs\MicrosoftIdentityExtensions-64.msi"
            Name      = "Microsoft Identity Extensions"
            ProductId = "F99F24BF-0B90-463E-9658-3FD2EFC3C992"
            LogPath   = "c:\temp\MicrosoftIdentityExtensions.log"
            DependsOn = "[WindowsFeature]WindowsIdentityFoundation"
        }

        Package MSIPC
        {
            Ensure    = "Present"  
            Path      = "C:\Temp\SharepointPreReqs\setup_msipc_x64.msi"
            Name      = "Active Directory Rights Management Services Client 2.0"
            ProductId = "C293A044-3603-4CA3-B8FC-BA3F86F9F169"
            LogPath   = "c:\temp\setup_msipc_x64.log"
            DependsOn = "[Package]MicrosoftIdentityExtensions"
        }

        Package SqlNCli
        {
            Ensure    = "Present"   
            Name      = "Microsoft SQL Server 2012 Native Client "
            #Path      = "C:\Temp\SharepointPreReqs\sqlncli.msi"
            #ProductId = "D411E9C9-CE62-4DBF-9D92-4CB22B750ED5"
            Path      = "C:\Temp\SQL\1033_ENU_LP\x64\Setup\x64\sqlncli.msi"
            ProductId = "49D665A2-4C2A-476E-9AB8-FCC425F526FC"
            LogPath   = "c:\temp\sqlncli.log"
            Arguments = "IACCEPTSQLNCLILICENSETERMS=YES"
        }

        Package Synchronization
        {
            Ensure    = "Present"  
            Path      = "C:\Temp\SharepointPreReqs\Synchronization.msi"
            Name      = "Microsoft Sync Framework Runtime v1.0 SP1 (x64)"
            ProductId = "8438EC02-B8A9-462D-AC72-1B521349C001"
            LogPath   = "c:\temp\Synchronization.log"
            DependsOn = "[Package]SqlNCli"
        }

        Package WcfDataServices5
        {
            Ensure    = "Present"  
            Path      = "C:\Temp\SharePointPreReqs\WCF-5.0\WcfDataServices.exe"
            Name      = "WCF Data Services 5.0 (OData v3)"
            ProductId = "ad60454d-9edf-4100-8342-06830732be63"
            LogPath   = "c:\temp\WcfDataServices.log"
            Arguments = "/quiet"
            DependsOn = "[Package]Synchronization"
        }

        Package WcfDataServices56
        {
            Ensure    = "Present"  
            Path      = "C:\Temp\SharePointPreReqs\WCF-5.6\WcfDataServices.exe"
            Name      = "WCF Data Services 5.6.0 Runtime"
            ProductId = "46910786-E4AC-41E4-A4A0-C086EA85242D"
            LogPath   = "c:\temp\WcfDataServices.log"
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
            Path      = "C:\Temp\SharepointPreReqs\WindowsServerAppFabricSetup_x64.exe"
            Name      = "AppFabric 1.1 for Windows Server"
            ProductId = "96E70525-4CD1-4920-9C0B-91055C79A962"
            #LogPath   = "c:\temp\WindowsServerAppFabricSetup_x64.log" # note: this does not work with an EXE and the Package Resource
            Arguments = "/i cacheclient,cachingService,cacheadmin /gac /l c:\temp\WindowsServerAppFabricSetup_x64.log"
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
                Start-Process -FilePath 'C:\Temp\SharepointPreReqs\AppFabric1.1-RTM-KB2671763-x64-ENU.exe' -ArgumentList '/quiet' -Wait | Write-verbose 
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
            SourcePath = "C:\Temp\SQL"           
            SqlAdministratorCredential = $saCred
            PID = "7TFR8-FMK2W-MWDXP-J224F-JTR8F"
            SysAdminAccounts = 'administrator'
            #DependsOn = "[File]SQLServerIso"
        }

        ## Start the sql Agent service
        Service StartSQLAgent
        {
            Name = "SQLSERVERAGENT"
            StartupType = "Automatic"
            State = "Running"
            DependsOn = "[cSqlServerInstall]InstallSQLServer"

        }   
        #endregion  

        Package InstallSharePointFoundation
        {
            Ensure             = "Present"
            Name               = "Microsoft SharePoint Foundation 2013 Core"
            Path               = "C:\Temp\SharePointFoundation2013\Setup.exe"
            Arguments          = "/config C:\Temp\SharePointFoundation2013\files\setupsilent\config.xml"
            ProductID          = "90150000-1014-0000-1000-0000000FF1CE"
            ReturnCode         = 8
            DependsOn          = "[Script]AppFabricUpdate","[WindowsFeature]ApplicationServer","[WindowsFeature]WebWebServer","[WindowsFeature]NetFramework45Full","[Package]WcfDataServices5","[Package]WcfDataServices56", "[xPendingReboot]BeforeSharePointInstall", "[cSqlServerInstall]InstallSQLServer"
        }
    }
}

SqlAndSharePoint -ConfigurationData $ConfigurationData -OutputPath c:\temp\SqlAndSharePoint

Set-DscLocalConfigurationManager -Path c:\temp\SqlAndSharePoint

Start-DscConfiguration -Verbose -Wait -Path c:\temp\SqlAndSharePoint -Force