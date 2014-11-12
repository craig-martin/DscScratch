$ConfigurationData = @{
    AllNodes = @(
        @{
            NodeName               = (hostname)
            CertificateFile        = "c:\Temp\Certificates\craigweb.corp.microsoft.com.cer"
         }
    )
}

Configuration SqlInstall
{
    
    Import-DscResource -ModuleName cSqlPs

    $saCred                 = New-Object System.Management.Automation.PSCredential sa, (ConvertTo-SecureString 'PA$$w0rd2014' -AsPlainText -Force)

    node $AllNodes.NodeName
    {
        LocalConfigurationManager 
        { 
             CertificateId = "13AA23245848B50C787D56C15595400213BA2E15" 
             RebootNodeIfNeeded = 'true'
             ConfigurationModeFrequencyMins = '15'
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
    }
}

SqlInstall -ConfigurationData $ConfigurationData -OutputPath c:\temp\SqlInstall

Set-DscLocalConfigurationManager -Path c:\temp\SqlInstall

Start-DscConfiguration -Verbose -Wait -Path c:\temp\SqlInstall