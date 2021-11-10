#!/bin/sh
FILENAME=$(grep -A 1 "music_title:" data.asm | cut -d: -f2 | cut -d\" -f2 | tr ' ' '_' | tr -d '\040\011\012\015')

rm -f $FILENAME.prg

acme -v4 -f cbm -o out.prg music-player.asm

exomizer sfx 0x0800 -s "lda #\$0b sta \$d011" -x3 -o $FILENAME.prg out.prg

rm -f out.prg

x64sc -VICIIborders 0 $FILENAME.prg
