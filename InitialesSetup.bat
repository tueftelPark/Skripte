@echo off
setlocal enabledelayedexpansion

echo ========================================================
echo   TueftelPark - Initiales Laptop Setup (Skripte)
echo ========================================================
echo.

:: Pfade definieren
set "REPO_URL=https://github.com/tueftelPark/Skripte/archive/refs/heads/main.zip"
set "TEMP_ZIP=%TEMP%\TueftelSkripte.zip"
set "TEMP_EXTRACT=%TEMP%\TueftelSkripte_Extract"
set "DESKTOP_PATH=%USERPROFILE%\Desktop"

:: Alten temporaeren Entpack-Ordner leeren, falls er vom letzten Mal noch existiert
if exist "%TEMP_EXTRACT%" rmdir /S /Q "%TEMP_EXTRACT%"

:: 1. Herunterladen
echo [1/3] Lade Skripte-Repository von GitHub herunter...
curl -L -s -o "%TEMP_ZIP%" "%REPO_URL%"
if %errorlevel% neq 0 (
    echo [FEHLER] Herunterladen fehlgeschlagen. Bitte Internetverbindung pruefen.
    pause
    exit /b
)

:: 2. Entpacken
echo [2/3] Entpacke die heruntergeladene ZIP-Datei...
powershell -command "Expand-Archive -Path '%TEMP_ZIP%' -DestinationPath '%TEMP_EXTRACT%' -Force"

:: 3. Kopieren (.bat Dateien auf den Desktop)
echo [3/3] Platziere alle .bat Dateien auf dem Desktop...
for /R "%TEMP_EXTRACT%" %%F in (*.bat) do (
    copy "%%F" "%DESKTOP_PATH%\" /Y >nul
)

:: 4. Aufraeumen
echo.
echo Raeume temporaere Dateien auf...
if exist "%TEMP_ZIP%" del "%TEMP_ZIP%"
if exist "%TEMP_EXTRACT%" rmdir /S /Q "%TEMP_EXTRACT%"

echo.
echo ========================================================
echo   Skripte erfolgreich auf den Desktop kopiert!
echo ========================================================
echo.
echo Starte nun automatisch die Library-Installation...
echo --------------------------------------------------------

:: 5. Führe das Installations-Skript direkt vom Desktop aus
if exist "%DESKTOP_PATH%\AlleLibrariesInstallieren.bat" (
    call "%DESKTOP_PATH%\AlleLibrariesInstallieren.bat"
) else (
    echo [FEHLER] Die Datei AlleLibrariesInstallieren.bat wurde nicht auf dem Desktop gefunden.
    pause
)