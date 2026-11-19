#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC=$ROOT/source/omarchy-katakana.webp
OUT=$ROOT/logo-variants
mkdir -p $OUT
TMP=$(mktemp -d)
W=2048; H=820          # 2x upscale of 1024x410
CW=32; CH=64           # "terminal cell" size in px: 64x13 cells (~char cell aspect 1:2)
CX=$((W/CW)); CY=$((H/CH))

# mask: green text -> white, black bg -> black (upscaled first for smoother edges)
magick "$SRC" -filter Lanczos -resize ${W}x${H}! -channel G -separate +channel -threshold 40% -strip $TMP/mask.png

# coarse(): build a tiny gradient (cells) then blow up with pixel replication
# args: name, gradient-spec ("gradient:a-b" or "gradient:a-b with -define"), rotate degrees, extra ops
coarse() {
  local name=$1 grad=$2 rot=$3; shift 3
  magick -size ${CX}x${CY} -define gradient:angle=$rot "$grad" "$@" -scale ${W}x${H}! +repage $TMP/fill.png
  magick $TMP/fill.png $TMP/mask.png -alpha off -compose CopyOpacity -composite $OUT/$name.png
  magick $OUT/$name.png -background black -flatten $OUT/$name-black.png
}

# multi-stop gradients need a tiny strip: build via -define gradient: with 3+ stops isn't native -> compose from appended gradients
multistop() {  # name rot color1 color2 color3 [color4]
  local name=$1 rot=$2; shift 2
  local n=$(($#-1)) parts=() i=0 a
  local len=$(( rot == 0 ? CY : CX ))
  local seg=$(( len / n ))
  a=$1; shift
  for b in "$@"; do
    i=$((i+1)); local l=$seg; [ $i -eq $n ] && l=$((len - seg*(n-1)))
    if [ $rot -eq 0 ]; then parts+=( "(" -size ${CX}x${l} gradient:$a-$b ")" )
    else parts+=( "(" -size ${CY}x${l} gradient:$a-$b -rotate -90 ")" ); fi
    a=$b
  done
  if [ $rot -eq 0 ]; then magick "${parts[@]}" -append +repage $TMP/strip.png
  else magick "${parts[@]}" +append +repage $TMP/strip.png; fi
  magick $TMP/strip.png -scale ${W}x${H}! +repage $TMP/fill.png
  magick $TMP/fill.png $TMP/mask.png -alpha off -compose CopyOpacity -composite $OUT/$name.png
  magick $OUT/$name.png -background black -flatten $OUT/$name-black.png
}

# 1. TTE default gradient (purple -> cyan -> white), vertical  == classic screensaver look
multistop 01-tte-classic 0 '#8A008A' '#00D1FF' '#FFFFFF'
# 2. Synthwave sunset (matches the Tokyo artwork sun), vertical
multistop 02-sunset 0 '#ffd166' '#ff9e64' '#ff5c8a' '#bb9af7'
# 3. Tokyo Night blue -> purple -> pink, horizontal
multistop 03-tokyo-night 90 '#7aa2f7' '#bb9af7' '#ff79c6'
# 4. Brand green stepped (dark green -> omarchy green -> white), vertical
multistop 04-green-steps 0 '#2f6b2a' '#9ece6a' '#b4fc7a' '#ffffff'
# 5. Diagonal rainbow-ish cyberpunk (cyan -> magenta -> yellow)
multistop 05-cyber 90 '#0db9d7' '#ad8ee6' '#ff7a93' '#ffd166'
# 6. Ordered-dither retro: green->cyan with 8x8 Bayer dither at cell level, 2 colors + blends
magick -size 128x52 gradient:'#b4fc7a'-'#0db9d7' -ordered-dither o4x4,4 -scale ${W}x${H}! +repage $TMP/fill.png
magick $TMP/fill.png $TMP/mask.png -alpha off -compose CopyOpacity -composite $OUT/06-dither.png
magick $OUT/06-dither.png -background black -flatten $OUT/06-dither-black.png

# contact sheet for preview
magick montage $OUT/0*-black.png -tile 2x3 -geometry 1024x410+12+12 -background '#333' $OUT/preview.jpg
rm -rf $TMP; ls $OUT
