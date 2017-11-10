$ConfigurationData = @{
    AllNodes = @(
        @{
            NodeName               = (hostname)
            CertificateFile        = "c:\Temp\Certificates\craigweb.corp.microsoft.com.cer"
         }
    )
}

configuration FimInstall
{

    Import-DscResource -ModuleName cSqlPs
    Import-DsCResource -ModuleName xPendingReboot
    Import-DsCResource -ModuleName xComputerManagement
    Import-DscResource -ModuleName xPSDesiredStateConfiguration

    $saCred                 = New-Object System.Management.Automation.PSCredential sa,                   (ConvertTo-SecureString 'PA$$w0rd2014' -AsPlainText -Force)
    $localAdminCred         = New-Object System.Management.Automation.PSCredential administrator,        (ConvertTo-SecureString 'PA$$w0rd2014' -AsPlainText -Force)
    $fimMaCred              = New-Object System.Management.Automation.PSCredential "$(hostname)\fimma",  (ConvertTo-SecureString 'PA$$w0rd2014' -AsPlainText -Force)
    $fimSvcCred             = New-Object System.Management.Automation.PSCredential "$(hostname)\fimsvc", (ConvertTo-SecureString 'PA$$w0rd2014' -AsPlainText -Force)
    $domainCredential       = New-Object System.Management.Automation.PSCredential MyDomain\myFimServiceAccount,       (ConvertTo-SecureString 'PA$$w0rd2014' -AsPlainText -Force)

    node $AllNodes.NodeName
    {
        LocalConfigurationManager 
        { 
             CertificateId = "13AA23245848B50C787D56C15595400213BA2E15" 
             RebootNodeIfNeeded = 'true'
             ConfigurationModeFrequencyMins = '15'
        } 

        <#
        xPackage InstallFimSync
        {
            Ensure             = "Present"
            Name               = "Forefront Identity Manager Synchronization Service"
            Path               = "c:\temp\fim\synchronization Service\synchronization Service.msi"
            RunAsCredential    = $credential
            ProductId          = '51F4677B-5C3F-49AA-87F8-2B58ABA98301'
            Arguments          = "ACCEPT_EULA=1 serviceaccount=anbecvar servicepassword=$( [System.Runtime.InteropServices.marshal]::PtrToStringAuto([System.Runtime.InteropServices.marshal]::SecureStringToBSTR($credential.password))) servicedomain=$($Node.domain) storeserver=$($Node.NodeName) reboot=reallysuppress groupadmins=FIMSyncAdmins GROUPOPERATORS=FIMSyncOperators GROUPACCOUNTJOINERS=FIMSyncJoiners GROUPBROWSE=FIMSyncBrowse GROUPPASSWORDSET=FIMSyncPasswordSet"
            LogPath            = "c:\temp\fimsync-install.log"
            DependsOn          = "[Service]StartSQLAgent"

        }
        #>

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

        xPackage FimService
        {
            Ensure             = "Present"
            Name               = "Forefront Identity Manager Service and Portal"
            Path               = "c:\temp\fim\Service and Portal\service and portal.msi"
            RunAsCredential    = $localAdminCred
            Arguments          = "ADDLOCAL=CommonServices,WebPortals ACCEPT_EULA=1 SQLSERVER_SERVER=localhost SERVICE_ACCOUNT_NAME=$($fimSvcCred.UserName) SERVICE_ACCOUNT_PASSWORD=$($fimSvcCred.GetNetworkCredential().Password) SERVICE_ACCOUNT_DOMAIN=$($fimSvcCred.GetNetworkCredential().Domain) SERVICE_ACCOUNT_EMAIL=foo@bar.baz SYNCHRONIZATION_SERVER=$(hostname) SYNCHRONIZATION_SERVER_ACCOUNT=$($fimMaCred.UserName) MAIL_SERVER=localhost MAIL_SERVER_USE_SSL=0 MAIL_SERVER_IS_EXCHANGE=0 SERVICEADDRESS=$(hostname) SHAREPOINT_URL=http://localhost"
            LogPath            = "c:\temp\fimservice.log"
            ProductID          = "8EB24D93-91BA-435D-BF88-9339C1C46362"
            DependsOn          = "[xPendingReboot]BeforeFimInstall","[Service]SQLAgentService","[Service]SPAdminV4Service","[User]FimMA"         
        }

    }
}

FimInstall -ConfigurationData $ConfigurationData -OutputPath c:\temp\FimInstall

Set-DscLocalConfigurationManager -Path c:\temp\FimInstall
Get-DscLocalConfigurationManager
Start-DscConfiguration -Verbose -Wait -Path c:\temp\FimInstall -force
