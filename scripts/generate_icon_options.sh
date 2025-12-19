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

tile_base_4w() {
  local out="$1"
  local size="${2:-740}"
  local inset="${3:-40}"
  local stroke="${4:-22}"

  local tab_height=110
  local corner=110
  local tab_corner=55

  local full_top="${inset}"
  local full_bottom=$((size - inset))
  local main_left="${inset}"
  local main_right=$((size - inset))
  local main_top=$((inset + tab_height))
  local main_bottom=$((size - inset - tab_height))

  local tab_width=240
  local tab_left=$(((size - tab_width) / 2))
  local tab_right=$((tab_left + tab_width))

  local svg="${TMP_DIR}/tile4w.svg"
  cat >"${svg}" <<SVG
<svg xmlns="http://www.w3.org/2000/svg" width="${size}" height="${size}" viewBox="0 0 ${size} ${size}">
  <path
    fill="#FFFFFF"
    stroke="#1A1A1A"
    stroke-width="${stroke}"
    stroke-linejoin="round"
    d="
      M $((main_left + corner)) ${main_top}
      L ${tab_left} ${main_top}
      L ${tab_left} $((full_top + tab_corner))
      Q ${tab_left} ${full_top} $((tab_left + tab_corner)) ${full_top}
      L $((tab_right - tab_corner)) ${full_top}
      Q ${tab_right} ${full_top} ${tab_right} $((full_top + tab_corner))
      L ${tab_right} ${main_top}
      L $((main_right - corner)) ${main_top}
      Q ${main_right} ${main_top} ${main_right} $((main_top + corner))
      L ${main_right} $((main_bottom - corner))
      Q ${main_right} ${main_bottom} $((main_right - corner)) ${main_bottom}
      L ${tab_right} ${main_bottom}
      L ${tab_right} $((full_bottom - tab_corner))
      Q ${tab_right} ${full_bottom} $((tab_right - tab_corner)) ${full_bottom}
      L $((tab_left + tab_corner)) ${full_bottom}
      Q ${tab_left} ${full_bottom} ${tab_left} $((full_bottom - tab_corner))
      L ${tab_left} ${main_bottom}
      L $((main_left + corner)) ${main_bottom}
      Q ${main_left} ${main_bottom} ${main_left} $((main_bottom - corner))
      L ${main_left} $((main_top + corner))
      Q ${main_left} ${main_top} $((main_left + corner)) ${main_top}
      Z
    "
  />
</svg>
SVG

  # rsvg-convert yields a clean single-stroke outline (no double-stroke artifacts).
  rsvg-convert -w "${size}" -h "${size}" "${svg}" -o "${out}"
}

tile_with_letter() {
  local out="$1"
  local tile="$2"
  local letter="${3:-W}"
  local pts="${4:-520}"
  local y_offset="${5:-0}"

  local glyph="${TMP_DIR}/glyph-${letter}-${pts}.png"
  magick -background none -fill "#151515" -font "${FONT_PATH}" -pointsize "${pts}" \
    "label:${letter}" -trim +repage "${glyph}"

  magick "${tile}" "${glyph}" \
    -gravity center -geometry "+0+${y_offset}" -composite \
    "${out}"
}

tile_add_value_and_bonus() {
  local out="$1"
  local tile="$2"
  local letter_value="${3:-4}"
  local bonus_label="${4:-4W}"

  local size=740
  local inset=40
  local tab_height=110

  local main_right=$((size - inset))
  local main_bottom=$((size - inset - tab_height))
  local value_inset=70

  local value_dx=$(( (size - main_right) + value_inset ))
  local value_dy=$(( (size - main_bottom) + value_inset ))

  local value_glyph="${TMP_DIR}/glyph-value-${letter_value}.png"
  magick -background none -fill "#151515" -font "${FONT_PATH}" -pointsize 92 \
    "label:${letter_value}" -trim +repage "${value_glyph}"

  local bonus_glyph="${TMP_DIR}/glyph-bonus-${bonus_label}.png"
  magick -background none -fill "#151515" -font "${FONT_PATH}" -pointsize 92 \
    "label:${bonus_label}" -trim +repage "${bonus_glyph}"

  magick "${tile}" \
    "${bonus_glyph}" -gravity north -geometry "+0+58" -composite \
    "${bonus_glyph}" -gravity south -geometry "+0+58" -composite \
    "${value_glyph}" -gravity southeast -geometry "+${value_dx}+${value_dy}" -composite \
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

# 4W tile used for icon option C
tile4w="${TMP_DIR}/tile4w.png"
tile4w_letter="${TMP_DIR}/tile4w_letter.png"
tile4w_full="${TMP_DIR}/tile4w_full.png"
tile_base_4w "${tile4w}"
tile_with_letter "${tile4w_letter}" "${tile4w}" "W" 470 8
tile_add_value_and_bonus "${tile4w_full}" "${tile4w_letter}" "4" "4W"

tile4w_shadow="${TMP_DIR}/tile4w_shadow.png"
shadowed "${tile4w_shadow}" "${tile4w_full}"

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
echo "Skipping Option C here; run scripts/export_icon_option_c.sh to generate it using the in-app renderer."

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
  "${OUT_DIR}/D-quadrants.png" \
  "${OUT_DIR}/E-dark.png" \
  -tile 4x1 -geometry 220x220+24+24 -background "#FFFFFF" \
  "${OUT_DIR}/preview-montage.png"

echo "Wrote icon options to: ${OUT_DIR}"
