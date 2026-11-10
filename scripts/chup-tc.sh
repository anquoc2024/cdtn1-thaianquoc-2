#!/usr/bin/env bash
# Chạy từng test case, dừng để chụp màn hình, rồi chép ảnh mới nhất vào docs/screenshots/TC-xx.png
#   bash scripts/chup-tc.sh                 # TC-01 → TC-16
#   bash scripts/chup-tc.sh TC-13 TC-16     # chỉ vài test case (chạy lại / chụp lại)
# Kết quả chữ của mọi lần chạy được ghi thêm vào docs/tc-ket-qua.txt
cd "$(dirname "$0")/.." || exit 1
SHOTS="/mnt/c/Users/Thai An Quoc/Pictures/Screenshots"
OUT=docs/tc-ket-qua.txt
mkdir -p docs/screenshots

if [ $# -eq 0 ]; then
  set -- TC-01 TC-02 TC-03 TC-04 TC-05 TC-06 TC-07 TC-08 TC-09 TC-10 TC-11 TC-12 TC-13 TC-14 TC-15 TC-16
  : > "$OUT"
fi

for t in "$@"; do
  clear
  bash scripts/tc.sh "$t" 2>&1 | tee -a "$OUT"
  truoc=$(ls -t "$SHOTS"/*.png 2>/dev/null | head -1)
  echo
  read -r -p ">>> Chụp màn hình (Win+Shift+S) rồi nhấn Enter để lưu $t.png ... "
  moi=$(ls -t "$SHOTS"/*.png 2>/dev/null | head -1)
  if [ -n "$moi" ] && [ "$moi" != "$truoc" ]; then
    cp "$moi" "docs/screenshots/$t.png" && echo "Đã lưu docs/screenshots/$t.png"
  else
    echo "*** Chưa thấy ảnh mới trong thư mục Screenshots – bỏ qua $t. Chụp lại: bash scripts/chup-tc.sh $t"
  fi
  sleep 1
done
echo; echo "Ảnh đã có:"; ls docs/screenshots/TC-*.png 2>/dev/null
