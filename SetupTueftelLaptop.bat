@echo off
setlocal enabledelayedexpansion

echo ========================================================
echo   TueftelPark - Initiales Laptop Setup (Vollautomatisch)
echo ========================================================
echo.

:: --- 0. WARNHINWEIS & BESTAETIGUNG ---
echo   !!! ACHTUNG - DATENVERLUST !!!
echo   Dieses Skript leert als Erstes den kompletten Desktop!
echo   Alle bisherigen Dateien, Ordner und Verknuepfungen,
echo   die auf diesem Bildschirm liegen, werden geloescht.
echo.
CHOICE /C JN /M "Bist du sicher, dass du den Laptop JETZT neu aufsetzen willst?"
if errorlevel 2 (
    echo.
    echo [INFO] Setup wurde abgebrochen. Es wurde nichts veraendert.
    pause
    exit /b
)
echo.
echo ========================================================
echo Setup startet...
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
:: Pfad zum Edge-Browser fuer das Ersatz-Icon
set "EDGE_ICON=%ProgramFiles(x86)%\Microsoft\Edge\Application\msedge.exe"

:: Alten temporaeren Entpack-Ordner leeren, falls er vom letzten Mal noch existiert
if exist "%TEMP_EXTRACT%" rmdir /S /Q "%TEMP_EXTRACT%"

:: --- 1. DESKTOP LEEREN (Tabula Rasa) ---
echo [1/8] Leere den aktuellen Desktop...
:: Geht alle Dateien durch und loescht sie, AUSSER dieses Skript selbst (%~nx0)
for %%F in ("%DESKTOP_PATH%\*") do (
    if /I not "%%~nxF"=="%~nx0" del /Q /F "%%F" >nul 2>&1
)
:: Loescht zusaetzlich alle Unterordner auf dem Desktop
for /D %%D in ("%DESKTOP_PATH%\*") do (
    rmdir /S /Q "%%D" >nul 2>&1
)
echo        -^> Desktop wurde aufgeraeumt!
echo.

:: --- 2. SKRIPTE HERUNTERLADEN & PLATZIEREN ---
echo [2/8] Lade Skripte-Repository von GitHub herunter...
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
echo        -^> Skripte erfolgreich platziert!
echo.

:: --- 3. ARDUINO SCHLIESSEN ---
echo [3/8] Stelle sicher, dass Arduino IDE geschlossen ist...
taskkill /F /IM "Arduino IDE.exe" /T >nul 2>&1
timeout /t 2 >nul

:: --- 4. ARDUINO IDE HERUNTERLADEN ---
echo.
echo [4/8] Ermittle aktuellste Arduino IDE Version...
for /f "delims=" %%I in ('powershell -command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; $release = Invoke-RestMethod -Uri 'https://api.github.com/repos/arduino/arduino-ide/releases/latest'; ($release.assets | ? { $_.name -match 'Windows_64bit\.exe$' }).browser_download_url"') do set "DOWNLOAD_URL=%%I"

if "!DOWNLOAD_URL!"=="" (
    echo [FEHLER] Konnte Download-Link nicht ermitteln. Bitte Internet prüfen.
    pause
    exit /b
)

echo        Lade neueste Arduino IDE herunter...
curl -L -s -o "%SETUP_EXE%" "!DOWNLOAD_URL!"

:: --- 5. INSTALLATION ---
echo.
echo [5/8] Installiere Arduino IDE im Hintergrund...
echo        Das Installationsfenster bleibt unsichtbar. Bitte kurz warten...
start /wait "" "%SETUP_EXE%" /S
echo        -^> Installation abgeschlossen!
echo.

:: --- 6. DESKTOP-VERKNUEPFUNG ARDUINO ---
echo [6/8] Pruefe Arduino-Installation und Desktop-Verknuepfung...
if exist "%ARDUINO_EXE%" (
    powershell -command "$wshell = New-Object -ComObject WScript.Shell; $shortcut = $wshell.CreateShortcut('%DESKTOP_PATH%\Arduino IDE.lnk'); $shortcut.TargetPath = '%ARDUINO_EXE%'; $shortcut.Save()"
    echo        -^> Desktop-Verknuepfung erfolgreich erstellt!
) else (
    echo        -^> [FEHLER] Arduino IDE konnte nicht gefunden werden.
)
echo.

:: --- 7. WEBSEITEN-VERKNUEPFUNGEN ---
echo [7/8] Erstelle Webseiten-Verknuepfungen...
if not exist "%ICON_DIR%" mkdir "%ICON_DIR%"

:: Tinkercad (mit eigenem Icon)
echo        -^> Tinkercad
curl -L -s -o "%ICON_DIR%\tinkercad.ico" "https://www.tinkercad.com/favicon.ico"
echo [InternetShortcut] > "%DESKTOP_PATH%\Tinkercad.url"
echo URL=https://www.tinkercad.com/ >> "%DESKTOP_PATH%\Tinkercad.url"
echo IconIndex=0 >> "%DESKTOP_PATH%\Tinkercad.url"
echo IconFile=%ICON_DIR%\tinkercad.ico >> "%DESKTOP_PATH%\Tinkercad.url"

:: Tuefteln Feedback (Nutzt nun das Symbol des Edge-Browsers - Zeile fuer Zeile generiert)
echo        -^> Tuefteln Feedback
echo [InternetShortcut] > "%DESKTOP_PATH%\Tuefteln Feedback.url"
echo URL=https://www.tuefteln.com/feedback >> "%DESKTOP_PATH%\Tuefteln Feedback.url"
echo IconIndex=0 >> "%DESKTOP_PATH%\Tuefteln Feedback.url"
echo IconFile=%EDGE_ICON% >> "%DESKTOP_PATH%\Tuefteln Feedback.url"
echo.

:: --- 8. AUFRAEUMEN ---
echo [8/8] Raeume temporaere Dateien auf...
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