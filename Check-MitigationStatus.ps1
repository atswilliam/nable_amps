$url = "https://gallery.technet.microsoft.com/scriptcenter/Speculation-Control-e36f0050/file/185258/1/SpeculationControl.zip"


$temp = $env:temp
Push-Location $temp

function Check-Mitigation {
	$spec = Get-SpeculationControlSettings
	
	$BTIHardwarePresent = $spec.BTIHardwarePresent
	$BTIWindowsSupportPresent = $spec.BTIWindowsSupportPresent
	
	$BTIWindowsSupportEnabled = $spec.BTIWindowsSupportEnabled
	$BTIDisabledBySystemPolicy = $spec.BTIDisabledBySystemPolicy
	$BTIDisabledByNoHardwareSupport = $spec.BTIDisabledByNoHardwareSupport
	
	$KVAShadowRequired = $spec.KVAShadowRequired
	$KVAShadowWindowsSupportPresent = $spec.KVAShadowWindowsSupportPresent
	$KVAWShadowWindowsSupportEnabled = $spec.KVAWShadowWindowsSupportEnabled
	
	$script:xBIOSUpdateInstalled = 5
	$script:xUpdateInstalled = 5
	$script:xServerRegRequired = 0
	
	
	if ($btiHardwarePresent -eq $false) {
		$script:xBIOSUpdateInstalled = 0
		Write-Host "BIOS Update Required"
	}
	if ($btiHardwarePresent -eq $true) {
        $script:xBIOSUpdateInstalled = 1
        Write-Host "BIOS Update Installed"
     }
	
	if ($btiWindowsSupportPresent -eq $false -or $KVAShadowWindowsSupportPresent -eq $false) {
		$script:xUpdateInstalled = 0
	}
	
	if (($btiHardwarePresent -eq $true -and $btiWindowsSupportEnabled -eq $false) -or ($kvaShadowRequired -eq $true -and $KVAWShadowWindowsSupportEnabled -eq $false)) {
		$script:xUpdateInstalled = 1
		
		$os = Get-WmiObject Win32_OperatingSystem
		
		if ($os.ProductType -eq 1) {
			# Workstation
		}
		else {
			# Server
			$script:xServerRegRequired = 1
		}		
	}
	
	if ($btiWindowsSupportPresent -eq $true -and $KVAShadowWindowsSupportPresent -eq $true) {
		$script:xUpdateInstalled = 1
		Write-Host "Windows Update Installed"
	}
	
	$spec
}


# Check if SpeculationControl PSModule is installed...
$specmodule = Get-Module SpeculationControl
if ($specmodule) {
	# Run check function
	Check-Mitigation
}
else {
	Write-Output "SpeculationControl module not installed... trying to install."	
	# Download and install module
	try {
		# Save ExecutionPolicy to revert any changes
		$savedExecutionPolicy = Get-ExecutionPolicy
		Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
		
		# Download and Install SpeculationControl Module
		(New-Object System.Net.WebClient).DownloadFile($url, "C:\ats\SpeculationControl.zip")
		Expand-Archive SpeculationControl.zip .\ -Force
		Import-Module C:\ats\SpeculationControl\SpeculationControl.psd1
	
		# Reset Excution policy back to original state
		Set-ExecutionPolicy $savedExecutionPolicy -Scope CurrentUser
		
		# Now try to run again
		Check-Mitigation
	}
	catch {
		$xResult = "2"
		$xResultText = "Download or install failed"
	}
}