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

IRQ_LINE0           = 0xA0
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
vidmem0             = vicbank0+0x0c00
;sprite_data         = vicbank0+0x0C00
;sprite_base         = <((sprite_data-vicbank0)/0x40)
dd00_val0           = <!(vicbank0/0x4000) & 3
d018_val0           = <(((vidmem0-vicbank0)/0x400) << 4)+ <(((charset0-vicbank0)/0x800) << 1)
music_init          = 0x1000
music_play          = 0x1003

cursor              = vidmem0 + 0x190
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
                    !bin "screen.prg",1000,2
                    *= music_init
                    !bin "Rustikales_Ambiente.sid",,0x7E
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
                    ldx #0x04
-                   dex
                    bne -
                    lda #LIGHT_GREEN
                    sta 0xD020
                    sta 0xD021
                    jsr music_play
                    lda #0x0E
                    sta 0xD020
                    lda #0x06
                    sta 0xD021
                    jmp irq_end

irq_tab_lo:         !byte <irq0
irq_tab_hi:         !byte >irq0
irq_lines:          !byte IRQ_LINE0
; ==============================================================================
init_code:          jsr init_nmi
                    jsr init_vic
                    lda #0
                    tax
                    tay
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
                    ldx #0
                    lda #0x0E
-                   sta 0xD800,x
                    sta 0xD900,x
                    sta 0xDA00,x
                    sta 0xDBE7,x
                    inx
                    bne -
                    sta 0xD020
                    lda #0x06
                    sta 0xD021
                    rts
; ==============================================================================
                    !zone MAINLOOP
mainloop:           jsr wait_irq
                    jsr count
                    lda count+1
                    cmp #20
                    bne +
                    lda cursor
                    eor #( 0x20 XOR 0xA0 )
                    sta cursor
+                   jmp mainloop
; ==============================================================================
count:              ldx #20
                    dex
                    bne +
                    ldx #20
+                   stx count+1
                    rts
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
