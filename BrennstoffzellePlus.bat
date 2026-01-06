@echo off
setlocal

set "TARGET=%USERPROFILE%\Desktop\BrennstoffzellePlus"

:: Schliesse alle Arduino-IDEs (falls offen)
taskkill /f /im "Arduino IDE.exe" 2>nul
taskkill /f /im "arduino.exe" 2>nul
if %errorlevel% equ 0 (
    echo [+] Arduino IDE erfolgreich geschlossen.
) else (
    echo [!] Arduino IDE war nicht offen.
)

:: Schliesse alle Explorer-Fenster (neu starten)
taskkill /f /im explorer.exe 2>nul
if %errorlevel% equ 0 (
    echo [+] Explorer-Fenster geschlossen - starte Explorer neu...
    timeout /t 1 >nul
    start explorer.exe
) else (
    echo [!] Keine Explorer-Fenster offen.
)

:: Loesche alten Ordner (falls vorhanden)
if exist "%TARGET%" (
    echo [+] Loesche alten "BrennstoffzellePlus"-Ordner...
    rd /s /q "%TARGET%" 2>nul
    if exist "%TARGET%" (
        echo     Fehler: Ordner konnte nicht geloescht werden.
        echo     Bitte schliessen Sie alle offenen Dateien im Ordner.
        pause
        exit /b
    )
)

:: Klone Repo und oeffne Ordner
cd "%USERPROFILE%\Desktop"
git clone https://github.com/tueftelPark/BrennstoffzellePlus.git
cd "%TARGET%"
start .
exit