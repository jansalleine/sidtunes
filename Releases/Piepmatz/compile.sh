rm out-exo.prg;
acme -v4 -f cbm -o out.prg music-player.asm;
exomizer sfx 0x0800 -s "lda #\$0b sta \$d011" -x3 -o out-exo.prg out.prg;
rm out.prg;
x64sc -VICIIborders 0 out-exo.prg;
