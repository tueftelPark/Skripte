# NeuerLaptop.ps1 - richtet einen nagelneuen Windows-11-Kurslaptop ein.
# Start ueber NEUER_LAPTOP.bat (holt die Adminrechte und dieses Skript).
#
#   0. Fragen (Schuelerkonto, Passwort, Geraetename) - danach laeuft alles allein
#   1. Schuelerkonto anlegen (Standardbenutzer ohne Adminrechte)
#   2. Vorinstalliertes entfernen (Werbe-Apps, McAfee)
#   3. OneDrive-Umleitung, Werbung, Edge-Begruessung, Datenschutz-Abfrage aus
#   4. Windows-Updates: kein Neustart waehrend der Kurszeiten
#   5. Neue Benutzerprofile vorbereiten: bei der ersten Anmeldung ins
#      Schuelerkonto laeuft FULL_RESET.bat automatisch (Arduino, Git,
#      Libraries, Desktop). Arduino & Co. bleiben bewusst pro Benutzer
#      installiert - so arbeiten SETUP.bat und FULL_RESET.bat spaeter gleich.
#
# Darf mehrfach laufen: Erledigtes wird erkannt und uebersprungen.
# Nur ASCII in dieser Datei: PowerShell 5.1 liest Dateien ohne BOM als ANSI.

# ---------------- Einstellungen ----------------
$StandardKonto = 'Tuefteln'
$AktivVon      = 7    # In diesem Zeitfenster startet Windows nicht fuer Updates neu
$AktivBis      = 20   # (Windows erlaubt hoechstens 18 Stunden)
$FullResetUrl  = 'https://raw.githubusercontent.com/tueftelPark/Skripte/main/FULL_RESET.bat'
$McafeeToolUrl = 'https://download.mcafee.com/molbin/iss-loc/SupportTools/MCPR/MCPR.exe'
$Ordner        = 'C:\ProgramData\TueftelPark'

# Apps, die entfernt werden (Platzhalter * erlaubt). Bewusst NICHT dabei:
# Store, Rechner, Fotos, Paint, Editor, Kamera, Snipping Tool, Medienwiedergabe,
# Quick Assist (Fernhilfe), Lenovo Vantage und die Lenovo-Treiber-Apps.
$WegApps = @(
    'Microsoft.BingNews', 'Microsoft.BingWeather', 'Microsoft.BingSearch',
    'Microsoft.GamingApp', 'Microsoft.XboxApp', 'Microsoft.Xbox.TCUI',
    'Microsoft.XboxGamingOverlay', 'Microsoft.XboxSpeechToTextOverlay',
    'Microsoft.MicrosoftSolitaireCollection', 'Microsoft.GetHelp', 'Microsoft.Getstarted',
    'Microsoft.WindowsFeedbackHub', 'Microsoft.People', 'Microsoft.YourPhone',
    'Microsoft.ZuneVideo', 'Microsoft.MicrosoftOfficeHub', 'Microsoft.Todos',
    'Microsoft.OutlookForWindows', 'Microsoft.Windows.DevHome', 'Microsoft.549981C3F5F10',
    'MicrosoftTeams', 'MSTeams', 'Clipchamp.Clipchamp',
    '*CandyCrush*', '*king.com*', '*Spotify*', '*Disney*', '*TikTok*', '*Facebook*',
    '*Instagram*', '*LinkedIn*', '*AmazonVideo*', '*Netflix*', '*McAfee*'
)
# ------------------------------------------------

$ErrorActionPreference = 'Stop'
$script:Warnungen = @()
$NeustartNoetig = $false

function Schritt($Text) { Write-Host ''; Write-Host "=== $Text ===" -ForegroundColor Cyan }
function Ok($Text)      { Write-Host "  -> $Text" -ForegroundColor Green }
function Info($Text)    { Write-Host "  -> $Text" }
function Warnung($Text) { Write-Host "  [!] $Text" -ForegroundColor Yellow; $script:Warnungen += $Text }

# Registry ueber reg.exe statt ueber den PowerShell-Provider: der haelt Handles
# offen, und dann laesst sich das Default-Profil (Schritt 5) nicht mehr entladen.
# Externe Programme (reg.exe, winget) ohne Ausgabe ausfuehren. Noetig, weil
# PowerShell 5.1 bei ErrorActionPreference=Stop sonst abbricht, sobald das
# Programm etwas auf stderr schreibt - auch wenn die Ausgabe umgeleitet ist.
# Ergebnis steht danach wie gewohnt in $LASTEXITCODE.
function Leise([string]$Programm, [string[]]$Argumente) {
    $alt = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
    try { & $Programm @Argumente *> $null } finally { $ErrorActionPreference = $alt }
}

function Set-Reg($Pfad, $Name, $Wert, $Typ = 'REG_DWORD') {
    Leise reg.exe @('add', $Pfad, '/v', $Name, '/t', $Typ, '/d', "$Wert", '/f')
    if ($LASTEXITCODE -ne 0) { Warnung "Registry-Wert $Pfad\$Name konnte nicht gesetzt werden." }
}

function Get-Programme($Muster) {
    $pfade = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
             'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
    Get-ItemProperty $pfade -ErrorAction SilentlyContinue |
        Where-Object { $_.DisplayName -like $Muster } |
        Sort-Object DisplayName -Unique
}

$istAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $istAdmin) {
    Write-Host 'Bitte ueber NEUER_LAPTOP.bat starten - das Skript braucht Adminrechte.' -ForegroundColor Red
    exit 1
}

New-Item -ItemType Directory -Path $Ordner -Force | Out-Null
Start-Transcript -Path "$Ordner\Einrichtung.log" -Append | Out-Null

Write-Host '========================================================'
Write-Host '  TueftelPark - Neuen Kurslaptop einrichten'
Write-Host '========================================================'
$os  = Get-CimInstance Win32_OperatingSystem
$cs  = Get-CimInstance Win32_ComputerSystemProduct
$sn  = (Get-CimInstance Win32_BIOS).SerialNumber
Write-Host "  Geraet:       $($cs.Version) ($($cs.Name))"
Write-Host "  Seriennummer: $sn"
Write-Host "  Windows:      $($os.Caption) $($os.Version)"
Write-Host "  Geraetename:  $env:COMPUTERNAME"

# ---------------- 0. Fragen ----------------
Schritt '0/5  Angaben (danach laeuft alles allein)'

$NeuerName = Read-Host "  Neuer Geraetename, z.B. TP-LAPTOP-07 (Enter = '$env:COMPUTERNAME' behalten)"
if (-not [string]::IsNullOrWhiteSpace($NeuerName)) {
    if ($NeuerName -notmatch '^[A-Za-z0-9-]{1,15}$') {
        Warnung "Geraetename '$NeuerName' ungueltig (nur Buchstaben, Ziffern, Bindestrich, max. 15 Zeichen) - bleibt unveraendert."
        $NeuerName = ''
    }
}
$Geraetenamen = @($env:COMPUTERNAME, $NeuerName) | Where-Object { $_ }

# Reste eines frueheren Laufs aufraeumen: ein von uns angelegtes, nie benutztes
# Konto, das wie das Geraet heisst (siehe unten), ist unbrauchbar.
foreach ($alt in (Get-LocalUser | Where-Object { $_.Description -eq 'TueftelPark Kurskonto' -and $Geraetenamen -contains $_.Name })) {
    if (-not (Get-CimInstance Win32_UserProfile | Where-Object { $_.SID -eq $alt.SID.Value })) {
        Remove-LocalUser -SID $alt.SID
        Info "Unbrauchbares Konto '$($alt.Name)' aus einem frueheren Lauf entfernt (hiess wie das Geraet)."
    }
}

do {
    $eingabe = Read-Host "  Name des Schuelerkontos (Enter = $StandardKonto)"
    if ([string]::IsNullOrWhiteSpace($eingabe)) { $eingabe = $StandardKonto }
    # Keine Umlaute: der Name wird in der Batch-Datei mit %USERNAME% verglichen,
    # und die Konsole versteht Umlaute je nach Codepage anders.
    $gueltig = $eingabe -match '^[A-Za-z0-9][A-Za-z0-9._-]{0,19}$'
    if (-not $gueltig) {
        Write-Host '  Nur Buchstaben ohne Umlaute, Ziffern, Punkt, Bindestrich und Unterstrich, hoechstens 20 Zeichen.' -ForegroundColor Yellow
    } elseif ($Geraetenamen -contains $eingabe) {
        # Windows verwechselt das Konto sonst mit dem Geraet selbst (so gescheitert
        # auf CAD98 mit Konto "cad98"); die Ersteinrichtung verbietet es ebenso.
        Write-Host "  Das Konto darf nicht wie das Geraet heissen ('$eingabe'). Z.B. '$eingabe-kurs' oder 'Tuefteln' nehmen." -ForegroundColor Yellow
        $gueltig = $false
    }
} until ($gueltig)
$Konto = $eingabe

$kontoObjekt = Get-LocalUser -Name $Konto -ErrorAction SilentlyContinue
$Passwort = $null
if (-not $kontoObjekt) {
    $Passwort = Read-Host "  Passwort fuer '$Konto' (Enter = kein Passwort)" -AsSecureString
}

# ---------------- 1. Schuelerkonto ----------------
Schritt "1/5  Schuelerkonto '$Konto'"
# Gruppen ueber die SID statt ueber den Namen: auf Deutsch heissen sie "Benutzer"
# und "Administratoren". Auch das Mitglied geben wir als SID an - ein Name kann
# mehrdeutig sein.
$benutzerGruppe = Get-LocalGroup -SID 'S-1-5-32-545'
$adminGruppe    = Get-LocalGroup -SID 'S-1-5-32-544'
# Get-LocalGroupMember scheitert bei verwaisten Eintraegen in der Gruppe - dann leer
function Ist-Mitglied($Gruppe, $Sid) {
    $mitglieder = try { Get-LocalGroupMember -Group $Gruppe } catch { @() }
    [bool]($mitglieder | Where-Object { $_.SID -eq $Sid })
}

if ($kontoObjekt) {
    Info "Konto gibt es schon - Name und Passwort bleiben unveraendert."
    if (Ist-Mitglied $adminGruppe $kontoObjekt.SID) {
        Warnung "Konto '$Konto' hat Adminrechte. Fuer ein Schuelerkonto unbedingt entfernen."
    }
    if (Get-CimInstance Win32_UserProfile | Where-Object { $_.SID -eq $kontoObjekt.SID.Value }) {
        Warnung "Konto '$Konto' war schon angemeldet - die automatische Einrichtung bei der ersten Anmeldung greift dort nicht mehr. FULL_RESET.bat im Konto von Hand ausfuehren."
    }
} else {
    $beschreibung = 'TueftelPark Kurskonto'
    if ($Passwort.Length -eq 0) {
        $kontoObjekt = New-LocalUser -Name $Konto -NoPassword -Description $beschreibung
    } else {
        $kontoObjekt = New-LocalUser -Name $Konto -Password $Passwort -Description $beschreibung
    }
    Set-LocalUser -SID $kontoObjekt.SID -PasswordNeverExpires $true
    Ok "Standardkonto ohne Adminrechte angelegt."
}
# Auch bei einem bestehenden Konto: ohne die Gruppe "Benutzer" kann man sich
# nicht anmelden (z.B. wenn ein frueherer Lauf genau hier abgebrochen ist).
if (-not (Ist-Mitglied $benutzerGruppe $kontoObjekt.SID)) {
    Add-LocalGroupMember -Group $benutzerGruppe -Member $kontoObjekt.SID.Value
    Info "Zur Gruppe '$($benutzerGruppe.Name)' hinzugefuegt."
}

if ($NeuerName -and $NeuerName -ne $env:COMPUTERNAME) {
    try {
        Rename-Computer -NewName $NeuerName -Force -WarningAction SilentlyContinue
        $NeustartNoetig = $true
        Ok "Geraet heisst nach dem Neustart '$NeuerName'."
    } catch { Warnung "Umbenennen fehlgeschlagen: $($_.Exception.Message)" }
}

# ---------------- 2. Vorinstalliertes entfernen ----------------
Schritt '2/5  Vorinstalliertes entfernen'

# Erst aus dem Vorrat fuer neue Konten (sonst kommen die Apps im Schuelerkonto
# wieder), dann bei allen bestehenden Konten.
$vorrat = Get-AppxProvisionedPackage -Online
$installiert = Get-AppxPackage -AllUsers
$entfernt = @(); $nichtEntfernbar = @()
foreach ($muster in $WegApps) {
    foreach ($p in ($vorrat | Where-Object { $_.DisplayName -like $muster })) {
        try { Remove-AppxProvisionedPackage -Online -PackageName $p.PackageName | Out-Null; $entfernt += $p.DisplayName }
        catch { $nichtEntfernbar += $p.DisplayName }
    }
    foreach ($a in ($installiert | Where-Object { $_.Name -like $muster })) {
        try { Remove-AppxPackage -Package $a.PackageFullName -AllUsers; $entfernt += $a.Name }
        catch { $nichtEntfernbar += $a.Name }
    }
}
$entfernt = $entfernt | Sort-Object -Unique
if ($entfernt) { Ok "Entfernt: $($entfernt -join ', ')" } else { Info 'Keine der aufgelisteten Apps gefunden.' }
$nichtEntfernbar = $nichtEntfernbar | Sort-Object -Unique | Where-Object { $entfernt -notcontains $_ }
if ($nichtEntfernbar) { Info "Nicht entfernbar (von Windows geschuetzt): $($nichtEntfernbar -join ', ')" }

# McAfee: zuerst still per winget, wenn das nicht reicht das offizielle Removal Tool.
$mcafee = Get-Programme '*McAfee*'
if (-not $mcafee) {
    Ok 'Kein McAfee gefunden.'
} else {
    Info "Gefunden: $(($mcafee.DisplayName) -join ', ')"
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        foreach ($m in $mcafee) {
            Info "Deinstalliere $($m.DisplayName) ..."
            Leise winget @('uninstall', '--name', $m.DisplayName, '--exact', '--silent', '--accept-source-agreements', '--disable-interactivity')
        }
        $mcafee = Get-Programme '*McAfee*'
    }
    if ($mcafee) {
        Write-Host ''
        Write-Host '  McAfee laesst sich nicht still entfernen. Jetzt startet das offizielle' -ForegroundColor Yellow
        Write-Host '  McAfee Removal Tool (MCPR): den Anweisungen folgen und den angezeigten' -ForegroundColor Yellow
        Write-Host '  Code abtippen. Danach geht es hier automatisch weiter.' -ForegroundColor Yellow
        $mcpr = Join-Path $env:TEMP 'MCPR.exe'
        try {
            Invoke-WebRequest -Uri $McafeeToolUrl -OutFile $mcpr -UseBasicParsing
            Start-Process -FilePath $mcpr -Wait
            Read-Host '  Enter druecken, sobald das McAfee-Tool fertig ist' | Out-Null
            Remove-Item $mcpr -Force -ErrorAction SilentlyContinue
            $NeustartNoetig = $true
        } catch { Warnung "McAfee Removal Tool konnte nicht gestartet werden: $($_.Exception.Message)" }
        $rest = Get-Programme '*McAfee*'
        if ($rest) { Warnung "Noch vorhanden (evtl. erst nach Neustart weg): $(($rest.DisplayName) -join ', ')" }
        else { Ok 'McAfee entfernt.' }
    } else {
        Ok 'McAfee entfernt.'
    }
}

# ---------------- 3. OneDrive, Werbung, Begruessung ----------------
Schritt '3/5  OneDrive-Umleitung, Werbung und Begruessungen abschalten'
# OneDrive: sonst verschiebt OneDrive Desktop und Dokumente in die Cloud -
# unsere Skripte (Desktop, Documents\Arduino\libraries) liefen dann ins Leere.
Set-Reg 'HKLM\SOFTWARE\Policies\Microsoft\Windows\OneDrive' 'DisableFileSyncNGSC' 1
Set-Reg 'HKLM\SOFTWARE\Policies\Microsoft\OneDrive' 'KFMBlockOptIn' 1
# Datenschutz-Abfrage bei der ersten Anmeldung jedes neuen Kontos
Set-Reg 'HKLM\SOFTWARE\Policies\Microsoft\Windows\OOBE' 'DisablePrivacyExperience' 1
# Werbe-Apps und Vorschlaege (wirkt voll nur auf Education/Enterprise -
# fuer Home/Pro uebernimmt das Schritt 5 im Benutzerprofil)
Set-Reg 'HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent' 'DisableWindowsConsumerFeatures' 1
Set-Reg 'HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent' 'DisableSoftLanding' 1
Set-Reg 'HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent' 'DisableConsumerAccountStateContent' 1
# Edge: keine Begruessungsseiten, keine Einkaufs- und Inhaltsvorschlaege
$edge = 'HKLM\SOFTWARE\Policies\Microsoft\Edge'
Set-Reg $edge 'HideFirstRunExperience' 1
Set-Reg $edge 'ShowRecommendationsEnabled' 0
Set-Reg $edge 'EdgeShoppingAssistantEnabled' 0
Set-Reg $edge 'NewTabPageContentEnabled' 0
Set-Reg $edge 'HubsSidebarEnabled' 0
Ok 'Richtlinien gesetzt.'

# ---------------- 4. Windows-Updates ----------------
Schritt "4/5  Windows-Updates: kein Neustart zwischen $AktivVon und $AktivBis Uhr"
if (($AktivBis - $AktivVon) -gt 18 -or $AktivBis -le $AktivVon) {
    Warnung "Nutzungszeit $AktivVon-$AktivBis Uhr ungueltig (max. 18 Stunden) - Schritt uebersprungen."
} else {
    $ux = 'HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings'
    Set-Reg $ux 'SmartActiveHoursState' 0
    Set-Reg $ux 'ActiveHoursStart' $AktivVon
    Set-Reg $ux 'ActiveHoursEnd' $AktivBis
    # Dieselben Werte als Richtlinie (greift auf Pro; Home nutzt die Werte oben)
    $wu = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate'
    Set-Reg $wu 'SetActiveHours' 1
    Set-Reg $wu 'ActiveHoursStart' $AktivVon
    Set-Reg $wu 'ActiveHoursEnd' $AktivBis
    Set-Reg "$wu\AU" 'NoAutoRebootWithLoggedOnUsers' 1
    Ok 'Updates werden ausserhalb der Kurszeit installiert; solange jemand angemeldet ist, startet Windows nicht von selbst neu.'
}

# ---------------- 5. Neue Benutzerprofile vorbereiten ----------------
Schritt '5/5  Erste Anmeldung ins Schuelerkonto vorbereiten'

# Taskleiste fuer neue Konten: Windows legt sie bei der ersten Anmeldung nach
# einer Vorlage an (Lenovo hat dort Vantage, Smart Meeting usw. eingetragen).
# Unsere Vorlage ersetzt die Standard-Pins (Replace) - angeheftet sind nur
# Edge und Explorer; Store, Outlook, Copilot und Lenovo-Apps bleiben installiert,
# aber nicht angeheftet. SETUP/FULL_RESET loesen sie zusaetzlich im laufenden Konto.
$taskleiste = @'
<?xml version="1.0" encoding="utf-8"?>
<LayoutModificationTemplate
    xmlns="http://schemas.microsoft.com/Start/2014/LayoutModification"
    xmlns:defaultlayout="http://schemas.microsoft.com/Start/2014/FullDefaultLayout"
    xmlns:start="http://schemas.microsoft.com/Start/2014/StartLayout"
    xmlns:taskbar="http://schemas.microsoft.com/Start/2014/TaskbarLayout"
    Version="1">
  <CustomTaskbarLayoutCollection PinListPlacement="Replace">
    <defaultlayout:TaskbarLayout>
      <taskbar:TaskbarPinList>
        <taskbar:DesktopApp DesktopApplicationID="MSEdge" />
        <taskbar:DesktopApp DesktopApplicationID="Microsoft.Windows.Explorer" />
      </taskbar:TaskbarPinList>
    </defaultlayout:TaskbarLayout>
  </CustomTaskbarLayoutCollection>
</LayoutModificationTemplate>
'@
$taskleisteDatei = Join-Path $Ordner 'TaskbarLayoutModification.xml'
[IO.File]::WriteAllText($taskleisteDatei, ($taskleiste -replace "`r?`n", "`r`n"), [Text.Encoding]::UTF8)
$explorerKey = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer'
$bisher = (Get-ItemProperty $explorerKey -Name LayoutXMLPath -ErrorAction SilentlyContinue).LayoutXMLPath
if ($bisher -and $bisher -ne $taskleisteDatei) { Info "Bisherige Taskleisten-Vorlage (Lenovo): $bisher" }
Set-Reg 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer' 'LayoutXMLPath' $taskleisteDatei 'REG_EXPAND_SZ'
Ok 'Taskleiste fuer neue Konten: nur Edge und Explorer angeheftet.'

# Startdatei fuer die erste Anmeldung. Laedt FULL_RESET.bat immer frisch von
# GitHub, damit auch ein Laptop, der erst in Wochen ausgepackt wird, den
# aktuellen Stand bekommt. Labels/goto sind hier ok: wir schreiben CRLF.
$start = @'
@echo off
setlocal
:: Erstellt von NeuerLaptop.ps1. Laeuft einmal bei der ersten Anmeldung eines
:: neuen Kontos (RunOnce aus dem Default-Profil) - aber nur im Schuelerkonto.
if /I not "%USERNAME%"=="__KONTO__" exit /b
title TueftelPark - Laptop wird eingerichtet
echo ========================================================
echo   Der Laptop wird fuer den Kurs eingerichtet.
echo   Bitte dieses Fenster NICHT schliessen (ca. 5-10 Minuten).
echo ========================================================
set "FR=%TEMP%\FULL_RESET.bat"
set "VERSUCH=0"
:: Nach der Anmeldung verbindet sich das WLAN manchmal erst nach einigen Sekunden
:warte
set /a VERSUCH+=1
curl -fsSL -o "%FR%" "__URL__" && goto los
if %VERSUCH% geq 30 goto fehler
echo Warte auf Internetverbindung (Versuch %VERSUCH% von 30)...
timeout /t 10 /nobreak >nul
goto warte
:fehler
echo.
echo [FEHLER] Keine Internetverbindung.
echo          Bitte WLAN verbinden und FULL_RESET.bat von Hand ausfuehren:
echo          https://github.com/tueftelPark/Skripte
pause
exit /b
:los
call "%FR%" /auto
del "%FR%" >nul 2>&1
echo.
echo Einrichtung beendet. Das Fenster schliesst sich in 20 Sekunden.
timeout /t 20 >nul
'@
$start = $start.Replace('__KONTO__', $Konto).Replace('__URL__', $FullResetUrl)
$startDatei = Join-Path $Ordner 'ErsteAnmeldung.bat'
[IO.File]::WriteAllText($startDatei, ($start -replace "`r?`n", "`r`n"), [Text.Encoding]::ASCII)

# Default-Profil laden: was hier steht, bekommt jedes neu angelegte Konto
# bei der ersten Anmeldung mit - also auch das Schuelerkonto.
$hive = 'HKU\TueftelDefault'
Leise reg.exe @('unload', $hive)   # Rest eines abgebrochenen Laufs
Leise reg.exe @('load', $hive, 'C:\Users\Default\NTUSER.DAT')
if ($LASTEXITCODE -ne 0) {
    Warnung 'Default-Profil konnte nicht geladen werden - Werbung im Schuelerkonto und automatische Einrichtung fehlen. FULL_RESET.bat dort von Hand ausfuehren.'
} else {
    try {
        $cdm = "$hive\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
        foreach ($n in 'ContentDeliveryAllowed', 'OemPreInstalledAppsEnabled', 'PreInstalledAppsEnabled',
                       'PreInstalledAppsEverEnabled', 'SilentInstalledAppsEnabled', 'SoftLandingEnabled',
                       'SystemPaneSuggestionsEnabled', 'SubscribedContent-310093Enabled',
                       'SubscribedContent-338388Enabled', 'SubscribedContent-338389Enabled',
                       'SubscribedContent-338393Enabled', 'SubscribedContent-353694Enabled',
                       'SubscribedContent-353696Enabled') {
            Set-Reg $cdm $n 0
        }
        # "Lass uns die Einrichtung abschliessen"-Bildschirm und Empfehlungen im Startmenue
        Set-Reg "$hive\Software\Microsoft\Windows\CurrentVersion\UserProfileEngagement" 'ScoobeSystemSettingEnabled' 0
        $adv = "$hive\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        Set-Reg $adv 'Start_IrisRecommendations' 0
        Set-Reg $adv 'ShowSyncProviderNotifications' 0
        # OneDrive nicht bei jedem neuen Konto einrichten
        Leise reg.exe @('delete', "$hive\Software\Microsoft\Windows\CurrentVersion\Run", '/v', 'OneDriveSetup', '/f')
        # Automatische Einrichtung bei der ersten Anmeldung
        Set-Reg "$hive\Software\Microsoft\Windows\CurrentVersion\RunOnce" 'TueftelPark' "cmd.exe /c $startDatei" 'REG_SZ'
        Ok "Bei der ersten Anmeldung als '$Konto' richtet sich der Laptop selbst ein."
    } finally {
        [GC]::Collect(); [GC]::WaitForPendingFinalizers(); Start-Sleep -Seconds 1
        Leise reg.exe @('unload', $hive)
        if ($LASTEXITCODE -ne 0) { Warnung 'Default-Profil konnte nicht entladen werden - bitte vor der ersten Anmeldung neu starten.'; $NeustartNoetig = $true }
    }
}

# ---------------- Zusammenfassung ----------------
Write-Host ''
Write-Host '========================================================'
if ($script:Warnungen.Count -eq 0) {
    Write-Host '  Fertig - alles ohne Warnungen.' -ForegroundColor Green
} else {
    Write-Host "  Fertig - mit $($script:Warnungen.Count) Warnung(en):" -ForegroundColor Yellow
    $script:Warnungen | ForEach-Object { Write-Host "   - $_" -ForegroundColor Yellow }
}
Write-Host '========================================================'

# Lenovo-Beigaben bewusst nur auflisten: Treiber, Vantage und Updates sollen
# bleiben. Was davon Werbung ist, beim ersten Laptop pruefen und oben in
# $WegApps ergaenzen.
$lenovoApps = Get-AppxPackage -AllUsers | Where-Object { $_.Name -like '*Lenovo*' } | ForEach-Object { $_.Name }
$lenovoProg = Get-Programme '*Lenovo*' | ForEach-Object { $_.DisplayName }
if ($lenovoApps -or $lenovoProg) {
    Write-Host ''
    Write-Host '  Lenovo-Software auf diesem Geraet (wurde nicht angetastet):'
    @($lenovoApps) + @($lenovoProg) | Sort-Object -Unique | ForEach-Object { Write-Host "   - $_" }
}

Write-Host ''
Write-Host '  Naechste Schritte:'
Write-Host '   1. Windows Update: Einstellungen > Windows Update > Nach Updates suchen'
Write-Host '      (bis nichts mehr kommt - beim ersten Mal dauert das).'
Write-Host "   2. Abmelden und als '$Konto' anmelden. Die Einrichtung startet von selbst."
Write-Host '   3. Arduino anstecken und pruefen, ob die IDE den Port findet.'
Write-Host "  Protokoll: $Ordner\Einrichtung.log"
Stop-Transcript | Out-Null

if ($NeustartNoetig) {
    Write-Host ''
    $antwort = Read-Host '  Ein Neustart ist noetig. Jetzt neu starten? (J/N)'
    if ($antwort -match '^[Jj]') { Restart-Computer -Force }
}
