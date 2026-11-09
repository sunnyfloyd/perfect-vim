<#
.SYNOPSIS
  One-time setup for Perfect Vim on Windows. Safe to run again.

.DESCRIPTION
  1. Builds the Docker image (Docker Desktop must be installed)
  2. Installs plugins, language tools and Claude Code into the "perfect-vim-home" volume
  3. Adds the `pvim` command to your user PATH
  4. Installs a Nerd Font for icons (skipped if you already have one)
  5. Adds a "Perfect Vim" profile to Windows Terminal

.PARAMETER ProjectsDir
  Folder the Windows Terminal profile starts in. Default: the folder containing this repo.
#>
param(
  [string] $ProjectsDir = (Split-Path -Parent $PSScriptRoot),
  [switch] $SkipFont,
  [switch] $SkipTerminalProfile
)

$ErrorActionPreference = "Continue"
$Root = $PSScriptRoot
$Bin = Join-Path $Root "bin"
$Nv = Join-Path $Root "lib\pvim.ps1"

function Step([string] $n, [string] $msg) { Write-Host "`n[$n/5] $msg" -ForegroundColor Cyan }
function Ok([string] $msg) { Write-Host "      $msg" -ForegroundColor Green }
function Note([string] $msg) { Write-Host "      $msg" -ForegroundColor Yellow }

# --- 1. Image ------------------------------------------------------------------------
Step 1 "Building the Docker image"
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $Nv -Build
if ($LASTEXITCODE -ne 0) { Write-Host "Stopping: the image could not be built." -ForegroundColor Red; exit 1 }
Ok "Image perfect-vim:latest is ready"

# --- 2. Plugins, language tools, Claude Code -----------------------------------------
Step 2 "Installing editor plugins, language tools and Claude Code (a few minutes)"
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $Nv -Setup
if ($LASTEXITCODE -ne 0) { Note "Some tools failed to install. They are retried automatically the next time you run pvim." }
else { Ok "Done" }

# --- 3. PATH -------------------------------------------------------------------------
Step 3 "Adding the pvim command to your PATH"
$envKey = Get-Item "HKCU:\Environment"
$rawPath = $envKey.GetValue("Path", "", "DoNotExpandEnvironmentNames")
if (($rawPath -split ';') -contains $Bin) {
  Ok "Already on PATH"
} else {
  # Keep the value type (usually ExpandString), so entries like %USERPROFILE%\... keep working
  $kind = if ($envKey.GetValueNames() -contains "Path") { $envKey.GetValueKind("Path") } else { "ExpandString" }
  $newPath = (@($rawPath.TrimEnd(';'), $Bin) | Where-Object { $_ }) -join ';'
  Set-ItemProperty -Path "HKCU:\Environment" -Name Path -Value $newPath -Type $kind
  # Tell Windows the environment changed (new terminals pick up the PATH)
  [Environment]::SetEnvironmentVariable("PVIM_REFRESH", "1", "User")
  [Environment]::SetEnvironmentVariable("PVIM_REFRESH", $null, "User")
  Ok "Added $Bin"
}
$env:Path = "$env:Path;$Bin"

# --- 4. Nerd Font --------------------------------------------------------------------
Step 4 "Checking for a Nerd Font (needed for icons)"
function Get-NerdFontFace {
  $faces = @()
  foreach ($key in @("HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts", "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Fonts")) {
    if (Test-Path $key) {
      $faces += (Get-Item $key).GetValueNames() | Where-Object { $_ -match 'Nerd Font|\bNF\b' }
    }
  }
  # Terminals need a monospaced font: prefer "Nerd Font Mono", never "Propo" (proportional).
  # Then turn "X Nerd Font Mono Bold (TrueType)" into the face name "X Nerd Font Mono".
  $best = $faces | Where-Object { $_ -match 'Nerd Font Mono|\bNFM\b' } | Select-Object -First 1
  if (-not $best) { $best = $faces | Where-Object { $_ -notmatch 'Propo|\bNFP\b' } | Select-Object -First 1 }
  if (-not $best) { $best = $faces | Select-Object -First 1 }
  if (-not $best) { return $null }
  $face = $best -replace '\s*\(.*\)$', ''
  $face = $face -replace '(\s+(Regular|Bold|Italic|Light|Medium|SemiBold|ExtraBold|ExtraLight|Thin|Black|Retina|Oblique))+$', ''
  return $face.Trim()
}

$fontFace = Get-NerdFontFace
if ($fontFace) {
  Ok "Found: $fontFace"
} elseif ($SkipFont) {
  Note "Skipped. Without a Nerd Font some icons show as boxes."
} else {
  $tmp = Join-Path $env:TEMP "pvim-font"
  New-Item -ItemType Directory -Force $tmp | Out-Null
  $archive = Join-Path $tmp "JetBrainsMono.tar.xz"
  $files = @("JetBrainsMonoNerdFontMono-Regular.ttf", "JetBrainsMonoNerdFontMono-Bold.ttf",
    "JetBrainsMonoNerdFontMono-Italic.ttf", "JetBrainsMonoNerdFontMono-BoldItalic.ttf")
  try {
    $ProgressPreference = "SilentlyContinue"
    Invoke-WebRequest -UseBasicParsing "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz" -OutFile $archive
    & "$env:SystemRoot\System32\tar.exe" -xf $archive -C $tmp @files
    # Per-user install, no admin rights needed
    $fontDir = Join-Path $env:LOCALAPPDATA "Microsoft\Windows\Fonts"
    New-Item -ItemType Directory -Force $fontDir | Out-Null
    $regKey = "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts"
    if (-not (Test-Path $regKey)) { New-Item -Path $regKey -Force | Out-Null }
    foreach ($f in $files) {
      $dest = Join-Path $fontDir $f
      Copy-Item (Join-Path $tmp $f) $dest -Force
      $style = ($f -replace '^JetBrainsMonoNerdFontMono-', '' -replace '\.ttf$', '') -creplace '([a-z])([A-Z])', '$1 $2'
      New-ItemProperty -Path $regKey -Name "JetBrainsMono Nerd Font Mono $style (TrueType)" -Value $dest -PropertyType String -Force | Out-Null
    }
    $fontFace = "JetBrainsMono Nerd Font Mono"
    Ok "Installed $fontFace"
  } catch {
    Note "Font download failed ($($_.Exception.Message)). Install any Nerd Font from https://www.nerdfonts.com later."
  } finally {
    Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
  }
}

# --- 5. Windows Terminal profile -----------------------------------------------------
Step 5 "Windows Terminal profile"
if ($SkipTerminalProfile) {
  Note "Skipped"
} else {
  # A "fragment" adds a profile without touching your own settings.json
  $fragDir = Join-Path $env:LOCALAPPDATA "Microsoft\Windows Terminal\Fragments\PerfectVim"
  New-Item -ItemType Directory -Force $fragDir | Out-Null
  $wtProfile = [ordered]@{
    guid              = "{3f6c2a9e-8b7d-4e51-9c3a-6d2f1b0e7a44}"
    name              = "Perfect Vim"
    commandline       = "powershell.exe -NoLogo -NoExit -Command `"Write-Host 'Perfect Vim: pvim opens this folder, pvim <path> another one, pvim -Help shows all options.' -ForegroundColor Cyan`""
    startingDirectory = $ProjectsDir
    icon              = [char]::ConvertFromUtf32(0x1F4DD)
  }
  if ($fontFace) { $wtProfile.font = [ordered]@{ face = $fontFace } }
  $json = [ordered]@{ profiles = @($wtProfile) } | ConvertTo-Json -Depth 5
  [IO.File]::WriteAllText((Join-Path $fragDir "perfect-vim.json"), $json, (New-Object Text.UTF8Encoding $false))
  Ok "Added profile 'Perfect Vim' (restart Windows Terminal to see it in the dropdown)"
}

Write-Host "`nAll set." -ForegroundColor Green
Write-Host @"

Next steps:
  1. Open a NEW terminal (or the 'Perfect Vim' profile in Windows Terminal).
  2. cd into a project and run:   pvim
  3. Press F1 inside Neovim for the cheat sheet.
  4. First time only: press Space a c to open Claude Code and log in.

"@
if (-not $fontFace) { Note "Set a Nerd Font in your terminal for icons." }
elseif (-not $SkipTerminalProfile) { Write-Host "  Tip: also set '$fontFace' as the font of your usual terminal profile." }
