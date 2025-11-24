# AutonomesFahrzeug.ps1
# Vollautomatisches Update ohne Benutzerinteraktion

$Desktop    = Join-Path $env:USERPROFILE 'Desktop'
$TargetPath = Join-Path $Desktop 'AutonomesFahrzeug'
$ZipPath    = Join-Path $Desktop 'AutonomesFahrzeug.zip'
$ZipUrl     = 'https://github.com/tueftelPark/AutonomesFahrzeug/archive/refs/heads/main.zip'

Write-Host "==============================="
Write-Host "  AutonomesFahrzeug aktualisieren"
Write-Host "==============================="

# 1) Arduino IDE schliessen
Write-Host "[*] Schliesse Arduino IDE..."
Get-Process -Name "Arduino IDE","arduino" -ErrorAction SilentlyContinue |
    Stop-Process -Force -ErrorAction SilentlyContinue

# 2) Explorer schliessen
Write-Host "[*] Schliesse Explorer-Fenster..."
Get-Process -Name "explorer" -ErrorAction SilentlyContinue |
    Stop-Process -Force -ErrorAction SilentlyContinue

# 3) Alten Ordner loeschen
if (Test-Path $TargetPath) {
    Write-Host "[*] Loesche alten Ordner..."
    $deleted = $false

    for ($tries = 1; $tries -le 3; $tries++) {
        Remove-Item $TargetPath -Recurse -Force -ErrorAction SilentlyContinue

        if (-not (Test-Path $TargetPath)) {
            Write-Host "    [+] Ordner geloescht."
            $deleted = $true
            break
        } else {
            Write-Host "    [!] Versuch $tries : Ordner blockiert, versuche erneut..."
            Start-Sleep -Milliseconds 700
        }
    }

    if (-not $deleted) {
        Write-Host "[!] Ordner konnte nicht geloescht werden. Abbruch."
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

# 7) Entpackten Ordner umbenennen
$Unzip = Join-Path $Desktop 'AutonomesFahrzeug-main'
if (Test-Path $Unzip) {
    Rename-Item $Unzip 'AutonomesFahrzeug' -Force
}

# 8) ZIP entfernen
Remove-Item $ZipPath -Force -ErrorAction SilentlyContinue

# 9) Neuen Ordner oeffnen
Write-Host "[+] Fertig oeffne Projekt..."
Start-Process explorer.exe $TargetPath
