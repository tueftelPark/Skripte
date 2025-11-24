# ArduinoEinfuehrung.ps1
# Lädt die aktuelle Version des ArduinoEinfuehrung-Repos von GitHub herunter,
# entfernt alte Dateien und öffnet den neuen Ordner auf dem Desktop.

$Desktop    = Join-Path $env:USERPROFILE 'Desktop'
$TargetPath = Join-Path $Desktop 'ArduinoEinfuehrung'
$ZipPath    = Join-Path $Desktop 'ArduinoEinfuehrung.zip'
# Wenn Branch != main → am Ende entsprechend anpassen
$ZipUrl     = 'https://github.com/tueftelPark/ArduinoEinfuehrung/archive/refs/heads/main.zip'

Write-Host "==============================="
Write-Host "  ArduinoEinfuehrung aktualisieren"
Write-Host "==============================="
Write-Host ""

# 1) Arduino IDE schließen
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

# 2) Alle Explorer-Fenster schließen
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

# 3) Alten Ordner löschen — mit Wiederholversuchen
Write-Host ""
if (Test-Path -LiteralPath $TargetPath) {
    Write-Host "[*] Lösche alten 'ArduinoEinfuehrung'-Ordner..."

    $maxTries = 3
    $deleted  = $false

    for ($i = 1; $i -le $maxTries; $i++) {
        try {
            Remove-Item -LiteralPath $TargetPath -Recurse -Force -ErrorAction Stop
            $deleted = $true
            Write-Host "    [+] Ordner wurde gelöscht."
            break
        } catch {
            Write-Host "    [!] Versuch $i: Ordner konnte nicht gelöscht werden."
            if ($i -lt $maxTries) {
                Write-Host "        ➤ Bitte alle Dateien/Programme schließen,"
                Write-Host "          die im Ordner geöffnet sind."
                Read-Host "        Enter drücken, um es erneut zu versuchen"
            }
        }
    }

    if (-not $deleted) {
        Write-Host "    [!] Auch nach mehreren Versuchen blockiert!"
        Write-Host "        Vermutlich ist noch eine Datei geöffnet."
        Read-Host "Enter drücken zum Beenden"
        exit 1
    }
}

# 4) alte ZIP löschen
if (Test-Path -LiteralPath $ZipPath) {
    Remove-Item -LiteralPath $ZipPath -Force -ErrorAction SilentlyContinue
}

# 5) ZIP herunterladen
Write-Host ""
Write-Host "[*] Lade aktuelle Version von GitHub herunter..."
try {
    Invoke-WebRequest -Uri $ZipUrl -OutFile $ZipPath -UseBasicParsing -ErrorAction Stop
} catch {
    Write-Host "    [!] Fehler beim Herunterladen!"
    Write-Host "        Internetverbindung prüfen."
    Read-Host "Enter drücken zum Beenden"
    exit 1
}

# 6) ZIP entpacken
Write-Host "[*] Entpacke ZIP-Datei..."
try {
    Expand-Archive -LiteralPath $ZipPath -DestinationPath $Desktop -Force -ErrorAction Stop
} catch {
    Write-Host "    [!] Fehler beim Entpacken!"
    Read-Host "Enter drücken zum Beenden"
    exit 1
}

# 7) entpackten Ordner korrekt benennen
$UnzippedFolder = Join-Path $Desktop 'ArduinoEinfuehrung-main'
if (Test-Path -LiteralPath $UnzippedFolder) {
    Rename-Item -LiteralPath $UnzippedFolder -NewName 'ArduinoEinfuehrung'
}

# 8) ZIP entfernen
if (Test-Path -LiteralPath $ZipPath) {
    Remove-Item -LiteralPath $ZipPath -Force -ErrorAction SilentlyContinue
}

# 9) Zielordner öffnen — genau ein Explorer-Fenster
Write-Host ""
Write-Host "[+] Fertig ✅ Öffne ArduinoEinfuehrung..."
Start-Process -FilePath 'explorer.exe' -ArgumentList $TargetPath

exit 0
