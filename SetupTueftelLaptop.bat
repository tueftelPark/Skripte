@echo off
setlocal enabledelayedexpansion

echo ========================================================
echo   TueftelPark - Initiales Laptop Setup (Vollautomatisch)
echo ========================================================
echo.

:: Pfade definieren
set "REPO_URL=https://github.com/tueftelPark/Skripte/archive/refs/heads/main.zip"
set "TEMP_ZIP=%TEMP%\TueftelSkripte.zip"
set "TEMP_EXTRACT=%TEMP%\TueftelSkripte_Extract"
set "DESKTOP_PATH=%USERPROFILE%\Desktop"
:: Der echte Standard-Pfad fuer Benutzer-Installationen
set "ARDUINO_DIR=%LOCALAPPDATA%\Programs\Arduino IDE"
set "ARDUINO_EXE=%ARDUINO_DIR%\Arduino IDE.exe"

:: --- 1. ARDUINO IDE INSTALLIEREN (Am richtigen Ort) ---
echo [1/5] Pruefe und installiere Arduino IDE...
echo        Das kann je nach Internetgeschwindigkeit dauern.
echo.

:: - Wir erzwingen den echten Installer (--installer-type nullsoft)
:: - Wir geben den exakten Pfad vor (--location)
winget install --id ArduinoSA.IDE.stable --exact --scope user --installer-type nullsoft --location "%ARDUINO_DIR%" --accept-package-agreements --accept-source-agreements

if %errorlevel% neq 0 (
    echo.
    echo [WARNUNG] Winget meldete einen Fehler. Bitte Ausgabe pruefen.
) else (
    echo.
    echo        -^> Installation im Standard-Ordner abgeschlossen!
)
echo.

:: --- 2. DESKTOP-VERKNUEPFUNG SICHERSTELLEN ---
echo [2/5] Pruefe Arduino-Installation und Desktop-Verknuepfung...
if exist "%ARDUINO_EXE%" (
    :: Der echte Installer traegt Arduino bereits ins Startmenue ein (Indexierung funktioniert!). 
    :: Wir legen hier nur noch zur Sicherheit eine Verknuepfung auf dem Desktop ab.
    powershell -command "$wshell = New-Object -ComObject WScript.Shell; $shortcut = $wshell.CreateShortcut('%DESKTOP_PATH%\Arduino IDE.lnk'); $shortcut.TargetPath = '%ARDUINO_EXE%'; $shortcut.Save()"
    echo        -^> Desktop-Verknuepfung erfolgreich erstellt!
) else (
    echo        -^> [FEHLER] Arduino IDE konnte nicht im Verzeichnis %ARDUINO_DIR% gefunden werden.
)
echo.

:: Alten temporaeren Entpack-Ordner leeren, falls er noch existiert
if exist "%TEMP_EXTRACT%" rmdir /S /Q "%TEMP_EXTRACT%"

:: --- 3. SKRIPTE HERUNTERLADEN ---
echo [3/5] Lade Skripte-Repository von GitHub herunter...
curl -L -s -o "%TEMP_ZIP%" "%REPO_URL%"
if %errorlevel% neq 0 (
    echo [FEHLER] Herunterladen fehlgeschlagen. Bitte Internetverbindung pruefen.
    pause
    exit /b
)

:: --- 4. ENTPACKEN & AUF DESKTOP KOPIEREN ---
echo [4/5] Entpacke und kopiere .bat Dateien auf den Desktop...
powershell -command "Expand-Archive -Path '%TEMP_ZIP%' -DestinationPath '%TEMP_EXTRACT%' -Force"
for /R "%TEMP_EXTRACT%" %%F in (*.bat) do (
    copy "%%F" "%DESKTOP_PATH%\" /Y >nul
)

:: --- 5. AUFRAEUMEN ---
echo [5/5] Raeume temporaere Dateien auf...
if exist "%TEMP_ZIP%" del "%TEMP_ZIP%"
if exist "%TEMP_EXTRACT%" rmdir /S /Q "%TEMP_EXTRACT%"

echo.
echo ========================================================
echo   Laptop-Setup (Programme & Skripte) erfolgreich!
echo ========================================================
echo.
echo Starte nun automatisch die Library-Installation...
echo --------------------------------------------------------

:: Führe das Installations-Skript direkt vom Desktop aus
if exist "%DESKTOP_PATH%\AlleLibrariesInstallieren.bat" (
    call "%DESKTOP_PATH%\AlleLibrariesInstallieren.bat"
) else (
    echo [FEHLER] Die Datei AlleLibrariesInstallieren.bat wurde nicht auf dem Desktop gefunden.
    pause
)