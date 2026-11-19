#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC=$ROOT/source/omarchy-katakana.webp
V=$ROOT/logo-variants
OUT=$ROOT/sheets
ICON_SRC=/usr/share/omarchy/icon.png
WORD=/usr/share/omarchy/logo.svg
GREEN='#b4fc7a'; BG='#0b0c14'
TMP=$(mktemp -d)
ICON=$TMP/icon_padded.png; magick $ICON_SRC -bordercolor none -border 1 $ICON
mkdir -p $OUT/round
mm() { python3 -Ic "print(round($1/25.4*300))"; }

magick "$SRC" -filter Lanczos -resize 2048x820! -channel G -separate +channel -threshold 40% -strip $TMP/mask.png
magick -size 2048x820 xc:"$GREEN" $TMP/mask.png -alpha off -compose CopyOpacity -composite $V/00-original-green.png
magick $V/00-original-green.png -background black -flatten $V/00-original-green-black.png

# disc <content(transparent)> <diameter> <content-width-ratio> <disc colour> <out>
disc() {
  local content=$1 D=$2 ratio=$3 col=$4 out=$5 b=18
  local Di=$((D-2*b)); local cw; cw=$(python3 -Ic "print(int($Di*$ratio))")
  magick -size ${Di}x${Di} xc:none -fill "$col" -draw "circle $((Di/2)),$((Di/2)) $((Di/2)),0" \
    \( "$content" -trim +repage -filter Lanczos -resize ${cw}x${cw} \) -gravity center -composite $TMP/inner.png
  magick -size ${D}x${D} xc:none -fill white -draw "circle $((D/2)),$((D/2)) $((D/2)),0" \
    -fill none -stroke '#9a9a9a' -strokewidth 2 -draw "circle $((D/2)),$((D/2)) $((D/2)),1" \
    $TMP/inner.png -gravity center -composite "$out"
}
D=440   # 37mm
disc $V/00-original-green.png $D 0.84 black $OUT/round/r00-original.png
for n in 01-tte-classic 02-sunset 03-tokyo-night 04-green-steps 05-cyber 06-dither; do
  disc $V/$n.png $D 0.84 black $OUT/round/r$n.png; done
disc $ICON $D 0.56 black $OUT/round/r07-icon-green.png
magick $ICON -fill black -colorize 100 $TMP/icon_black.png
disc $TMP/icon_black.png $D 0.56 "$GREEN" $OUT/round/r08-icon-black.png

order=(r00-original r01-tte-classic r02-sunset r03-tokyo-night r04-green-steps r05-cyber r06-dither r07-icon-green r08-icon-black r00-original r01-tte-classic r02-sunset)
gx=$(( (1500-3*D)/4 )); gy=$(( (2102-4*D)/5 )); args=()
for i in "${!order[@]}"; do r=$((i/3)); c=$((i%3))
  args+=( $OUT/round/${order[$i]}.png -geometry +$((gx + c*(D+gx)))+$((gy + r*(D+gy))) -composite ); done
magick -size 1500x2102 xc:"$BG" "${args[@]}" -units PixelsPerInch -density 300 -quality 95 $OUT/omarchy-round-stickers-2L.jpg

# ---------- palm-rest sheet, 2L判 1500x2102 ----------
B=12   # white border px (~1mm)
sq() { local icon=$1 s=$2 bg=$3 col=$4 out=$5 R=$((s/8)); local iw=$((s*68/100))
  magick "$icon" -fill "$col" -colorize 100 -filter Lanczos -resize ${iw}x${iw} $TMP/i.png
  magick -size ${s}x${s} xc:none -fill "$bg" -draw "roundrectangle 0,0 $((s-1)),$((s-1)) $R,$R" $TMP/i.png -gravity center -composite $TMP/in.png
  local S=$((s+2*B)); R=$((R+B))
  magick -size ${S}x${S} xc:none -fill white -draw "roundrectangle 0,0 $((S-1)),$((S-1)) $R,$R" \
    -fill none -stroke '#9a9a9a' -strokewidth 2 -draw "roundrectangle 1,1 $((S-2)),$((S-2)) $R,$R" $TMP/in.png -gravity center -composite "$out"; }
rsvg-convert -w 1215 "$WORD" -o $TMP/word.png
wordmark() { local w=$1 bg=$2 col=$3 out=$4 pad=22
  magick $TMP/word.png -fill "$col" -colorize 100 -filter Lanczos -resize ${w}x $TMP/w.png
  magick $TMP/w.png -bordercolor none -border $pad -background "$bg" -flatten -bordercolor white -border $B -bordercolor '#9a9a9a' -border 2 "$out"; }

M=50; AW=$((1500-2*M)); args=(); rowfiles=(); rowh=()
colours=("black:$GREEN" "$GREEN:black" "black:white" "white:$GREEN")
row=0
for spec in 17:4 21:4 24:4 29:3 36:3; do
  mmsize=${spec%%:*}; n=${spec##*:}; s=$(mm $mmsize); files=()
  for i in $(seq 0 $((n-1))); do cw=${colours[$i]}; sq $ICON $s "${cw%%:*}" "${cw##*:}" $TMP/sq_${row}_$i.png; files+=($TMP/sq_${row}_$i.png); done
  rowfiles[$row]="${files[*]}"; rowh[$row]=$((s+2*B)); row=$((row+1))
done
wordmark $(mm 47) black "$GREEN" $TMP/wm0.png; wordmark $(mm 47) "$GREEN" black $TMP/wm1.png
rowfiles[$row]="$TMP/wm0.png $TMP/wm1.png"; rowh[$row]=$(magick identify -format %h $TMP/wm0.png); row=$((row+1))
sumh=0; for h in "${rowh[@]}"; do sumh=$((sumh+h)); done
gy=$(( (2102-2*M-sumh)/(row-1) )); y=$M
for r in $(seq 0 $((row-1))); do
  files=(${rowfiles[$r]}); n=${#files[@]}; sumw=0
  for f in "${files[@]}"; do sumw=$((sumw+$(magick identify -format %w $f))); done
  gx=$(( (AW-sumw)/(n-1) )); x=$M
  for f in "${files[@]}"; do args+=( $f -geometry +$x+$y -composite ); x=$((x+$(magick identify -format %w $f)+gx)); done
  y=$((y+rowh[$r]+gy))
done
echo "row gap=$gy px"
magick -size 1500x2102 xc:"$BG" "${args[@]}" -units PixelsPerInch -density 300 -quality 95 $OUT/omarchy-palmrest-stickers-2L.jpg
rm -rf $TMP
