
Set-Location $HOME

$SwitchName       = Get-VMSwitch -SwitchType External | Select-Object -expand Name -First 1
$vmName           = "CraigmDev1112-3"
$adminCredential  = New-Object System.Management.Automation.PSCredential $vmName\administrator,(ConvertTo-SecureString 'PA$$w0rd2014' -AsPlainText -Force)
$vhdFilePath      = "S:\Hyper-V\Virtual Hard Disks\$vmName.vhdx"
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

###
### Create the Virtual Disk from the ISO
###
$convertwindowsimageParameters = @{
SourcePath          = (Join-Path $isoFolderPath en_windows_server_2012_r2_x64_dvd_2707946.iso)
UnattendPath        = $UnattendFilePath
Edition             = 'ServerDataCenter'
VHDPath             = $vhdFilePath
VHDPartitionStyle   = 'GPT'
VHDFormat           = 'VHDX'
RemoteDesktopEnable = $true
}
& 'D:\Users\v-crmart\Desktop\VM Automation\convertwindowsimage.codeplex.com\Convert-WindowsImage.ps1' @convertwindowsimageParameters     


### Create the VM
New-VM -Name $vmName -VHDPath $vhdFilePath -SwitchName $SwitchName -MemoryStartupBytes ($StartUpMemoryMB*1MB) -Generation 2 -BootDevice VHD 
Set-VM -Name $vmName -ProcessorCount $ProcessorCount

### Start the VM
Start-VM -Name $vmName          

### Add a DVD Drive
#Add-VMDvdDrive -VMName $vmName

### Add the new VM to the TrustedHosts for this VM Host
set-item WSMan:\localhost\Client\TrustedHosts –value $vmName

### Enable RDP
Invoke-Command -ComputerName $vmName -Credential $adminCredential -ScriptBlock {
    #Allow incoming RDP on firewall
    Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
    #Enable secure RDP authentication
    Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name "UserAuthentication" -Value 1   
}

