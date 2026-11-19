# Light DOCX Viewer

A minimal, native macOS reader for `.docx` files that puts **text and inline images in reading order**—without recreating Microsoft Word's page layout.

Designed for a simple workflow: open a document, read its contents, copy text, and copy embedded images into another app.

> **Status: early prototype (v0.1.2).** The project has not yet been fully compiled and tested on macOS. Expect compatibility issues. Contributions and bug reports are welcome.

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
└── README.md
```

## How it works

DOCX files are ZIP containers. The app temporarily extracts a DOCX using macOS `ditto`, reads `word/document.xml` and its image relationships using `XMLParser`, then renders text and images through `NSTextView` and `NSTextAttachment`. It removes the temporary extraction directory after loading. Image copy uses the macOS pasteboard.

This intentionally favors simple reading and copying over comprehensive Office Open XML rendering.

## Contributing

Bug reports, reproducible sample documents (with sensitive information removed), fixes, and compatibility improvements are welcome. In particular, macOS build verification, safer archive handling, and broader DOCX image support would be valuable.

## License

**License not yet selected.** Before publishing this repository for open-source reuse, add a `LICENSE` file (for example, MIT if you want a permissive license) and replace this section with the chosen license. Without an explicit license, public visibility on GitHub does not by itself grant others permission to reuse or redistribute the code.

---

## 繁體中文說明

Light DOCX Viewer 是一個不需要 Word、Pages 或 Python 的原生 AppKit DOCX 閱讀器原型。它只讀取 DOCX 主文件中的文字與行內圖片，依照出現順序排列，支援文字選取，以及點選圖片後 `⌘C` 複製圖片。

### 建置

1. macOS 12 或更新版本。先安裝 Apple Command Line Tools：`xcode-select --install`（若已安裝可略過）。
2. 在 Terminal 中進入本資料夾，執行 `bash build.command`。建置腳本會自動將 `AppIcon.png` 轉為 `AppIcon.icns` 並放入 `.app/Contents/Resources`，不需要開啟 Xcode。
3. 完成後會產生 `Light DOCX Viewer.app` 並自動開啟，使用 `⌘O` 選取 DOCX。
4. 若想雙擊開啟 DOCX，可在 Finder 對 DOCX 按右鍵 →「取得資訊」→「打開檔案的應用程式」，選擇建置好的 App。

### 使用方式

- 文字：滑鼠拖曳選取，`⌘C` 複製。
- 圖片：點選圖片，`⌘C` 複製，切換至其他 App 後 `⌘V` 貼上。
- 僅供閱讀，不支援編輯或儲存 DOCX。

### 限制

- 支援主要文件 XML 中的段落、表格內文字、文字換行，以及行內 DrawingML 圖片。
- 不重現原始字型、頁面、表格格線與欄位排版。
- 浮動圖片、VML 舊式圖片、文字方塊、註解、頁首、頁尾、註腳、外部連結圖片可能無法顯示。
- 開啟時解壓縮至暫存目錄，載入後立即清除。
