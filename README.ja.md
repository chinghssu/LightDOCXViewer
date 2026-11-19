# Light DOCX Viewer

[English](README.md) | [繁體中文](README.zh-TW.md) | **日本語** | [한국어](README.ko.md) | [Deutsch](README.de.md) | [Español](README.es.md) | [Français](README.fr.md)

`.docx` ファイルの**テキストとインライン画像を読む順番どおりに表示する**、軽量なネイティブ macOS ビューアです。Microsoft Word のページレイアウトは再現しません。

シンプルな用途を想定しています：文書を開いて内容を読み、テキストをコピーし、埋め込み画像を他のアプリにコピーする。

> **ステータス：初期プロトタイプ（v0.1.2）。** macOS でビルド・実行できます。一部の DOCX ファイルは完全に表示されない場合があります。不具合報告やコントリビューションを歓迎します。

## 機能

- ネイティブの AppKit ウィンドウで **DOCX ファイルを閲覧**。
- 対応するテキストとインライン画像の**内容の順序を維持**（例：段落 → 画像 → 段落）。
- **テキストのコピー**：テキストを選択して `⌘C`。
- **埋め込み画像のコピー**：画像をクリックして `⌘C`、他のアプリで `⌘V` で貼り付け。
- **読み取り専用**の設計：文書の編集や保存はできません。
- 実行に **Microsoft Word、Pages、Python、サードパーティ製ライブラリは不要**。
- ビルド時に**カスタムアプリアイコンを自動生成**。

## 動作環境

- macOS 12 以降（`Info.plist` の設定による）
- ビルドには Apple Command Line Tools（`swiftc`、`sips`、`iconutil`）が必要

## ソースからビルド

1. このリポジトリをクローンまたはダウンロードします。
2. 必要に応じて Command Line Tools をインストールします：

   ```bash
   xcode-select --install
   ```

3. ターミナルでプロジェクトフォルダに移動し、次を実行します：

   ```bash
   bash build.command
   ```

スクリプトはプロジェクトフォルダに `Light DOCX Viewer.app` をビルドし、`AppIcon.png` から `AppIcon.icns` を生成して、アプリを起動します。

**注意：** これはローカルでビルドされた未署名のプロトタイプであり、公証（notarize）済みの macOS リリースではありません。アプリアイコンに斜線が表示される場合、必ずしも Gatekeeper の隔離が原因とは限らず、アプリバンドルが互換性のない、または無効なものである可能性があります。macOS のセキュリティ設定を回避する前に、まずビルド出力とアプリバンドルを確認してください。

## 署名と公証（任意）

他の Mac で Gatekeeper の警告なしに開けるよう配布するには、**Developer ID Application** 証明書で署名し、Apple の公証を受ける必要があります。有料の Apple Developer アカウントが必要です。

1. ログインキーチェーンに `Developer ID Application` 証明書があることを確認します（`security find-identity -v -p codesigning`）。
2. account.apple.com で App 用パスワードを作成し、公証用の認証情報をキーチェーンに保存します（初回のみ）：

   ```bash
   xcrun notarytool store-credentials "notary-profile" \
     --apple-id "<Apple ID>" --team-id "<Team ID>"
   ```

3. ビルドしてから、署名・公証・ステープルを実行します：

   ```bash
   bash build.command
   bash sign-and-notarize.command
   ```

スクリプトはアプリのコピーに Hardened Runtime 付きで署名し、`notarytool` で提出、公証チケットをステープルし、`spctl` で確認したうえで、GitHub Release に添付できる `LightDOCXViewer-<バージョン>.zip` をプロジェクトフォルダに出力します。

- 公証せずに署名だけ行う場合（ローカルテスト用）：

  ```bash
  bash sign-and-notarize.command --sign-only
  ```

  `LightDOCXViewer-<バージョン>-unnotarized.zip` が出力されます。
- 任意の環境変数：`SIGN_IDENTITY`（既定は最初の Developer ID Application 証明書）、`NOTARY_PROFILE`（既定は `notary-profile`）。
- iCloud Drive などのファイルプロバイダは同期フォルダに Finder メタデータを付け直し、`codesign` が失敗する原因になるため、署名は一時ディレクトリで行います。
- Apple ID、App 用パスワード、リリース用 zip はリポジトリにコミットしないでください。

## 使い方

アプリを開き、`⌘O` で `.docx` ファイルを選択します。または Finder で DOCX を選択し、**「このアプリケーションで開く」→ Light DOCX Viewer** を選びます。

テキストをコピーするには、テキストを選択して `⌘C` を押します。画像をコピーするには、インライン画像を一度クリックして `⌘C` を押し、他のアプリケーションに貼り付けます。

デフォルトの DOCX ビューアにしたい場合は、Finder で `.docx` を選択し、**「情報を見る」→「このアプリケーションで開く」** でこのアプリを選んで **「すべてを変更…」** をクリックします。お使いの Mac でアプリが正しく動作することを確認してから設定してください。

## 既知の制限

これは**内容重視のビューア**であり、Word のレイアウトを忠実に再現するレンダラーではありません。

- メイン文書の基本的なテキスト、改行、表内のテキスト、対応するインライン DrawingML 画像をサポートします。
- Word のような改ページ、フォント、余白、段組み、表の罫線は再現しません。
- DOCX は一時ディレクトリに展開され、読み込み後すぐに削除されます。
- フローティング画像、旧式の VML 画像、テキストボックス、ヘッダー、フッター、脚注、コメント、外部リンク画像は表示されない、または順序がずれる場合があります。
- 画像のコピーはインライン添付として読み込まれた画像を対象としています。さまざまな DOCX ファイルや貼り付け先アプリでの動作はまだ検証が必要です。
- 一部の DOCX ファイルは解析に失敗したり、完全に表示されない場合があります。
- 自動テスト、公証、署名済みバイナリはまだ含まれていません。

## アプリアイコン

- 元画像：`AppIcon.png`（リポジトリに含まれています）。
- `build.command` は macOS 標準の `sips` と `iconutil` を使って各標準サイズの `AppIcon.icns` を生成し、`.app/Contents/Resources` に配置します。
- `Info.plist` で `CFBundleIconFile` を `AppIcon` に設定しています。
- Finder に古いアイコンが表示される場合は、アプリを別の場所に移動するか Finder を再起動してアイコンキャッシュを更新してください。

## プロジェクト構成

```text
.
├── LightDOCXViewer.swift   # AppKit インターフェース、DOCX XML の解析、クリップボード対応
├── AppIcon.png             # macOS アプリアイコンの元画像
├── Info.plist              # アプリバンドルのメタデータと DOCX ファイルの関連付け
├── build.command           # macOS アプリのビルドとアイコン生成を一括で実行
├── sign-and-notarize.command  # Developer ID による署名、公証、ステープル
├── LICENSE                 # MIT ライセンス
├── README.md               # 英語のドキュメント
└── README.*.md             # 各言語に翻訳されたドキュメント
```

## 仕組み

DOCX ファイルは ZIP コンテナです。アプリは macOS の `ditto` で DOCX を一時的に展開し、`XMLParser` で `word/document.xml` とその画像リレーションを読み取り、`NSTextView` と `NSTextAttachment` でテキストと画像を表示します。読み込み後、一時展開ディレクトリは削除されます。画像のコピーには macOS のペーストボードを使用します。

Office Open XML を網羅的にレンダリングすることよりも、シンプルな閲覧とコピーを意図的に優先しています。

## コントリビューション

不具合報告、再現可能なサンプル文書（機密情報は削除してください）、修正、互換性の改善を歓迎します。特に macOS でのビルド検証、より安全なアーカイブ処理、より幅広い DOCX 画像のサポートは大きな助けになります。

## ライセンス

[MIT License](LICENSE) の下で公開しています。

Microsoft および Word は Microsoft Corporation の商標です。本プロジェクトは Microsoft とは無関係であり、Microsoft による承認を受けたものではありません。
