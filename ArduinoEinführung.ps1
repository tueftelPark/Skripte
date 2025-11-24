# ArduinoEinfuehrung.ps1
# Laedt das ArduinoEinfuehrung-Projekt von GitHub als ZIP, entpackt es auf den Desktop
# und oeffnet anschliessend den Ordner. Kein installiertes git noetig.

$Desktop    = Join-Path $env:USERPROFILE 'Desktop'
$TargetPath = Join-Path $Desktop 'ArduinoEinfuehrung'
$ZipPath    = Join-Path $Desktop 'ArduinoEinfuehrung.zip'
# Falls dein Branch nicht "main" heisst (z.B. "master"), unten anpassen:
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
        } catch {
            # ignorieren, wenn nicht laufend
        }
    }
}

# 2) Alle Explorer-Fenster schliessen (explorer.exe stoppen)
Write-Host ""
Write-Host "[*] Schliesse alle Explorer-Fenster..."
$explorerClosed = $false
Get-Process -Name 'explorer' -ErrorAction SilentlyContinue | ForEach-Object {
    try {
        $_ | Stop-Process -Force -ErrorAction Stop
        $explorerClosed = $true
    } catch {
        # ignorieren
    }
}

if ($explorerClosed) {
    Write-Host "    [+] Explorer-Fenster wurden geschlossen."
} else {
    Write-Host "    [!] Keine Explorer-Fenster offen."
}

# 3) Alten Ordner loeschen
Write-Host ""
if (Test-Path -LiteralPath $TargetPath) {
    Write-Host "[*] Loesche alten 'ArduinoEinfuehrung'-Ordner..."
    try {
        Remove-Item -LiteralPath $TargetPath -Recurse -Force -ErrorAction Stop
    } catch {
        Write-Host "    [!] Fehler: Ordner konnte nicht geloescht werden."
        Write-Host "        Bitte alle Dateien im Ordner schliessen und Skript erneut ausfuehren."
        Read-Host "Enter druecken zum Beenden"
        exit 1
    }
}

# 4) Alte ZIP loeschen (falls vorhanden)
if (Test-Path -LiteralPath $ZipPath) {
    Write-Host "[*] Loesche alte ZIP-Datei..."
    Remove-Item -LiteralPath $ZipPath -Force -ErrorAction SilentlyContinue
}

# 5) ZIP von GitHub laden
Write-Host ""
Write-Host "[*] Lade aktuelle Version von GitHub..."
try {
    Invoke-WebRequest -Uri $ZipUrl -OutFile $ZipPath -UseBasicParsing -ErrorAction Stop
} catch {
    Write-Host "    [!] Fehler beim Herunterladen der ZIP-Datei."
    Write-Host "        Bitte Internetverbindung pruefen."
    Read-Host "Enter druecken zum Beenden"
    exit 1
}

# 6) ZIP entpacken
Write-Host "[*] Entpacke ZIP-Datei..."
try {
    Expand-Archive -LiteralPath $ZipPath -DestinationPath $Desktop -Force -ErrorAction Stop
} catch {
    Write-Host "    [!] Fehler beim Entpacken der ZIP-Datei."
    Read-Host "Enter druecken zum Beenden"
    exit 1
}

# 7) Entpackten Ordner richtig benennen (ArduinoEinfuehrung-main -> ArduinoEinfuehrung)
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

# 9) Am Ende GENAU EIN Explorer-Fenster im Zielordner oeffnen
Write-Host ""
Write-Host "[+] Fertig. Oeffne Ordner 'ArduinoEinfuehrung'..."
Start-Process -FilePath 'explorer.exe' -ArgumentList $TargetPath

exit 0
