
Set-Location $HOME

$SwitchName       = Get-VMSwitch -SwitchType External | Select-Object -expand Name -First 1
$ImageName        = "WindowsServer2012R2-Image"
$ImageVhdFilePath = "S:\Hyper-V\Virtual Hard Disks\$ImageName.vhdx"
$vmName           = "CraigmDev1118-7"
$vhdFilePath      = "S:\Hyper-V\Virtual Hard Disks\$vmName.vhdx"
$adminCredential  = New-Object System.Management.Automation.PSCredential $vmName\administrator,(ConvertTo-SecureString 'PA$$w0rd2014' -AsPlainText -Force)
$isoFolderPath    = "S:\ISO"
$StartUpMemoryMB  = 4096
$ProcessorCount   = 4
$UnattendFilePath = "$HOME\$vmName.xml"

[xml]$UnattendFile = @'
<?xml version='1.0' encoding='utf-8'?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">
  <settings pass="specialize">
    <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
      <ComputerName>{0}</ComputerName>
      <TimeZone>Pacific Standard Time</TimeZone>
    </component>
  </settings>
  <settings pass="oobeSystem">
    <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
      <OOBE>
        <HideEULAPage>true</HideEULAPage>
        <SkipMachineOOBE>true</SkipMachineOOBE>
        <SkipUserOOBE>true</SkipUserOOBE>
        <ProtectYourPC>3</ProtectYourPC>
        <NetworkLocation>Work</NetworkLocation>
      </OOBE>
      <UserAccounts>
        <AdministratorPassword>
          <Value>PA$$w0rd2014</Value>
          <PlainText>true</PlainText>
        </AdministratorPassword>
      </UserAccounts>
    </component>
  </settings>
</unattend>
'@ -F $vmName

$UnattendFile.Save($UnattendFilePath)

Copy -Path $ImageVhdFilePath -Destination $vhdFilePath -Verbose -Force
# del $vhdFilePath
# dir $vhdfilePath

### Mount the VHD
Mount-WindowsImage -ImagePath $vhdFilePath -Index 1 -Path s:\Temp

    ### Copy DSC Configuration into the VM
    Copy -Path S:\Install\Test-FimOneBox -Destination 'S:\Temp\Temp' -Recurse

    ### Copy the Unattend XML
    Copy -Path $UnattendFilePath  -Destination S:\Temp\unattend.xml

    ### Copy the DSC Resources into the VHD
    dir S:\Install\DscResources | copy -Destination 'S:\Temp\Program Files\WindowsPowerShell\Modules' -Recurse -Force

### Close and Save the VHD
Dismount-WindowsImage -Path s:\Temp -Save 

### Create the VM
New-VM -Name $vmName -VHDPath $vhdFilePath -SwitchName $SwitchName -MemoryStartupBytes ($StartUpMemoryMB*1MB) -Generation 2 -BootDevice VHD 
Set-VM -Name $vmName -ProcessorCount $ProcessorCount

### Start the VM
Start-VM -Name $vmName

### Add a DVD Drive
Add-VMDvdDrive -VMName $vmName

### Mount the ISO with the FIM OneBox Files
Set-VMDvdDrive -VMName $vmName -Path S:\ISO\FimOneBoxFiles.iso

### Add the new VM to the TrustedHosts for this VM Host
set-item WSMan:\localhost\Client\TrustedHosts –value $vmName -Force

### Enable RDP
Invoke-Command -ComputerName $vmName -Credential $adminCredential -ScriptBlock {
    #Allow incoming RDP on firewall
    Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
    #Enable secure RDP authentication
    Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name "UserAuthentication" -Value 1   
}


### Install the Certificate and Private Key (DSC requires it)
Invoke-Command -ComputerName $vmName -Credential $adminCredential -ScriptBlock {
    Import-PfxCertificate –FilePath D:\Certificates\craigweb.corp.microsoft.com.pfx -CertStoreLocation Cert:\LocalMachine\My -Password (ConvertTo-SecureString 'J$p1ter' -AsPlainText -Force)
}

### Start DSC
Invoke-Command -ComputerName $vmName -Credential $adminCredential -ScriptBlock {
     C:\Temp\Test-FimOneBox.ps1
}


