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

IRQ_LINE0           = 0xF0
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
sprite_data         = vicbank0+0x0F80
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
                    !bin "scr01.scr",,2
                    *= music_init
                    !bin "GubbWubb.sid",,0x7E
                    *= sprite_data
                    !bin "sprite.bin"
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
                    ldx #3
-                   dex
                    bne -
                    dec 0xD020
                    dec 0xD021
                    jsr music_play
                    inc 0xD020
                    inc 0xD021
enable_timer:       jsr timer
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
                    lda #BLUE
                    sta 0xD020
                    sta 0xD021
                    lda #LIGHT_GREEN
                    ldx #0
-                   sta 0xD800,x
                    sta 0xD900,x
                    sta 0xDA00,x
                    sta 0xDAE7,x
                    inx
                    bne -
                    lda #0xA8
                    sta 0xD000
                    lda #0x9B
                    sta 0xD001

                    lda #0x00
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
                    !zone TIMER
                    t0 = vidmem0+(6*40)+38
                    t1 = vidmem0+(6*40)+37
                    t2 = vidmem0+(6*40)+35
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
                    lda #0x30
                    sta t2
                    sta t1
                    sta t0
                    lda #DISABLE
                    sta enable_timer
+                   rts
