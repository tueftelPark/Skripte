@echo off
setlocal enabledelayedexpansion

echo ========================================================
echo   TueftelPark - Laptop Setup LIGHT (Desktop & Skripte)
echo ========================================================
echo.

:: --- 0. WARNHINWEIS & BESTAETIGUNG ---
echo   !!! ACHTUNG - DATENVERLUST !!!
echo   Dieses Skript leert als Erstes den kompletten Desktop!
echo   Alle bisherigen Dateien, Ordner und Verknuepfungen,
echo   die auf diesem Bildschirm liegen, werden geloescht.
echo.
CHOICE /C JN /M "Bist du sicher, dass du den Desktop JETZT neu aufsetzen willst?"
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
:: Dauerhafter Ordner fuer die Web-Icons
set "ICON_DIR=%LOCALAPPDATA%\TueftelPark"
:: Pfad zum Edge-Browser fuer das Ersatz-Icon
set "EDGE_ICON=%ProgramFiles(x86)%\Microsoft\Edge\Application\msedge.exe"

:: Alten temporaeren Entpack-Ordner leeren, falls er vom letzten Mal noch existiert
if exist "%TEMP_EXTRACT%" rmdir /S /Q "%TEMP_EXTRACT%"

:: --- 1. DESKTOP LEEREN (Tabula Rasa) ---
echo [1/4] Leere den aktuellen Desktop...
for %%F in ("%DESKTOP_PATH%\*") do (
    if /I not "%%~nxF"=="%~nx0" del /Q /F "%%F" >nul 2>&1
)
for /D %%D in ("%DESKTOP_PATH%\*") do (
    rmdir /S /Q "%%D" >nul 2>&1
)
echo        -^> Desktop wurde aufgeraeumt!
echo.

:: --- 2. SKRIPTE HERUNTERLADEN & PLATZIEREN ---
echo [2/4] Lade Skripte-Repository von GitHub herunter...
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

:: --- 3. WEBSEITEN-VERKNUEPFUNGEN ---
echo [3/4] Erstelle Webseiten-Verknuepfungen...
if not exist "%ICON_DIR%" mkdir "%ICON_DIR%"

:: Tinkercad (mit eigenem Icon)
echo        -^> Tinkercad
curl -L -s -o "%ICON_DIR%\tinkercad.ico" "https://www.tinkercad.com/favicon.ico"
echo [InternetShortcut] > "%DESKTOP_PATH%\Tinkercad.url"
echo URL=https://www.tinkercad.com/ >> "%DESKTOP_PATH%\Tinkercad.url"
echo IconIndex=0 >> "%DESKTOP_PATH%\Tinkercad.url"
echo IconFile=%ICON_DIR%\tinkercad.ico >> "%DESKTOP_PATH%\Tinkercad.url"

:: Tuefteln Feedback (Nutzt das Symbol des Edge-Browsers)
echo        -^> Tuefteln Feedback
echo [InternetShortcut] > "%DESKTOP_PATH%\Tuefteln Feedback.url"
echo URL=https://www.tuefteln.com/feedback >> "%DESKTOP_PATH%\Tuefteln Feedback.url"
echo IconIndex=0 >> "%DESKTOP_PATH%\Tuefteln Feedback.url"
echo IconFile=%EDGE_ICON% >> "%DESKTOP_PATH%\Tuefteln Feedback.url"

:: Tuefteln Start (Nutzt ebenfalls das Symbol des Edge-Browsers)
echo        -^> Tuefteln Start
echo [InternetShortcut] > "%DESKTOP_PATH%\Tuefteln Start.url"
echo URL=https://www.tuefteln.com/start >> "%DESKTOP_PATH%\Tuefteln Start.url"
echo IconIndex=0 >> "%DESKTOP_PATH%\Tuefteln Start.url"
echo IconFile=%EDGE_ICON% >> "%DESKTOP_PATH%\Tuefteln Start.url"
echo.

:: --- 4. AUFRAEUMEN ---
echo [4/4] Raeume temporaere Dateien auf...
if exist "%TEMP_ZIP%" del "%TEMP_ZIP%"
if exist "%TEMP_EXTRACT%" rmdir /S /Q "%TEMP_EXTRACT%"

echo.
echo ========================================================
echo   Laptop-Setup LIGHT erfolgreich durchgefuehrt!
echo ========================================================
echo.
echo Starte nun automatisch die Library-Installation...
echo --------------------------------------------------------

:: --- 5. LIBRARIES INSTALLIEREN ---
:: Führe das Installations-Skript direkt vom Desktop aus
if exist "%DESKTOP_PATH%\AlleLibrariesInstallieren.bat" (
    call "%DESKTOP_PATH%\AlleLibrariesInstallieren.bat"
) else (
    echo [FEHLER] Die Datei AlleLibrariesInstallieren.bat wurde nicht auf dem Desktop gefunden.
    pause
)