# Light DOCX Viewer

[English](README.md) | [繁體中文](README.zh-TW.md) | [日本語](README.ja.md) | [한국어](README.ko.md) | **Deutsch** | [Español](README.es.md) | [Français](README.fr.md)

Ein schlanker, nativer macOS-Reader für `.docx`-Dateien, der **Text und eingebettete Bilder in Lesereihenfolge** anzeigt – ohne das Seitenlayout von Microsoft Word nachzubilden.

Gedacht für einen einfachen Ablauf: Dokument öffnen, Inhalt lesen, Text kopieren und eingebettete Bilder in eine andere App kopieren.

> **Status: früher Prototyp (v0.1.2).** Lässt sich unter macOS bauen und ausführen. Manche DOCX-Dateien werden möglicherweise nicht vollständig angezeigt. Fehlerberichte und Beiträge sind willkommen.

## Funktionen

- **DOCX-Dateien lesen** in einem nativen AppKit-Fenster.
- **Inhaltsreihenfolge bleibt erhalten** für unterstützten Text und eingebettete Bilder (z. B. Absatz → Bild → Absatz).
- **Text kopieren**: Text markieren und `⌘C` drücken.
- **Eingebettete Bilder kopieren**: Bild anklicken, `⌘C` drücken und mit `⌘V` in einer anderen App einfügen.
- **Nur Lesezugriff**: Dokumente können nicht bearbeitet oder gespeichert werden.
- **Kein Microsoft Word, Pages, keine Python-Laufzeit und keine Drittanbieter-Abhängigkeiten** zum Ausführen erforderlich.
- **Eigenes App-Symbol**, das beim Build automatisch erzeugt wird.

## Voraussetzungen

- macOS 12 oder neuer (gemäß `Info.plist`)
- Apple Command Line Tools zum Bauen (`swiftc`, `sips`, `iconutil`)

## Aus dem Quellcode bauen

1. Dieses Repository klonen oder herunterladen.
2. Bei Bedarf die Command Line Tools installieren:

   ```bash
   xcode-select --install
   ```

3. Im Terminal in den Projektordner wechseln und ausführen:

   ```bash
   bash build.command
   ```

Das Skript baut `Light DOCX Viewer.app` im Projektordner, erzeugt `AppIcon.icns` aus `AppIcon.png` und versucht, die App zu öffnen.

**Hinweis:** Dies ist ein lokal gebauter, nicht signierter Prototyp und keine notarisierte macOS-Version. Ein durchgestrichenes App-Symbol bedeutet nicht unbedingt eine Gatekeeper-Quarantäne; es kann auch auf ein inkompatibles oder ungültiges App-Bundle hinweisen. Prüfen Sie zuerst die Build-Ausgabe und das App-Bundle, statt die Sicherheitseinstellungen von macOS zu umgehen.

## Signierung und Notarisierung (optional)

Damit sich die App auf anderen Macs ohne Gatekeeper-Warnung öffnen lässt, muss sie mit einem **Developer ID Application**-Zertifikat signiert und von Apple notarisiert werden. Dafür ist ein kostenpflichtiger Apple-Developer-Account nötig.

1. Prüfen Sie, ob ein `Developer ID Application`-Zertifikat in Ihrem Anmeldeschlüsselbund liegt (`security find-identity -v -p codesigning`).
2. Erstellen Sie unter account.apple.com ein app-spezifisches Passwort und speichern Sie die Zugangsdaten für die Notarisierung im Schlüsselbund (einmalig):

   ```bash
   xcrun notarytool store-credentials "notary-profile" \
     --apple-id "<Apple ID>" --team-id "<Team ID>"
   ```

3. Bauen Sie die App und signieren, notarisieren und „stapeln“ Sie sie anschließend:

   ```bash
   bash build.command
   bash sign-and-notarize.command
   ```

Das Skript signiert eine Kopie der App mit Hardened Runtime, reicht sie per `notarytool` ein, heftet das Notarisierungsticket an, prüft sie mit `spctl` und legt `LightDOCXViewer-<Version>.zip` im Projektordner ab – bereit zum Anhängen an ein GitHub Release.

- Nur signieren, ohne Notarisierung (für lokale Tests):

  ```bash
  bash sign-and-notarize.command --sign-only
  ```

  Dabei entsteht `LightDOCXViewer-<Version>-unnotarized.zip`.
- Optionale Umgebungsvariablen: `SIGN_IDENTITY` (Standard: erste Developer-ID-Application-Identität) und `NOTARY_PROFILE` (Standard: `notary-profile`).
- Signiert wird in einem temporären Verzeichnis, weil iCloud Drive und andere Dateianbieter in synchronisierten Ordnern immer wieder Finder-Metadaten hinzufügen, wodurch `codesign` fehlschlägt.
- Committen Sie niemals Ihre Apple-ID, Ihr app-spezifisches Passwort oder Release-ZIP-Dateien in das Repository.

## Verwendung

Öffnen Sie die App und drücken Sie `⌘O`, um eine `.docx`-Datei auszuwählen. Alternativ wählen Sie eine DOCX-Datei im Finder aus und wählen **Öffnen mit → Light DOCX Viewer**.

Um Text zu kopieren, markieren Sie ihn und drücken `⌘C`. Um ein Bild zu kopieren, klicken Sie einmal auf das eingebettete Bild, drücken `⌘C` und fügen es in einer anderen Anwendung ein.

Wenn Sie die App als Standard-Reader für DOCX festlegen möchten, wählen Sie im Finder eine `.docx`-Datei aus, öffnen **Informationen → Öffnen mit**, wählen diese App und klicken auf **Alle ändern**. Tun Sie dies erst, nachdem Sie sich vergewissert haben, dass die App auf Ihrem Mac korrekt läuft.

## Bekannte Einschränkungen

Dies ist ein **inhaltsorientierter Reader**, kein layoutgetreuer Word-Renderer.

- Unterstützt einfachen Text, Zeilenumbrüche, Tabellentext und unterstützte eingebettete DrawingML-Bilder aus dem Hauptdokument.
- Seitenumbrüche, Schriftarten, Ränder, Spalten und Tabellenrahmen werden nicht wie in Word wiedergegeben.
- DOCX-Dateien werden in ein temporäres Verzeichnis entpackt, das direkt nach dem Laden gelöscht wird.
- Frei positionierte Bilder, ältere VML-Bilder, Textfelder, Kopf- und Fußzeilen, Fußnoten, Kommentare und extern verknüpfte Bilder können fehlen oder in falscher Reihenfolge erscheinen.
- Das Kopieren von Bildern ist für Bilder gedacht, die als eingebettete Anhänge geladen werden; das Verhalten mit verschiedenen DOCX-Dateien und Ziel-Apps muss noch weiter getestet werden.
- Manche DOCX-Dateien lassen sich möglicherweise nicht parsen oder nicht vollständig anzeigen.
- Automatisierte Tests, Notarisierung und signierte Binärdateien sind noch nicht enthalten.

## App-Symbol

- Ausgangsgrafik: `AppIcon.png` (im Repository enthalten).
- `build.command` erzeugt mit den macOS-eigenen Werkzeugen `sips` und `iconutil` eine `AppIcon.icns` in allen Standardgrößen und legt sie in `.app/Contents/Resources` ab.
- `Info.plist` setzt `CFBundleIconFile` auf `AppIcon`.
- Zeigt der Finder noch ein altes Symbol, verschieben Sie die App an einen anderen Ort oder starten Sie den Finder neu, um den Symbol-Cache zu aktualisieren.

## Projektstruktur

```text
.
├── LightDOCXViewer.swift   # AppKit-Oberfläche, DOCX-XML-Parsing und Zwischenablage-Unterstützung
├── AppIcon.png             # Ausgangsgrafik für das macOS-App-Symbol
├── Info.plist              # Metadaten des App-Bundles und DOCX-Dateizuordnung
├── build.command           # macOS-Build und Symbolerzeugung mit einem Befehl
├── sign-and-notarize.command  # Developer-ID-Signierung, Notarisierung und Stapling
├── LICENSE                 # MIT-Lizenz
├── README.md               # Englische Dokumentation
└── README.*.md             # Übersetzte Dokumentation
```

## Funktionsweise

DOCX-Dateien sind ZIP-Container. Die App entpackt eine DOCX-Datei vorübergehend mit dem macOS-Werkzeug `ditto`, liest `word/document.xml` und die zugehörigen Bildbeziehungen mit `XMLParser` und stellt Text und Bilder über `NSTextView` und `NSTextAttachment` dar. Nach dem Laden wird das temporäre Verzeichnis entfernt. Zum Kopieren von Bildern wird die macOS-Zwischenablage verwendet.

Einfaches Lesen und Kopieren hat hier bewusst Vorrang vor einer vollständigen Office-Open-XML-Darstellung.

## Mitwirken

Fehlerberichte, reproduzierbare Beispieldokumente (mit entfernten sensiblen Informationen), Korrekturen und Kompatibilitätsverbesserungen sind willkommen. Besonders hilfreich wären Build-Überprüfungen unter macOS, eine sicherere Archivverarbeitung und eine breitere Unterstützung für DOCX-Bilder.

## Lizenz

Veröffentlicht unter der [MIT-Lizenz](LICENSE).

Microsoft und Word sind Marken der Microsoft Corporation. Dieses Projekt steht in keiner Verbindung zu Microsoft und wird nicht von Microsoft unterstützt.
