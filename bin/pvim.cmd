@echo off
rem Perfect Vim launcher. Works from cmd, PowerShell and Windows Terminal,
rem regardless of the PowerShell execution policy.
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\lib\pvim.ps1" %*
