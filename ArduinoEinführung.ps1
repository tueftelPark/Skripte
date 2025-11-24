# ArduinoEinfuehrung.ps1
# Vollautomatisches Update ohne Benutzerinteraktion

$Desktop    = Join-Path $env:USERPROFILE 'Desktop'
$TargetPath = Join-Path $Desktop 'ArduinoEinfuehrung'
$ZipPath    = Join-Path $Desktop 'ArduinoEinfuehrung.zip'
$ZipUrl     = 'https://github.com/tueftelPark/ArduinoEinfuehrung/archive/refs/heads/main.zip'

Write-Host "==============================="
Write-Host "  ArduinoEinfuehrung aktualisieren"
Write-Host "==============================="

# 1) Arduino IDE schließen
Write-Host "[*] Schliesse Arduino IDE..."
Get-Process -Name "Arduino IDE","arduino" -ErrorAction SilentlyContinue |
    Stop-Process -Force -ErrorAction SilentlyContinue

# 2) Explorer schließen
Write-Host "[*] Schliesse Explorer-Fenster..."
Get-Process -Name "explorer" -ErrorAction SilentlyContinue |
    Stop-Process -Force -ErrorAction SilentlyContinue

# 3) Alten Ordner automatisch löschen
if (Test-Path $TargetPath) {
    Write-Host "[*] Loesche alten Ordner..."
    $tries = 0
    while (Test-Path $TargetPath -and $tries -lt 3) {
        Remove-Item $TargetPath -Recurse -Force -ErrorAction SilentlyContinue
        Start-Sleep -Milliseconds 700
        $tries++
    }

    if (Test-Path $TargetPath) {
        Write-Host "[!] Ordner konnte nicht geloescht werden. Abbruch."
        exit
    }

    Write-Host "    [+] Ordner geloescht."
}

# 4) Alte ZIP löschen (falls vorhanden)
Remove-Item $ZipPath -Force -ErrorAction SilentlyContinue

# 5) ZIP herunterladen
Write-Host "[*] Lade ZIP von GitHub..."
Invoke-WebRequest -Uri $ZipUrl -OutFile $ZipPath -UseBasicParsing

# 6) Entpacken
Write-Host "[*] Entpacke ZIP..."
Expand-Archive $ZipPath -DestinationPath $Desktop -Force

# 7) Ordner umbenennen
$Unzip = Join-Path $Desktop 'ArduinoEinfuehrung-main'
if (Test-Path $Unzip) {
    Rename-Item $Unzip 'ArduinoEinfuehrung' -Force
}

# 8) ZIP entfernen
Remove-Item $ZipPath -Force -ErrorAction SilentlyContinue

# 9) Neuen Ordner öffnen
Write-Host "[+] Fertig — oeffne Projekt..."
Start-Process explorer.exe $TargetPath
