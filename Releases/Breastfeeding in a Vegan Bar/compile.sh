#!/bin/sh
OUTFILE="${PWD##*/}".prg

rm -f "$OUTFILE"

acme -v4 -f cbm -l labels.asm -o out.prg main.asm

STARTADDR=$(grep "code_start" labels.asm | cut -d$ -f2)
exomizer sfx 0x$STARTADDR -s "lda #\$0b sta \$d011" -x3 -o "$OUTFILE" out.prg

rm -f out.prg
rm -f labels.asm

x64sc -VICIIborders 0 "$OUTFILE"
#codenet -n 172.16.1.164 -x "$OUTFILE"
