@echo off
setlocal

set "TARGET=%USERPROFILE%\Desktop\AutonomesFahrzeug"
set "REPO=https://github.com/tueftelPark/AutonomesFahrzeug.git"

:: Git finden: zuerst das portable Git aus SETUP/FULL_RESET, sonst ein installiertes.
:: Bewusst VOR dem Loeschen pruefen - sonst waere der alte Kursordner weg und kein neuer da.
set "GIT=%LOCALAPPDATA%\TueftelPark\MinGit\cmd\git.exe"
if not exist "%GIT%" set "GIT=git"
"%GIT%" --version >nul 2>&1
if errorlevel 1 (
    echo [FEHLER] Git wurde nicht gefunden.
    echo          Bitte der Kursleitung Bescheid geben: SETUP.bat in Dokumente\TueftelPark Skripte ausfuehren.
    pause
    exit /b
)

:: Schliesse alle Arduino-IDEs (falls offen)
set "ARDUINO_OFFEN="
taskkill /f /im "Arduino IDE.exe" >nul 2>&1 && set "ARDUINO_OFFEN=1"
taskkill /f /im "arduino.exe" >nul 2>&1 && set "ARDUINO_OFFEN=1"
if defined ARDUINO_OFFEN (
    echo [+] Arduino IDE erfolgreich geschlossen.
) else (
    echo [!] Arduino IDE war nicht offen.
)

:: Explorer neu starten, damit er keine Dateien im Kursordner mehr festhaelt
taskkill /f /im explorer.exe >nul 2>&1
echo [+] Explorer wird neu gestartet...
timeout /t 1 >nul
start explorer.exe

:: Loesche alten Ordner (falls vorhanden)
if exist "%TARGET%" (
    echo [+] Loesche alten "AutonomesFahrzeug"-Ordner...
    rd /s /q "%TARGET%" 2>nul
    if exist "%TARGET%" (
        echo     Fehler: Ordner "AutonomesFahrzeug" konnte nicht geloescht werden.
        echo     Moeglicherweise ist noch eine Datei im Ordner geoeffnet.
        echo     Bitte schliessen und Skript erneut ausfuehren.
        pause
        exit /b
    )
)

:: Klone Repo und oeffne Ordner
echo [+] Lade Kurs "AutonomesFahrzeug" herunter...
"%GIT%" clone "%REPO%" "%TARGET%"
if errorlevel 1 (
    echo.
    echo [FEHLER] Der Kurs konnte nicht heruntergeladen werden.
    echo          Bitte Internetverbindung pruefen und Skript erneut ausfuehren.
    pause
    exit /b
)
start "" "%TARGET%"
exit
