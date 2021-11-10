#!/bin/sh
OUTFILE="${PWD##*/}".prg

rm -f "$OUTFILE"

acme -v4 -f cbm -l labels.s -o out.prg main.s

STARTADDR=$(grep "code_start" labels.s | cut -d$ -f2)
exomizer sfx 0x$STARTADDR -s "lda #\$0b sta \$d011" -x3 -o "$OUTFILE" out.prg

rm -f out.prg
#rm -f labels.s

x64sc -VICIIborders 0 "$OUTFILE"
#codenet -n 172.16.1.164 -x "$OUTFILE"
