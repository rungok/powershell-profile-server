#############################################################################################
$tit = 'PowerShell-Profile-Server Pimp v1.7 by RUNE GOKS0R'	 		  	    #
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
Write-Host("         '-----------------------------------------------------------------------------------'`n") -f white

$execPolicy = Get-ExecutionPolicy
if ($execPolicy -ne "RemoteSigned") {
        Set-ExecutionPolicy -Scope Process -ExecutionPolicy RemoteSigned -Force
}

#opt-out of telemetry before doing anything, only if PowerShell is run as admin
if ([bool]([System.Security.Principal.WindowsIdentity]::GetCurrent()).IsSystem) {
    [System.Environment]::SetEnvironmentVariable('POWERSHELL_TELEMETRY_OPTOUT', 'true', [System.EnvironmentVariableTarget]::Machine)
}

# Initial GitHub.com connectivity check with 1 second timeout
$canConnectToGitHub = Test-Connection github.com -Count 1 -Quiet

################################################################################
####### Test all components status and install if they are not present #########
################################################################################

# Install NuGet to ensure the other packages can be installed.
$nugetProvider = Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue
if (-not $nugetProvider) {
    Write-Host "NuGet provider not found. Installing..."
    Install-PackageProvider -Name NuGet -Force -Scope CurrentUser
    Import-PackageProvider -Name NuGet -Force
    Write-Host "NuGet provider installed."
} else {
    Write-Host "✅ NuGet provider detected." -ForegroundColor DarkGreen
}
# Trust the PSGallery repository.
Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted

# Install opensource Powershell
function Update-PowerShell {
	if (-not (Get-Command pwsh -ErrorAction SilentlyContinue)) {
		Write-Host "PowerShell Core (pwsh) is not installed. Starting the update..." -ForegroundColor Yellow
		Run-UpdatePowershell
		Start-Sleep -Seconds 8 # Wait for the update to finish
		Write-Host "Restarting the installation script with Powershell Core" -ForegroundColor DarkGreen
		Start-Process pwsh -ArgumentList "-NoExit", "-Command Invoke-Expression (Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/$githubUser/powershell-profile-server/main/Microsoft.PowerShell_profile.ps1'-UseBasicParsing).Content ; Install-Config"
		exit
		} else { Write-Host "✅ PowerShell Core (pwsh) detected." -ForegroundColor DarkGreen }
}
Update-PowerShell



### Install NerdFont (font with CLI icons for a bunch of stuff)
If (-not(Test-Path "$($env:LOCALAPPDATA)\Microsoft\Windows\Fonts\RobotoMonoNerdFontMono-Regular.ttf")) {
	Write-Host ("Does not exist. Trying to install...") -nonewline -f red
    & ([scriptblock]::Create((iwr 'https://to.loredo.me/Install-NerdFont.ps1'))) -Confirm:$false -Name roboto-mono
	Write-Host ("installed!") -f green	
	Write-Host ("There is no command that can change the font for you in Powershell. Change to RobotoMono in Terminal settings.") -f green
	} Else { Write-Host "✅ RobotoMono Nerd Font detected." -f DarkGreen }


# Import Modules and External Profiles
# Ensure Terminal-Icons module is installed before importing
if (-not (Get-Module -ListAvailable -Name Terminal-Icons)) {
    Install-Module -Name Terminal-Icons -Scope CurrentUser -Force -SkipPublisherCheck
}
Import-Module -Name Terminal-Icons


function Test-CreateProfile {
    # Create $PATH folder if not exists.
    if (-not (Test-Path -Path (Split-Path -Path $PROFILE -Parent))) {
        New-Item -ItemType Directory -Path (Split-Path -Path $PROFILE -Parent) -Force | Out-Null
    }
    # Create profile if not exists
    if (-not (Test-Path -Path $PROFILE)) {
        New-Item -ItemType File -Path $PROFILE | Out-Null
        Add-Content -Path $PROFILE -Value "if (Test-Path (Join-Path -Path `$env:USERPROFILE -ChildPath `"powershell-profile-server\Microsoft.PowerShell_profile.ps1`")) { . (Join-Path -Path `$env:USERPROFILE -ChildPath `"powershell-profile-server\Microsoft.PowerShell_profile.ps1`")
	} else {
		iex (iwr `"https://raw.githubusercontent.com/$githubUser/powershell-profile-server/main/Microsoft.PowerShell_profile.ps1`").Content }"
        Write-Host "PowerShell profile created at $PROFILE." -ForegroundColor Yellow
    }
}

# Check for Profile Updates
function Update-Profile {
    if (-not $global:canConnectToGitHub) {
        Write-Host "Skipping profile update check due to GitHub.com not responding within 1 second." -ForegroundColor Yellow
        return
    }

    try {
        $url = "https://raw.githubusercontent.com/$githubUser/powershell-profile-server/main/Microsoft.PowerShell_profile.ps1"
        $oldhash = Get-FileHash $PROFILE
        Invoke-RestMethod $url -OutFile "$env:temp/Microsoft.PowerShell_profile.ps1"
        $newhash = Get-FileHash "$env:temp/Microsoft.PowerShell_profile.ps1"
        if ($newhash.Hash -ne $oldhash.Hash) {
            Copy-Item -Path "$env:temp/Microsoft.PowerShell_profile.ps1" -Destination $PROFILE -Force
            Write-Host "Profile has been updated. Please restart your shell to reflect changes" -ForegroundColor Magenta
        }
    } catch {
        Write-Error "Unable to check for `$profile updates"
    } finally {
        Remove-Item "$env:temp/Microsoft.PowerShell_profile.ps1" -ErrorAction SilentlyContinue
    }
}

######################################################################
##### Setting aliases spesific to PowerShell-Profile-Server Pimp #####
######################################################################
New-Alias Notepad "$env:Programfiles\Notepad++\Notepad++.exe"
New-Alias np "$env:Programfiles\Notepad++\Notepad++.exe"
New-Alias vi "$env:Programfiles\Notepad++\Notepad++.exe"
function hf {Get-Content (Get-PSReadlineOption).HistorySavePath}
New-Alias Get-FullHistory hf
function Path { $env:Path }
function PathX { $env:Path -split ';' }

##### Aliases and functions spesific to forked powershell-profile ##### 
# Admin Check and Prompt Customization
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
function prompt {
    if ($isAdmin) { "[" + (Get-Location) + "] # " } else { "[" + (Get-Location) + "] $ " }
}
$adminSuffix = if ($isAdmin) { " [ADMIN]" } else { "" }
$Host.UI.RawUI.WindowTitle = "PowerShell {0}$adminSuffix" -f $PSVersionTable.PSVersion.ToString()

# Utility Functions
function Test-CommandExists {
    param($command)
    $exists = $null -ne (Get-Command $command -ErrorAction SilentlyContinue)
    return $exists
}

# Editor Configuration
$EDITOR = if (Test-CommandExists nvim) { 'nvim' }
          elseif (Test-CommandExists pvim) { 'pvim' }
          elseif (Test-CommandExists vim) { 'vim' }
          elseif (Test-CommandExists vi) { 'vi' }
          elseif (Test-CommandExists code) { 'code' }
          elseif (Test-CommandExists notepad++) { 'notepad++' }
          elseif (Test-CommandExists sublime_text) { 'sublime_text' }
          else { 'notepad' }
Set-Alias -Name vim -Value $EDITOR

function Edit-Profile {
    vim $PROFILE.CurrentUserAllHosts
}
function touch($file) { "" | Out-File $file -Encoding ASCII }
function ff($name) {
    Get-ChildItem -recurse -filter "*${name}*" -ErrorAction SilentlyContinue | ForEach-Object {
        Write-Output "$($_.FullName)"
    }
}

# Network Utilities
function Get-PubIP { (Invoke-WebRequest http://ifconfig.me/ip).Content }

# Open WinUtil
function winutil {
	iwr -useb https://christitus.com/win | iex
}

# System Utilities
function admin {
    if ($args.Count -gt 0) {
        $argList = "& '$args'"
        Start-Process wt -Verb runAs -ArgumentList "pwsh.exe -NoExit -Command $argList"
    } else {
        Start-Process wt -Verb runAs
    }
}

# Set UNIX-like aliases for the admin command, so sudo <command> will run the command with elevated rights.
Set-Alias -Name su -Value admin

function uptime {
    if ($PSVersionTable.PSVersion.Major -eq 5) {
        Get-WmiObject win32_operatingsystem | Select-Object @{Name='LastBootUpTime'; Expression={$_.ConverttoDateTime($_.lastbootuptime)}} | Format-Table -HideTableHeaders
    } else {
        net statistics workstation | Select-String "since" | ForEach-Object { $_.ToString().Replace('Statistics since ', '') }
    }
}

function reload-profile {
    & $profile
}

function unzip ($file) {
    Write-Output("Extracting", $file, "to", $pwd)
    $fullFile = Get-ChildItem -Path $pwd -Filter $file | ForEach-Object { $_.FullName }
    Expand-Archive -Path $fullFile -DestinationPath $pwd
}
function hb {
    if ($args.Length -eq 0) {
        Write-Error "No file path specified."
        return
    }
    
    $FilePath = $args[0]
    
    if (Test-Path $FilePath) {
        $Content = Get-Content $FilePath -Raw
    } else {
        Write-Error "File path does not exist."
        return
    }
    
    $uri = "http://bin.christitus.com/documents"
    try {
        $response = Invoke-RestMethod -Uri $uri -Method Post -Body $Content -ErrorAction Stop
        $hasteKey = $response.key
        $url = "http://bin.christitus.com/$hasteKey"
        Write-Output $url
    } catch {
        Write-Error "Failed to upload the document. Error: $_"
    }
}

function grep($regex, $dir) {
    if ( $dir ) {
        Get-ChildItem $dir | select-string $regex
        return
    }
    $input | select-string $regex
}

function df {
    get-volume
}

function sed($file, $find, $replace) {
    (Get-Content $file).replace("$find", $replace) | Set-Content $file
}

function which($name) {
    Get-Command $name | Select-Object -ExpandProperty Definition
}

function export($name, $value) {
    set-item -force -path "env:$name" -value $value;
}

function pkill($name) {
    Get-Process $name -ErrorAction SilentlyContinue | Stop-Process
}

function pgrep($name) {
    Get-Process $name
}

function head {
  param($Path, $n = 10)
  Get-Content $Path -Head $n
}

function tail {
  param($Path, $n = 10, [switch]$f = $false)
  Get-Content $Path -Tail $n -Wait:$f
}

# Quick File Creation
function nf { param($name) New-Item -ItemType "file" -Path . -Name $name }

# Directory Management
function mkcd { param($dir) mkdir $dir -Force; Set-Location $dir }

### Quality of Life Aliases

# Navigation Shortcuts
function docs { Set-Location -Path $HOME\Documents }

function dtop { Set-Location -Path $HOME\Desktop }

# Quick Access to Editing the Profile
function ep { vim $PROFILE }

# Simplified Process Management
function k9 { Stop-Process -Name $args[0] }

# Enhanced Listing
function la { Get-ChildItem -Path . -Force | Format-Table -AutoSize }
function ll { Get-ChildItem -Path . -Force -Hidden | Format-Table -AutoSize }

# Git Shortcuts
function gs { git status }

function ga { git add . }

function gc { param($m) git commit -m "$m" }

function gp { git push }

function g { __zoxide_z github }

function gcl { git clone "$args" }

function gcom {
    git add .
    git commit -m "$args"
}
function lazyg {
    git add .
    git commit -m "$args"
    git push
}

# Quick Access to System Information
function sysinfo { Get-ComputerInfo }

# Networking Utilities
function flushdns {
	Clear-DnsClientCache
	Write-Host "DNS has been flushed"
}

# Clipboard Utilities
function cpy { Set-Clipboard $args[0] }

function pst { Get-Clipboard }

# Enhanced PowerShell Experience
Set-PSReadLineOption -Colors @{
    Command = 'Yellow'
    Parameter = 'Green'
    String = 'DarkCyan'
}

$PSROptions = @{
    ContinuationPrompt = '  '
    Colors             = @{
    Parameter          = $PSStyle.Foreground.Magenta
    Selection          = $PSStyle.Background.Black
    InLinePrediction   = $PSStyle.Foreground.BrightYellow + $PSStyle.Background.BrightBlack
    }
}
Set-PSReadLineOption @PSROptions
Set-PSReadLineKeyHandler -Chord 'Ctrl+f' -Function ForwardWord
Set-PSReadLineKeyHandler -Chord 'Enter' -Function ValidateAndAcceptLine

$scriptblock = {
    param($wordToComplete, $commandAst, $cursorPosition)
    dotnet complete --position $cursorPosition $commandAst.ToString() |
        ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
        }
}
Register-ArgumentCompleter -Native -CommandName dotnet -ScriptBlock $scriptblock


# Get theme from profile.ps1 or use a default theme
function Get-Theme {
    if (Test-Path -Path $PROFILE.CurrentUserAllHosts -PathType leaf) {
        $existingTheme = Select-String -Raw -Path $PROFILE.CurrentUserAllHosts -Pattern "oh-my-posh init pwsh --config"
        if ($null -ne $existingTheme) {
            Invoke-Expression $existingTheme
            return
        }
    } else {
        oh-my-posh init pwsh --config https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/$PoshTheme.omp.json | Invoke-Expression
    }
}
## Final Line to set prompt
Get-Theme

### Install Chocolatey if not installed and shell is started in administrative mode ####
if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
	Write-Host ("❌ Chocolatey packet manager not installed...") -nonewline -f red
	if ($isAdmin) {
		Write-Host ("Trying to install...") -nonewline -f DarkGreen
		Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
		} else { Write-Host ("❌ Terminal must be started in elevated mode to install Chocolatey. Zoxide fuzzy shell will not be activated until this is done.") -f red }
	} else {
		Write-Host "✅ Chocolatey packet manager detected." -f DarkGreen
		$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
		if (Test-Path($ChocolateyProfile)) {
			Import-Module "$ChocolateyProfile"
		}
}

### Install zoxide fuzzy shell if not installed and shell is started in administrative mode ####
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
	Write-Host "✅ Zoxide detected." -ForegroundColor DarkGreen
	Invoke-Expression (& { (zoxide init --cmd cd powershell | Out-String) })
	Set-Alias -Name z -Value __zoxide_z -Option AllScope -Scope Global -Force
	Set-Alias -Name zi -Value __zoxide_zi -Option AllScope -Scope Global -Force
} else {
	if ($isAdmin) {
		Write-Host "❌ Zoxide command not found. Attempting to install via Chocolatey..." -nonewline -f red
		try {
			choco install zoxide -y
			Invoke-Expression (& { (zoxide init powershell | Out-String) })
			Write-Host "✅ Zoxide installed successfully. Initializing..." -ForegroundColor DarkGreen
		} catch {
			Write-Error "❌ Failed to install zoxide. Error: $_"
		}
	} else { Write-Host ("❌ Terminal must be started in elevated mode to install Zoxide. Fuzzy shell will not be activated until this is done.") -f red }
}

# Help Function
function Show-Help {
    @"
Help for $tit
.======================================================================.
| Path - Prints out current users Path like MS-DOS.                    |
| PathX - Prints out current users Path like MS-DOS in listed format.  |
| np - Notepad++ full qualified path, so use np <file.txt> to edit.    |
| vi - same as np                                                      |
| hf - Full commandline history (also Get-FullHistory works)           |
'----------------------------------------------------------------------'

---------------------- original commands from forked "powershell-profile" ---------------------------------------------
Update-Profile - Checks for profile updates from a remote repository and updates if necessary.
Update-PowerShell - Checks for the latest PowerShell release and updates if a new version is available.
Edit-Profile - Opens the current user's profile for editing using the configured editor.
touch <file> - Creates a new empty file.
ff <name> - Finds files recursively with the specified name.
Get-PubIP - Retrieves the public IP address of the machine.
winutil - Runs the WinUtil script from Chris Titus Tech.
uptime - Displays the system uptime.
reload-profile - Reloads the current user's PowerShell profile.
unzip <file> - Extracts a zip file to the current directory.
hb <file> - Uploads the specified file's content to a hastebin-like service and returns the URL.
grep <regex> [dir] - Searches for a regex pattern in files within the specified directory or from the pipeline input.
df - Displays information about volumes.
sed <file> <find> <replace> - Replaces text in a file.
which <name> - Shows the path of the command.
export <name> <value> - Sets an environment variable.
pkill <name> - Kills processes by name.
pgrep <name> - Lists processes by name.
head <path> [n] - Displays the first n lines of a file (default 10).
tail <path> [n] - Displays the last n lines of a file (default 10).
nf <name> - Creates a new file with the specified name.
mkcd <dir> - Creates and changes to a new directory.
docs - Changes the current directory to the user's Documents folder.
dtop - Changes the current directory to the user's Desktop folder.
ep - Opens the profile for editing.
k9 <name> - Kills a process by name.
la - Lists all files in the current directory with detailed formatting.
ll - Lists all files, including hidden, in the current directory with detailed formatting.
gs - Shortcut for 'git status'.
ga - Shortcut for 'git add .'.
gc <message> - Shortcut for 'git commit -m'.
gp - Shortcut for 'git push'.
g - Changes to the GitHub directory.
gcom <message> - Adds all changes and commits with the specified message.
lazyg <message> - Adds all changes, commits with the specified message, and pushes to the remote repository.
sysinfo - Displays detailed system information.
flushdns - Clears the DNS cache.
cpy <text> - Copies the specified text to the clipboard.
pst - Retrieves text from the clipboard.
z - ehanced zoxide CD (change directory) that guess which directory you want to change to based on history.
Get-PoshThemes - See overview of all Oh-My-Posh themes in action based on your current folder
-------------------------------------------------------------------------------------------------------------------------
Use 'Show-Help' to display this help message.
"@
}

Write-Host "Write 'Show-Help' to display overview of enhanced PowerShell commands in this setup"

# Install and execute WinFetch (neofetch-port to powershell) - requires PSGallery
if (-not(Get-InstalledScript -Name winfetch)) { Install-Script winfetch -Force }
	# Get full path to this scripts path to execute winfetch from System Powershell folder + winfetch:
	# $FetchImage = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, "winfetch\windows-7-logo2.png"))
	# $FetchConfig = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, "winfetch\config.ps1"))
	# $FetchScript = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, "Scripts\winfetch.ps1"))
	# Invoke-expression -Command "$FetchScript -configpath $FetchConfig -Image $FetchImage"
winfetch

