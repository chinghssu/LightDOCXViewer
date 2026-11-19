#!/bin/bash
# Sign, notarize, and staple Light DOCX Viewer.app for distribution outside the Mac App Store.
# Requires a "Developer ID Application" certificate in the login keychain and, for notarization,
# credentials stored once with:
#   xcrun notarytool store-credentials "notary-profile" --apple-id "<Apple ID>" --team-id "<Team ID>"
#
# Usage:
#   bash sign-and-notarize.command              # sign + notarize + staple + package
#   bash sign-and-notarize.command --sign-only  # sign and verify only (no notarization)
#
# Optional environment variables:
#   SIGN_IDENTITY   Signing identity to use (default: first "Developer ID Application" identity)
#   NOTARY_PROFILE  notarytool keychain profile name (default: notary-profile)
set -euo pipefail
cd "$(dirname "$0")"

APP="$PWD/Light DOCX Viewer.app"
NOTARY_PROFILE="${NOTARY_PROFILE:-notary-profile}"
SIGN_ONLY=false

for ARG in "$@"; do
    case "$ARG" in
        --sign-only) SIGN_ONLY=true ;;
        *) echo "Unknown option: $ARG" >&2; exit 2 ;;
    esac
done

if [ ! -d "$APP" ]; then
    echo "App not found: $APP" >&2
    echo "Run 'bash build.command' first." >&2
    exit 1
fi

# Pick the Developer ID identity automatically unless one was given explicitly.
if [ -z "${SIGN_IDENTITY:-}" ]; then
    SIGN_IDENTITY=$(security find-identity -v -p codesigning \
        | sed -n 's/.*"\(Developer ID Application: .*\)"/\1/p' | head -n 1)
fi
if [ -z "$SIGN_IDENTITY" ]; then
    echo "No 'Developer ID Application' signing identity found in the keychain." >&2
    echo "Create one in your Apple Developer account, or set SIGN_IDENTITY." >&2
    exit 1
fi

VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" Info.plist)

# Work on a copy outside the project folder: iCloud Drive or other file providers keep
# re-adding Finder metadata (com.apple.FinderInfo) to synced folders, which breaks codesign.
WORK=$(mktemp -d "${TMPDIR:-/tmp}/lightdocxviewer-sign.XXXXXX")
trap 'rm -rf "$WORK"' EXIT
SIGNED_APP="$WORK/Light DOCX Viewer.app"
/usr/bin/ditto --norsrc --noextattr --noacl "$APP" "$SIGNED_APP"
/usr/bin/xattr -cr "$SIGNED_APP"
SUBMIT_ZIP="$WORK/LightDOCXViewer-notarize.zip"

# Sign with the hardened runtime and a secure timestamp, both required for notarization.
echo "==> Signing with: $SIGN_IDENTITY"
/usr/bin/codesign --force --options runtime --timestamp --sign "$SIGN_IDENTITY" "$SIGNED_APP"
/usr/bin/codesign --verify --strict --verbose=2 "$SIGNED_APP"

if [ "$SIGN_ONLY" = true ]; then
    OUTPUT_ZIP="$PWD/LightDOCXViewer-$VERSION-unnotarized.zip"
    rm -f "$OUTPUT_ZIP"
    /usr/bin/ditto -c -k --keepParent "$SIGNED_APP" "$OUTPUT_ZIP"
    echo "Signed (not notarized): $OUTPUT_ZIP"
    exit 0
fi

# Submit to Apple's notary service and wait for the verdict.
echo "==> Submitting for notarization (profile: $NOTARY_PROFILE)"
rm -f "$SUBMIT_ZIP"
/usr/bin/ditto -c -k --keepParent "$SIGNED_APP" "$SUBMIT_ZIP"
set +e
RESULT=$(xcrun notarytool submit "$SUBMIT_ZIP" --keychain-profile "$NOTARY_PROFILE" --wait 2>&1)
STATUS=$?
set -e
echo "$RESULT"

if [ $STATUS -ne 0 ] || ! echo "$RESULT" | grep -q "status: Accepted"; then
    SUBMISSION_ID=$(echo "$RESULT" | sed -n 's/^ *id: \([0-9a-f-]*\).*/\1/p' | head -n 1)
    if [ -n "$SUBMISSION_ID" ]; then
        echo "==> Notarization log:"
        xcrun notarytool log "$SUBMISSION_ID" --keychain-profile "$NOTARY_PROFILE" || true
    fi
    echo "Notarization failed." >&2
    exit 1
fi

# Attach the notarization ticket so the app verifies offline, then confirm Gatekeeper accepts it.
echo "==> Stapling"
xcrun stapler staple "$SIGNED_APP"
/usr/sbin/spctl --assess --type execute --verbose "$SIGNED_APP"

# Package the stapled app for distribution (for example, as a GitHub Release asset).
RELEASE_ZIP="$PWD/LightDOCXViewer-$VERSION.zip"
rm -f "$RELEASE_ZIP"
/usr/bin/ditto -c -k --keepParent "$SIGNED_APP" "$RELEASE_ZIP"
echo "Notarized release ready: $RELEASE_ZIP"
