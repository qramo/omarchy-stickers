#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
V=$ROOT/logo-variants
OUT=$ROOT/sheets
TMP=$(mktemp -d); BG='#0b0c14'; BORDER=22; RADIUS=40
sticker() { magick "$1" -filter Lanczos -resize "${2}x" -bordercolor white -border $BORDER -bordercolor '#9a9a9a' -border 2 \
  \( +clone -alpha extract -draw "fill black polygon 0,0 0,$RADIUS $RADIUS,0 fill white circle $RADIUS,$RADIUS $RADIUS,0" \
     \( +clone -flip \) -compose Multiply -composite \( +clone -flop \) -compose Multiply -composite \) \
  -alpha off -compose CopyOpacity -composite "$3"; }
i=0; args=()
for f in $V/0*-black.png; do sticker "$f" 650 $TMP/$i.png; i=$((i+1)); done
sw=$(magick identify -format %w $TMP/0.png); sh=$(magick identify -format %h $TMP/0.png)
cols=2; rows=6; gx=$((1500-2*sw)); gx=$((gx/3)); gy=$(( (2102 - rows*sh) / (rows+1) ))
for r in $(seq 0 $((rows-1))); do for c in 0 1; do
  k=$(( (r*cols + c) % 6 ))
  args+=( $TMP/$k.png -geometry +$((gx + c*(sw+gx)))+$((gy + r*(sh+gy))) -composite )
done; done
magick -size 1500x2102 xc:"$BG" "${args[@]}" -units PixelsPerInch -density 300 -quality 95 $OUT/omarchy-logo-stickers-2L.jpg
rm -rf $TMP; magick identify $OUT/omarchy-logo-stickers-2L.jpg
