# 🎨 PowerShell Profile Server Pimp (Pretty PowerShell)

A stylish and functional PowerShell profile that looks and feels almost as good as a Linux terminal.
This fork is tailored to work better for vanilla Windows Server 2022 and simplified to be only 1 file you can paste in manually if you want.
As winget is not yet supported on server 2022 by Microsoft, modules like Zoxide fuzzy shell are installed via Chocolatey instead.

## ⚡ One Line Install (Elevated PowerShell Recommended)

Execute the following command in an elevated PowerShell window to install the PowerShell profile:

```
irm "https://github.com/rungok/powershell-profile-server/raw/main/Microsoft.PowerShell_profile.ps1" | iex
```

## 🛠️ Fix the terminal config

After running the script. That means starting the OS-included Powershell (preferably in Administrative mode),
you need to manually change these settings by pressing CTRL + , in Windows Terminal:

1. Defaults -> Appearance -> Text -> Font Face -> <b>Robotomono</b> (Nerd font with icon set for Oh-My-Posh)
2. Defaults ->	Advanced -> Text antialiasing -> <b>ClearType</b> (important for visual quality)
3. Save. DONE!
   
## Customize this profile

Now, enjoy your enhanced and stylish PowerShell experience! 🚀
