# Definiere die FFmpeg-Argumente
$ffmpegArgs = @(
    "-c:v hevc_nvenc",
    "-preset medium",
    "-profile:v main",
    "-crf 30",
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
