# 🎨 PowerShell Profile (Pretty PowerShell)

A stylish and functional PowerShell profile that looks and feels almost as good as a Linux terminal. This fork is tailored to work better for vanilla Winodows Server 2022.

## ⚡ One Line Install (Elevated PowerShell Recommended)

Execute the following command in an elevated PowerShell window to install the PowerShell profile:

```
irm "https://github.com/rungok/powershell-profile/raw/main/setup.ps1" | iex
```

## 🛠️ Fix the terminal config

After running the script. That means starting the OS-included Powershell (preferably in Administrative mode),
you need to manually change these settings by pressing CTRL + , in Windows Terminal:

1. Startup ->
Default profile -> Powershell (default: Windows Powershell)
Default terminal appliaction -> Windows Terminal (default: Let Windows decide)
2. Defaults -> 
Appearance -> Text -> Font Face -> Robotomono (Nerd font with icon set for Oh-My-Posh prompt and directory listings)
Appearance -> Text -> Font Size -> 10 (Set the font size according to your vision handicap level ;-)
3. Defaults ->
Advanced -> Text antialiasing -> ClearType (important for visual quality)
4. DONE!
   
## Customize this profile

**Do not make any changes to the `Microsoft.PowerShell_profile.ps1` file**, since it's hashed and automatically overwritten by any commits to this repository.

After the profile is installed and active, run the `Edit-Profile` function to create a separate profile file for your current user. Make any changes and customizations in this new file named `profile.ps1`.

Now, enjoy your enhanced and stylish PowerShell experience! 🚀
