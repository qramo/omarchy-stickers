#!/usr/bin/env bash
# Layout sample: one 2L sheet (1500x2102 @300dpi)
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
V=$ROOT/logo-variants
OUT=$ROOT/sheets
ICON_SRC=/usr/share/omarchy/icon.png
WORD=/usr/share/omarchy/logo.svg
GREEN='#b4fc7a'; BG='#0b0c14'; CUT='#9a9a9a'; B=14
TMP=$(mktemp -d)
ICON=$TMP/icon_padded.png; magick $ICON_SRC -bordercolor none -border 1 $ICON
mm() { python3 -Ic "print(round($1/25.4*300))"; }
rsvg-convert -w 1215 "$WORD" -o $TMP/word.png

# disc content D ratio disccol out
disc() { local content=$1 D=$2 ratio=$3 col=$4 out=$5; local Di=$((D-2*B)) cw; cw=$(python3 -Ic "print(int($Di*$ratio))")
  magick -size ${Di}x${Di} xc:none -fill "$col" -draw "circle $((Di/2)),$((Di/2)) $((Di/2)),0" \
    \( "$content" -trim +repage -filter Lanczos -resize ${cw}x${cw} \) -gravity center -composite $TMP/inner.png
  magick -size ${D}x${D} xc:none -fill white -draw "circle $((D/2)),$((D/2)) $((D/2)),0" \
    -fill none -stroke "$CUT" -strokewidth 2 -draw "circle $((D/2)),$((D/2)) $((D/2)),1" $TMP/inner.png -gravity center -composite "$out"; }
# rounded box: content W H bgcol out   (content fitted inside with padding)
box() { local content=$1 W=$2 H=$3 col=$4 out=$5; local R=36 pad=$(( H/8 > 40 ? 40 : H/8 ))
  magick -size ${W}x${H} xc:none -fill "$col" -draw "roundrectangle 0,0 $((W-1)),$((H-1)) $R,$R" \
    \( "$content" -trim +repage -filter Lanczos -resize $((W-2*pad))x$((H-2*pad)) \) -gravity center -composite $TMP/inner.png
  local S=$((W+2*B)) T=$((H+2*B)); R=$((R+B))
  magick -size ${S}x${T} xc:none -fill white -draw "roundrectangle 0,0 $((S-1)),$((T-1)) $R,$R" \
    -fill none -stroke "$CUT" -strokewidth 2 -draw "roundrectangle 1,1 $((S-2)),$((T-2)) $R,$R" $TMP/inner.png -gravity center -composite "$out"; }
recolor() { magick "$1" -fill "$2" -colorize 100 "$3"; }

# ---- pieces ----
LR=600; SR=420; SQ=$(mm 17)
disc $V/00-original-green.png $LR 0.84 black $TMP/kana_big.png
disc $V/01-tte-classic.png    $SR 0.84 black $TMP/kana_small.png
recolor $TMP/word.png "$GREEN" $TMP/word_green.png; recolor $TMP/word.png black $TMP/word_black.png; recolor $TMP/word.png white $TMP/word_white.png
disc $TMP/word_green.png $LR 0.80 black   $TMP/word_big.png
disc $TMP/word_black.png $SR 0.80 "$GREEN" $TMP/word_small.png
i=0; for cw in "black:$GREEN" "$GREEN:black" "black:white" "white:$GREEN"; do
  recolor $ICON "${cw##*:}" $TMP/ic.png; S=$((SQ-2*B))   # make outer = 17mm incl. border? no: 地=17mm
  box $TMP/ic.png $SQ $SQ "${cw%%:*}" $TMP/sq$i.png; i=$((i+1)); done
# banners, dwindle-style: full width -> left half -> right half split top/bottom
GAP=24; BH=330                      # block height for level 1 and 2 (incl. border)
FW=$((1400-2*B)); HW=$(( (1400-GAP)/2 - 2*B )); QH=$(( (BH-GAP)/2 - 2*B ))
box $V/02-sunset.png    $FW $((BH-2*B)) black   $TMP/ban_full.png     # level 1: katakana
box $TMP/word_green.png $HW $((BH-2*B)) black   $TMP/ban_half.png     # level 2: wordmark
box $V/01-tte-classic.png $HW $QH "$GREEN"      $TMP/ban_q1.png       # level 3: katakana
box $TMP/word_black.png  $HW $QH "$GREEN"       $TMP/ban_q2.png       # level 3: wordmark

# ---- layout ----
M=50; args=()
# row 1: two large discs
y=$M; g=$(( (1400 - 2*LR)/3 ))
args+=( $TMP/kana_big.png -geometry +$((M+g))+$y -composite  $TMP/word_big.png -geometry +$((M+g+LR+g))+$y -composite )
y=$((y+LR+50))
# row 2: two small discs + 2x2 maze squares
sqw=$(magick identify -format %w $TMP/sq0.png); grid=$((2*sqw+16))
g=$(( (1400 - 2*SR - grid)/4 ))
x=$((M+g)); args+=( $TMP/kana_small.png -geometry +$x+$y -composite ); x=$((x+SR+g))
args+=( $TMP/word_small.png -geometry +$x+$y -composite ); x=$((x+SR+g))
args+=( $TMP/sq0.png -geometry +$x+$y -composite $TMP/sq1.png -geometry +$((x+sqw+16))+$y -composite
        $TMP/sq2.png -geometry +$x+$((y+sqw+16)) -composite $TMP/sq3.png -geometry +$((x+sqw+16))+$((y+sqw+16)) -composite )
y=$((y+grid+50))
# rows 3-4: banner block
args+=( $TMP/ban_full.png -geometry +$M+$y -composite ); y=$((y+BH+GAP))
args+=( $TMP/ban_half.png -geometry +$M+$y -composite )
xr=$((M + HW + 2*B + GAP))
args+=( $TMP/ban_q1.png -geometry +$xr+$y -composite  $TMP/ban_q2.png -geometry +$xr+$((y + QH + 2*B + GAP)) -composite )
y=$((y+BH))
echo "bottom y=$y (limit 2052)"
magick -size 1500x2102 xc:"$BG" "${args[@]}" -units PixelsPerInch -density 300 -quality 95 $OUT/omarchy-layout-sample-2L.jpg
rm -rf $TMP
