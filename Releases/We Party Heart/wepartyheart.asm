!cpu 6510

*= $1000
    !bin "partyheart18.sid",,$7e
*= $3000
    !bin "wepartyheart.chr"

*= $0f00
    !bin "spider-sprite.prg",,2

*= $0810
    sei
    lda #$7f
    sta $dc0d
    sta $dd0d
    lda $dc0d
    lda $dd0d

    lda #$35
    sta $01

    lda #<nmi
    sta $fffa
    lda #>nmi
    sta $fffb

    lda #$0b
    sta $d011

    lda #$0e
    sta $d020
    sta $d021

    lda #0
    jsr $1000

    ldx #0
-
    lda source_screen+$000,x
    sta $0400+$000,x
    lda source_screen+$100,x
    sta $0400+$100,x
    lda source_screen+$200,x
    sta $0400+$200,x
    lda source_screen+$2e8,x
    sta $0400+$2e8,x
    lda #$06
    sta $d800+$000,x
    sta $d800+$100,x
    sta $d800+$200,x
    sta $d800+$2e8,x
    inx
    bne -

    lda #$3c
    sta $0400+$3f8

    lda #$01
    sta $d015
    sta $d010

    lda #$06
    sta $d027

    lda #$40
    sta $d000

    lda #$e0
    sta $d001

    lda #%00011100
    sta $d018

    jsr wait_bottom
    lda #$1b
    sta $d011

mainloop:
    jsr wait_bottom
    jsr $1003
    jmp mainloop

wait_bottom:
    lda #$ff
    cmp $d012
    bne *-3
    rts
nmi:
    rti

source_screen:
    !bin "wepartyheart.sc1"
