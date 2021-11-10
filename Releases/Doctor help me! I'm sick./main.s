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

IRQ_LINE0           = 0x00
IRQ_LINE1           = 0xBA
IRQ_LINE2           = 0xFA

COLOR_BG_TOP        = LIGHT_BLUE
COLOR_BG_BOTTOM     = BLUE

COLOR_TOP           = BLUE
COLOR_BOTTOM        = LIGHT_BLUE

COLOR_HIGHLIGHT     = WHITE
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
vicbank0            = 0x4000
charset0            = vicbank0+0x0000
charset1            = vicbank0+0x0800
vidmem0             = vicbank0+0x1000

anim_screen         = vidmem0+(3*40)-40+10
anim_charset        = charset1

sprite_data         = charset1 - 0x40
sprite_base         = <((sprite_data-vicbank0)/0x40)
dd00_val0           = <!(vicbank0/0x4000) & 3
d018_val0           = <(((vidmem0-vicbank0)/0x400) << 4)+ <(((charset0-vicbank0)/0x800) << 1)
d018_val1           = <(((vidmem0-vicbank0)/0x400) << 4)+ <(((charset1-vicbank0)/0x800) << 1)

music_init          = 0x1000
music_play          = music_init + 0x03

speedcode           = vidmem0 + 0x0400
; ==============================================================================
                    !zone MACROS
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
                    !zone INCLUDES
                    *= music_init
                    !bin "includes/Doctor_help_me!_I'm_sick..sid",,0x7E
                    *= charset0
                    !bin "includes/dochelpcharset/chars.raw"
                    !bin "includes/timeuntilcharset/chars.raw"
                    !bin "includes/numbersdigicharset/chars.raw"
                    *= charset1
                    !bin "includes/phase0.chr"
                    *= sprite_data
                    !bin "includes/sprite.bin"
                    *= speedcode
                    !src "src/speedcode-char.s"
                    !src "src/speedcode-screen.s"
; ==============================================================================
                    !zone CODE_START
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
                    NUM_IRQS = 0x03
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

irq0:
col_top_mod0:       lda #COLOR_BG_TOP
                    sta 0xD020
col_top_mod1:       lda #COLOR_BG_TOP
                    sta 0xD021
                    lda #d018_val1
                    sta 0xD018
                    lda #0x1B
                    sta 0xD011
                    lda #0x01
                    sta 0xD015
                    jsr music_play
                    jsr timer
                    jsr count_frames
                    jsr check_snare
                    jsr anim_snare
                    +flag_set flag_irq_ready
                    jmp irq_end

irq1:
                    ldx #0x03
-
                    dex
                    bpl -

                    lda #COLOR_BG_BOTTOM
                    sta 0xD021
                    lda #COLOR_BG_BOTTOM
                    sta 0xD020

                    ldx #0x57
-
                    dex
                    bpl -

                    lda #d018_val0
                    sta 0xD018

                    jsr animation

                    jmp irq_end

irq2:               lda #0x13
                    sta 0xD011
                    lda #0
                    sta 0xD015
                    jmp irq_end

irq_tab_lo:         !byte <irq0, <irq1, <irq2
irq_tab_hi:         !byte >irq0, >irq1, >irq2
irq_lines:          !byte IRQ_LINE0, IRQ_LINE1, IRQ_LINE2
; ==============================================================================
                    !zone INIT
init_code:          jsr init_nmi
                    jsr init_vic
                    jsr init_music
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

init_vic:           lda #0x00
                    sta vicbank0 + 0x3FFF
                    ldx #>vidmem0
                    jsr lib_vidmemfill
                    lda #COLOR_BOTTOM
                    jsr lib_colramfill
                    lda #COLOR_TOP
                    ldx #0x00
-                   sta 0xD800,x
                    sta 0xD900,x
                    sta 0xDA00,x
                    inx
                    bne -
                    jsr print_songtitle
                    jsr print_shit
                    lda #dd00_val0
                    sta 0xDD00
                    lda #d018_val0
                    sta 0xD018
                    lda #0x40
                    sta 0xD000
                    lda #0x18
                    sta 0xD001
                    lda #0x01
                    sta 0xD010
                    lda #COLOR_TOP
                    sta 0xD027
                    lda #0x00
                    sta 0xD017
                    sta 0xD01C
                    sta 0xD01D
                    lda #sprite_base
                    sta vidmem0 + 0x03F8
                    rts

init_music:         lda #0x00
                    jsr music_init
                    rts
; ==============================================================================
                    !zone MAINLOOP
mainloop:           jsr wait_irq
                    jsr print_timer
                    jsr check_timer
                    jsr reset
                    jmp mainloop
check_timer:        bit check_timer_end
                    lda counter + 1
                    cmp #0x0F
                    beq +
.delete0:           cmp #0x0E
                    beq +
                    rts
+                   lda counter
                    cmp #0xE0
                    beq +
.delete1:           cmp #0x25
                    beq ++
                    rts
+
                    lda #ENABLE_JMP
                    sta check_timer
                    lda #0xEA
                    sta animation
                    rts
++                  lda #0xEA
                    sta check_snare
                    sta .delete0
                    sta .delete0 + 1
                    sta .delete0 + 2
                    sta .delete0 + 3
                    sta .delete1
                    sta .delete1 + 1
                    sta .delete1 + 2
                    sta .delete1 + 3
                    rts

check_snare:        rts
                    lda music_init + 0x3B
                    cmp #0x26
                    beq +
                    cmp #0x2F
                    beq +
                    sta .old_checkval
                    rts
+                   lda .old_checkval
                    cmp #0x26
                    bne +
-                   lda music_init + 0x3B
                    sta .old_checkval
                    rts
+                   cmp #0x2F
                    bne +
                    jmp -
+                   lda #0xEA
                    sta anim_snare
                    lda #0x60
                    sta check_snare
                    lda music_init + 0x3B
                    sta .old_checkval
                    rts

.old_checkval:      !byte 0

check_timer_end:    lda counter + 1
                    cmp #0x20
                    beq +
                    rts
+                   lda counter
                    cmp #0xA0
                    beq +
                    rts
+                   lda #0x60
                    sta animation
                    sta check_timer
                    rts

reset:              rts
                    sei
                    jmp nmi
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
                    !zone PRINT

print_songtitle:    ldx #0x00

.tile_num:          lda #0x01
                    ldy #0x07
                    stx .savex0 + 1
                    jsr print_tile
                    inc .tile_num + 1
.savex0:            ldx #0x00
                    inx
                    cpx #0x09
                    bne .tile_num
                    rts

print_shit:         ldx #25
.loop0:             lda #( 0x3E + 26 )
                    sta vidmem0 + ( 24 * 40 ),x
                    dec .loop0 + 1
                    dex
                    bpl .loop0
                    rts

;                   print_tile ( 3x3 )
;                   ==========
;                   A : tile number
;                   X : column          ( 0x00 - 0x0C )
;                   Y : row             ( 0x00 - 0x07 )
print_tile:         pha
                    lda .screentab_x,x
                    sta .x0 + 1
                    pla
                    tax
                    lda .tiles_index0_lo,x
                    sta .tile_pt0 + 1
                    lda .tiles_index0_hi,x
                    sta .tile_pt0 + 2
                    lda .tiles_index1_lo,x
                    sta .tile_pt1 + 1
                    lda .tiles_index1_hi,x
                    sta .tile_pt1 + 2
                    lda .tiles_index2_lo,x
                    sta .tile_pt2 + 1
                    lda .tiles_index2_hi,x
                    sta .tile_pt2 + 2

                    lda .screentab_y0_lo,y
                    sta .screen_pt0 + 1
                    lda .screentab_y0_hi,y
                    sta .screen_pt0 + 2
                    lda .screentab_y1_lo,y
                    sta .screen_pt1 + 1
                    lda .screentab_y1_hi,y
                    sta .screen_pt1 + 2
                    lda .screentab_y2_lo,y
                    sta .screen_pt2 + 1
                    lda .screentab_y2_hi,y
                    sta .screen_pt2 + 2

                    ldy #0x00

.x0:                ldx #0x00
.tile_pt0:          lda 0x0000,y
.screen_pt0:        sta 0x0000,x
.tile_pt1:          lda 0x0000,y
.screen_pt1:        sta 0x0000,x
.tile_pt2:          lda 0x0000,y
.screen_pt2:        sta 0x0000,x
                    inx
                    iny
                    cpy #3
                    bne .tile_pt0
                    rts

.screentab_x:       !for i, 0x00, 0x0C {
                        !byte ( 3 * i )
                    }
.screentab_y0_lo:   !for i, 0x00, 0x07 {
                        !byte <( vidmem0 + ( 0 * 40 ) + ( ( 3 * 40 ) * i ) )
                    }
.screentab_y0_hi:   !for i, 0x00, 0x07 {
                        !byte >( vidmem0 + ( 0 * 40 ) + ( ( 3 * 40 ) * i ) )
                    }
.screentab_y1_lo:   !for i, 0x00, 0x07 {
                        !byte <( vidmem0 + ( 1 * 40 ) + ( ( 3 * 40 ) * i ) )
                    }
.screentab_y1_hi:   !for i, 0x00, 0x07 {
                        !byte >( vidmem0 + ( 1 * 40 ) + ( ( 3 * 40 ) * i ) )
                    }
.screentab_y2_lo:   !for i, 0x00, 0x07 {
                        !byte <( vidmem0 + ( 2 * 40 ) + ( ( 3 * 40 ) * i ) )
                    }
.screentab_y2_hi:   !for i, 0x00, 0x07 {
                        !byte >( vidmem0 + ( 2 * 40 ) + ( ( 3 * 40 ) * i ) )
                    }
.tiles_index0_lo:   !for i, 0x00, 0x09 {
                        !byte <( dochelptiles + ( 9 * i ) )
                    }
.tiles_index0_hi:   !for i, 0x00, 0x09 {
                        !byte >( dochelptiles + ( 9 * i ) )
                    }
.tiles_index1_lo:   !for i, 0x00, 0x09 {
                        !byte <( dochelptiles + ( 9 * i ) + 3 )
                    }
.tiles_index1_hi:   !for i, 0x00, 0x09 {
                        !byte >( dochelptiles + ( 9 * i ) + 3 )
                    }
.tiles_index2_lo:   !for i, 0x00, 0x09 {
                        !byte <( dochelptiles + ( 9 * i ) + 6 )
                    }
.tiles_index2_hi:   !for i, 0x00, 0x09 {
                        !byte >( dochelptiles + ( 9 * i ) + 6 )
                    }

print_timer:        TIMEPOS = vidmem0 + ( 23 * 40 ) + 35
                    TIMECOLPOS = 0xD800 + ( 23 * 40 ) + 35
                    ldx timer_vals
                    lda numbertiles_t,x
                    sta TIMEPOS + ( 0 * 40 ) + 4
                    lda numbertiles_b,x
                    sta TIMEPOS + ( 1 * 40 ) + 4

                    ldx timer_vals + 1
                    lda numbertiles_t,x
                    sta TIMEPOS + ( 0 * 40 ) + 3
                    lda numbertiles_b,x
                    sta TIMEPOS + ( 1 * 40 ) + 3

                    ldx #0x0A
                    lda numbertiles_t,x
                    sta TIMEPOS + ( 0 * 40 ) + 2
                    lda numbertiles_b,x
                    sta TIMEPOS + ( 1 * 40 ) + 2

                    ldx timer_vals + 2
                    lda numbertiles_t,x
                    sta TIMEPOS + ( 0 * 40 ) + 1
                    lda numbertiles_b,x
                    sta TIMEPOS + ( 1 * 40 ) + 1

                    ldx timer_vals + 3
                    lda numbertiles_t,x
                    sta TIMEPOS + ( 0 * 40 ) + 0
                    lda numbertiles_b,x
                    sta TIMEPOS + ( 1 * 40 ) + 0

                    ldx #4
                    lda #COLOR_HIGHLIGHT
-                   sta TIMECOLPOS + ( 0 * 40 ),x
                    sta TIMECOLPOS + ( 1 * 40 ),x
                    dex
                    bpl -
                    rts
; ==============================================================================
                    !zone TIMER
timer:
                    lda .framecount
                    beq +
                    dec .framecount
                    rts
+                   lda #50
                    sta .framecount

                    dec .s0
                    lda .s0
                    cmp #0xFF
                    beq +
                    rts
+
                    lda #0x09
                    sta .s0

                    dec .s1
                    lda .s1
                    cmp #0xFF
                    beq +
                    rts
+
                    lda #0x05
                    sta .s1

                    dec .m0
                    lda .m0
                    cmp #0xFF
                    beq +
                    rts
+
                    lda #0x09
                    sta .m0

                    dec .m1
                    lda .m1
                    cmp #0xFF
                    beq +
                    rts
+
                    lda #0x00
                    sta .s0
                    sta .s1
                    sta .m0
                    sta .m1
                    lda #0xEA
                    sta reset
                    rts
timer_vals:
.s0:                !byte 0x01
.s1:                !byte 0x05
.m0:                !byte 0x02
.m1:                !byte 0x00
.framecount:        !byte 50

count_frames:
                    clc
                    lda .count0
                    adc #1
                    sta .count0
                    lda .count1
                    adc #0
                    sta .count1
                    rts
counter:
.count0:            !byte 0x00
.count1:            !byte 0x00
; ==============================================================================
                    !zone ANIMATION
                    ANIM_SPEED = 4
animation:          rts ; nop
                    ;inc $d020
.speed =*+1
                    lda #ANIM_SPEED
                    beq +
                    dec .speed
                    ;dec $d020
                    rts
+
                    lda #ANIM_SPEED
                    sta .speed
.count =*+1
                    lda #0
                    bne +
                    jsr phase0_chr_to_phase1_chr
                    jsr phase0_sc1_to_phase1_sc1
                    jmp .exit
+
                    cmp #1
                    bne +
                    jsr phase1_chr_to_phase2_chr
                    jsr phase1_sc1_to_phase2_sc1
                    jmp .exit
+
                    cmp #2
                    bne +
                    jsr phase2_chr_to_phase3_chr
                    jsr phase2_sc1_to_phase3_sc1
                    jmp .exit
+
                    cmp #3
                    bne +
                    jsr phase3_chr_to_phase4_chr
                    jsr phase3_sc1_to_phase4_sc1
                    jmp .exit
+
                    cmp #4
                    bne +
                    jsr phase4_chr_to_phase0_chr
                    jsr phase4_sc1_to_phase0_sc1
                    lda #$ff
                    sta .count
+
.exit:
                    inc .count
                    ;dec $d020
                    rts

anim_snare:         rts
.anim_index:        ldx #0x05
                    lda .coltab,x
                    sta col_top_mod0 + 1
                    sta col_top_mod1 + 1
                    dex
                    bpl +
                    lda #0x60
                    sta anim_snare
                    lda #0xEA
                    sta check_snare
                    ldx #0x05
+                   stx .anim_index + 1
                    rts

.coltab:            !byte COLOR_BG_TOP, LIGHT_GREY, YELLOW, WHITE, YELLOW, LIGHT_GREY
; ==============================================================================
                    !zone SOURCES
                    LIB_INCLUDE = 1
                    !src "src/library.s"
; ==============================================================================
                    !zone DATA
dochelptiles:       !bin "includes/dochelpcharset/tiles.raw"

                    NUMBERTILES_START = ( 0x3E + 27 )
numbertiles_t:      !byte NUMBERTILES_START + 0x0B              ; 0
                    !byte NUMBERTILES_START + 0x00              ; 1
                    !byte NUMBERTILES_START + 0x01              ; 2
                    !byte NUMBERTILES_START + 0x01              ; 3
                    !byte NUMBERTILES_START + 0x04              ; 4
                    !byte NUMBERTILES_START + 0x07              ; 5
                    !byte NUMBERTILES_START + 0x07              ; 6
                    !byte NUMBERTILES_START + 0x09              ; 7
                    !byte NUMBERTILES_START + 0x0A              ; 8
                    !byte NUMBERTILES_START + 0x0A              ; 9
                    !byte NUMBERTILES_START + 0x0D              ; :
numbertiles_b:      !byte NUMBERTILES_START + 0x0C              ; 0
                    !byte NUMBERTILES_START + 0x00              ; 1
                    !byte NUMBERTILES_START + 0x03              ; 2
                    !byte NUMBERTILES_START + 0x05              ; 3
                    !byte NUMBERTILES_START + 0x06              ; 4
                    !byte NUMBERTILES_START + 0x05              ; 5
                    !byte NUMBERTILES_START + 0x08              ; 6
                    !byte NUMBERTILES_START + 0x06              ; 7
                    !byte NUMBERTILES_START + 0x08              ; 8
                    !byte NUMBERTILES_START + 0x06              ; 9
                    !byte NUMBERTILES_START + 0x0E              ; :
