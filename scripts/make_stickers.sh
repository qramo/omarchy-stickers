#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC=$ROOT/source
OUT=$ROOT/sheets
TMP=$(mktemp -d)
BG='#0b0c14'
BORDER=22
RADIUS=48

# sticker <src> <width> <out.png> : resize, add white border, round corners (transparent outside)
sticker() {
  local src=$1 w=$2 out=$3
  magick "$src" -filter Lanczos -resize "${w}x" \
    -bordercolor white -border $BORDER -bordercolor '#9a9a9a' -border 2 \
    \( +clone -alpha extract \
       -draw "fill black polygon 0,0 0,$RADIUS $RADIUS,0 fill white circle $RADIUS,$RADIUS $RADIUS,0" \
       \( +clone -flip \) -compose Multiply -composite \
       \( +clone -flop \) -compose Multiply -composite \
    \) -alpha off -compose CopyOpacity -composite "$out"
}

# ---------- 2L判 127x178mm @300dpi = 1500x2102, all three ----------
sticker $SRC/omarchy-tokyo.webp       1200 $TMP/a.png
sticker $SRC/omarchy-tokyo-night.webp 1200 $TMP/b.png
sticker $SRC/omarchy-katakana.webp    1000 $TMP/c.png
ha=$(magick identify -format %h $TMP/a.png); hb=$(magick identify -format %h $TMP/b.png); hc=$(magick identify -format %h $TMP/c.png)
total=$((ha+hb+hc)); gap=$(( (2102 - 2*70 - total) / 2 ))
y1=70; y2=$((y1+ha+gap)); y3=$((y2+hb+gap))
magick -size 1500x2102 xc:"$BG" \
  $TMP/a.png -gravity North -geometry +0+$y1 -composite \
  $TMP/b.png -gravity North -geometry +0+$y2 -composite \
  $TMP/c.png -gravity North -geometry +0+$y3 -composite \
  -units PixelsPerInch -density 300 -quality 95 $OUT/omarchy-stickers-2L.jpg

# ---------- L判 89x127mm @300dpi = 1051x1500, both scenes + logo ----------
sticker $SRC/omarchy-tokyo.webp       860 $TMP/a.png
sticker $SRC/omarchy-tokyo-night.webp 860 $TMP/b.png
sticker $SRC/omarchy-katakana.webp    640 $TMP/c.png
ha=$(magick identify -format %h $TMP/a.png); hb=$(magick identify -format %h $TMP/b.png); hc=$(magick identify -format %h $TMP/c.png)
total=$((ha+hb+hc)); m=45; gap=$(( (1500 - 2*m - total) / 2 ))
y1=$m; y2=$((y1+ha+gap)); y3=$((y2+hb+gap))
magick -size 1051x1500 xc:"$BG" \
  $TMP/a.png -gravity North -geometry +0+$y1 -composite \
  $TMP/b.png -gravity North -geometry +0+$y2 -composite \
  $TMP/c.png -gravity North -geometry +0+$y3 -composite \
  -units PixelsPerInch -density 300 -quality 95 $OUT/omarchy-stickers-L.jpg
rm -rf "$TMP"
ls -la $OUT; magick identify $OUT/*.jpg
