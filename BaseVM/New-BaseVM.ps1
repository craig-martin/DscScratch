
Set-Location $HOME

$SwitchName       = Get-VMSwitch -SwitchType External | Select-Object -expand Name -First 1
$ImageName        = "WindowsServer2012R2-Image"
$ImageVhdFilePath = "S:\Hyper-V\Virtual Hard Disks\$ImageName.vhdx"

###
### Create the Virtual Disk from the ISO
###
$convertwindowsimageParameters = @{
SourcePath          = (Join-Path $isoFolderPath en_windows_server_2012_r2_x64_dvd_2707946.iso)
Edition             = 'ServerDataCenter'
VHDPath             = $ImageVhdFilePath
VHDPartitionStyle   = 'GPT'
VHDFormat           = 'VHDX'
RemoteDesktopEnable = $true
}
& 'D:\Users\v-crmart\Desktop\VM Automation\convertwindowsimage.codeplex.com\Convert-WindowsImage.ps1' @convertwindowsimageParameters     

### Path to the Base VHD
$ImageVhdFilePath = 'S:\Hyper-V\Virtual Hard Disks\WindowsServer2012R2-Image.vhdx'

### Add features to the VHD
Add-WindowsFeature -Vhd $ImageVhdFilePath -IncludeAllSubFeature -Source E:\sources\sxs -Verbose -Name @(
    'Web-Server'
    'Web-Mgmt-Tools'
    'Windows-Identity-Foundation'
    'NET-Framework-Features'
    'NET-Framework-45-Features'
    'Application-Server'
)

### Install KB2883200 (DSC requires it) 
Mount-WindowsImage -ImagePath $ImageVhdFilePath -Index 1 -Path s:\Temp
Add-WindowsPackage -Path s:\Temp -PackagePath S:\Install\Windows8.1-KB2883200-x64.msu -Verbose

### Copy the DSC Resources into the VHD
dir S:\Install\DscResources -Recurse | copy -Destination 'S:\Temp\Program Files\WindowsPowerShell\Modules' 
Dismount-WindowsImage -Path s:\Temp -Save 

