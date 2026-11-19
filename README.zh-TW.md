# Light DOCX Viewer

[English](README.md) | **繁體中文** | [日本語](README.ja.md) | [한국어](README.ko.md) | [Deutsch](README.de.md) | [Español](README.es.md) | [Français](README.fr.md)

一個輕量的原生 macOS `.docx` 閱讀器，依照**閱讀順序呈現文字與行內圖片**，不重現 Microsoft Word 的頁面排版。

設計目的很單純：開啟文件、閱讀內容、複製文字，並把內嵌圖片複製到其他 App。

> **狀態：早期原型（v0.1.2）。** 可在 macOS 上建置與執行，部分 DOCX 可能無法完整顯示。歡迎回報問題與貢獻程式碼。

## 功能

- 在原生 AppKit 視窗中**閱讀 DOCX 檔案**。
- 支援的文字與行內圖片會**維持原本的內容順序**（例如：段落 → 圖片 → 段落）。
- **複製文字**：選取文字後按 `⌘C`。
- **複製內嵌圖片**：點選圖片後按 `⌘C`，再到其他 App 按 `⌘V` 貼上。
- 設計上**僅供閱讀**，不支援編輯或儲存文件。
- 執行時**不需要 Microsoft Word、Pages、Python 或任何第三方套件**。
- 建置時會**自動產生自訂 App 圖示**。

## 系統需求

- macOS 12 或更新版本（依 `Info.plist` 設定）
- 建置需要 Apple Command Line Tools（`swiftc`、`sips`、`iconutil`）

## 從原始碼建置

1. Clone 或下載本 repository。
2. 如有需要，先安裝 Command Line Tools：

   ```bash
   xcode-select --install
   ```

3. 在 Terminal 進入專案資料夾，執行：

   ```bash
   bash build.command
   ```

腳本會在專案資料夾中建置 `Light DOCX Viewer.app`，從 `AppIcon.png` 產生 `AppIcon.icns`，並嘗試開啟 App。

**注意：** 這是本機建置、未簽署的原型，不是經過 Apple 公證（notarized）的正式版本。如果 App 圖示出現斜線，不一定是 Gatekeeper 隔離造成，也可能是 App bundle 不相容或無效。請先檢查建置輸出與 App bundle，不要直接繞過 macOS 的安全設定。

## 簽章與公證（選用）

若要發佈給其他人使用，並讓 App 在其他 Mac 上開啟時不被 Gatekeeper 擋下，需要用 **Developer ID Application** 憑證簽章，並送 Apple 公證。這需要付費的 Apple Developer 帳號。

1. 確認登入鑰匙圈中有 `Developer ID Application` 憑證（`security find-identity -v -p codesigning`）。
2. 到 account.apple.com 產生「App 專用密碼」，再把公證用的登入資訊存進鑰匙圈（只需設定一次）：

   ```bash
   xcrun notarytool store-credentials "notary-profile" \
     --apple-id "<Apple ID>" --team-id "<Team ID>"
   ```

3. 建置後，執行簽章、公證與釘選：

   ```bash
   bash build.command
   bash sign-and-notarize.command
   ```

腳本會用 Hardened Runtime 簽署 App 的副本，透過 `notarytool` 送出公證、釘選公證票證、用 `spctl` 檢查，最後在專案資料夾產生 `LightDOCXViewer-<版本>.zip`，可直接上傳到 GitHub Releases。

- 只簽章、不公證（本機測試用）：

  ```bash
  bash sign-and-notarize.command --sign-only
  ```

  會產生 `LightDOCXViewer-<版本>-unnotarized.zip`。
- 可選的環境變數：`SIGN_IDENTITY`（預設為第一個 Developer ID Application 憑證）與 `NOTARY_PROFILE`（預設為 `notary-profile`）。
- 簽章會在暫存目錄進行，因為 iCloud 雲碟等同步服務會不斷在同步資料夾中加回 Finder 中繼資料，導致 `codesign` 失敗。
- 切勿將 Apple ID、App 專用密碼或發佈用 zip 檔 commit 到 repository。

## 使用方式

開啟 App 後按 `⌘O` 選擇 `.docx` 檔案。也可以在 Finder 中對 DOCX 按右鍵，選擇**「打開檔案的應用程式」→ Light DOCX Viewer**。

複製文字：選取文字後按 `⌘C`。複製圖片：點一下行內圖片，按 `⌘C`，再貼到其他應用程式。

若想設為預設的 DOCX 閱讀器，在 Finder 選取一個 `.docx`，選擇**「取得資訊」→「打開檔案的應用程式」**，選擇本 App 後按**「全部更改」**。請先確認 App 能在你的 Mac 上正常執行再這樣設定。

## 已知限制

這是**以內容為主的閱讀器**，不是忠實重現 Word 排版的渲染器。

- 支援主要文件中的基本文字、換行、表格內文字，以及支援的行內 DrawingML 圖片。
- 不重現 Word 中的分頁、字型、邊界、欄位或表格框線。
- DOCX 會解壓縮到暫存目錄，載入後立即刪除。
- 浮動圖片、VML 舊式圖片、文字方塊、頁首、頁尾、註腳、註解與外部連結圖片可能無法顯示或順序錯亂。
- 圖片複製功能針對以行內附件載入的圖片；在不同 DOCX 檔案與目標 App 之間的行為仍需更多測試。
- 部分 DOCX 檔案可能無法解析或無法完整顯示。
- 目前尚無自動化測試、Apple 公證或已簽署的執行檔。

## App 圖示

- 原始圖檔：`AppIcon.png`（已包含在 repository 中）。
- `build.command` 使用 macOS 內建的 `sips` 與 `iconutil` 產生各種標準尺寸的 `AppIcon.icns`，並放入 `.app/Contents/Resources`。
- `Info.plist` 已將 `CFBundleIconFile` 設為 `AppIcon`。
- 若 Finder 仍顯示舊圖示，將 App 移到其他位置或重新啟動 Finder，以更新圖示快取。

## 專案結構

```text
.
├── LightDOCXViewer.swift   # AppKit 介面、DOCX XML 解析與剪貼簿支援
├── AppIcon.png             # macOS App 圖示的原始圖檔
├── Info.plist              # App bundle 資訊與 DOCX 檔案關聯
├── build.command           # 一鍵建置 macOS App 與產生圖示
├── sign-and-notarize.command  # Developer ID 簽章、公證與釘選
├── LICENSE                 # MIT 授權
├── README.md               # 英文說明文件
└── README.*.md             # 其他語言的說明文件
```

## 運作原理

DOCX 檔案其實是 ZIP 壓縮檔。App 會用 macOS 的 `ditto` 將 DOCX 暫時解壓縮，用 `XMLParser` 讀取 `word/document.xml` 及其圖片關聯，再透過 `NSTextView` 與 `NSTextAttachment` 呈現文字與圖片。載入完成後會刪除暫存的解壓縮目錄。圖片複製使用 macOS 剪貼簿。

本專案刻意以簡單的閱讀與複製為優先，而不是完整渲染 Office Open XML。

## 參與貢獻

歡迎回報問題、提供可重現問題的範例文件（請先移除敏感資訊）、修正錯誤與改善相容性。特別歡迎 macOS 建置驗證、更安全的壓縮檔處理，以及更廣泛的 DOCX 圖片支援。

## 授權

本專案以 [MIT License](LICENSE) 釋出。

Microsoft 與 Word 是 Microsoft Corporation 的商標。本專案與 Microsoft 無任何關聯，亦未獲其背書。
