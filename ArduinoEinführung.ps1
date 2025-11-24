# ArduinoEinfuehrung.ps1
# Aktualisiert den ArduinoEinfuehrung-Ordner auf dem Desktop ohne git
# und ohne jegliche Benutzereingabe.

$Desktop    = Join-Path $env:USERPROFILE 'Desktop'
$TargetPath = Join-Path $Desktop 'ArduinoEinfuehrung'
$ZipPath    = Join-Path $Desktop 'ArduinoEinfuehrung.zip'
$ZipUrl     = 'https://github.com/tueftelPark/ArduinoEinfuehrung/archive/refs/heads/main.zip'

Write-Host "==============================="
Write-Host "  ArduinoEinfuehrung aktualisieren"
Write-Host "==============================="
Write-Host ""

# 1) Arduino IDE schliessen
Write-Host "[*] Schliesse Arduino IDE..."
Get-Process -Name "Arduino IDE","arduino" -ErrorAction SilentlyContinue |
    Stop-Process -Force -ErrorAction SilentlyContinue

# 2) Explorer schliessen
Write-Host "[*] Schliesse Explorer-Fenster..."
Get-Process -Name "explorer" -ErrorAction SilentlyContinue |
    Stop-Process -Force -ErrorAction SilentlyContinue

# 3) Alten Ordner loeschen — mit automatischen Wiederholversuchen
if (Test-Path $TargetPath) {
    Write-Host "[*] Loesche alten Ordner..."
    $deleted = $false

    for ($i = 1; $i -le 3; $i++) {
        Remove-Item $TargetPath -Recurse -Force -ErrorAction SilentlyContinue
        if (-not (Test-Path $TargetPath)) {
            Write-Host "    [+] Ordner geloescht."
            $deleted = $true
            break
        } else {
            Write-Host "    [!] Versuch $i : Ordner blockiert. Versuche erneut..."
            Start-Sleep -Seconds 1
        }
    }

    if (-not $deleted) {
        Write-Host "    [!] Ordner konnte nicht geloescht werden. Skript wird beendet."
        exit
    }
}

# 4) Alte ZIP loeschen
Remove-Item $ZipPath -Force -ErrorAction SilentlyContinue

# 5) ZIP herunterladen
Write-Host "[*] Lade ZIP von GitHub..."
Invoke-WebRequest -Uri $ZipUrl -OutFile $ZipPath -UseBasicParsing

# 6) ZIP entpacken
Write-Host "[*] Entpacke ZIP..."
Expand-Archive $ZipPath -DestinationPath $Desktop -Force

# 7) Ordner umbenennen
$Unzip = Join-Path $Desktop 'ArduinoEinfuehrung-main'
if (Test-Path $Unzip) {
    Rename-Item $Unzip 'ArduinoEinfuehrung' -Force
}

# 8) ZIP loeschen
Remove-Item $ZipPath -Force -ErrorAction SilentlyContinue

# 9) Neuen Ordner oeffnen
Write-Host ""
Write-Host "[+] Fertig – oeffne Projekt..."
Start-Process explorer.exe $TargetPath
