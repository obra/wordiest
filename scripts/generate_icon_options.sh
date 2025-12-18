#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="${ROOT_DIR}/docs/app-store/icon-options"
FONT_PATH="${ROOT_DIR}/Wordiest/Resources/IstokWeb-Bold.ttf"

mkdir -p "${OUT_DIR}"

if ! command -v magick >/dev/null 2>&1; then
  echo "error: ImageMagick 'magick' not found" >&2
  exit 1
fi

if [[ ! -f "${FONT_PATH}" ]]; then
  echo "error: expected font at ${FONT_PATH}" >&2
  exit 1
fi

TMP_DIR="$(mktemp -d)"
cleanup() { rm -rf "${TMP_DIR}"; }
trap cleanup EXIT

tile_base() {
  local out="$1"
  local size="${2:-740}"
  local corner="${3:-110}"
  local stroke="${4:-22}"
  local inset="${5:-40}"

  magick -size "${size}x${size}" xc:none \
    -fill "#FFFFFF" -stroke "#1A1A1A" -strokewidth "${stroke}" \
    -draw "roundrectangle ${inset},${inset} $((size-inset)),$((size-inset)) ${corner},${corner}" \
    "${out}"
}

tile_with_letter() {
  local out="$1"
  local tile="$2"
  local letter="${3:-W}"
  local pts="${4:-520}"
  local y_offset="${5:-20}"

  magick "${tile}" \
    -font "${FONT_PATH}" -gravity center -fill "#151515" \
    -pointsize "${pts}" -annotate "+0+${y_offset}" "${letter}" \
    "${out}"
}

shadowed() {
  local out="$1"
  local img="$2"
  local sigma="${3:-14}"
  local opacity="${4:-60}"
  local x="${5:-0}"
  local y="${6:-26}"

  magick "${img}" -alpha set \
    \( +clone -background black -shadow "${opacity}x${sigma}+${x}+${y}" \) \
    +swap -background none -layers merge +repage \
    "${out}"
}

tile="${TMP_DIR}/tile.png"
tile_w="${TMP_DIR}/tile_w.png"
tile_base "${tile}"
tile_with_letter "${tile_w}" "${tile}" "W"

tile_shadow="${TMP_DIR}/tile_w_shadow.png"
shadowed "${tile_shadow}" "${tile_w}"

# Option A: warm yellow + slight tilt (classic tile vibe)
magick -size 1024x1024 xc:"#F4D84B" \
  \( "${tile_shadow}" -background none -rotate -12 \) -gravity center -composite \
  -alpha off \
  "${OUT_DIR}/A-warm-tile.png"

# Option B: neutral gray gradient + flat tile (clean + modern)
magick -size 1024x1024 radial-gradient:"#F7F7F7"-"#D8D8D8" \
  "${tile_shadow}" -gravity center -composite \
  -alpha off \
  "${OUT_DIR}/B-clean-gray.png"

# Option C: deep blue gradient + white tile (bold, high contrast)
magick -size 1024x1024 radial-gradient:"#3B82F6"-"#0B1A3A" \
  \( "${tile_shadow}" -background none -rotate 8 \) -gravity center -composite \
  -alpha off \
  "${OUT_DIR}/C-blue-badge.png"

# Option D: subtle quadrant chart nod + tile (ties to after-round screen, still simple)
magick -size 1024x1024 xc:"#FFFFFF" \
  -stroke "#E3E3E3" -strokewidth 18 -draw "line 512,160 512,864" \
  -stroke "#E3E3E3" -strokewidth 18 -draw "line 160,512 864,512" \
  -fill "#111111" -stroke none \
  -draw "circle 720,520 730,520" -draw "circle 760,560 770,560" -draw "circle 680,600 690,600" \
  -draw "circle 320,440 330,440" -draw "circle 360,380 370,380" \
  \( "${tile_shadow}" -background none -rotate -6 \) -gravity center -composite \
  -colorspace sRGB -alpha off \
  "${OUT_DIR}/D-quadrants.png"

# Option E: dark mode friendly + bright tile (simple and legible)
magick -size 1024x1024 xc:"#0F0F12" \
  \( "${tile_shadow}" -background none -rotate 10 \) -gravity center -composite \
  -alpha off \
  "${OUT_DIR}/E-dark.png"

# Quick comparison sheet
magick montage \
  "${OUT_DIR}/A-warm-tile.png" \
  "${OUT_DIR}/B-clean-gray.png" \
  "${OUT_DIR}/C-blue-badge.png" \
  "${OUT_DIR}/D-quadrants.png" \
  "${OUT_DIR}/E-dark.png" \
  -tile 5x1 -geometry 220x220+24+24 -background "#FFFFFF" \
  "${OUT_DIR}/preview-montage.png"

echo "Wrote icon options to: ${OUT_DIR}"
