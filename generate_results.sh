#!/usr/bin/env bash

TINYLINUX_ELF=$HOME/aisin/tinylinux/vmlinux
OUT=$HOME/aisin/$(sha1sum .config | awk '{print $1}')
mkdir -p $OUT
echo "Storing results at $OUT"
bzip2 -c .config > $OUT/config.bz2
bzip2 -c vmlinux > $OUT/vmlinux.bz2
./scripts/bloat-o-meter -c $TINYLINUX_ELF vmlinux | grep -e "^Total" 2>&1 > $OUT/stats.txt
awk -F'[=, ]' '{printf "%s,%s,%s,", $3, $6, $9} END{print ""}' $OUT/stats.txt > $OUT/csv.txt

