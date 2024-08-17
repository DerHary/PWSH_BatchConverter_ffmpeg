# Define ffmpg Parameters
$ffmpegArgs = @(
    "-c:v hevc_nvenc",
    "-vf scale=-1:720",
    "-r 25",
    "-preset fast",
    "-profile:v main",
    "-level 4.0",
    "-b:v 600k",
    "-minrate:v 500k",
    "-maxrate:v 1000k",
    "-c:a copy"
) -join " "

$VideoContainer = ".mp4"

# Use $PSScriptRoot, to get the path to the Processor Script
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "PROCESSOR.ps1"

# Check if Processor Script exists
if (Test-Path $scriptPath) {
    # Call Processor Script
    & "$scriptPath" -ffmpegArgs $ffmpegArgs -VideoContainer $VideoContainer
} else { Write-Host "Das Skript '$scriptPath' wurde nicht gefunden." }