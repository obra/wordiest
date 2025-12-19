#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="${ROOT_DIR}/docs/app-store/icon-options"
RESULT_BUNDLE="${ROOT_DIR}/.tmp/app-icon-export.xcresult"
ATTACH_DIR="${ROOT_DIR}/.tmp/app-icon-export-attachments"

mkdir -p "${ROOT_DIR}/.tmp" "${OUT_DIR}"
rm -rf "${RESULT_BUNDLE}" "${ATTACH_DIR}"

DESTINATION="${DESTINATION:-platform=iOS Simulator,name=iPhone 16 Pro}"

echo "Running icon export test (${DESTINATION})..."
xcodebuild \
  -project "${ROOT_DIR}/Wordiest.xcodeproj" \
  -scheme Wordiest \
  -destination "${DESTINATION}" \
  -resultBundlePath "${RESULT_BUNDLE}" \
  'SWIFT_ACTIVE_COMPILATION_CONDITIONS=$(inherited) WORDIEST_ICON_EXPORT' \
  -only-testing:WordiestTests/AppIconExportTests/testExportAppIconOptionC \
  test \
  | cat

echo "Exporting test attachments..."
xcrun xcresulttool export attachments \
  --path "${RESULT_BUNDLE}" \
  --output-path "${ATTACH_DIR}"

MANIFEST="${ATTACH_DIR}/manifest.json"
if [[ ! -f "${MANIFEST}" ]]; then
  echo "error: expected manifest.json at ${MANIFEST}" >&2
  exit 1
fi

EXPORT_PATH="$(
  python3 - <<'PY' "${MANIFEST}"
import json
import sys
from pathlib import Path

manifest_path = Path(sys.argv[1])
obj = json.loads(manifest_path.read_text())

matches = []
tests = obj if isinstance(obj, list) else obj.get("tests", [])
for test in tests:
  for att in (test.get("attachments", []) or []):
    suggested = att.get("suggestedHumanReadableName", "")
    exported = att.get("exportedFileName", "")
    if suggested.startswith("C-blue-badge") and exported:
      matches.append(exported)

if not matches:
  print("", end="")
  sys.exit(0)

print(matches[-1], end="")
PY
)"

if [[ -z "${EXPORT_PATH}" ]]; then
  echo "error: attachment C-blue-badge.png not found in xcresult export" >&2
  exit 1
fi

SRC="${ATTACH_DIR}/${EXPORT_PATH}"
DEST="${OUT_DIR}/C-blue-badge.png"

if [[ ! -f "${SRC}" ]]; then
  echo "error: expected exported attachment at ${SRC}" >&2
  exit 1
fi

if command -v magick >/dev/null 2>&1; then
  # Ensure App Store–safe: no alpha channel.
  magick "${SRC}" -colorspace sRGB -alpha off "${DEST}"
else
  cp -f "${SRC}" "${DEST}"
fi

echo "Wrote: ${DEST}"
