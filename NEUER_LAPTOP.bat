@echo off
setlocal
:: Einmal pro NEUEM Laptop ausfuehren: im Admin-Konto, nach der Windows-Ersteinrichtung.
:: Holt Adminrechte, laedt Einrichtung\NeuerLaptop.ps1 von GitHub und fuehrt es aus.
:: Liegt eine NeuerLaptop.ps1 im selben Ordner (z.B. auf einem USB-Stick zum
:: Testen), wird stattdessen diese verwendet.

net session >nul 2>&1
if errorlevel 1 (
    echo Adminrechte werden angefragt - bitte im naechsten Fenster mit "Ja" bestaetigen.
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

set "PS1=%~dp0NeuerLaptop.ps1"
if not exist "%PS1%" set "PS1=%TEMP%\NeuerLaptop.ps1"
if not exist "%~dp0NeuerLaptop.ps1" (
    echo Lade Einrichtungs-Skript von GitHub...
    curl -fsSL -o "%TEMP%\NeuerLaptop.ps1" "https://raw.githubusercontent.com/tueftelPark/Skripte/main/Einrichtung/NeuerLaptop.ps1"
    if errorlevel 1 (
        echo [FEHLER] Herunterladen fehlgeschlagen. Bitte Internetverbindung pruefen.
        pause
        exit /b
    )
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1%"
if exist "%TEMP%\NeuerLaptop.ps1" del "%TEMP%\NeuerLaptop.ps1"
echo.
pause
