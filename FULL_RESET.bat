@echo off
setlocal enabledelayedexpansion

echo ========================================================
echo   TueftelPark - Initiales Laptop Setup (Vollautomatisch)
echo ========================================================
echo.

:: --- 0. WARNHINWEIS & BESTAETIGUNG ---
:: Mit /auto ohne Rueckfrage - so startet es NEUER_LAPTOP.bat bei der ersten
:: Anmeldung ins Schuelerkonto, auf einem leeren Desktop.
if /I "%~1"=="/auto" (
    echo [INFO] Automatischer Modus: Rueckfrage uebersprungen.
) else (
    echo   ACHTUNG - DATENVERLUST
    echo   Dieses Skript leert als Erstes den kompletten Desktop^^!
    echo   Alle bisherigen Dateien, Ordner und Verknuepfungen,
    echo   die auf diesem Bildschirm liegen, werden geloescht.
    echo.
    CHOICE /C JN /M "Bist du sicher, dass du den Laptop JETZT neu aufsetzen willst?"
    if errorlevel 2 (
        echo.
        echo [INFO] Setup wurde abgebrochen. Es wurde nichts veraendert.
        pause
        exit /b
    )
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
:: Setup-Skripte fuer die Kursleitung - auch im Schuelerkonto griffbereit, aber nicht auf dem Desktop
set "SKRIPT_DIR=%USERPROFILE%\Documents\TueftelPark Skripte"
set "SELBST_NEU=%TEMP%\TueftelSelbstUpdate.bat"
set "DESKTOP_PATH=%USERPROFILE%\Desktop"
:: Der echte Standard-Pfad fuer Benutzer-Installationen
set "ARDUINO_DIR=%LOCALAPPDATA%\Programs\Arduino IDE"
set "ARDUINO_EXE=%ARDUINO_DIR%\Arduino IDE.exe"
set "UNINSTALLER_EXE=%ARDUINO_DIR%\Uninstall Arduino IDE.exe"
set "SETUP_EXE=%TEMP%\arduino_setup.exe"
:: Dauerhafter Ordner fuer die Web-Icons
set "ICON_DIR=%LOCALAPPDATA%\TueftelPark"
:: Portables Git fuer die Kurs-Skripte (MinGit: ein ZIP, kein Installer, keine Adminrechte)
set "GIT_DIR=%LOCALAPPDATA%\TueftelPark\MinGit"
set "GIT_EXE=%GIT_DIR%\cmd\git.exe"
set "GIT_ZIP=%TEMP%\MinGit.zip"
:: Pfad zum Edge-Browser fuer das Ersatz-Icon
set "EDGE_ICON=%ProgramFiles(x86)%\Microsoft\Edge\Application\msedge.exe"

:: Alten temporaeren Entpack-Ordner leeren, falls er vom letzten Mal noch existiert
if exist "%TEMP_EXTRACT%" rmdir /S /Q "%TEMP_EXTRACT%"
if exist "%SELBST_NEU%" del "%SELBST_NEU%"

:: --- 1. DESKTOP LEEREN (Tabula Rasa) ---
echo [1/10] Leere den aktuellen Desktop...
for %%F in ("%DESKTOP_PATH%\*") do (
    if /I not "%%~nxF"=="%~nx0" del /Q /F "%%F" >nul 2>&1
)
for /D %%D in ("%DESKTOP_PATH%\*") do (
    rmdir /S /Q "%%D" >nul 2>&1
)
echo        -^> Desktop wurde aufgeraeumt!
echo.

:: --- 2. SKRIPTE HERUNTERLADEN & PLATZIEREN ---
echo [2/10] Lade Skripte-Repository von GitHub herunter...
curl -fsSL -o "%TEMP_ZIP%" "%REPO_URL%"
if %errorlevel% neq 0 (
    echo [FEHLER] Herunterladen fehlgeschlagen. Bitte Internetverbindung pruefen.
    pause
    exit /b
)

echo        Entpacke und kopiere die Kurs-Skripte auf den Desktop...
powershell -command "Expand-Archive -Path '%TEMP_ZIP%' -DestinationPath '%TEMP_EXTRACT%' -Force"
:: Auf den Desktop kommen NUR die Skripte aus dem Ordner Kurse\. SETUP, FULL_RESET und
:: AlleLibrariesInstallieren landen in Dokumente\TueftelPark Skripte - griffbereit fuer
:: die Kursleitung, aber nicht dort, wo im Kurs jemand aus Versehen draufklickt.
:: Laeuft dieses Skript selbst aus jenem Ordner, wird es nicht jetzt ueberschrieben
:: (cmd liest Batch-Dateien zeilenweise), sondern erst in der letzten Zeile.
if not exist "%SKRIPT_DIR%" mkdir "%SKRIPT_DIR%"
set "KURS_ANZAHL=0"
for /R "%TEMP_EXTRACT%" %%F in (*.bat) do (
    for %%N in (SETUP.bat FULL_RESET.bat AlleLibrariesInstallieren.bat) do if /I "%%~nxF"=="%%N" (
        if /I "%SKRIPT_DIR%\%%N"=="%~f0" (
            copy "%%F" "%SELBST_NEU%" /Y >nul
        ) else (
            copy "%%F" "%SKRIPT_DIR%\" /Y >nul
        )
    )
    for %%P in ("%%~dpF.") do if /I "%%~nxP"=="Kurse" (
        copy "%%F" "%DESKTOP_PATH%\" /Y >nul
        set /a KURS_ANZAHL+=1
    )
)
echo        -^> !KURS_ANZAHL! Kurs-Skripte auf dem Desktop, Setup-Skripte in Dokumente\TueftelPark Skripte
echo.

:: --- 3. WEBSEITEN-VERKNUEPFUNGEN ---
echo [3/10] Erstelle Webseiten-Verknuepfungen...
if not exist "%ICON_DIR%" mkdir "%ICON_DIR%"

:: Tinkercad (mit eigenem Icon)
echo        -^> Tinkercad
curl -fsSL -o "%ICON_DIR%\tinkercad.ico" "https://www.tinkercad.com/favicon.ico"
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

:: --- 4. ARDUINO IDE HERUNTERLADEN ---
:: Bewusst VOR dem Deinstallieren: scheitert der Download, bleibt die alte Version stehen.
echo [4/10] Ermittle aktuellste Arduino IDE Version...
for /f "delims=" %%I in ('powershell -command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; $release = Invoke-RestMethod -Uri 'https://api.github.com/repos/arduino/arduino-ide/releases/latest'; ($release.assets | ? { $_.name -match 'Windows_64bit\.exe$' }).browser_download_url"') do set "DOWNLOAD_URL=%%I"

if "!DOWNLOAD_URL!"=="" (
    echo [FEHLER] Konnte Download-Link nicht ermitteln. Bitte Internet pruefen.
    pause
    exit /b
)

echo        Lade neueste Arduino IDE herunter...
if exist "%SETUP_EXE%" del "%SETUP_EXE%"
curl -fsSL -o "%SETUP_EXE%" "!DOWNLOAD_URL!"
if %errorlevel% neq 0 (
    echo [FEHLER] Download der Arduino IDE fehlgeschlagen. Bitte Internetverbindung pruefen.
    echo          Die bisherige Arduino IDE wurde nicht angetastet.
    if exist "%SETUP_EXE%" del "%SETUP_EXE%"
    pause
    exit /b
)
echo.

:: --- 5. ARDUINO SCHLIESSEN ---
echo [5/10] Stelle sicher, dass Arduino IDE geschlossen ist...
taskkill /F /IM "Arduino IDE.exe" /T >nul 2>&1
timeout /t 2 >nul

:: --- 6. ARDUINO SAUBER DEINSTALLIEREN ---
echo.
echo [6/10] Pruefe auf alte Arduino Installation...
if exist "%UNINSTALLER_EXE%" (
    echo        Alte Version gefunden. Deinstalliere im Hintergrund...
    :: /S fuer Silent (unsichtbar)
    start /wait "" "%UNINSTALLER_EXE%" /S
    :: Kurze Pause, damit Windows die Dateien in Ruhe loeschen kann
    timeout /t 5 >nul
    :: Loesche den Ordner zur Sicherheit komplett, falls Reste uebrig blieben
    if exist "%ARDUINO_DIR%" rmdir /S /Q "%ARDUINO_DIR%" >nul 2>&1
    echo        -^> Alte Version sauber entfernt!
) else (
    echo        -^> Keine alte Version gefunden.
)

:: --- 7. INSTALLATION ---
echo.
echo [7/10] Installiere Arduino IDE im Hintergrund...
echo        Das Installationsfenster bleibt unsichtbar. Bitte kurz warten...
start /wait "" "%SETUP_EXE%" /S
echo        -^> Installation abgeschlossen!
echo.

:: --- 8. GIT (fuer die Kurs-Skripte) ---
:: Die Kurs-Skripte rufen Git ueber den festen Pfad GIT_EXE auf, PATH bleibt unveraendert.
echo [8/10] Pruefe Git (wird von den Kurs-Skripten gebraucht)...
if exist "%GIT_EXE%" (
    echo        -^> Git ist bereits vorhanden.
) else (
    echo        Ermittle aktuellste Git-Version...
    set "GIT_URL="
    for /f "delims=" %%I in ('powershell -command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; $release = Invoke-RestMethod -Uri 'https://api.github.com/repos/git-for-windows/git/releases/latest'; ($release.assets | ? { $_.name -match 'MinGit-[\d.]+-64-bit\.zip$' }).browser_download_url"') do set "GIT_URL=%%I"
    if defined GIT_URL (
        echo        Lade Git herunter...
        if exist "%GIT_ZIP%" del "%GIT_ZIP%"
        curl -fsSL -o "%GIT_ZIP%" "!GIT_URL!"
        if exist "%GIT_ZIP%" powershell -command "Expand-Archive -Path '%GIT_ZIP%' -DestinationPath '%GIT_DIR%' -Force"
        if exist "%GIT_ZIP%" del "%GIT_ZIP%"
    )
    if exist "%GIT_EXE%" (
        echo        -^> Git erfolgreich installiert!
    ) else (
        echo        -^> [FEHLER] Git konnte nicht installiert werden.
        echo           Die Kurs-Skripte funktionieren erst, wenn dieses Setup
        echo           mit Internetverbindung erneut ausgefuehrt wurde.
        pause
    )
)
echo.

:: --- 9. DESKTOP-VERKNUEPFUNG ARDUINO ---
echo [9/10] Pruefe Arduino-Installation und Desktop-Verknuepfung...
if exist "%ARDUINO_EXE%" (
    powershell -command "$wshell = New-Object -ComObject WScript.Shell; $shortcut = $wshell.CreateShortcut('%DESKTOP_PATH%\Arduino IDE.lnk'); $shortcut.TargetPath = '%ARDUINO_EXE%'; $shortcut.Save()"
    echo        -^> Desktop-Verknuepfung erfolgreich erstellt!
) else (
    echo        -^> [FEHLER] Arduino IDE konnte nicht gefunden werden.
)
echo.

:: --- 10. AUFRAEUMEN ---
echo [10/10] Raeume temporaere Dateien auf...
if exist "%SETUP_EXE%" del "%SETUP_EXE%"
if exist "%TEMP_ZIP%" del "%TEMP_ZIP%"
if exist "%TEMP_EXTRACT%" rmdir /S /Q "%TEMP_EXTRACT%"

echo.
echo ========================================================
echo   Laptop-Setup (Programme, Skripte & Links) erfolgreich!
echo ========================================================
echo.
echo Starte nun automatisch die Library-Installation...
echo --------------------------------------------------------

:: Library-Installation aus Dokumente\TueftelPark Skripte starten
if exist "%SKRIPT_DIR%\AlleLibrariesInstallieren.bat" (
    call "%SKRIPT_DIR%\AlleLibrariesInstallieren.bat"
) else (
    echo [FEHLER] AlleLibrariesInstallieren.bat wurde nicht gefunden.
    pause
)

:: Sich selbst zuletzt aktualisieren. Die ganze Zeile wird gelesen, bevor sie laeuft -
:: das exit /b kommt also an, egal was danach in der neuen Datei steht.
if exist "%SELBST_NEU%" (copy /Y "%SELBST_NEU%" "%~f0" >nul & del "%SELBST_NEU%" & exit /b)
