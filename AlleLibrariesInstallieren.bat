@echo off
echo ========================================================
echo   Starte Arduino Library Update (TueftelPark)...
echo ========================================================
echo.
echo Verbinde mit GitHub und lade den aktuellen Installer...

:: Die URL zur "Raw" (reiner Text) Version deines Skripts auf GitHub
:: WICHTIG: Das setzt voraus, dass die Datei genau "InstallLibraries.bat" heisst 
:: und direkt im Hauptverzeichnis des 'main' Branches liegt.
set "SCRIPT_URL=https://raw.githubusercontent.com/tueftelPark/ArduinoKomponentenLibrariesSammlung/main/InstallLibraries.bat"
set "TEMP_SCRIPT=%TEMP%\InstallLibraries_Temp.bat"

:: 1. Nur das Skript herunterladen (via curl)
curl -L -s -o "%TEMP_SCRIPT%" "%SCRIPT_URL%"

if %errorlevel% neq 0 (
    echo.
    echo [FEHLER] Konnte das Skript nicht von GitHub abrufen.
    echo Bitte Internetverbindung pruefen.
    pause
    exit /b
)

:: 2. Das heruntergeladene Skript ausfuehren
echo.
echo Starte eigentliche Installation...
echo --------------------------------------------------------
call "%TEMP_SCRIPT%"
echo --------------------------------------------------------

:: 3. Den temporaeren Launcher wieder loeschen
del "%TEMP_SCRIPT%"