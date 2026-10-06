@echo off
setlocal

:: Kursname = Ordner auf dem Desktop = Repository auf GitHub.
:: Fuer einen neuen Kurs nur diese Zeile anpassen.
set "KURS=AutonomesFahrzeug"
set "TARGET=%USERPROFILE%\Desktop\%KURS%"
set "REPO=https://github.com/tueftelPark/%KURS%.git"

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

:: Arduino IDE schliessen, falls sie offen ist. Laeuft sie nicht, ist das kein Fehler.
:: /t beendet auch die Hintergrundprozesse der IDE 2 (arduino-cli, Language Server),
:: die sonst Dateien im Kursordner festhalten.
set "ARDUINO_OFFEN="
taskkill /f /t /im "Arduino IDE.exe" >nul 2>&1 && set "ARDUINO_OFFEN=1"
taskkill /f /t /im "arduino.exe" >nul 2>&1 && set "ARDUINO_OFFEN=1"
taskkill /f /im "arduino-cli.exe" >nul 2>&1
taskkill /f /im "arduino-language-server.exe" >nul 2>&1
taskkill /f /im "clangd.exe" >nul 2>&1
if defined ARDUINO_OFFEN (
    echo [+] Arduino IDE geschlossen.
    timeout /t 2 /nobreak >nul
) else (
    echo [+] Arduino IDE war nicht offen - nichts zu schliessen.
)

:: Explorer neu starten, damit er keine Dateien im Kursordner mehr festhaelt.
:: Windows startet ihn manchmal von selbst neu - dann keinen zweiten starten.
echo [+] Explorer wird neu gestartet...
taskkill /f /im explorer.exe >nul 2>&1
timeout /t 2 /nobreak >nul
tasklist /fi "imagename eq explorer.exe" 2>nul | find /i "explorer.exe" >nul || start "" explorer.exe

:: Alten Ordner loeschen (falls vorhanden). Ein paar Versuche, weil Windows
:: Dateien nach dem Beenden von Programmen oft noch kurz gesperrt haelt.
if exist "%TARGET%" (
    echo [+] Loesche alten "%KURS%"-Ordner...
    for /l %%i in (1,1,5) do if exist "%TARGET%" (
        rd /s /q "%TARGET%" >nul 2>&1
        if exist "%TARGET%" timeout /t 1 /nobreak >nul
    )
)
if exist "%TARGET%" (
    echo.
    echo [FEHLER] Ordner "%KURS%" konnte nicht geloescht werden.
    echo          Moeglicherweise ist noch eine Datei daraus geoeffnet.
    echo          Bitte schliessen und Skript erneut ausfuehren.
    pause
    exit /b
)

:: Kurs herunterladen
echo [+] Lade Kurs "%KURS%" herunter...
"%GIT%" clone "%REPO%" "%TARGET%"
if errorlevel 1 (
    echo.
    echo [FEHLER] Der Kurs konnte nicht heruntergeladen werden.
    echo          Bitte Internetverbindung pruefen und Skript erneut ausfuehren.
    pause
    exit /b
)

:: Ordner ausdruecklich mit explorer.exe oeffnen, NICHT mit start "" "<Ordner>":
:: start probiert an einen Pfad ohne Endung .com/.exe/.bat/... anzuhaengen, findet
:: dabei dieses Skript (Desktop\<Kurs>.bat) statt des Ordners und startet es
:: endlos immer wieder neu.
explorer.exe "%TARGET%"
exit
