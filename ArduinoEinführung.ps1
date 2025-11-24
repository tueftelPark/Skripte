# ArduinoEinfuehrung.ps1
# Laedt die aktuelle Version des ArduinoEinfuehrung-Repos von GitHub herunter,
# entfernt alte Dateien und oeffnet den neuen Ordner auf dem Desktop.

$Desktop    = Join-Path $env:USERPROFILE 'Desktop'
$TargetPath = Join-Path $Desktop 'ArduinoEinfuehrung'
$ZipPath    = Join-Path $Desktop 'ArduinoEinfuehrung.zip'
# Wenn Branch != main -> hier anpassen:
$ZipUrl     = 'https://github.com/tueftelPark/ArduinoEinfuehrung/archive/refs/heads/main.zip'

Write-Host "==============================="
Write-Host "  ArduinoEinfuehrung aktualisieren"
Write-Host "==============================="
Write-Host ""

# 1) Arduino IDE schliessen
Write-Host "[*] Schliesse Arduino IDE (falls offen)..."
$arduinoProcs = @('Arduino IDE','arduino')
foreach ($name in $arduinoProcs) {
    Get-Process -Name $name -ErrorAction SilentlyContinue | ForEach-Object {
        try {
            $_ | Stop-Process -Force -ErrorAction Stop
            Write-Host "    [+] Prozess $name beendet."
        } catch {}
    }
}

# 2) Alle Explorer-Fenster schliessen
Write-Host ""
Write-Host "[*] Schliesse alle Explorer-Fenster..."
$explorerClosed = $false
Get-Process -Name 'explorer' -ErrorAction SilentlyContinue | ForEach-Object {
    try {
        $_ | Stop-Process -Force -ErrorAction Stop
        $explorerClosed = $true
    } catch {}
}

if ($explorerClosed) {
    Write-Host "    [+] Explorer-Fenster wurden geschlossen."
} else {
    Write-Host "    [!] Keine Explorer-Fenster offen."
}

# 3) Alten Ordner loeschen — mit Wiederholversuchen
Write-Host ""
if (Test-Path -LiteralPath $TargetPath) {
    Write-Host "[*] Loesche alten 'ArduinoEinfuehrung'-Ordner..."

    $maxTries = 3
    $deleted  = $false

    for ($i = 1; $i -le $maxTries; $i++) {

        # Versuch, den Ordner zu loeschen
        Remove-Item -LiteralPath $TargetPath -Recurse -Force -ErrorAction SilentlyContinue

        if (-not (Test-Path -LiteralPath $TargetPath)) {
            Write-Host "    [+] Ordner wurde geloescht."
            $deleted = $true
            break
        } else {
            Write-Host "    [!] Versuch $i : Ordner konnte nicht geloescht werden."
            if ($i -lt $maxTries) {
                Write-Host "        Bitte alle Dateien/Programme schliessen,"
                Write-Host "        die im Ordner geoeffnet sind (Arduino, Editor, Word, ...)."
                Read-Host "        Enter druecken, um es erneut zu versuchen"
            }
        }
    }

    if (-not $deleted) {
        Write-Host "    [!] Auch nach mehreren Versuchen blockiert!"
        Write-Host "        Vermutlich ist noch eine Datei geoeffnet."
        Write-Host ""
        Read-Host "Enter druecken zum Schliessen"
        exit 1
    }
}

# 4) Alte ZIP loeschen
if (Test-Path -LiteralPath $ZipPath) {
    Remove-Item -LiteralPath $ZipPath -Force -ErrorAction SilentlyContinue
}

# 5) ZIP herunterladen
Write-Host ""
Write-Host "[*] Lade aktuelle Version von GitHub herunter..."
Invoke-WebRequest -Uri $ZipUrl -OutFile $ZipPath -UseBasicParsing -ErrorAction Stop

# 6) ZIP entpacken
Write-Host "[*] Entpacke ZIP-Datei..."
Expand-Archive -LiteralPath $ZipPath -DestinationPath $Desktop -Force -ErrorAction Stop

# 7) Entpackten Ordner korrekt benennen (ArduinoEinfuehrung-main -> ArduinoEinfuehrung)
$UnzippedFolder = Join-Path $Desktop 'ArduinoEinfuehrung-main'
if (Test-Path -LiteralPath $UnzippedFolder) {
    if (Test-Path -LiteralPath $TargetPath) {
        Remove-Item -LiteralPath $TargetPath -Recurse -Force -ErrorAction SilentlyContinue
    }
    Rename-Item -LiteralPath $UnzippedFolder -NewName 'ArduinoEinfuehrung'
}

# 8) ZIP entfernen
if (Test-Path -LiteralPath $ZipPath) {
    Remove-Item -LiteralPath $ZipPath -Force -ErrorAction SilentlyContinue
}

# 9) Zielordner oeffnen
Write-Host ""
Write-Host "[+] Fertig – oeffne ArduinoEinfuehrung..."
Start-Process -FilePath 'explorer.exe' -ArgumentList $TargetPath

Write-Host ""
Read-Host "Enter druecken zum Schliessen"
