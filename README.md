# Omarchy Sticker Gacha

[Omarchy](https://omarchy.org) のロゴを使ったステッカーシートを、コンビニのシール紙プリント(2L判)向けに作るためのツールです。
ブラウザで配色をガチャして、そのまま印刷用 JPEG を保存できます。

**ガチャページ:** https://qramo.github.io/omarchy-stickers/

## 使い方

1. ページを開いて「ガチャ」を押す。気に入らなければ何度でも引き直せます。
2. 残したいシールをクリックするとロック(🔒)され、次のガチャで変わらなくなります。
3. 「JPEGを保存」で 1500×2102px(2L判 127×178mm、300dpi)の JPEG がダウンロードされます。
4. [ネットワークプリント](https://networkprint.ne.jp/)(ローソン・ファミリーマート・ミニストップ)に JPEG を登録し、
   店のマルチコピー機で **シール紙 / 2L** を選んで印刷します(2L判 300円前後)。セブン-イレブンはシール紙非対応です。
5. 白フチの外側にある薄いグレーの線に沿って切り出します。

seed(乱数の種)が表示されるので、控えておけば同じシートを再現できます。

## シートの内容

| シール | 実寸 |
|---|---|
| カタカナ「オマーチー」 ラウンド大 / 小 | 直径 51mm / 36mm |
| OMARCHY ワードマーク ラウンド大 / 小 | 直径 51mm / 36mm |
| 迷路ロゴ(公式アイコン) 角丸四角 ×4配色 | 地 17mm |
| バナー(全幅 / 半分 / 1/4 ×2) | 119×28mm / 58×28mm / 58×13mm |

カタカナのうち1枚は必ず元の単色の緑になります。迷路ロゴは4配色が1枚ずつ入ります。
カタカナのグラデーションは、Omarchy のスクリーンセーバー(ttfx)のようなセル単位の荒い段階にしてあります。

## リポジトリの構成

- `index.html` ガチャページ本体(素材を埋め込み済み、この1ファイルで動きます)
- `gacha-template.html` + `gacha-assets/` ガチャページのソース。`scripts/build-gacha.sh` で `index.html` を生成
- `scripts/` ImageMagick でシートを生成するスクリプト(レイアウト見本、ロゴのグラデ版、円形シートなど)
- `sheets/` 生成済みのシート例(そのまま印刷可)
- `logo-variants/`, `round/` 生成した中間素材
- `source/` 元画像

## 自分で作り直す

ImageMagick 7 と rsvg-convert、python3 が必要です。

```sh
bash scripts/make_logos.sh      # カタカナロゴのグラデ6種
bash scripts/make_layout.sh     # レイアウト見本 (sheets/omarchy-layout-sample-2L.jpg)
bash scripts/build-gacha.sh     # index.html を再生成
```

レイアウトを変えるときは `scripts/make_layout.sh` と、`gacha-template.html` の `STICKERS` 表の両方を直してください。

## クレジット

- 迷路アイコンと OMARCHY ワードマークは [Omarchy](https://github.com/basecamp/omarchy) の公式素材です。
- カタカナ「オマーチー」ロゴ: [Komagata さん (@komagata)](https://x.com/komagata) の作品です。
  [ステッカーの投稿 (X)](https://x.com/komagata/status/2098961422290125142) / [配布元 (Omarchy Discord)](https://discord.com/channels/1390012484194275541/1548046499160793329/1568133428988215346)
- OMARCHY TOKYO / TOKYO NIGHT の壁紙: 作者 (確認中)
- 非公式のファン制作物です。
