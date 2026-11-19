# Light DOCX Viewer

[English](README.md) | [繁體中文](README.zh-TW.md) | [日本語](README.ja.md) | **한국어** | [Deutsch](README.de.md) | [Español](README.es.md) | [Français](README.fr.md)

`.docx` 파일의 **텍스트와 인라인 이미지를 읽는 순서대로 보여 주는** 가볍고 네이티브한 macOS 뷰어입니다. Microsoft Word의 페이지 레이아웃은 재현하지 않습니다.

단순한 작업 흐름을 위해 설계되었습니다: 문서를 열고, 내용을 읽고, 텍스트를 복사하고, 포함된 이미지를 다른 앱으로 복사합니다.

> **상태: 초기 프로토타입 (v0.1.2).** macOS에서 빌드 및 실행됩니다. 일부 DOCX 파일은 완전히 표시되지 않을 수 있습니다. 버그 제보와 기여를 환영합니다.

## 기능

- 네이티브 AppKit 창에서 **DOCX 파일 읽기**.
- 지원되는 텍스트와 인라인 이미지의 **내용 순서 유지** (예: 문단 → 이미지 → 문단).
- **텍스트 복사**: 텍스트를 선택하고 `⌘C`를 누릅니다.
- **포함된 이미지 복사**: 이미지를 클릭하고 `⌘C`를 누른 뒤, 다른 앱에서 `⌘V`로 붙여 넣습니다.
- **읽기 전용** 설계: 문서 편집이나 저장은 지원하지 않습니다.
- 실행에 **Microsoft Word, Pages, Python 런타임, 서드파티 라이브러리가 필요하지 않습니다**.
- 빌드 시 **사용자 지정 앱 아이콘이 자동으로 생성**됩니다.

## 요구 사항

- macOS 12 이상 (`Info.plist` 설정 기준)
- 빌드용 Apple Command Line Tools (`swiftc`, `sips`, `iconutil`)

## 소스에서 빌드

1. 이 저장소를 클론하거나 다운로드합니다.
2. 필요하면 Command Line Tools를 설치합니다:

   ```bash
   xcode-select --install
   ```

3. 터미널에서 프로젝트 폴더로 이동한 뒤 다음을 실행합니다:

   ```bash
   bash build.command
   ```

스크립트는 프로젝트 폴더에 `Light DOCX Viewer.app`을 빌드하고, `AppIcon.png`로부터 `AppIcon.icns`를 생성한 뒤 앱을 실행합니다.

**참고:** 이것은 로컬에서 빌드된 서명되지 않은 프로토타입이며, 공증(notarized)된 macOS 릴리스가 아닙니다. 앱 아이콘에 사선이 표시되는 것은 반드시 Gatekeeper 격리 문제 때문은 아니며, 앱 번들이 호환되지 않거나 유효하지 않다는 뜻일 수 있습니다. macOS 보안 설정을 우회하기 전에 먼저 빌드 출력과 앱 번들을 확인하세요.

## 서명 및 공증 (선택)

다른 Mac에서 Gatekeeper 경고 없이 열리도록 배포하려면 **Developer ID Application** 인증서로 서명하고 Apple 공증을 받아야 합니다. 유료 Apple Developer 계정이 필요합니다.

1. 로그인 키체인에 `Developer ID Application` 인증서가 있는지 확인합니다 (`security find-identity -v -p codesigning`).
2. account.apple.com에서 앱 암호를 만든 뒤, 공증용 자격 증명을 키체인에 저장합니다 (최초 1회):

   ```bash
   xcrun notarytool store-credentials "notary-profile" \
     --apple-id "<Apple ID>" --team-id "<Team ID>"
   ```

3. 빌드한 다음 서명, 공증, 스테이플을 실행합니다:

   ```bash
   bash build.command
   bash sign-and-notarize.command
   ```

스크립트는 앱 사본에 Hardened Runtime으로 서명하고, `notarytool`로 제출하고, 공증 티켓을 스테이플하고, `spctl`로 확인한 뒤, GitHub Release에 첨부할 수 있는 `LightDOCXViewer-<버전>.zip`을 프로젝트 폴더에 만듭니다.

- 공증 없이 서명만 하려면 (로컬 테스트용):

  ```bash
  bash sign-and-notarize.command --sign-only
  ```

  `LightDOCXViewer-<버전>-unnotarized.zip`이 만들어집니다.
- 선택 환경 변수: `SIGN_IDENTITY` (기본값은 첫 번째 Developer ID Application 인증서), `NOTARY_PROFILE` (기본값은 `notary-profile`).
- iCloud Drive 같은 파일 제공자가 동기화 폴더에 Finder 메타데이터를 계속 다시 붙여 `codesign`이 실패하므로, 서명은 임시 디렉터리에서 진행합니다.
- Apple ID, 앱 암호, 배포용 zip 파일은 절대 저장소에 커밋하지 마세요.

## 사용 방법

앱을 열고 `⌘O`를 눌러 `.docx` 파일을 선택합니다. 또는 Finder에서 DOCX를 선택하고 **다음으로 열기 → Light DOCX Viewer**를 선택합니다.

텍스트를 복사하려면 텍스트를 선택하고 `⌘C`를 누릅니다. 그림을 복사하려면 인라인 이미지를 한 번 클릭하고 `⌘C`를 누른 뒤 다른 애플리케이션에 붙여 넣습니다.

기본 DOCX 뷰어로 지정하려면 Finder에서 `.docx`를 선택하고 **정보 가져오기 → 다음으로 열기**에서 이 앱을 선택한 뒤 **모두 변경**을 클릭합니다. 앱이 사용 중인 Mac에서 올바르게 실행되는지 확인한 후에 설정하세요.

## 알려진 제한 사항

이 앱은 **내용 중심의 뷰어**이며, Word 레이아웃을 충실히 재현하는 렌더러가 아닙니다.

- 본문 문서의 기본 텍스트, 줄 바꿈, 표 안의 텍스트, 지원되는 인라인 DrawingML 이미지를 지원합니다.
- Word처럼 페이지 나누기, 글꼴, 여백, 단, 표 테두리를 재현하지 않습니다.
- DOCX 파일은 임시 디렉터리에 압축 해제되며, 불러온 직후 삭제됩니다.
- 떠 있는 이미지, 구형 VML 이미지, 텍스트 상자, 머리글, 바닥글, 각주, 메모, 외부 링크 이미지는 표시되지 않거나 순서가 어긋날 수 있습니다.
- 이미지 복사는 인라인 첨부로 불러온 이미지를 대상으로 하며, 다양한 DOCX 파일과 대상 앱에서의 동작은 아직 테스트가 필요합니다.
- 일부 DOCX 파일은 파싱에 실패하거나 완전히 표시되지 않을 수 있습니다.
- 자동화된 테스트, 공증, 서명된 바이너리는 아직 포함되어 있지 않습니다.

## 앱 아이콘

- 원본 이미지: `AppIcon.png` (저장소에 포함).
- `build.command`는 macOS 기본 도구인 `sips`와 `iconutil`을 사용해 모든 표준 크기의 `AppIcon.icns`를 생성하고 `.app/Contents/Resources`에 넣습니다.
- `Info.plist`에서 `CFBundleIconFile`을 `AppIcon`으로 설정합니다.
- Finder에 이전 아이콘이 계속 표시되면 앱을 다른 위치로 옮기거나 Finder를 재시작해 아이콘 캐시를 갱신하세요.

## 프로젝트 구조

```text
.
├── LightDOCXViewer.swift   # AppKit 인터페이스, DOCX XML 파싱, 클립보드 지원
├── AppIcon.png             # macOS 앱 아이콘 원본 이미지
├── Info.plist              # 앱 번들 메타데이터와 DOCX 파일 연결
├── build.command           # macOS 앱 빌드와 아이콘 생성을 한 번에 실행
├── sign-and-notarize.command  # Developer ID 서명, 공증, 스테이플
├── LICENSE                 # MIT 라이선스
├── README.md               # 영어 문서
└── README.*.md             # 번역된 문서
```

## 작동 방식

DOCX 파일은 ZIP 컨테이너입니다. 앱은 macOS의 `ditto`로 DOCX를 임시로 압축 해제하고, `XMLParser`로 `word/document.xml`과 이미지 관계 정보를 읽은 다음, `NSTextView`와 `NSTextAttachment`로 텍스트와 이미지를 표시합니다. 불러온 뒤에는 임시 압축 해제 디렉터리를 삭제합니다. 이미지 복사에는 macOS 페이스트보드를 사용합니다.

Office Open XML의 포괄적인 렌더링보다 간단한 읽기와 복사를 의도적으로 우선합니다.

## 기여하기

버그 제보, 재현 가능한 샘플 문서(민감한 정보는 제거해 주세요), 수정 사항, 호환성 개선을 환영합니다. 특히 macOS 빌드 검증, 더 안전한 압축 파일 처리, 더 폭넓은 DOCX 이미지 지원이 큰 도움이 됩니다.

## 라이선스

[MIT License](LICENSE)로 배포됩니다.

Microsoft와 Word는 Microsoft Corporation의 상표입니다. 이 프로젝트는 Microsoft와 관련이 없으며 Microsoft의 보증을 받지 않았습니다.
