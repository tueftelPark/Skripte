@echo off
setlocal enabledelayedexpansion

echo ========================================================
echo   TueftelPark - Initiales Laptop Setup (Vollautomatisch)
echo ========================================================
echo.

:: --- ADMIN-RECHTE PRUEFEN ---
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [FEHLER] Fehlende Administrator-Rechte!
    echo.
    echo Damit die Arduino IDE installiert werden kann, muss dieses
    echo Skript als Administrator gestartet werden.
    echo.
    echo Bitte schliesse dieses Fenster, mache einen Rechtsklick auf
    echo die Datei und waehle "Als Administrator ausfuehren".
    echo ========================================================
    pause
    exit /b
)

:: Pfade definieren
set "REPO_URL=https://github.com/tueftelPark/Skripte/archive/refs/heads/main.zip"
set "TEMP_ZIP=%TEMP%\TueftelSkripte.zip"
set "TEMP_EXTRACT=%TEMP%\TueftelSkripte_Extract"
set "DESKTOP_PATH=%USERPROFILE%\Desktop"

:: --- 1. ARDUINO IDE INSTALLIEREN ---
echo [1/5] Pruefe und installiere Arduino IDE (neueste Version)...
echo        (Das kann einen Moment dauern. Bitte warten...)
:: winget sucht die App "Arduino.IDE", akzeptiert die Lizenz automatisch und installiert/updatet lautlos
winget install --id Arduino.IDE --exact --silent --accept-package-agreements --accept-source-agreements >nul 2>&1
echo        -^> Arduino IDE Check abgeschlossen!
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