rm -f wepartyheart.o;
rm -f wepartyheart.prg;
acme -v4 -f cbm -o wepartyheart.o wepartyheart.asm;
exomizer sfx 0x0810 -x1 -o wepartyheart.prg wepartyheart.o;
x64sc wepartyheart.prg;
