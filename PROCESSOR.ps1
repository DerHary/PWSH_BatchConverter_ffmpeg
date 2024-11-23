########################################################################################
# PWSH_BatchConverter_ffmpeg
# Author: DerHary
# https://github.com/DerHary/
# Requirements:
# 	NVIDIA GPU (hwaccel)
# 	ffmpg (defined in PATH or at least directly call-able with "ffmpg")
# 	Powershell (tested it with PWSH 7.4)
########################################################################################

# Define static Parameters and inputs from Templates
param (
	# Input Params from Template Script
    [string]$ffmpegArgs,
	[string]$VideoContainer,
	# Directories to get/write Videos (relative!)
    [string]$VideoInputFolder = "source",
    [string]$VideoOutputFolder = "output"
)

# possible Filetypes
$VideoFileTypes = '*.mkv', '*.mp4', '*.webm', '*.mov', '*.avi'

# Build input and output Path with relative from Script Root
$VideoInputFolder = Join-Path -Path $PSScriptRoot -ChildPath $VideoInputFolder
$VideoOutputFolder = Join-Path -Path $PSScriptRoot -ChildPath $VideoOutputFolder

# Print the Parameters
Write-Host "Input Folder: $VideoInputFolder"
Write-Host "Output Folder: $VideoOutputFolder"
Write-Host "Using FFmpeg arguments:"
Write-Host "$ffmpegArgs"
Write-Host "Container Format: $VideoContainer"

Write-Host "Conversion starting in 3 Seconds - close the Window to abbort"
Start-Sleep -Seconds 3

# Define the optical Part
function Show-ProgressBar {
    param (
        [int]$PercentComplete,
        [string]$CurrentTime,
        [string]$Bitrate,
        [string]$Quality,
        [int]$Speed,
        [int]$RemainingFiles
    )
	# Progress bar Chars width
    $width = 50
	# math the Progressbar
    $progress = [Math]::Round($PercentComplete / 100 * $width)
	# Define Character for Progressbar (Examples █,#,O,....)
    $bar = ("█" * $progress).PadRight($width)
    
    # Progressbar color
    $coloredProgressBar = "`e[34m$bar`e[0m"

    # Define speed colors (Defined for Info about slow conversions)
    if ($Speed -le 10) {
        $formattedSpeed = "`e[31m$Speed`e[0m"  # red
    } elseif ($Speed -le 20) {
        $formattedSpeed = "`e[33m$Speed`e[0m"  # yellow
    } elseif ($Speed -le 30) {
        $formattedSpeed = "`e[92m$Speed`e[0m"  # lightgreen
    } else {
        $formattedSpeed = "`e[96m$Speed`e[0m"  # lightblue
    }

    # always 3 digit Progress (prevent moving line)
    $formattedPercentComplete = $PercentComplete.ToString("000")

    # Remove Coma (prevent moving line)
    $formattedBitrate = ([math]::Round([double]($Bitrate -replace 'kbits/s', ''))).ToString("00000")

    # Define Statustext
    $greenText = "[`e[32m$formattedPercentComplete%|$CurrentTime|${formattedBitrate}kb/s|Q:$Quality|SP:$formattedSpeed] [Files:$RemainingFiles]`e[0m]"
    
    # Show Progressbar and Infotext
    Write-Host -NoNewline "`r[$coloredProgressBar] $greenText"
}

# Request Video Duration from Windows (for some Formats we cant get it from ffprobe)
function Get-VideoDuration {
    param ([string]$FilePath)
    $shell = New-Object -ComObject Shell.Application
    $folder = $shell.Namespace((Get-Item $FilePath).DirectoryName)
    $file = $folder.ParseName((Get-Item $FilePath).Name)
    $duration = $folder.GetDetailsOf($file, 27)
    if ($duration -ne "") {
        $timeParts = $duration -split "[:]"
        return ([int]$timeParts[0] * 3600) + ([int]$timeParts[1] * 60) + [int]$timeParts[2]
    }
    return 0
}

$global:ffmpegProcess = $null

function CleanUp { if ($global:ffmpegProcess -and -not $global:ffmpegProcess.HasExited) { $global:ffmpegProcess.Kill() } }
trap { CleanUp; break }

# Collect the Videos for processing
$videoFiles = Get-ChildItem -Path $VideoInputFolder -Recurse -File -Include $VideoFileTypes
# Count them
$totalFiles, $processedFiles = $videoFiles.Count, 0

# Loop through Files and do the Job
$videoFiles | ForEach-Object {
    $OutputFileName = $_.BaseName + $VideoContainer
    $OutputFilePath = Join-Path -Path $VideoOutputFolder -ChildPath $OutputFileName
    Write-Output "Processing file: $($_.FullName)"
    $duration = Get-VideoDuration -FilePath $_.FullName
    if ($duration -eq 0) { Write-Host "Video lenght could not be determinated: $($_.FullName). Skipped..."; return }
	# DO THE JOB - FFMPEG Commandline
    $completeArgs = "-hwaccel cuda -i `"$($_.FullName)`" $ffmpegArgs -y `"$OutputFilePath`""
	# DO THE JOB - FFMPEG Commandline
    $processInfo = New-Object System.Diagnostics.ProcessStartInfo
    $processInfo.FileName, $processInfo.Arguments = "ffmpeg", $completeArgs
    $processInfo.RedirectStandardError, $processInfo.UseShellExecute, $processInfo.CreateNoWindow = $true, $false, $true
    $global:ffmpegProcess = New-Object System.Diagnostics.Process
    $global:ffmpegProcess.StartInfo = $processInfo

    try {
        $global:ffmpegProcess.Start() | Out-Null
        $bitrate, $quality, $speed, $currentTime = "", "", 0, ""

        while (-not $global:ffmpegProcess.HasExited) {
            $line = $global:ffmpegProcess.StandardError.ReadLine()
            if ($line -match "time=(\d+:\d+:\d+).(\d+)") {
                $currentTime = $matches[1]
                $currentSeconds = [TimeSpan]::Parse($currentTime).TotalSeconds
                $percentComplete = [math]::Round(($currentSeconds / $duration) * 100)
            }
            if ($line -match "bitrate=\s*(\d+\.\d+kbits/s)") { $bitrate = $matches[1] }
            if ($line -match "q=\s*(\d+\.\d+)") { $quality = [math]::Round($matches[1]) }
            if ($line -match "speed=\s*(\d+\.\d+)x") { $speed = [math]::Round($matches[1]) }
            $remainingFiles = $totalFiles - $processedFiles - 1
            Show-ProgressBar -PercentComplete $percentComplete -CurrentTime $currentTime -Bitrate $bitrate -Quality $quality -Speed $speed -RemainingFiles $remainingFiles
        }
    } finally { CleanUp }
    $processedFiles++
    Write-Host "`nDONE: $($OutputFileName)"
}

Write-Host "Batch coversion done!"
pause
