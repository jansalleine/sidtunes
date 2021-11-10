#!/bin/sh
rm sidanalyzer.prg

acme -v4 -f cbm -l labels.asm -o out.prg sidanalyzer.asm

STARTADDR=$(grep "code_start" labels.asm | cut -d$ -f2)
exomizer sfx 0x$STARTADDR -s "lda #\$0b sta \$d011" -x3 -o sidanalyzer.prg out.prg

rm -f out.prg
rm -f labels.asm

x64sc -VICIIborders 0 sidanalyzer.prg
#codenet -n 172.16.1.164 -x sidanalyzer.prg
