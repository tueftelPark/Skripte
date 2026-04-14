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
set "SETUP_EXE=%TEMP%\arduino_setup.exe"
:: Dauerhafter Ordner fuer die Web-Icons
set "ICON_DIR=%LOCALAPPDATA%\TueftelPark"

:: --- 1. ARDUINO SCHLIESSEN ---
echo [1/7] Stelle sicher, dass Arduino IDE geschlossen ist...
taskkill /F /IM "Arduino IDE.exe" /T >nul 2>&1
timeout /t 2 >nul

:: --- 2. ARDUINO IDE HERUNTERLADEN ---
echo.
echo [2/7] Ermittle aktuellste Arduino IDE Version...
for /f "delims=" %%I in ('powershell -command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; $release = Invoke-RestMethod -Uri 'https://api.github.com/repos/arduino/arduino-ide/releases/latest'; ($release.assets | ? { $_.name -match 'Windows_64bit\.exe$' }).browser_download_url"') do set "DOWNLOAD_URL=%%I"

if "!DOWNLOAD_URL!"=="" (
    echo [FEHLER] Konnte Download-Link nicht ermitteln. Bitte Internet prüfen.
    pause
    exit /b
)

echo        Lade neueste Arduino IDE herunter...
curl -L -s -o "%SETUP_EXE%" "!DOWNLOAD_URL!"

:: --- 3. INSTALLATION ---
echo.
echo [3/7] Installiere Arduino IDE im Hintergrund...
echo        Das Installationsfenster bleibt unsichtbar. Bitte kurz warten...
start /wait "" "%SETUP_EXE%" /S
echo        -^> Installation abgeschlossen!
echo.

:: --- 4. DESKTOP-VERKNUEPFUNG ARDUINO ---
echo [4/7] Pruefe Arduino-Installation und Desktop-Verknuepfung...
if exist "%ARDUINO_EXE%" (
    powershell -command "$wshell = New-Object -ComObject WScript.Shell; $shortcut = $wshell.CreateShortcut('%DESKTOP_PATH%\Arduino IDE.lnk'); $shortcut.TargetPath = '%ARDUINO_EXE%'; $shortcut.Save()"
    echo        -^> Desktop-Verknuepfung erfolgreich erstellt!
) else (
    echo        -^> [FEHLER] Arduino IDE konnte nicht gefunden werden.
)
echo.

:: --- 5. WEBSEITEN-VERKNUEPFUNGEN ---
echo [5/7] Erstelle Webseiten-Verknuepfungen...
if not exist "%ICON_DIR%" mkdir "%ICON_DIR%"

:: Tinkercad
echo        -^> Tinkercad
curl -L -s -o "%ICON_DIR%\tinkercad.ico" "https://www.tinkercad.com/favicon.ico"
(
    echo [InternetShortcut]
    echo URL=https://www.tinkercad.com/
    echo IconIndex=0
    echo IconFile=%ICON_DIR%\tinkercad.ico
) > "%DESKTOP_PATH%\Tinkercad.url"

:: Tuefteln Feedback
echo        -^> Tuefteln Feedback
curl -L -s -o "%ICON_DIR%\tuefteln.ico" "https://www.tuefteln.com/favicon.ico"
(
    echo [InternetShortcut]
    echo URL=https://www.tuefteln.com/feedback
    echo IconIndex=0
    echo IconFile=%ICON_DIR%\tuefteln.ico
) > "%DESKTOP_PATH%\Tuefteln Feedback.url"
echo.

:: Alten temporaeren Entpack-Ordner leeren, falls er noch existiert
if exist "%TEMP_EXTRACT%" rmdir /S /Q "%TEMP_EXTRACT%"

:: --- 6. SKRIPTE HERUNTERLADEN ---
echo [6/7] Lade Skripte-Repository von GitHub herunter...
curl -L -s -o "%TEMP_ZIP%" "%REPO_URL%"
if %errorlevel% neq 0 (
    echo [FEHLER] Herunterladen fehlgeschlagen. Bitte Internetverbindung pruefen.
    pause
    exit /b
)

echo        Entpacke und kopiere .bat Dateien auf den Desktop...
powershell -command "Expand-Archive -Path '%TEMP_ZIP%' -DestinationPath '%TEMP_EXTRACT%' -Force"
for /R "%TEMP_EXTRACT%" %%F in (*.bat) do (
    copy "%%F" "%DESKTOP_PATH%\" /Y >nul
)

:: --- 7. AUFRAEUMEN ---
echo.
echo [7/7] Raeume temporaere Dateien auf...
if exist "%SETUP_EXE%" del "%SETUP_EXE%"
if exist "%TEMP_ZIP%" del "%TEMP_ZIP%"
if exist "%TEMP_EXTRACT%" rmdir /S /Q "%TEMP_EXTRACT%"

echo.
echo ========================================================
echo   Laptop-Setup (Programme, Skripte & Links) erfolgreich!
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