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

IRQ_LINE0           = 0xC0
; ==============================================================================
zp_start            = 0x02
flag_irq_ready      = zp_start

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
music               = 0x1000
music_init          = music
music_play          = music_init+3
sprite_data         = vicbank0+0x0F80
sprite_base         = <((sprite_data-vicbank0)/0x40)
dd00_val0           = <!(vicbank0/0x4000) & 3
d018_val0           = <(((vidmem0-vicbank0)/0x400) << 4)+ <(((charset0-vicbank0)/0x800) << 1)
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
                    *= vidmem0
                    !bin "gfx/screen.prg",1000,2
                    *= vidmem0+(24*40)+25
                    !scr "> USE 8580!"
                    *= music
                    !bin "../dist/1_can't_ESC_;lt3.sid",,0x7E
                    *= sprite_data
                    !bin "gfx/sprite.bin"
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

irq0:               +flag_set flag_irq_ready
                    !fi 8, 0xEA
                    lda #LIGHT_BLUE
                    sta 0xD020
                    sta 0xD021
                    jsr music_play
                    lda #BLUE
                    sta 0xD020
                    sta 0xD021
                    jsr spider_hit
                    jsr colorblink
                    jsr cursor_blink
enable_timer:       jsr timer
enable_tir:         bit time_is_relative
                    jmp irq_end

irq_tab_lo:         !byte <irq0
irq_tab_hi:         !byte >irq0
irq_lines:          !byte IRQ_LINE0
; ==============================================================================
init_code:          jsr init_nmi
                    jsr init_vic
                    lda #0x00
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
                    lda #LIGHT_GREEN
                    ldx #0x00
-                   sta 0xD800+0x000,x
                    sta 0xD800+0x100,x
                    sta 0xD800+0x200,x
                    sta 0xD800+0x2E8,x
                    inx
                    bne -

                    lda #GREEN
                    ldx #0x0F
-                   sta 0xD800+(1*40),x
                    sta 0xD800+(3*40),x
                    sta 0xD800+(5*40),x
                    sta 0xD800+(7*40),x
                    sta 0xD800+(9*40),x
                    sta 0xD800+(11*40),x
                    dex
                    bpl -

                    sta 0xD800+(24*40)+25

                    lda #WHITE
                    ldx #0x0F
-                   sta 0xD800,x
                    dex
                    bpl -

                    lda #0x40
                    sta 0xD000
                    lda #0xE8
                    sta 0xD001

                    lda #0x01
                    sta 0xD010

                    lda #0x00
                    sta 0xD017
                    sta 0xD01D
                    lda #LIGHT_GREEN
                    sta 0xD027

                    lda #sprite_base
                    sta vidmem0+0x3F8

                    lda #0x01
                    sta 0xD015
                    rts
; ==============================================================================
                    !zone MAINLOOP
mainloop:           jsr wait_irq
                    jmp mainloop
; ==============================================================================
                    !zone NMI
nmi:                lda #0x37               ; restore 0x01 standard value
                    sta 0x01
                    lda #0                  ; if AR/RR present
                    sta 0xDE00              ; reset will lead to menu
                    jmp 0xFCE2              ; reset
; ==============================================================================
                    !zone WAIT
wait_irq:           +flag_clear flag_irq_ready
.wait_irq:          +flag_get flag_irq_ready
                    beq .wait_irq
                    rts
; ==============================================================================
                    !zone COLORBLINK
                    COLORBLINK_COUNTER = 0x06
colorblink:         lda #COLORBLINK_COUNTER
                    beq +
                    dec colorblink+1
                    rts
+                   lda #COLORBLINK_COUNTER
                    sta colorblink+1
.index:             ldx #0x00
                    lda .blinktab,x
                    sta 0xD800+(2*40)+03
                    sta 0xD800+(2*40)+04
                    sta 0xD800+(2*40)+05
                    sta 0xD800+(2*40)+06
                    sta 0xD800+(2*40)+07
                    sta 0xD800+(2*40)+08
disable_blink:      sta 0xD800+(8*40)+12
                    sta 0xD800+(8*40)+14
                    sta 0xD800+(8*40)+15
                    inx
                    cpx #8
                    bne +
                    ldx #0
+                   stx .index+1
                    rts
.blinktab:          !byte BLUE, DARK_GREY, LIGHT_BLUE, LIGHT_GREY
                    !byte GREEN, DARK_GREY, LIGHT_BLUE, LIGHT_GREEN
; ==============================================================================
                    !zone TIMER
                    t0 = vidmem0+(8*40)+15
                    t1 = vidmem0+(8*40)+14
                    t2 = vidmem0+(8*40)+12
                    SECONDS_VAL = 49
timer:              lda #SECONDS_VAL
                    beq +
                    dec timer+1
                    rts
+                   lda #SECONDS_VAL
                    sta timer+1
                    sec
                    dec t0
                    lda t0
                    cmp #0x2F
                    bne +
                    lda #0x39
                    sta t0
                    dec t1
                    lda t1
                    cmp #0x2F
                    bne +
                    lda #0x35
                    sta t1
                    dec t2
                    lda t2
                    cmp #0x2F
                    bne +
                    lda #0xEA
                    ldx #8
-                   sta disable_blink,x
                    dex
                    bpl -
                    lda #0x30
                    sta t2
                    lda #DISABLE
                    sta enable_timer
                    lda #ENABLE
                    sta enable_tir
+                   rts
; ==============================================================================
                    !zone RELATIVE
                    RELATIVE_DELAY = 0x06
time_is_relative:   lda #RELATIVE_DELAY
                    beq +
                    dec time_is_relative+1
                    rts
+                   lda #RELATIVE_DELAY
                    sta time_is_relative+1
.tir_x:             ldx #0x00
                    lda .reltext,x
                    sta vidmem0+(8*40),x
                    lda #WHITE
                    sta 0xD800+(8*40),x
                    inx
                    cpx #0x10
                    bne +
                    ldx #0x00
                    lda #DISABLE
                    sta enable_tir
+                   stx .tir_x+1
                    rts
.reltext:           !scr "TiME is RELaTi<3"
; ==============================================================================
                    !zone SPRITES
spider_hit:         lda music_init+0x4C
                    cmp #0x01
                    bne +
                    lda #GREEN
                    !byte 0x2C
+                   lda #LIGHT_GREEN
                    sta 0xD027
                    rts
; ==============================================================================
                    !zone CURSOR
                    CURSOR_BLINK_FREQ = 24
cursor_blink:       lda #CURSOR_BLINK_FREQ
                    beq +
                    dec cursor_blink+1
                    rts
+                   lda #CURSOR_BLINK_FREQ
                    sta cursor_blink+1
.crsr_x:            ldx #0x00
                    lda .blinktab,x
                    sta vidmem0+(13*40)
                    inx
                    cpx #20
                    bne +
                    ldx #0x00
+                   stx .crsr_x+1
                    rts
.blinktab:          !byte 032+000, 032+128
                    !byte 032+000, 032+128
                    !byte 032+000, 032+128
                    !byte 032+000, 032+128
                    !byte 032, 173
                    !byte 32, 175
                    !byte 32, 188
                    !byte 32, 250
                    !byte 32, 255
                    !byte 32, 127

