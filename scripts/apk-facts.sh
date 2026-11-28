#!/usr/bin/env bash
# Checks FACTS about a built release APK: what Android will actually install, not what the sources say.
# Used by the release gate (.github/workflows/release-gates.yml).
#
#   bash scripts/apk-facts.sh <apk> <api-base-url>
#
# Needs aapt2 (Android SDK build-tools): set AAPT2, or have ANDROID_HOME set.
set -uo pipefail

APK="${1:?usage: apk-facts.sh <apk> <api-base-url>}"
API="${2:?usage: apk-facts.sh <apk> <api-base-url>}"
AAPT2="${AAPT2:-$(ls -d "${ANDROID_HOME:?set ANDROID_HOME or AAPT2}"/build-tools/* | sort -V | tail -1)/aapt2}"
failed=0
pass() { echo "  ok   $1"; }
fail() { echo "  FAIL $1"; failed=1; }

manifest=$("$AAPT2" dump xmltree --file AndroidManifest.xml "$APK") || { echo "cannot read $APK"; exit 1; }
# attr <name>: the value of the first android:<name> attribute in the merged manifest, empty if not set
attr() { sed -n "s/.*android:$1([^)]*)=\([^ ]*\).*/\1/p" <<<"$manifest" | head -1; }

echo "Facts about $APK"

echo "- it is a release build"
[ "$(attr debuggable)" != "true" ] && pass "not debuggable" || fail "android:debuggable is true"

echo "- user data stays on the device"
[ "$(attr allowBackup)" = "false" ] && pass "allowBackup is false" || fail "allowBackup is '$(attr allowBackup)', not false"

echo "- it only talks https"
[ "$(attr usesCleartextTraffic)" != "true" ] && pass "cleartext traffic is not allowed" \
  || fail "usesCleartextTraffic is true (only the debug manifest may allow it)"
case "$API" in
  https://*) pass "the API address is https ($API)" ;;
  *) fail "the API address is not https: $API" ;;
esac

echo "- it talks to the right API"
libs=$(unzip -Z1 "$APK" 'lib/*/libapp.so' 2>/dev/null)
[ -n "$libs" ] || fail "no lib/*/libapp.so in the APK"
for lib in $libs; do
  # grep -c, not -q: -q stops reading early, and with pipefail the killed unzip would count as a failure
  [ "$(unzip -p "$APK" "$lib" | LC_ALL=C grep -acF "$API")" -gt 0 ] \
    && pass "$API is compiled into $lib" || fail "$API is not in $lib (was --dart-define=API_BASE_URL passed?)"
done

[ "$failed" = 0 ] && echo "All facts hold." || { echo "Some facts do not hold."; exit 1; }
