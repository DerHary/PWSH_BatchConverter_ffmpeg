# Definiere die FFmpeg-Argumente
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

# Verwende $PSScriptRoot, um den Pfad zum Hauptskript zu erstellen
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "PROCESSOR.ps1"

# Überprüfen, ob das Hauptskript existiert
if (Test-Path $scriptPath) {
    # Rufe das Hauptskript mit den FFmpeg-Argumenten auf
    & "$scriptPath" -ffmpegArgs $ffmpegArgs
} else {
    Write-Host "Das Skript '$scriptPath' wurde nicht gefunden."
}
