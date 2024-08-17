# Configure this
# Define ffmpg Parameters
# can also be passed in one line, as one string, but having it seperated makes better overview
$ffmpegArgs = @(
    "-c:v hevc_nvenc",
    "-preset medium",
    "-profile:v main",
    "-level 5.2",
    "-b:v 7000k",
    "-minrate:v 5000k",
    "-maxrate:v 10000k",
    "-c:a copy"
) -join " "

# Define output Container (Exampes: .mkv or .mp4)
$VideoContainer = ".mp4"




# Static Parameters (usually this dont need to be touched)
# Use $PSScriptRoot, to get the path to the Processor Script
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "PROCESSOR.ps1"
# Check if Processor Script exists and if, call it with the given Parameters
if (Test-Path $scriptPath) { & "$scriptPath" -ffmpegArgs $ffmpegArgs -VideoContainer $VideoContainer } else { Write-Host "Processor Script '$scriptPath' was not found!" }