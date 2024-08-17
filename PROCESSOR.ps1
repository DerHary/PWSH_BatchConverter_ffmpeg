param (
    [string]$ffmpegArgs,
    [string]$VideoInputFolder = "source",
    [string]$VideoOutputFolder = "output"
)

# possible Filetypes
$VideoFileTypes = '*.mkv', '*.mp4', '*.webm', '*.mov'

$VideoInputFolder = Join-Path -Path $PSScriptRoot -ChildPath $VideoInputFolder
$VideoOutputFolder = Join-Path -Path $PSScriptRoot -ChildPath $VideoOutputFolder

Write-Host "Input Folder: $VideoInputFolder"
Write-Host "Output Folder: $VideoOutputFolder"
Write-Host "Using FFmpeg arguments: $ffmpegArgs"

function Show-ProgressBar {
    param (
        [int]$PercentComplete,
        [string]$CurrentTime,
        [string]$Bitrate,
        [string]$Quality,
        [int]$Speed,
        [int]$RemainingFiles
    )

    $width = 50
    $progress = [Math]::Round($PercentComplete / 100 * $width)
    $bar = ("█" * $progress).PadRight($width)
    
    # Progressbar color
    $blueBar = "`e[34m$bar`e[0m"

    # Convert speed colors
    if ($Speed -le 10) {
        $formattedSpeed = "`e[31m$Speed`e[0m"  # rot
    } elseif ($Speed -le 20) {
        $formattedSpeed = "`e[33m$Speed`e[0m"  # gelb
    } elseif ($Speed -le 30) {
        $formattedSpeed = "`e[92m$Speed`e[0m"  # hellgrün
    } else {
        $formattedSpeed = "`e[96m$Speed`e[0m"  # hellblau
    }

    # always 3 digit Progress (prevent moving line)
    $formattedPercentComplete = $PercentComplete.ToString("000")

    # Remove Coma (prevent moving line)
    $formattedBitrate = ([math]::Round([double]($Bitrate -replace 'kbits/s', ''))).ToString("00000")

    # Define Statustext
    $greenText = "[`e[32m$formattedPercentComplete%|$CurrentTime|${formattedBitrate}kb/s|Q:$Quality|SP:$formattedSpeed] [Files:$RemainingFiles]`e[0m]"
    
    # Show Progressbar and Infotext
    Write-Host -NoNewline "`r[$blueBar] $greenText"
}

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

$videoFiles = Get-ChildItem -Path $VideoInputFolder -Recurse -File -Include $VideoFileTypes
$totalFiles, $processedFiles = $videoFiles.Count, 0

$videoFiles | ForEach-Object {
    $OutputFileName = $_.BaseName + ".mkv"
    $OutputFilePath = Join-Path -Path $VideoOutputFolder -ChildPath $OutputFileName
    Write-Output "Processing file: $($_.FullName)"
    $duration = Get-VideoDuration -FilePath $_.FullName
    if ($duration -eq 0) { Write-Host "Videolaenge konnte nicht festgestellt werden $($_.FullName). Skippe..."; return }
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
    Write-Host "`nFertig: $($_.FullName)"
}

Write-Host "Konvertierung abgeschlossen!"
pause
