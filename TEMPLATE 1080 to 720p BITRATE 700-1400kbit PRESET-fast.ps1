# Configure this
# Define ffmpg Parameters
# can also be passed in one line, as one string, but having it seperated makes better overview
$ffmpegArgs = @(
    "-c:v hevc_nvenc",
    "-vf scale=-1:720",
    "-r 25",
    "-preset fast",
    "-profile:v main",
    "-level 4.0",
    "-b:v 800k",
    "-minrate:v 700k",
    "-maxrate:v 1400k",
    "-c:a copy"
) -join " "

# Define output Container (Exampes: .mkv or .mp4)
$VideoContainer = ".mkv"




# Static Parameters (usually this dont need to be touched)
# Use $PSScriptRoot, to get the path to the Processor Script
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "PROCESSOR.ps1"
# Check if Processor Script exists and if, call it with the given Parameters
if (Test-Path $scriptPath) { & "$scriptPath" -ffmpegArgs $ffmpegArgs -VideoContainer $VideoContainer } else { Write-Host "Processor Script '$scriptPath' was not found!" }