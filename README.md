# Skripte für die Kurslaptops

Alle Skripte sind Windows-Batch-Dateien und laufen ohne Adminrechte im Benutzerkonto.

## Neuen Laptop einrichten

1. Windows-Ersteinrichtung durchklicken (Sprache, WLAN, euer Admin-Konto).
2. [NEUER_LAPTOP Skript hier downloaden](NEUER_LAPTOP.bat) und doppelklicken.
   Meldet Windows „Der Computer wurde durch Windows geschützt“: *Weitere Informationen → Trotzdem ausführen*. Die Adminrechte-Abfrage mit *Ja* bestätigen.
3. Am Anfang fragt das Skript nach dem Namen des Schülerkontos, einem Passwort (Enter = keines) und optional einem Gerätenamen. Danach läuft es allein. Nur falls sich McAfee nicht still entfernen lässt, öffnet sich das McAfee-Entfernungstool.
4. Windows Update laufen lassen, bis nichts mehr kommt.
5. Abmelden und im Schülerkonto anmelden: die Einrichtung (Arduino IDE, Git, Libraries, Desktop) startet von selbst.

Was das Skript macht: Schülerkonto ohne Adminrechte anlegen, Werbe-Apps, McAfee und Lenovo Smart Meeting entfernen (Lenovo-Treiber und Vantage bleiben), OneDrive-Umleitung von Desktop/Dokumenten sowie Werbung und Begrüssungsseiten abschalten, Windows-Updates nicht während der Kurszeit (7–20 Uhr) neu starten lassen. Es darf mehrfach laufen. Protokoll: `C:\ProgramData\TueftelPark\Einrichtung.log`.

Die Logik steckt in [`Einrichtung/NeuerLaptop.ps1`](Einrichtung/NeuerLaptop.ps1); die Liste der zu entfernenden Apps und die Kurszeit stehen oben in der Datei.

## Für die Kursleitung

Die Setup-Skripte liegen **nicht** auf dem Schüler-Desktop, sondern auf jedem eingerichteten Laptop unter **Dokumente → TueftelPark Skripte** (`SETUP.bat`, `FULL_RESET.bat`, `AlleLibrariesInstallieren.bat`, `NanoErkennung.bat`). Jeder Lauf von SETUP oder FULL_RESET bringt sie dort auf den neuesten Stand. Alternativ hier herunterladen:

- **Initiales Setup:** [FULL_RESET Skript hier downloaden](FULL_RESET.bat)
  Leert den Desktop, installiert die neueste Arduino IDE (nur wenn nicht schon aktuell) und Git, legt die Kurs-Skripte und die Verknüpfungen zur Tinkercad-Klasse (www.tinkercad.com/joinclass/DLFXZMAX37MZ), www.tuefteln.com/feedback und www.tuefteln.com/start auf den Desktop und installiert alle Arduino-Libraries.
- **Vor jedem Kurs:** [Setup Skript hier downloaden](SETUP.bat)
  Dasselbe ohne Neuinstallation der Arduino IDE. Git wird nur installiert, falls es noch fehlt.

Beide Skripte leeren den Desktop komplett und fragen vorher nach. Geleert wird erst, wenn die Skripte erfolgreich heruntergeladen sind – ohne Internet bleibt der Desktop, wie er ist.

## Für die Schüler:innen

Auf dem Desktop liegt pro Kurs ein Skript (z.B. `Sortieranlage.bat`). Es schliesst die Arduino IDE, löscht den alten Kursordner, lädt den Kurs frisch von GitHub und öffnet den Ordner.

## Aufbau

| Ort | Inhalt |
|---|---|
| `NEUER_LAPTOP.bat`, `Einrichtung/` | einmalige Einrichtung eines neuen Laptops (Adminrechte) |
| `SETUP.bat`, `FULL_RESET.bat` | Laptop zurücksetzen (nur für die Kursleitung); `FULL_RESET.bat /auto` ohne Rückfrage |
| `AlleLibrariesInstallieren.bat` | wird von den Setup-Skripten aufgerufen; holt den Installer aus [ArduinoKomponentenLibrariesSammlung](https://github.com/tueftelPark/ArduinoKomponentenLibrariesSammlung) |
| `NanoErkennung.bat` | wird von den Setup-Skripten aufgerufen; Nano-Klone erscheinen in der Arduino IDE als „Arduino Nano“ statt „Unknown“ (siehe unten) |
| `Kurse/` | ein Skript pro Kurs — **nur diese** kommen auf den Desktop |

**Neuen Kurs hinzufügen:** ein bestehendes Skript in `Kurse/` kopieren, so benennen wie das GitHub-Repository und oben die Zeile `set "KURS=..."` anpassen – der Rest leitet sich davon ab. Dateinamen ohne Umlaute, Zeilenenden CRLF.

## Nano-Klone als „Arduino Nano“ erkennen

Nano-Klone haben einen allgemeinen USB-Chip (CP2102, CH340, …), der Seeeduino Nano aus dem Kurs LED Matrix einen CP2102N. Die Arduino IDE kann daran nicht erkennen, welches Board dahintersteckt, und zeigt „Unknown“. `NanoErkennung.bat` legt eine `boards.local.txt` neben die `boards.txt` der Arduino AVR Boards (`%LOCALAPPDATA%\Arduino15\packages\arduino\hardware\avr\<Version>\`) und ordnet diese Chips dem Arduino Nano zu. Danach steht im Board-Menü direkt „Arduino Nano“ auf dem richtigen Port.

- Läuft am Ende von SETUP und FULL_RESET, darf beliebig oft laufen. Nach einem Update der AVR Boards (neuer Versionsordner) richtet der nächste SETUP-Lauf die Datei wieder ein.
- Fehlen die AVR Boards noch, installiert das Skript sie über das arduino-cli der IDE.
- Eine offene Arduino IDE muss einmal neu gestartet werden.
- **Nebenwirkung:** Jedes Board mit einem dieser Chips erscheint als „Arduino Nano“. Original-UNOs sind nicht betroffen.
- Weiterer Chip: in `NanoErkennung.bat` unter `:datei_schreiben` mit der nächsten freien Nummer eintragen (VID/PID stehen im Geräte-Manager unter *Eigenschaften → Details → Hardware-IDs*).

Git liegt als portable Version (MinGit) unter `%LOCALAPPDATA%\TueftelPark\MinGit` und wird von den Kurs-Skripten direkt über diesen Pfad aufgerufen.
