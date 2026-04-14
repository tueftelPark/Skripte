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

:: --- 1. ARDUINO IDE INSTALLIEREN ---
echo [1/6] Pruefe und installiere Arduino IDE...
echo        Das kann je nach Internetgeschwindigkeit dauern.
echo        Download-Fortschritt wird unten angezeigt...
echo.

winget install --id ArduinoSA.IDE.stable --exact --scope user --accept-package-agreements --accept-source-agreements

if %errorlevel% neq 0 (
    echo.
    echo [WARNUNG] Winget konnte Arduino nicht installieren. 
    pause
) else (
    echo.
    echo        -^> Arduino IDE Check / Installation abgeschlossen!
)
echo.

:: --- 2. DESKTOP-VERKNUEPFUNG FUER ARDUINO ERSTELLEN ---
echo [2/6] Suche Arduino und erstelle Verknuepfung...
:: Der Standardpfad fuer die User-Installation
set "ARDUINO_EXE=%LOCALAPPDATA%\Programs\Arduino IDE\Arduino IDE.exe"

if exist "!ARDUINO_EXE!" (
    :: Nutzt einen kurzen PowerShell-Befehl, um den Shortcut zu erzeugen
    powershell -command "$wshell = New-Object -ComObject WScript.Shell; $shortcut = $wshell.CreateShortcut('%DESKTOP_PATH%\Arduino IDE.lnk'); $shortcut.TargetPath = '!ARDUINO_EXE!'; $shortcut.Save()"
    echo        -^> Verknuepfung auf dem Desktop erstellt!
) else (
    echo        -^> [INFO] Arduino wurde evtl. in einem anderen Pfad installiert.
)
echo.

:: Alten temporaeren Entpack-Ordner leeren, falls er noch existiert
if exist "%TEMP_EXTRACT%" rmdir /S /Q "%TEMP_EXTRACT%"

:: --- 3. SKRIPTE HERUNTERLADEN ---
echo [3/6] Lade Skripte-Repository von GitHub herunter...
curl -L -s -o "%TEMP_ZIP%" "%REPO_URL%"
if %errorlevel% neq 0 (
    echo [FEHLER] Herunterladen fehlgeschlagen. Bitte Internetverbindung pruefen.
    pause
    exit /b
)

:: --- 4. ENTPACKEN ---
echo [4/6] Entpacke die heruntergeladene ZIP-Datei...
powershell -command "Expand-Archive -Path '%TEMP_ZIP%' -DestinationPath '%TEMP_EXTRACT%' -Force"

:: --- 5. KOPIEREN AUF DESKTOP ---
echo [5/6] Platziere alle .bat Dateien auf dem Desktop...
for /R "%TEMP_EXTRACT%" %%F in (*.bat) do (
    copy "%%F" "%DESKTOP_PATH%\" /Y >nul
)

:: --- 6. AUFRAEUMEN ---
echo [6/6] Raeume temporaere Dateien auf...
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