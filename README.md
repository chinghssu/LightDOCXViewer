# Light DOCX Viewer

**English** | [繁體中文](README.zh-TW.md) | [日本語](README.ja.md) | [한국어](README.ko.md) | [Deutsch](README.de.md) | [Español](README.es.md) | [Français](README.fr.md)

A minimal, native macOS reader for `.docx` files that puts **text and inline images in reading order**—without recreating Microsoft Word's page layout.

Designed for a simple workflow: open a document, read its contents, copy text, and copy embedded images into another app.

> **Status: early prototype (v0.1.2).** Builds and runs on macOS. Some DOCX files may not display completely. Contributions and bug reports are welcome.

## Features

- **Read DOCX files** in a native AppKit window.
- **Preserve content order** for supported text and inline images (for example: paragraph → image → paragraph).
- **Copy text** by selecting it and pressing `⌘C`.
- **Copy embedded images** by clicking an image and pressing `⌘C`, then paste with `⌘V` into another app.
- **Read-only** by design: no document editing or saving.
- **No Microsoft Word, Pages, Python runtime, or third-party dependencies** required to run the app.
- **Custom app icon** generated automatically during the build.

## Requirements

- macOS 12 or later (as configured in `Info.plist`)
- Apple Command Line Tools for building (`swiftc`, `sips`, `iconutil`)

## Build from source

1. Clone or download this repository.
2. Install the Command Line Tools if needed:

   ```bash
   xcode-select --install
   ```

3. In Terminal, open the project folder and run:

   ```bash
   bash build.command
   ```

The script builds `Light DOCX Viewer.app` in the project directory, generates `AppIcon.icns` from `AppIcon.png`, and attempts to open the app.

**Note:** This is a locally built, unsigned prototype, not a notarized macOS release. A crossed-out app icon is not necessarily a Gatekeeper quarantine issue; it may indicate an incompatible or invalid app bundle. Check the build output and app bundle first rather than bypassing macOS security settings.

## Signing and notarization (optional)

To distribute the app so it opens on other Macs without Gatekeeper warnings, sign it with a **Developer ID Application** certificate and notarize it with Apple. This requires a paid Apple Developer account.

1. Make sure a `Developer ID Application` certificate is in your login keychain (`security find-identity -v -p codesigning`).
2. Create an app-specific password at account.apple.com, then store notarization credentials in the keychain (one-time setup):

   ```bash
   xcrun notarytool store-credentials "notary-profile" \
     --apple-id "<Apple ID>" --team-id "<Team ID>"
   ```

3. Build, then sign, notarize, and staple:

   ```bash
   bash build.command
   bash sign-and-notarize.command
   ```

The script signs a copy of the app with the hardened runtime, submits it with `notarytool`, staples the ticket, checks it with `spctl`, and writes `LightDOCXViewer-<version>.zip` to the project folder, ready to attach to a GitHub Release.

- To sign without notarizing (for local testing), run:

  ```bash
  bash sign-and-notarize.command --sign-only
  ```

  This writes `LightDOCXViewer-<version>-unnotarized.zip`.
- Optional environment variables: `SIGN_IDENTITY` (defaults to the first Developer ID Application identity) and `NOTARY_PROFILE` (defaults to `notary-profile`).
- Signing happens in a temporary directory because iCloud Drive and other file providers keep adding Finder metadata to synced folders, which makes `codesign` fail.
- Never commit your Apple ID, app-specific password, or release zips to the repository.

## Usage

Open the app and press `⌘O` to choose a `.docx` file. Alternatively, select a DOCX in Finder and choose **Open With → Light DOCX Viewer**.

To copy text, select the text and press `⌘C`. To copy a picture, click the inline image once and press `⌘C`, then paste it into another application.

If you want to make this the default DOCX reader, select a `.docx` in Finder, choose **Get Info → Open with**, select this app, and click **Change All**. Only do this after confirming the app runs correctly on your Mac.

## Known limitations

This is a **content-oriented reader**, not a layout-faithful Word renderer.

- Supports the main document's basic text, line breaks, table text, and supported inline DrawingML images.
- Does not reproduce page breaks, fonts, margins, columns, or table borders as in Word.
- DOCX files are extracted to a temporary directory, which is removed immediately after loading.
- Floating images, legacy VML images, text boxes, headers, footers, footnotes, comments, and externally linked images may be missing or out of order.
- Image copying is intended for images loaded as inline attachments; behavior still needs testing across different DOCX files and destination apps.
- Some DOCX files may fail to parse or display completely.
- No automated test suite, notarization, or signed binary is included yet.

## App icon

- Source artwork: `AppIcon.png` (included in the repository).
- `build.command` uses the built-in macOS tools `sips` and `iconutil` to generate `AppIcon.icns` in all standard sizes and places it in `.app/Contents/Resources`.
- `Info.plist` sets `CFBundleIconFile` to `AppIcon`.
- If Finder still shows an old icon, move the app to a different location or restart Finder to refresh its icon cache.

## Project structure

```text
.
├── LightDOCXViewer.swift   # AppKit interface, DOCX XML parsing, and clipboard support
├── AppIcon.png             # Source artwork for the macOS app icon
├── Info.plist              # App bundle metadata and DOCX file association
├── build.command           # One-command macOS build and icon generation
├── sign-and-notarize.command  # Developer ID signing, notarization, and stapling
├── LICENSE                 # MIT License
├── README.md               # English documentation
└── README.*.md             # Translated documentation
```

## How it works

DOCX files are ZIP containers. The app temporarily extracts a DOCX using macOS `ditto`, reads `word/document.xml` and its image relationships using `XMLParser`, then renders text and images through `NSTextView` and `NSTextAttachment`. It removes the temporary extraction directory after loading. Image copy uses the macOS pasteboard.

This intentionally favors simple reading and copying over comprehensive Office Open XML rendering.

## Contributing

Bug reports, reproducible sample documents (with sensitive information removed), fixes, and compatibility improvements are welcome. In particular, macOS build verification, safer archive handling, and broader DOCX image support would be valuable.

## License

Released under the [MIT License](LICENSE).

Microsoft and Word are trademarks of Microsoft Corporation. This project is not affiliated with or endorsed by Microsoft.
