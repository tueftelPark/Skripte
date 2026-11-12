@echo off
setlocal enabledelayedexpansion

:: Nano-Klone haben einen allgemeinen USB-Chip (CP2102, CH340, ...), der Seeeduino Nano
:: aus dem Kurs LED Matrix z. B. einen CP2102N. Daran erkennt
:: die Arduino IDE das Board nicht und zeigt "Unknown" - die Schueler:innen muessten
:: dann selbst "Arduino Nano" heraussuchen. Eine boards.local.txt neben der
:: boards.txt der Arduino AVR Boards ordnet diese Chips dem Arduino Nano zu.
::
:: Nebenwirkung: JEDES Board mit einem dieser Chips erscheint als "Arduino Nano".
:: Original-UNOs sind nicht betroffen, sie melden sich mit einer eigenen Arduino-Kennung.
::
:: Wird am Ende von SETUP und FULL_RESET aufgerufen und darf beliebig oft laufen.
:: Die IDE liest die Datei beim Start - eine offene IDE also einmal neu starten.
:: Weitere Chips: unten in :datei_schreiben eintragen (naechste freie Nummer).

set "AVR_DIR=%LOCALAPPDATA%\Arduino15\packages\arduino\hardware\avr"
set "IDE_DIR=%LOCALAPPDATA%\Programs\Arduino IDE"

echo ========================================================
echo   Nano-Erkennung einrichten (TueftelPark)
echo ========================================================
echo.

:: 1. Die Arduino AVR Boards (UNO, Nano, ...) muessen installiert sein. Sonst holt
:: die IDE sie erst beim ersten Start - dann gaebe es den Ordner fuer die Datei noch nicht.
echo [1/2] Pruefe die Arduino AVR Boards...
call :avr_vorhanden
if defined AVR_DA (
    echo        -^> Vorhanden.
) else (
    echo        Noch nicht installiert - installiere sie ueber die Arduino IDE...
    set "ARDUINO_CLI="
    if exist "%IDE_DIR%\resources" (
        for /R "%IDE_DIR%\resources" %%F in (arduino-cli.exe) do if exist "%%F" set "ARDUINO_CLI=%%F"
    )
    if not defined ARDUINO_CLI (
        echo        [WARNUNG] Arduino IDE nicht gefunden - Nano-Erkennung uebersprungen.
        goto ende
    )
    "!ARDUINO_CLI!" core update-index >nul 2>&1
    "!ARDUINO_CLI!" core install arduino:avr >nul 2>&1
    call :avr_vorhanden
    if not defined AVR_DA (
        echo        [WARNUNG] Installation fehlgeschlagen ^(Internet?^) - Nano-Erkennung uebersprungen.
        goto ende
    )
    echo        -^> Installiert.
)

:: 2. Die Datei in jede installierte Version schreiben. Bei einem Update der AVR Boards
:: entsteht ein neuer Versionsordner - darum laeuft dieser Schritt bei jedem SETUP.
echo [2/2] Trage die USB-Chips der Nano-Klone ein...
for /D %%V in ("%AVR_DIR%\*") do if exist "%%V\boards.txt" (
    call :datei_schreiben "%%V\boards.local.txt"
    echo        -^> Arduino AVR Boards %%~nxV
)
echo.
echo [ERFOLG] Nano-Klone erscheinen in der Arduino IDE jetzt als "Arduino Nano".
echo          Laeuft die IDE gerade, bitte einmal schliessen und neu oeffnen.

:ende
echo.
exit /b


:: ---------------- Unterprogramme ----------------

:: Setzt AVR_DA, wenn mindestens eine Version der Arduino AVR Boards installiert ist.
:avr_vorhanden
set "AVR_DA="
if exist "%AVR_DIR%" (
    for /D %%V in ("%AVR_DIR%\*") do if exist "%%V\boards.txt" set "AVR_DA=1"
)
exit /b

:: Schreibt die Zuordnung USB-Chip -> Arduino Nano. Die Nummer 0 ist in der
:: boards.txt schon belegt, darum geht es bei 1 los.
:datei_schreiben
(
    echo # Angelegt von NanoErkennung.bat ^(TueftelPark Skripte^) - wird bei jedem SETUP ueberschrieben.
    echo # Nano-Klone mit allgemeinem USB-Chip als "Arduino Nano" erkennen statt als "Unknown".
    echo.
    echo # Silicon Labs CP2102 / CP2102N - steckt im Seeeduino Nano ^(Kurs LED Matrix^)
    echo nano.upload_port.1.vid=0x10C4
    echo nano.upload_port.1.pid=0xEA60
    echo # WCH CH340
    echo nano.upload_port.2.vid=0x1A86
    echo nano.upload_port.2.pid=0x7523
    echo # WCH CH9102 ^(neuere Klone^)
    echo nano.upload_port.3.vid=0x1A86
    echo nano.upload_port.3.pid=0x55D4
    echo # FTDI FT232R ^(aeltere Original-Nanos^)
    echo nano.upload_port.4.vid=0x0403
    echo nano.upload_port.4.pid=0x6001
) > "%~1"
exit /b
