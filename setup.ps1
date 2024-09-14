#############################################################################################
$tit = 'PowerShell-Profile-Server Pimp v1.7 setup.ps1-script by RUNE GOKS0R'         	    #
$githubUser = 'rungok'									    #
$PoshTheme = 'markbull'  # Write Get-PoshThemes to see all themes in action                 #
#  This setup.ps1 will try to install Microsoft Windows Terminal with required compnents    #
#  in additions to Oh-My-Posh and other enhancments so even some Linux-commands will work   #
#  And then it will insert a loginscript into where it should be placed, which is the path  #
#  of $PROFILE. Write $PROFILE in Powershell if you wonder where it is. Usually in your     #
#  $HOME\Documents\PowerShell\Microsoft.PowerShell_profile.ps1                              #
#  Recommended requirement: Windows Terminal					 	    #
#		https://github.com/microsoft/terminal/releases)   			    #
#############################################################################################

Write-Host("`n         .--------< ") -f white -nonewline
Write-Host($tit) -f Cyan -nonewline
Write-Host(" >---------------------.") -f white
Write-Host("         '----------------------------------------------------------------------------------------------------'`n") -f white

# Ensure the script can run with elevated privileges
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "Please run this script as an Administrator!"
    break
}

# Function to test internet connectivity
function Test-InternetConnection {
    try {
        $testConnection = Test-Connection -ComputerName www.google.com -Count 1 -ErrorAction Stop
        return $true
    }
    catch {
        Write-Warning "Internet connection is required but not available. Please check your connection."
        return $false
    }
}

# Check for internet connectivity before proceeding
if (-not (Test-InternetConnection)) {
    break
}

# Set Executionpolicy for this script so we can install stuff
$execPolicy = Get-ExecutionPolicy
if ($execPolicy -ne "RemoteSigned") {
        Set-ExecutionPolicy -Scope Process -ExecutionPolicy RemoteSigned -Force
}

# Profile creation or update
if (!(Test-Path -Path $PROFILE -PathType Leaf)) {
    try {
        # Detect Version of PowerShell & Create Profile directories if they do not exist.
        $profilePath = ""
        if ($PSVersionTable.PSEdition -eq "Core") {
            $profilePath = "$env:userprofile\Documents\Powershell"
        }
        elseif ($PSVersionTable.PSEdition -eq "Desktop") {
            $profilePath = "$env:userprofile\Documents\WindowsPowerShell"
        }

        if (!(Test-Path -Path $profilePath)) {
            New-Item -Path $profilePath -ItemType "directory"
        }

        Invoke-RestMethod https://github.com/$githubUser/powershell-profile-server/raw/main/Microsoft.PowerShell_profile.ps1 -OutFile $PROFILE
        Write-Host "The profile @ [$PROFILE] has been created and will be executed on every Terminal/Powershell-window launch."
        Write-Host "If you want to make any personal changes or customizations, please do so at [$profilePath\Profile.ps1]"
	Write-Host "else your subsequent installs of this script can overwrite your custom changes if you are in a Onedrive-enabled domain."
    }
    catch {
        Write-Error "Failed to create or update the profile. Error: $_"
    }
}
else {
    try {
        Get-Item -Path $PROFILE | Move-Item -Destination "Microsoft.PowerShell_profile_old.ps1" -Force
        Invoke-RestMethod https://github.com/$githubUser/powershell-profile-server/raw/main/Microsoft.PowerShell_profile.ps1 -OutFile $PROFILE
        Write-Host "The profile @ [$PROFILE] has been created and old profile removed."
        Write-Host "Please back up any persistent components of your old profile to [$HOME\Documents\PowerShell\Profile.ps1] as there is an updater in the installed profile which uses the hash to update the profile and will lead to loss of changes"
    }
    catch {
        Write-Error "Failed to backup and update the profile. Error: $_"
    }
}

# Install NuGet to ensure the other packages can be installed.
$nugetProvider = Get-PackageProvider | Select-Object Name | Where-Object Name -match NuGet
if (-not $nugetProvider) {
    Write-Host "NuGet provider not found. Installing..."
    Install-PackageProvider -Name NuGet -Force -Scope CurrentUser
    Import-PackageProvider -Name NuGet -Force
    Write-Host "NuGet provider installed."
} else {
    Write-Host "NuGet provider already installed." -ForegroundColor DarkGreen
}
# Trust the PSGallery repository.
Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted

# Choco install
try {
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
}
catch {
    Write-Error "Failed to install Chocolatey. Error: $_"
}

# Microsoft Windows Terminal Install
try {
    choco install microsoft-windows-terminal -y
}
catch {
    Write-Error "Failed to install Microsoft Windows Terminal. Error: $_"
}

# Terminal Icons Install
try {
    Install-Module -Name Terminal-Icons -Repository PSGallery -Force
}
catch {
    Write-Error "Failed to install Terminal Icons module. Error: $_"
}

# zoxide Install
try {
    choco install zoxide -y
    Invoke-Expression (& { (zoxide init powershell | Out-String) })
    Write-Host "✅ Zoxide installed successfully. Initializing..." -ForegroundColor DarkGreen
}
catch {
    Write-Error "Failed to install zoxide. Error: $_"
}

# Install opensource Powershell
function Update-PowerShell {
	if (-not (Get-Command pwsh -ErrorAction SilentlyContinue)) {
		Write-Host "PowerShell Core (pwsh v7.x) is not installed. Starting the install..." -ForegroundColor Yellow
		[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12;iex "& { $(irm https://aka.ms/install-powershell.ps1) } -UseMSI -Quiet"
		Start-Sleep -Seconds 8 # Wait for the update to finish
		Write-Host "Restarting the installation script with Powershell Core" -ForegroundColor DarkGreen
		Start-Process pwsh -ArgumentList "-NoExit", "-Command Invoke-Expression (Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/$githubUser/powershell-profile-server/main/setup.ps1'-UseBasicParsing).Content"
		exit
		} else { 
  		Write-Host "✅ PowerShell Core (pwsh) detected. Respawning in Terminal." -ForegroundColor DarkGreen
    		Start-Process wt -ArgumentList "-NoExit"
      		exit
    		}
}
Update-PowerShell
