!cpu 6510
!src "colorcodes.asm"
!src "data.asm"

DEBUG = 0

; ==============================================================================
ENABLE              = $20
DISABLE             = $2c

LINE0               = $15
LINE1               = $f0

COLORBG             = blue
COLORTEXT1          = light_blue
COLORTEXT2          = light_green
COLORTEXT3          = cyan
COLORTEXT4          = pink
COLORRASTER         = purple
COLORSPRITE         = white

SPRITEXBASE         = $50+7
SPRITEYBASE         = $61-8

KEY_CRSRUP          = $91
KEY_CRSRDOWN        = $11
KEY_CRSRLEFT        = $9d
KEY_CRSRRIGHT       = $1d

; ==============================================================================
irq_ready           = $02
music_pt            = $2b
;music_pt+1         = music_pt+1
cursorx             = music_pt+2
cursory             = cursorx+1
cursorlinear        = cursory+1
curval              = cursorlinear+1
oldval              = curval+1

; ==============================================================================
!if music_init >= $1000 {
  vidmem0           = $0400
  code_start        = $0840
  vicbank           = $0000
} else {
  vidmem0           = $8400
  code_start        = $8840
  vicbank           = $8000 }

spritedata          = code_start-$40

getin               = $ffe4

DATAAREA            = vidmem0+(5*40)+8
DATACOUNT1          = DATAAREA-(1*40)
STATUSCURPAGE       = vidmem0+(2*40)
STATUSVALUE         = vidmem0+(14*40)
VALADDR             = STATUSVALUE+19
VAL                 = STATUSVALUE+26
CURPAGE             = STATUSCURPAGE+15
INSLINE             = vidmem0+(17*40)
; ==============================================================================
                    *= code_start
init_code:          sei
                    lda #$7f
                    sta $dc0d
                    sta $dd0d
                    lda $dc0d
                    lda $dd0d
                    lda #$36
                    sta $01
                    jsr init_vic
                    jsr screen_init
                    lda #SUBTUNE
                    jsr music_init
                    lda #<music_start
                    sta music_pt
                    lda #>music_start
                    sta music_pt+1
                    lda #LINE0
                    sta $d012
                    lda #$1b
                    sta $d011
                    lda #<irq0
                    sta $0314
                    lda #>irq0
                    sta $0315
                    lda #<nmi
                    sta $0318
                    lda #>nmi
                    sta $0319
                    asl $d019
                    cli
; ==============================================================================
mainloop:           jsr wait_irq
                    jsr keyboard_get
                    jmp mainloop
; ==============================================================================
init_vic:           lxa #$00
-                   sta $d000,x
                    inx
                    cpx #$2f
                    bne -
                    lda #$08
                    sta $d016
                    lda #$16
                    sta $d018
                    lda #$01
                    sta $d01a
                    lda #COLORBG
                    sta $d020
                    sta $d021
                    lda $dd00
                    and #$fc
                    ora #<!(vicbank/$4000) & 3
                    sta $dd00
                    rts
; ==============================================================================
; memfill
; ------------+-----------------------------------------------------------------
; depends on: | -
; ------------+-----------------------------------------------------------------
; uses:       | A, X, Y
; ------------+-----------------------------------------------------------------
; preserves:  | A
; ------------+---+-------------------------------------------------------------
; input:      | A | fill value
;             | X | highbyte fill startaddress
;             | Y | highbyte fill endaddress
; ------------+---+-------------------------------------------------------------
; output:     | - |
; ------------+---+-------------------------------------------------------------
!zone MEMFILL

memfill:            stx .from_hi+2
                    sty .to_hi+1
.loop:              ldx #0
.from_hi:           sta $0000,x
                    inx
                    bne .from_hi
                    inc .from_hi+2
                    ldy .from_hi+2
.to_hi:             cpy #0
                    bne .loop
                    rts
; ==============================================================================
; hex2screen
; ------------+-----------------------------------------------------------------
; depends on: | -
; ------------+-----------------------------------------------------------------
; uses:       | A, X
; ------------+-----------------------------------------------------------------
; preserves:  | Y
; ------------+---+-------------------------------------------------------------
; input:      | A | hexvalue to be converted
; ------------+---+-------------------------------------------------------------
; output:     | A | petscii/screencode high nibble
;             | X | petscii/screencode low nibble
; ------------+---+-------------------------------------------------------------
!zone HEX2SCREEN

hex2screen:         sta .savea+1
                    and #%00001111
                    tax
                    lda .hextab,x
                    sta .low_nibble+1
.savea              lda #0
                    lsr
                    lsr
                    lsr
                    lsr
                    tax
                    lda .hextab,x           ; high nibble
.low_nibble         ldx #0
                    rts
.hextab:            !scr "0123456789abcdef"
; ==============================================================================
!zone WAIT_IRQ

wait_irq:           lda #0
                    sta irq_ready
-                   lda irq_ready
                    beq -
                    rts
; ==============================================================================
!zone KEYBOARD

keyboard_get:       jsr getin
                    bne +
                    rts
+                   cmp #'+'
                    bne +
                    jmp pt_increase
+                   cmp #'-'
                    bne +
                    jmp pt_decrease
+                   cmp #'P'
                    bne +
                    jmp music_pause
+                   cmp #'R'
                    bne +
                    jmp music_restart
+                   cmp #KEY_CRSRUP
                    bne +
                    jmp cursor_up
+                   cmp #KEY_CRSRDOWN
                    bne +
                    jmp cursor_down
+                   cmp #KEY_CRSRLEFT
                    bne +
                    jmp cursor_left
+                   cmp #KEY_CRSRRIGHT
                    bne +
                    jmp cursor_right
+                   cmp #'S'
                    bne +
                    jmp music_step_enable
+                   cmp #'1'
                    bne +
                    jmp vt_mute1_enable
+                   cmp #'2'
                    bne +
                    jmp vt_mute2_enable
+                   cmp #'3'
                    bne +
                    jmp vt_mute3_enable
+                   rts
; ==============================================================================
!zone CURSORMOVEMENT

cursor_up:          lda cursory
                    beq +
                    dec cursory
                    sec
                    lda cursorlinear
                    sbc #32
                    sta cursorlinear
                    rts
+                   lda #$07
                    sta cursory
                    tax
-                   clc
                    lda cursorlinear
                    adc #32
                    sta cursorlinear
                    dex
                    bne -
                    rts
cursor_down:        lda cursory
                    cmp #$07
                    beq +
                    inc cursory
                    clc
                    lda cursorlinear
                    adc #32
                    sta cursorlinear
                    rts
+                   lda #$00
                    sta cursory
                    clc
                    adc cursorx
                    sta cursorlinear
                    rts
cursor_left:        lda cursorx
                    beq +
                    dec cursorx
                    dec cursorlinear
                    rts
+                   lda cursory
                    beq +
                    dec cursorlinear
                    lda #31
                    sta cursorx
                    dec cursory
                    rts
+                   lda #31
                    sta cursorx
                    lda #$07
                    sta cursory
                    lda #$ff
                    sta cursorlinear
                    rts
cursor_right:       lda cursorx
                    cmp #$1f
                    beq +
                    inc cursorx
                    inc cursorlinear
                    rts
+                   lda cursory
                    cmp #$07
                    beq +
                    inc cursorlinear
                    lda #$00
                    sta cursorx
                    inc cursory
                    rts
+                   lda #$00
                    sta cursorx
                    sta cursory
                    sta cursorlinear
                    rts
; ==============================================================================
!zone MUSICHANDLING

music_pause:        lda .pause_flag
                    beq .pause
.unpause_resetstep: lda #DISABLE
                    sta enable_music_step
                    lda curval
                    sta oldval
.unpause:           lda #$00
                    sta .pause_flag
                    lda #ENABLE
                    sta enable_music
                    rts
.pause:             lda #$01
                    sta .pause_flag
                    lda #DISABLE
                    sta enable_music
                    lda #$00
                    sta virtualregs+$18
                    rts
.pause_flag:        !byte $00
music_step_enable:  lda .pause_flag
                    beq +
                    lda #ENABLE
                    sta enable_music_step
                    lda curval
                    sta oldval
                    jmp .unpause
+                   lda #ENABLE
                    sta enable_music_step
                    lda curval
                    sta oldval
                    rts
music_step:         lda curval
                    cmp oldval
                    beq +
                    lda curval
                    sta oldval
                    jmp .pause
+                   rts
music_restart:      lda #$00
                    sta .pause_flag
                    lda #DISABLE
                    sta enable_music
                    lda #$00
                    sta virtualregs+$18
                    lda #SUBTUNE
                    jsr music_init
                    lda #ENABLE
                    sta enable_music
                    rts
; ==============================================================================
!zone POINTERHANDLING

pt_increase:        inc music_pt+1
                    lda music_pt+1
                    cmp #>(music_end+$100)
                    bne +
                    lda #>music_init
                    sta music_pt+1
+                   rts
pt_decrease:        dec music_pt+1
                    lda music_pt+1
                    cmp #>(music_init-$100)
                    bne +
                    lda #>music_end
                    sta music_pt+1
+                   rts
; ==============================================================================
!zone VIRTUAL

vt_load:            ldx #$18
-                   lda $d400,x
                    sta virtualregs,x
                    dex
                    bpl -
                    rts

vt_store:           ldx #$18
                    lda enable_music
                    cmp #DISABLE
                    bne +
                    lda #0
                    sta $d418
                    dex
+
-                   lda virtualregs,x
                    sta $d400,x
                    dex
                    bpl -
                    rts

vt_mute1:           lda #0
                    sta virtualregs+$04
                    rts
vt_mute2:           lda #0
                    sta virtualregs+$0b
                    rts
vt_mute3:           lda #0
                    sta virtualregs+$12
                    rts

vt_mute1_enable:    lda enable_mute1
                    eor #(ENABLE XOR DISABLE)
                    sta enable_mute1
                    rts
vt_mute2_enable:    lda enable_mute2
                    eor #(ENABLE XOR DISABLE)
                    sta enable_mute2
                    rts
vt_mute3_enable:    lda enable_mute3
                    eor #(ENABLE XOR DISABLE)
                    sta enable_mute3
                    rts
; ==============================================================================
!zone SCREEN

screen_update:      ldy #0
                    !for i, 0, 7 {
                    ldx #0
-                   lda (music_pt),y
                    sta DATAAREA+(i*40),x
                    iny
                    inx
                    cpx #32
                    bne - }
                    lda music_pt+1
                    sta .val+2
                    jsr hex2screen
                    sta CURPAGE
                    stx CURPAGE+1
                    sta VALADDR
                    stx VALADDR+1
                    lda music_pt
                    jsr hex2screen
                    sta CURPAGE+2
                    stx CURPAGE+3
                    clc
                    lda music_pt
                    adc cursorlinear
                    sta .val+1
                    jsr hex2screen
                    sta VALADDR+2
                    stx VALADDR+3
.val:               lda $0000
                    sta curval
                    jsr hex2screen
                    sta VAL
                    stx VAL+1
                    lda cursorx
                    asl
                    asl
                    asl
                    sta .xadd
                    lda cursory
                    asl
                    asl
                    asl
                    sta .yadd
                    clc
                    lda #SPRITEXBASE
                    adc .xadd
                    sta $d000
                    bcc +
                    lda #$01
                    !byte $2c
+                   lda #$00
                    sta $d010
                    clc
                    lda #SPRITEYBASE
                    adc .yadd
                    sta $d001
                    rts
.xadd:              !byte $00
.yadd:              !byte $00
screen_init:        lda #$20
                    ldx #>vidmem0
                    ldy #>(vidmem0+$400)
                    jsr memfill
                    lda #COLORTEXT1
                    ldx #$d8
                    ldy #$dc
                    jsr memfill
                    ldx #0
-                   lda textcurpage,x
                    beq +
                    sta STATUSCURPAGE,x
                    inx
                    jmp -
+                   ldx #0
-                   lda textvalue,x
                    beq +
                    sta STATUSVALUE,x
                    inx
                    jmp -
+                   lda #COLORTEXT2
                    sta CURPAGE+0+($d800-vidmem0)
                    sta CURPAGE+1+($d800-vidmem0)
                    sta CURPAGE+2+($d800-vidmem0)
                    sta CURPAGE+3+($d800-vidmem0)
                    sta VALADDR+0+($d800-vidmem0)
                    sta VALADDR+1+($d800-vidmem0)
                    sta VALADDR+2+($d800-vidmem0)
                    sta VALADDR+3+($d800-vidmem0)
                    sta VAL+0+($d800-vidmem0)
                    sta VAL+1+($d800-vidmem0)
                    lda #COLORTEXT3
                    !for i, 0, 7 {
                    ldx #0
-                   sta DATAAREA+(i*40)+($d800-vidmem0),x
                    inx
                    cpx #32
                    bne - }
                    ldx #0
-                   lda textdatacount1,x
                    beq +
                    sta DATACOUNT1,x
                    inx
                    jmp -
+                   ldx #6
-                   !for i, 0, 7 {
                    lda textdatadown+(i*7),x
                    sta DATAAREA-8+(i*40),x }
                    dex
                    bpl -
                    ldx #$27
-                   !for i, 0, 6 {
                    lda textinstructions+(i*40),x
                    sta INSLINE+(i*40),x
                    lda #COLORTEXT4
                    sta INSLINE+(i*40)+($d800-vidmem0),x }
                    dex
                    bpl -
                    lda #$00
                    ldx #$3f
-                   sta spritedata,x
                    dex
                    bpl -
                    ldx #$02
-                   lda .spritedata,x
                    sta spritedata,x
                    sta spritedata+(9*3),x
                    lda .spritedata+3,x
                    !for i, 1, 8 {
                    sta spritedata+(i*3),x }
                    dex
                    bpl -
                    lda #<((spritedata-vicbank)/$40)
                    sta vidmem0+$3f8
                    lda #SPRITEXBASE
                    sta $d000
                    lda #SPRITEYBASE
                    sta $d001
                    lda #$00
                    sta $d010
                    lda #COLORSPRITE
                    sta $d027
                    lda #$01
                    sta $d015
                    lda #$00
                    sta cursorx
                    sta cursory
                    sta cursorlinear
                    rts
.spritedata         !byte $ff, $c0, $00
                    !byte $80, $40, $00
; ==============================================================================
!zone IRQs

irq0:               lda $d012
-                   cmp $d012
                    beq -
                    lda #COLORRASTER
                    sta $d020
                    lda #$34
                    sta $01
enable_music:       jsr music_play
                    jsr vt_load
                    lda #$36
                    sta $01
                    lda #COLORBG
                    sta $d020
enable_mute1:       bit vt_mute1
enable_mute2:       bit vt_mute2
enable_mute3:       bit vt_mute3
                    jsr vt_store
enable_music_step:  bit music_step
                    lda #<irq1
                    sta $0314
                    lda #>irq1
                    sta $0315
                    lda #LINE1
                    sta $d012
                    lda #$1b
                    sta $d011
                    lda #$01
                    sta irq_ready
                    asl $d019
                    jmp $ea31
irq1:               !if DEBUG = 1 {
                    lda #COLORRASTER
                    sta $d020 }
                    jsr screen_update
                    !if DEBUG = 1 {
                    lda #COLORBG
                    sta $d020 }
                    lda #<irq0
                    sta $0314
                    lda #>irq0
                    sta $0315
                    lda #LINE0
                    sta $d012
                    lda #$1b
                    sta $d011
                    asl $d019
                    jmp $ea81
nmi:                rti
; ==============================================================================
!zone DATA

textcurpage:        !scr "Current page: $0000 [+/- to scroll]",0
textvalue:          !scr "Selected value at $0000: $00",0
textdatacount1:     !scr "0123456789ABCDEF0123456789ABCDEF",0

textdatadown:       !scr "$00-$1F"
                    !scr "$20-$3F"
                    !scr "$40-$5F"
                    !scr "$60-$7F"
                    !scr "$80-$9F"
                    !scr "$A0-$BF"
                    !scr "$C0-$DF"
                    !scr "$E0-$FF"

textinstructions:   ;scr "0123456789012345678901234567890123456789"
                    !scr "1-3: (un)mute voice 1, 2, 3             "
                    !scr "  +: display next music data page       "
                    !scr "  -: display previous music data page   "
                    !scr "  P: pause/resume music playback        "
                    !scr "  R: restart tune                       "
                    !scr "  S: step to next selected value change "
                    !scr "     use CRSR keys to select a value    "

virtualregs:        !fi $18, $00
