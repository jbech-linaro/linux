#!/usr/bin/env bash

OUT=$HOME/aisin/$(sha1sum .config | awk '{print $1}')
OUT_CSV=$OUT/csv.txt
BOOT_LOG=../out/run.log
mkdir -p $OUT

TIMESTAMP=`grep "/sbin/init as init process" $BOOT_LOG | grep -oP '\[ *\K[0-9]+\.[0-9]+'`
echo "Time to boot to init is: $TIMESTAMP"

if [ -n "$TIMESTAMP" ]; then
    echo "Storing boot time results at $OUT_CSV"
    sed -i "s/$/$TIMESTAMP/" "$OUT_CSV"
else
    echo "Failed to boot to init"
    sed -i "s/$/-1/" "$OUT_CSV"
    exit -1
fi
