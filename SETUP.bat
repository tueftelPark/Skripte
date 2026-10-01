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
:: Setup-Skripte fuer die Kursleitung - auch im Schuelerkonto griffbereit, aber nicht auf dem Desktop
set "SKRIPT_DIR=%USERPROFILE%\Documents\TueftelPark Skripte"
set "SELBST_NEU=%TEMP%\TueftelSelbstUpdate.bat"
set "DESKTOP_PATH=%USERPROFILE%\Desktop"
:: Dauerhafter Ordner fuer die Web-Icons
set "ICON_DIR=%LOCALAPPDATA%\TueftelPark"
:: Portables Git fuer die Kurs-Skripte (MinGit: ein ZIP, kein Installer, keine Adminrechte)
set "GIT_DIR=%LOCALAPPDATA%\TueftelPark\MinGit"
set "GIT_EXE=%GIT_DIR%\cmd\git.exe"
set "GIT_ZIP=%TEMP%\MinGit.zip"
:: Pfad zum Edge-Browser fuer das Ersatz-Icon
set "EDGE_ICON=%ProgramFiles(x86)%\Microsoft\Edge\Application\msedge.exe"
:: Pfad zu Arduino (fuer die Wiederherstellung der Verknuepfung)
set "ARDUINO_EXE=%LOCALAPPDATA%\Programs\Arduino IDE\Arduino IDE.exe"

:: Alten temporaeren Entpack-Ordner leeren, falls er vom letzten Mal noch existiert
if exist "%TEMP_EXTRACT%" rmdir /S /Q "%TEMP_EXTRACT%"
if exist "%SELBST_NEU%" del "%SELBST_NEU%"

:: --- 1. DESKTOP LEEREN (Tabula Rasa) ---
echo [1/6] Leere den aktuellen Desktop...
for %%F in ("%DESKTOP_PATH%\*") do (
    if /I not "%%~nxF"=="%~nx0" del /Q /F "%%F" >nul 2>&1
)
for /D %%D in ("%DESKTOP_PATH%\*") do (
    rmdir /S /Q "%%D" >nul 2>&1
)
echo        -^> Desktop wurde aufgeraeumt!
echo.

:: --- 2. SKRIPTE HERUNTERLADEN & PLATZIEREN ---
echo [2/6] Lade Skripte-Repository von GitHub herunter...
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
echo [3/6] Erstelle Webseiten-Verknuepfungen...
if not exist "%ICON_DIR%" mkdir "%ICON_DIR%"

:: Tinkercad (mit eigenem Icon) - fuehrt direkt zum Beitritt in die Tinkercad-Klasse
echo        -^> Tinkercad
curl -fsSL -o "%ICON_DIR%\tinkercad.ico" "https://www.tinkercad.com/favicon.ico"
echo [InternetShortcut] > "%DESKTOP_PATH%\Tinkercad.url"
echo URL=https://www.tinkercad.com/joinclass/DLFXZMAX37MZ >> "%DESKTOP_PATH%\Tinkercad.url"
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

:: --- 4. ARDUINO VERKNUEPFUNG WIEDERHERSTELLEN ---
echo [4/6] Pruefe Arduino-Installation und erstelle Verknuepfung...
if exist "%ARDUINO_EXE%" (
    powershell -command "$wshell = New-Object -ComObject WScript.Shell; $shortcut = $wshell.CreateShortcut('%DESKTOP_PATH%\Arduino IDE.lnk'); $shortcut.TargetPath = '%ARDUINO_EXE%'; $shortcut.Save()"
    echo        -^> Desktop-Verknuepfung erfolgreich wiederhergestellt!
) else (
    echo        -^> [INFO] Arduino IDE konnte nicht gefunden werden. Verknuepfung uebersprungen.
)
echo.

:: --- 5. GIT (fuer die Kurs-Skripte) ---
:: Die Kurs-Skripte rufen Git ueber den festen Pfad GIT_EXE auf, PATH bleibt unveraendert.
echo [5/6] Pruefe Git (wird von den Kurs-Skripten gebraucht)...
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

:: --- 6. AUFRAEUMEN ---
echo [6/6] Raeume temporaere Dateien auf...
if exist "%TEMP_ZIP%" del "%TEMP_ZIP%"
if exist "%TEMP_EXTRACT%" rmdir /S /Q "%TEMP_EXTRACT%"

echo.
echo ========================================================
echo   Laptop-Setup LIGHT erfolgreich durchgefuehrt!
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
