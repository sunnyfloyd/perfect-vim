<#
.SYNOPSIS
  Open a Windows folder or file in Perfect Vim (Neovim running in Docker).

.DESCRIPTION
  The folder is mounted live into the container: edits are visible in Windows right
  away and vice versa. If the folder is inside a git repository, the whole repository
  is mounted, so git and the language servers see the full project.

.EXAMPLE
  pvim                      # current folder
  pvim C:\code\my-app       # a folder
  pvim .\src\main.py        # a file (its repository/folder is mounted)
  pvim -Claude              # start Claude Code directly instead of Neovim
  pvim -Shell               # bash shell in the same environment
  pvim -Port 3000,5173      # also reach dev servers at http://localhost:3000 ...
  pvim -Ssh                 # make your Windows SSH keys available (for git push over SSH)
  pvim -Update              # rebuild the image with the newest tools + update plugins
  pvim -Setup               # (re)install plugins, language tools and Claude Code
  pvim -Reset               # delete the container home (plugins, logins, history)
  pvim -DryRun              # print the docker command instead of running it
#>
[CmdletBinding()]
param(
  [Parameter(Position = 0)] [string] $Path = ".",
  [switch] $Shell,
  [switch] $Claude,
  [string[]] $Port = @(),
  [switch] $Ssh,
  [switch] $Build,
  [switch] $Setup,
  [switch] $Update,
  [switch] $Reset,
  [switch] $DryRun,
  [switch] $Help
)

# Not "Stop": in Windows PowerShell 5.1 that turns harmless stderr output of docker/git into errors
$ErrorActionPreference = "Continue"
$Image = "perfect-vim:latest"
$HomeVolume = "perfect-vim-home"
$RepoRoot = Split-Path -Parent $PSScriptRoot
$NvimConfig = Join-Path $RepoRoot "nvim"
$DockerDir = Join-Path $RepoRoot "docker"

function Say([string] $msg, [string] $color = "Cyan") { Write-Host $msg -ForegroundColor $color }

if ($Help) { Get-Help $PSCommandPath -Detailed; exit 0 }

# --- Docker Desktop must be running --------------------------------------------------
function Test-Docker {
  docker info --format "{{.ServerVersion}}" *> $null
  return ($LASTEXITCODE -eq 0)
}
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
  Say "Docker is not installed. Install Docker Desktop: https://www.docker.com/products/docker-desktop/" Red
  exit 1
}
if (-not (Test-Docker)) {
  $desktop = Join-Path $env:ProgramFiles "Docker\Docker\Docker Desktop.exe"
  if (Test-Path $desktop) {
    Say "Starting Docker Desktop..."
    Start-Process $desktop | Out-Null
    $deadline = (Get-Date).AddSeconds(120)
    while (-not (Test-Docker) -and (Get-Date) -lt $deadline) { Start-Sleep -Seconds 2 }
  }
  if (-not (Test-Docker)) { Say "Docker Desktop isn't running. Start it and try again." Red; exit 1 }
}

# --- Maintenance commands ------------------------------------------------------------
function Invoke-Build([switch] $Fresh) {
  $buildArgs = @("build", "-t", $Image)
  if ($Fresh) { $buildArgs += @("--pull", "--no-cache") }
  Say "Building the Perfect Vim image (a few minutes the first time)..."
  docker @buildArgs $DockerDir
  if ($LASTEXITCODE -ne 0) { Say "Image build failed." Red; exit 1 }
}

$base = @("run", "--rm", "-it", "--init",
  "-e", "TERM=xterm-256color", "-e", "COLORTERM=truecolor",
  "-v", "${HomeVolume}:/home/dev",
  "-v", "${NvimConfig}:/home/dev/.config/nvim")

if ($Reset) {
  $answer = Read-Host "Delete the '$HomeVolume' volume (plugins, Claude login, shell history)? Your project files are not touched. [y/N]"
  if ($answer -match '^[yY]') {
    docker volume rm $HomeVolume
    Say "Done. Everything is reinstalled on the next start."
  }
  exit 0
}
if ($Update) {
  Invoke-Build -Fresh
  docker @base $Image pvim-setup --update
  exit $LASTEXITCODE
}
if ($Build) { Invoke-Build; exit 0 }

docker image inspect $Image *> $null
if ($LASTEXITCODE -ne 0) { Invoke-Build }

if ($Setup) {
  # Non-interactive, so the installer can run it too
  docker run --rm --entrypoint pvim-setup -v "${HomeVolume}:/home/dev" -v "${NvimConfig}:/home/dev/.config/nvim" $Image
  exit $LASTEXITCODE
}

# --- What to mount -------------------------------------------------------------------
$target = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)
$openFile = $null
if (Test-Path -LiteralPath $target -PathType Container) {
  $dir = $target
} elseif (Test-Path -LiteralPath (Split-Path -Parent $target) -PathType Container) {
  # An existing file, or a new file in an existing folder
  $dir = Split-Path -Parent $target
  $openFile = Split-Path -Leaf $target
} else {
  Say "Not found: $target" Red
  exit 1
}
$dir = (Resolve-Path -LiteralPath $dir).ProviderPath
if ($dir -match '^[A-Za-z]:\\?$') {
  Say "Refusing to mount a whole drive ($dir). Open a project folder instead." Red
  exit 1
}
$dir = $dir.TrimEnd('\')

# Mount the whole git repository when the folder is inside one
$mountRoot = $dir
$probe = $dir
while ($probe) {
  if (Test-Path -LiteralPath (Join-Path $probe ".git")) { $mountRoot = $probe; break }
  $parent = Split-Path -Parent $probe
  if (-not $parent -or $parent -eq $probe) { break }
  $probe = $parent
}

if ($mountRoot -match '^[A-Za-z]:\\?$') {
  Say "Refusing to mount a whole drive ($mountRoot). Open a project folder instead." Red
  exit 1
}

# /workspace/<folder name>: each project gets its own path, so Claude Code keeps
# separate history and settings per project
$name = (Split-Path -Leaf $mountRoot) -replace '[^A-Za-z0-9._-]', '-'
$containerRoot = "/workspace/$name"
$relative = $dir.Substring($mountRoot.Length).TrimStart('\') -replace '\\', '/'
$workdir = if ($relative) { "$containerRoot/$relative" } else { $containerRoot }

# --- Environment passed into the container -------------------------------------------
$envArgs = @()
$gitName = (git config --global user.name 2>$null)
$gitEmail = (git config --global user.email 2>$null)
if ($gitName) { $envArgs += @("-e", "GIT_AUTHOR_NAME=$gitName", "-e", "GIT_COMMITTER_NAME=$gitName") }
if ($gitEmail) { $envArgs += @("-e", "GIT_AUTHOR_EMAIL=$gitEmail", "-e", "GIT_COMMITTER_EMAIL=$gitEmail") }

# Use the same line-ending setting as Git for Windows, so git inside the container
# doesn't report every file as modified
$autocrlf = (git config --get core.autocrlf 2>$null)
if ($autocrlf) {
  $envArgs += @("-e", "GIT_CONFIG_COUNT=1", "-e", "GIT_CONFIG_KEY_0=core.autocrlf", "-e", "GIT_CONFIG_VALUE_0=$autocrlf")
}

# API keys, if you use them instead of logging in (passed by name, value stays out of the command line)
foreach ($var in @("ANTHROPIC_API_KEY", "GITHUB_TOKEN", "GH_TOKEN")) {
  if (Test-Path "env:$var") { $envArgs += @("-e", $var) }
}

$extra = @()
# "-Port 3000,5173" arrives as one string when called through pvim.cmd
foreach ($p in ($Port -join ',' -split '[,\s]+' | Where-Object { $_ })) {
  if ($p -notmatch '^\d+$') { Say "Not a port number: $p" Red; exit 1 }
  $extra += @("-p", "127.0.0.1:${p}:${p}")
}
if ($Ssh) {
  $sshDir = Join-Path $env:USERPROFILE ".ssh"
  if (Test-Path $sshDir) {
    $extra += @("-v", "${sshDir}:/run/host-ssh:ro", "--tmpfs", "/home/dev/.ssh")
  } else {
    Say "No SSH folder at $sshDir, continuing without SSH keys." Yellow
  }
}

$suffix = -join ((48..57) + (97..122) | Get-Random -Count 4 | ForEach-Object { [char]$_ })
$containerName = "pvim-$($name.ToLower())-$suffix" -replace '[^a-z0-9_.-]', '-'

$command = @("nvim")
if ($Shell) { $command = @("bash") }
elseif ($Claude) { $command = @("claude") }
elseif ($openFile) { $command = @("nvim", $openFile) }

$runArgs = $base + @("--name", $containerName, "--hostname", "pvim",
  "-v", "${mountRoot}:${containerRoot}", "-w", $workdir) + $envArgs + $extra + @($Image) + $command

if ($DryRun) {
  $shown = $runArgs | ForEach-Object { if ($_ -match '\s') { "`"$_`"" } else { $_ } }
  Write-Output ("docker " + ($shown -join " "))
  exit 0
}
docker @runArgs
exit $LASTEXITCODE
