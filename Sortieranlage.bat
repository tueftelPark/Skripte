@echo off
setlocal

set "TARGET=%USERPROFILE%\Desktop\Sortieranlage"

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

:: Ordner pruefen und ggf. loeschen
if exist "%TARGET%" (
    echo [+] Versuche, alten Ordner zu loeschen...
    rd /s /q "%TARGET%" 2>nul
    if exist "%TARGET%" (
        echo     Fehler: Ordner "Sortieranlage" konnte nicht geloescht werden.
        echo     Moeglicherweise ist noch eine Datei im Ordner geoeffnet.
        echo     Bitte schliessen und Skript erneut ausfuehren.
        pause
        exit /b
    )
)

:: Klonen
cd "%USERPROFILE%\Desktop"
git clone https://github.com/tueftelPark/Sortieranlage.git

:: Oeffnen
cd "%TARGET%"
start .
exit
