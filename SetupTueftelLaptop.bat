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

:: --- 1. ARDUINO IDE INSTALLIEREN (Ohne Admin-Rechte) ---
echo [1/5] Pruefe und installiere Arduino IDE...
echo        Das kann je nach Internetgeschwindigkeit dauern.
echo        Download-Fortschritt wird unten angezeigt...
echo.

:: Parameter --scope user zwingt die Installation in das Benutzerprofil (kein Admin noetig)
winget install --id ArduinoSA.IDE.stable --exact --scope user --accept-package-agreements --accept-source-agreements

if %errorlevel% neq 0 (
    echo.
    echo [WARNUNG] Winget konnte Arduino nicht installieren. 
    echo           Bitte pruefe die Fehlermeldung oberhalb.
    pause
) else (
    echo.
    echo        -^> Arduino IDE Check / Installation abgeschlossen!
)
echo.

:: Alten temporaeren Entpack-Ordner leeren, falls er noch existiert
if exist "%TEMP_EXTRACT%" rmdir /S /Q "%TEMP_EXTRACT%"

:: --- 2. SKRIPTE HERUNTERLADEN ---
echo [2/5] Lade Skripte-Repository von GitHub herunter...
curl -L -s -o "%TEMP_ZIP%" "%REPO_URL%"
if %errorlevel% neq 0 (
    echo [FEHLER] Herunterladen fehlgeschlagen. Bitte Internetverbindung pruefen.
    pause
    exit /b
)

:: --- 3. ENTPACKEN ---
echo [3/5] Entpacke die heruntergeladene ZIP-Datei...
powershell -command "Expand-Archive -Path '%TEMP_ZIP%' -DestinationPath '%TEMP_EXTRACT%' -Force"

:: --- 4. KOPIEREN AUF DESKTOP ---
echo [4/5] Platziere alle .bat Dateien auf dem Desktop...
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