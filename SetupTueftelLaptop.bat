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

:: --- 1. ARDUINO IDE HERUNTERLADEN (Bypass Winget) ---
echo [1/5] Ermittle aktuellste Arduino IDE Version...
:: Fragt die offizielle API nach dem Link zur neuesten .exe Datei
for /f "delims=" %%I in ('powershell -command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; $release = Invoke-RestMethod -Uri 'https://api.github.com/repos/arduino/arduino-ide/releases/latest'; ($release.assets | ? { $_.name -match 'Windows_64bit\.exe$' }).browser_download_url"') do set "DOWNLOAD_URL=%%I"

if "!DOWNLOAD_URL!"=="" (
    echo [FEHLER] Konnte Download-Link nicht ermitteln. Bitte Internet prüfen.
    pause
    exit /b
)

echo.
echo Lade neueste Arduino IDE herunter...
curl -L -o "%SETUP_EXE%" "!DOWNLOAD_URL!"

:: --- 2. INSTALLATION ---
echo.
echo [2/5] Installiere Arduino IDE im Hintergrund...
echo        Das Installationsfenster bleibt unsichtbar. Bitte kurz warten...
:: /S ist der Befehl fuer den echten Installer, um ohne Fragen im Hintergrund zu arbeiten
start /wait "" "%SETUP_EXE%" /S

echo        -^> Installation im Standard-Ordner abgeschlossen!
echo.

:: --- 3. DESKTOP-VERKNUEPFUNG SICHERSTELLEN ---
echo [3/5] Pruefe Arduino-Installation und Desktop-Verknuepfung...
if exist "%ARDUINO_EXE%" (
    :: Der echte Installer hat es nun ins Startmenue gepackt. Wir legen nur noch den Desktop-Shortcut an.
    powershell -command "$wshell = New-Object -ComObject WScript.Shell; $shortcut = $wshell.CreateShortcut('%DESKTOP_PATH%\Arduino IDE.lnk'); $shortcut.TargetPath = '%ARDUINO_EXE%'; $shortcut.Save()"
    echo        -^> Desktop-Verknuepfung erfolgreich erstellt!
) else (
    echo        -^> [FEHLER] Arduino IDE konnte nicht im Verzeichnis %ARDUINO_DIR% gefunden werden.
)
echo.

:: Alten temporaeren Entpack-Ordner leeren, falls er noch existiert
if exist "%TEMP_EXTRACT%" rmdir /S /Q "%TEMP_EXTRACT%"

:: --- 4. SKRIPTE HERUNTERLADEN ---
echo [4/5] Lade Skripte-Repository von GitHub herunter...
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

:: --- 5. AUFRAEUMEN ---
echo.
echo [5/5] Raeume temporaere Dateien auf...
if exist "%SETUP_EXE%" del "%SETUP_EXE%"
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