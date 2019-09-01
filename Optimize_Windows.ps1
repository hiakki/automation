#!/bin/bash
# Author - Akshay Gupta
# Version - 1.0.0
# Description - Optimize your windows for best performance experience in just 1 click.
<# 

Usage - 
1. Open Windows PowerShell
2. Run the following command so that you can run scripts on your PowerShell
	
	Set-ExecutionPolicy Bypass -Force

3. Navigate to this ps1 file's location
4. Run the ps1 file with/without parameters, as shown in example

	Optimize_Windows.ps1
	Optimize_Windows.ps1 1
	Optimize_Windows.ps1 2
	Optimize_Windows.ps1 3

#>

param (
[Parameter(mandatory = $false)]
[ValidateSet('1','2','3')]
[string]$choice = "default"
)

# Self-elevate the script if required
if (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {

	if ([int](Get-CimInstance -Class Win32_OperatingSystem | Select-Object -ExpandProperty BuildNumber) -ge 6000) {
  		
		$CommandLine = "-File `"" + $MyInvocation.MyCommand.Path + "`" " + $choice
		Start-Process -FilePath PowerShell.exe -Verb Runas -ArgumentList $CommandLine
		Exit

	}

}

$ErrorActionPreference = 'silentlycontinue'

function updating_powershell {

	# Upgrading Chocolatey (Warnings cannot be suppressed - https://github.com/chocolatey/choco/issues/362)
	try { choco upgrade chocolatey -y }

	catch { iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1')) }

	choco feature enable -n=allowGlobalConfirmation

	# Upgrading PowerShell to 5.1
	if ( (((Get-ItemProperty "HKLM:\Software\Microsoft\PowerShell\3\PowerShellEngine\").PowerShellVersion) -lt 5.1) -or !(dir "HKLM:\Software\Microsoft\PowerShell\3\PowerShellEngine\") ) {

		if ( (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full').Version -lt '4.5.2' ) {
			choco install dotnet4.5 -y
		}	

	}

	if ((Get-Service wuauserv).Status -ne "Running") {
		echo y | REG ADD HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\wuauserv /v Start /t REG_DWORD /d 2
		sc.exe config wuauserv start= auto
		Start-Service wuauserv
		
		choco install powershell -y
		
		Stop-Service wuauserv
		sc.exe config wuauserv start= disabled
		echo y | REG ADD HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\wuauserv /v Start /t REG_DWORD /d 4
	}

	else {
		choco install powershell -y
	}

}

function disabling_services {

	# Stop services related to Windows Update, Google Update and Theme regarding services through CMD
	Stop-Service BITS
	Stop-Service DoSvc
	Stop-Service gupdate
	Stop-Service gupdatem
	Stop-Service UsoSvc
	Stop-Service wuauserv
	sc.exe config BITS start= disabled
	sc.exe config DoSvc start= disabled
	sc.exe config gupdate start= disabled
	sc.exe config gupdatem start= disabled
	sc.exe config UsoSvc start= disabled
	sc.exe config wuauserv start= disabled
	# Stop services related to Windows Update, Google Update and Theme regarding services through Registry Keys
	echo y | REG ADD HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\BITS /v Start /t REG_DWORD /d 4
	echo y | REG ADD HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\DoSvc /v Start /t REG_DWORD /d 4
	echo y | REG ADD HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\gupdate /v Start /t REG_DWORD /d 4
	echo y | REG ADD HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\gupdatem /v Start /t REG_DWORD /d 4
	echo y | REG ADD HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\UsoSvc /v Start /t REG_DWORD /d 4
	echo y | REG ADD HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\wuauserv /v Start /t REG_DWORD /d 4
	# Adjust for Best Performance
	echo y | REG ADD "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v VisualFXSetting /t REG_DWORD /d 2
	# Disabling One Drive
	echo y | REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\Onedrive"  /v DisableLibrariesDefaultSaveToOneDrive /t REG_DWORD /d 1
	echo y | REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\Onedrive"  /v DisableFileSync /t REG_DWORD /d 1
	echo y | REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\Onedrive"  /v DisableMeteredNetworkFileSync /t REG_DWORD /d 1
	# Disabling Antimalware
	echo y | REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows Defender" /v AllowFastServiceStartup /t REG_DWORD /d 0
	echo y | REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows Defender" /v DisableRoutinelyTakingAction /t REG_DWORD /d 1
	echo y | REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows Defender" /v ServiceKeepAlive /t REG_DWORD /d 0
	echo y | REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection"  /v DisableRealtimeMonitoring /t REG_DWORD /d 1
	if ( !( (Get-WmiObject win32_OperatingSystem).Caption -Like "*2008*" -or (Get-WmiObject win32_OperatingSystem).Caption -Like "*Windows 7*" ) ) {

		# Disabling Cortana
		echo y | REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\Windows Search"  /v AllowCortana /t REG_DWORD /d 0

		# Disable Store
		echo y | REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\WindowsStore" /v AutoDownload /t REG_DWORD /d 2
		echo y | REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\WindowsStore" /v DisableOSUpgrade /t REG_DWORD /d 1
		echo y | REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\WindowsStore" /v DisableStoreApps /t REG_DWORD /d 0
		echo y | REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\WindowsStore" /v RemoveWindowsStore /t REG_DWORD /d 1
		echo y | REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\WindowsStore" /v RequirePrivateStoreOnly /t REG_DWORD /d 1
	}
	# Disabling google updates
	Get-Process google* | Stop-Process -Force
	Rename-Item 'C:\Program Files (x86)\Google\Update' 'C:\Program Files (x86)\Google\D-Update'

}

function disk_optimization {

	# Delete Built in Apps and Windows Update Assistant
	if ( (Get-WmiObject win32_OperatingSystem).Caption -Like "*2016*" -or (Get-WmiObject win32_OperatingSystem).Caption -Like "*Windows 10*" -or (Get-WmiObject win32_OperatingSystem).Caption -Like "*Windows 8*" ) {

		Get-AppxPackage | Remove-AppxPackage
		if ( Test-Path "$env:SystemRoot\SysWOW64\OneDriveSetup.exe" ) {
			& "$env:SystemRoot\SysWOW64\OneDriveSetup.exe" /uninstall
		}
		if ( Test-Path C:\Windows10Upgrade\Windows10UpgraderApp.exe ) {
			& "C:\Windows10Upgrade\Windows10UpgraderApp.exe" /ForceUninstall 
		}
		Remove-Item C:\Windows\UpdateAssistant\* -Recurse -Confirm:$False -Force
	}

	# Clear Recycle Bin
	$Shell = New-Object -ComObject Shell.Application
	$RecBin = $Shell.Namespace(0xA)
	$RecBin.Items() | %{Remove-Item $_.Path -Recurse -Confirm:$false -Force}


	# Defragment Tool
	defrag C: /H /X /U /V


	# Disk Cleanup
	Remove-Item $env:TEMP\* -Recurse -Confirm:$False -Force
	Remove-Item C:\Windows.old -Recurse -Confirm:$False -Force
	Remove-Item "C:\Windows\Downloaded Program Files\*" -Recurse -Confirm:$False -Force
	Remove-Item C:\Windows\Temp\* -Recurse -Confirm:$False -Force
}

if ($choice -eq $null) {
	$msg = @"

	1. Updated Powershell
	2. Disable Services
	3. Disk Optiimization
	
	"@

	Write-Host $msg -ForegroundColor Yellow
	Write-Host 'Default: All 3 of them will run' -ForegroundColor Red
	Write-Host 'Enter your choice:' -ForegroundColor Green
	$choice = Read-Host
}

switch ($choice) {

	1 {
		updating_powershell
	}
	
	2 {
		disabling_services
	}
	
	3 {
		disk_optimization
	}
	
	default {
		updating_powershell
		disabling_services
		disk_optimization
	}

}
