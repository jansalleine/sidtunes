                    !cpu 6510

DEBUG = 0
RELEASE = 1
; ==============================================================================
ENABLE              = 0x20
ENABLE_JMP          = 0x4C
DISABLE             = 0x2C

BLACK               = 0x00
WHITE               = 0x01
RED                 = 0x02
CYAN                = 0x03
PURPLE              = 0x04
GREEN               = 0x05
BLUE                = 0x06
YELLOW              = 0x07
ORANGE              = 0x08
BROWN               = 0x09
PINK                = 0x0A
DARK_GREY           = 0x0B
GREY                = 0x0C
LIGHT_GREEN         = 0x0D
LIGHT_BLUE          = 0x0E
LIGHT_GREY          = 0x0F

MEMCFG              = 0x35

IRQ_LINE0           = 0xE4

COL_BG              = BLUE
COL_RASTER          = CYAN
; ==============================================================================
zp_start            = 0x02
flag_irq_ready      = zp_start
zp_temp0            = flag_irq_ready+1
zp_temp0_lo         = zp_temp0
zp_temp0_hi         = zp_temp0_lo+1

; ==============================================================================
KEY_CRSRUP          = 0x91
KEY_CRSRDOWN        = 0x11
KEY_CRSRLEFT        = 0x9D
KEY_CRSRRIGHT       = 0x1D
KEY_RETURN          = 0x0D
KEY_STOP            = 0x03

getin               = 0xFFE4
keyscan             = 0xEA87
; ==============================================================================
code_start          = 0x0810
vicbank0            = 0x0000
charset0            = vicbank0+0x1800
vidmem0             = vicbank0+0x0400
sprite_data         = vicbank0+0x0C00
sprite_base         = <((sprite_data-vicbank0)/0x40)
dd00_val0           = <!(vicbank0/0x4000) & 3
d018_val0           = <(((vidmem0-vicbank0)/0x400) << 4)+ <(((charset0-vicbank0)/0x800) << 1)
music_init          = 0x1000
music_play          = 0x1003
; ==============================================================================
                    !macro flag_set .flag {
                        lda #1
                        sta .flag
                    }
                    !macro flag_clear .flag {
                        lda #0
                        sta .flag
                    }
                    !macro flag_get .flag {
                        lda .flag
                    }
; ==============================================================================
                    *= vidmem0
                    !bin "screen1.scr",1000,2
                    *= sprite_data
                    !bin "sprite.bin"
                    *= music_init
                    !bin "Breastfeeding_in_a_Vegan_Bar.sid",, 0x7E
; ==============================================================================
                    *= code_start
                    lda #0x7F
                    sta 0xDC0D
                    lda #MEMCFG
                    sta 0x01
                    lda #0x0B
                    sta 0xD011
                    jmp init_code
; ==============================================================================
                    !zone IRQ
                    NUM_IRQS = 0x01
irq:                !if MEMCFG = 0x35 {
                        sta .irq_savea+1
                        stx .irq_savex+1
                        sty .irq_savey+1
                        lda 0x01
                        sta .irq_save0x01+1
                        lda #0x35
                        sta 0x01
                    }
irq_next:           jmp irq0
irq_end:            lda 0xD012
-                   cmp 0xD012
                    beq -
.irq_index:         ldx #0
                    lda irq_tab_lo,x
                    sta irq_next+1
                    lda irq_tab_hi,x
                    sta irq_next+2
                    lda irq_lines,x
                    sta 0xD012
                    inc .irq_index+1
                    lda .irq_index+1
                    cmp #NUM_IRQS
                    bne +
                    lda #0
                    sta .irq_index+1
+                   asl 0xD019
                    !if MEMCFG = 0x37 {
                        jmp 0xEA31
                    }
                    !if MEMCFG = 0x36 {
                        jmp 0xEA81
                    }
                    !if MEMCFG = 0x35 {
.irq_save0x01:          lda #0x35
                        sta 0x01
                        cmp #0x36
                        beq +
.irq_savea:             lda #0
.irq_savex:             ldx #0
.irq_savey:             ldy #0
                        rti
+                       jmp 0xEA81
                    }

irq0:               lda #COL_RASTER
                    sta 0xD020
                    sta 0xD021
enable_music:       jsr music_play
                    +flag_set flag_irq_ready
                    lda #COL_BG
                    sta 0xD020
                    sta 0xD021
                    !if DEBUG=1 { dec 0xD020 }
                    jsr anim_textborder
enable_timer:       jsr timer
                    jsr check_end
                    jsr anim_time
                    jsr anim_cursor
                    !if DEBUG=1 { inc 0xD020 }
                    jmp irq_end

irq_tab_lo:         !byte <irq0
irq_tab_hi:         !byte >irq0
irq_lines:          !byte IRQ_LINE0
; ==============================================================================
init_code:          jsr init_nmi
                    jsr init_vic
                    lda #0
                    jsr music_init
                    jsr init_irq
                    jmp mainloop

init_irq:           lda irq_lines
                    sta 0xD012
                    lda #<irq
                    sta 0x0314
                    !if MEMCFG = 0x35 {
                        sta 0xFFFE
                    }
                    lda #>irq
                    sta 0x0315
                    !if MEMCFG = 0x35 {
                        sta 0xFFFF
                    }
                    lda 0xD011
                    and #%01101111
                    ora #%00010000
                    sta 0xD011
                    lda #0x01
                    sta 0xD019
                    sta 0xD01A
                    rts

init_nmi:           lda #<nmi
                    sta 0x0318
                    !if MEMCFG = 0x35 {
                        sta 0xFFFA
                    }
                    lda #>nmi
                    sta 0x0319
                    !if MEMCFG = 0x35 {
                        sta 0xFFFB
                    }
                    rts

init_vic:           lda #dd00_val0
                    sta 0xDD00
                    lda #d018_val0
                    sta 0xD018
                    lda #CYAN
                    ldx #0x00
-                   sta 0xD800+0x000,x
                    sta 0xD800+0x100,x
                    sta 0xD800+0x200,x
                    sta 0xD800+0x2E8,x
                    inx
                    bne -
                    lda #COL_BG
                    ldx #39
-                   sta 0xD800+(0*40),x
                    sta 0xD800+(4*40),x
                    dex
                    bpl -
                    sta 0xD800+(1*40)
                    sta 0xD800+(2*40)
                    sta 0xD800+(3*40)
                    sta 0xD800+(1*40)+20
                    sta 0xD800+(2*40)+20
                    sta 0xD800+(3*40)+20
                    lda #YELLOW
                    ldx #19
-                   sta 0xD800+(1*40),x
                    sta 0xD800+(2*40),x
                    sta 0xD800+(3*40),x
                    dex
                    bne -
                    sta 0xD800+(11*40)+25
                    sta 0xD800+(11*40)+24
                    ;sta 0xD800+(11*40)+23
                    sta 0xD800+(11*40)+22
                    lda #PINK
                    ldx #25
-                   sta 0xD800+(6*40),x
                    dex
                    bpl -
                    lda #WHITE
                    ldx #15
-                   sta 0xD800+(7*40)+10,x
                    dex
                    bpl -
                    lda #LIGHT_GREEN
                    ldx #15
-                   sta 0xD800+(9*40)+10,x
                    dex
                    bpl -
                    lda #LIGHT_BLUE
                    ldx #40
-                   sta 0xD800+(15*40),x
                    dex
                    bpl -
                    lda #sprite_base
                    sta vidmem0+0x3F8
                    lda #0x28
                    sta 0xD000
                    lda #0x5F
                    sta 0xD001
                    lda #WHITE
                    sta 0xD027
                    lda #0x01
                    sta 0xD010
                    sta 0xD017
                    sta 0xD01D
                    sta 0xD015
                    rts
; ==============================================================================
                    !zone MAINLOOP
mainloop:           jsr wait_irq
enable_init:        lda #0
                    beq +
                    dec enable_init+1
                    sei
                    lda #0
                    jsr music_init
                    lda #ENABLE
                    sta enable_music
                    sta enable_timer
                    asl 0xD019
                    cli
+                   jmp mainloop
; ==============================================================================
                    !zone NMI
nmi:                pha
                    lda #0x30
                    sta t0
                    sta t1
                    sta t2
                    lda #1
                    sta enable_init+1
                    lda #SECONDS_VAL
                    sta timer+1
                    pla
                    rti
; ==============================================================================
                    !zone WAIT
wait_irq:           +flag_clear flag_irq_ready
.wait_irq:          +flag_get flag_irq_ready
                    beq .wait_irq
                    rts
; ==============================================================================
                    !zone ANIMATION
                    ANIM_SPEED = 1
anim_textborder:    lda #ANIM_SPEED
                    beq +
                    dec anim_textborder+1
                    rts
+                   lda #ANIM_SPEED
                    sta anim_textborder+1
                    ldx #6+8
-                   lda coltab,x
                    pha
.colpospt:          ldy #0
                    lda colpostab_lo,y
                    cmp #0xFF
                    bne +
                    lda #0
                    sta .colpospt+1
                    jmp .colpospt
+                   sta .dest+1
                    lda colpostab_hi,y
                    sta .dest+2
                    inc .colpospt+1
                    pla
.dest:              sta 0x0000
                    dex
                    bpl -
                    rts
                    ANIM_TIME_SPEED = 2
anim_time:          lda #ANIM_TIME_SPEED
                    beq +
                    dec anim_time+1
                    rts
+                   lda #ANIM_TIME_SPEED
                    sta anim_time+1
.anim_time_pt:      ldx #0
                    lda .time_cols,x
                    sta 0xD800+(11*40)+13
                    sta 0xD800+(11*40)+12
                    sta 0xD800+(11*40)+10
                    eor #2
                    sta 0xD027
                    inx
                    cpx #12
                    bne +
                    ldx #0
+                   stx .anim_time_pt+1
                    rts
.time_cols:         !byte BLUE, LIGHT_BLUE, LIGHT_GREEN, CYAN, YELLOW, WHITE
                    !byte YELLOW, CYAN, LIGHT_GREEN, LIGHT_BLUE, BLUE
                    ANIM_CRSR_TIME = 16
                    CRSR_POS = vidmem0+(18*40)
anim_cursor:        lda #ANIM_CRSR_TIME
                    beq +
                    dec anim_cursor+1
                    rts
+                   lda #ANIM_CRSR_TIME
                    sta anim_cursor+1
                    lda CRSR_POS
                    eor #(32 XOR 160)
                    sta CRSR_POS
                    rts
; ==============================================================================
                    !zone TIMER
                    t0 = vidmem0+(11*40)+13
                    t1 = vidmem0+(11*40)+12
                    t2 = vidmem0+(11*40)+10
                    SECONDS_VAL = 49
timer:              lda #SECONDS_VAL
                    beq +
                    dec timer+1
                    rts
+                   lda #SECONDS_VAL
                    sta timer+1
                    clc
                    inc t0
                    lda t0
                    cmp #0x3A
                    bne +
                    lda #0x30
                    sta t0
                    inc t1
                    lda t1
                    cmp #0x36
                    bne +
                    lda #0x30
                    sta t1
                    inc t2
                    lda t2
                    cmp #0x3A
                    bne +
+                   rts
                    e0 = vidmem0+(11*40)+25
                    e1 = vidmem0+(11*40)+24
                    e2 = vidmem0+(11*40)+22
check_end:          lda t2
                    cmp e2
                    bne +
                    lda t1
                    cmp e1
                    bne +
                    lda t0
                    cmp e0
                    bne +
                    lda #DISABLE
                    sta enable_music
                    sta enable_timer
+                   rts
; ==============================================================================
                    !zone TABLES
colpostab_lo:       !for i, 0, 20 {
                        !byte <(0xD800+(0*40)+i)
                    }
                    !byte <(0xD800+(1*40)+20)
                    !byte <(0xD800+(2*40)+20)
                    !for i, 20, 0 {
                        !byte <(0xD800+(3*40)+i)
                    }
                    !byte <(0xD800+(1*40))
                    !byte <(0xD800+(2*40))
                    !byte 0xFF

colpostab_hi:       !for i, 0, 20 {
                        !byte >(0xD800+(0*40)+i)
                    }
                    !byte >(0xD800+(1*40)+20)
                    !byte >(0xD800+(2*40)+20)
                    !for i, 20, 0 {
                        !byte >(0xD800+(3*40)+i)
                    }
                    !byte >(0xD800+(1*40))
                    !byte >(0xD800+(2*40))
                    !byte 0xFF

coltab:             !byte BLUE, LIGHT_GREEN, CYAN, WHITE, CYAN, LIGHT_GREEN, BLUE
                    !byte BLUE, BLUE, BLUE, BLUE, BLUE, BLUE, BLUE, BLUE, BLUE
