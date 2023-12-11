#!/usr/bin/env bash

TINYLINUX_ELF=$HOME/aisin/tinylinux/vmlinux
DEFCONFIGLINUX_ELF=$HOME/aisin/defconfiglinux/vmlinux
OUT=$HOME/aisin/$(sha1sum .config | awk '{print $1}')
mkdir -p $OUT
echo "Storing results at $OUT"
bzip2 -c .config > $OUT/config.bz2
bzip2 -c vmlinux > $OUT/vmlinux.bz2
# size vmlinux | awk 'NR==2 {printf "%s,%s,%s,%s\n", $1, $2, $3, $4}' > $OUT/csv.txt
# size vmlinux | awk 'NR==2 {printf "%s,%s,%s,%.2f\n", $1, $2, $3, $4/1024/1024}' > $OUT/csv.txt
# ./scripts/bloat-o-meter -p aarch64-linux-gnu- -c $TINYLINUX_ELF vmlinux | grep -e "^Total" 2>&1 > $OUT/stats.txt
./scripts/bloat-o-meter -c $DEFCONFIGLINUX_ELF vmlinux | grep -e "^Total" 2>&1 > $OUT/stats_defconfig.txt
awk -F'[=, ]' '{printf "%s,%s,%s,", $3, $6, $9} END{print ""}' $OUT/stats_defconfig.txt > $OUT/csv_defconfig.txt
./scripts/bloat-o-meter -c $TINYLINUX_ELF vmlinux | grep -e "^Total" 2>&1 > $OUT/stats_tinyconfig.txt
awk -F'[=, ]' '{printf "%s,%s,%s,", $3, $6, $9} END{print ""}' $OUT/stats_tinyconfig.txt > $OUT/csv_tinyconfig.txt
cat $OUT/csv_defconfig.txt $OUT/csv_tinyconfig.txt | tr -d '\n' > $OUT/csv.txt
git format-patch -1 && mv *.patch $OUT/

