!cpu 6510
!src "colorcodes.asm"
!src "data.asm"

DEBUG = 0

; ==============================================================================
enable            = $20
disable           = $2c

line0             = $00
line1             = $2d
line2             = $32
line3             = $6d
line4             = $b2
line5             = $fa
line6             = $ff

line_title        = $0400+(17*40)
line_author       = $0400+(19*40)
line_sidinfo      = $0400+(21*40)
line_time         = $0400+(23*40)
line_instructions = $0400+(1*40)
line_mode_pos     = line_instructions+(4*40)+35
line_scroller     = $0400+(8*40)
colram_scroller   = $d800+(8*40)

; ==============================================================================
savea             = $02
savex             = savea+1
savey             = savex+1
color_border      = savey+1
color_backgr      = color_border+1
color_blink       = color_backgr+1
irq_ready         = color_blink+1
current_mode      = irq_ready+1
pt_screenpos      = current_mode+1  ; NEXT: pt_screenpos+2
pt_charset        = pt_screenpos+2  ; NEXT: pt_charset+2
pause_flag        = pt_charset+2
; ==============================================================================
*= $0800
init_code:
    sei
    lda #$7f
    sta $dc0d
    sta $dd0d
    lda $dc0d
    lda $dd0d

    lda #$35
    sta $01

    jsr init_vic

    lda #$20
    ldx #$04
    ldy #$08
    jsr memfill

    lda #color5
    ldx #$d8
    ldy #$dc
    jsr memfill

    ldx #music_title_length
-   lda music_title,x
    sta line_title+music_title_center,x
    lda #$63
    sta line_title+(1*40)+music_title_center,x
    dex
    bpl -

    ldx #music_time_length
-   lda music_time,x
    sta line_time+music_time_center,x
    dex
    bpl -

    ldx #music_sidinfo_length
-   lda music_sidinfo,x
    sta line_sidinfo+music_sidinfo_center,x
    dex
    bpl -

    ldx #music_author_length
-   lda music_author,x
    sta line_author+music_author_center,x
    dex
    bpl -

    jsr print_instructions

    ldx #$27
    lda #color6
-   sta colram_scroller+(0*40),x
    sta colram_scroller+(1*40),x
    sta colram_scroller+(2*40),x
    sta colram_scroller+(3*40),x
    sta colram_scroller+(4*40),x
    sta colram_scroller+(5*40),x
    sta colram_scroller+(6*40),x
    sta colram_scroller+(7*40),x
    dex
    bpl -

    lda #SUBTUNE
    jsr music_init

    lda #color0
    sta color_border
    lda #color1
    sta color_backgr
    lda #color4
    sta color_blink

    lda #MODE
    sta current_mode

    lda #0
    sta pause_flag

    lda #$3c
    sta $0400+$3f8

    lda #$01
    sta $d015
    sta $d010

    lda #color5
    sta $d027

    lda #$40
    sta $d000

    lda #$e0
    sta $d001

    lda #<irq0
    sta $fffe
    lda #>irq0
    sta $ffff
!if DEBUG = 1 {
    lda #<nmi_debug
    sta $fffa
    lda #>nmi_debug
    sta $fffb
} else {
    lda #<nmi
    sta $fffa
    lda #>nmi
    sta $fffb
}
    asl $d019
    cli

; ==============================================================================
mainloop:
!if DEBUG = 1 {
    dec $d020
}
    jsr wait_irq
    jsr keyboard_get
    jsr scroller
!if DEBUG = 1 {
    inc $d020
}
tune_end_flag =*+1
    lda #0
    beq mainloop

    lda #SUBTUNE
    jsr music_init

    lda #0
    sta tune_end_flag

    jmp mainloop
; ==============================================================================
init_vic:
    lxa #$00
-   sta $d000,x
    inx
    cpx #$2f
    bne -

    lda #$08
    sta $d016

    lda #$16
    sta $d018

    lda #$01
    sta $d01a
    rts
; ==============================================================================
irq_routine0:
    lda color_border
    sta $d020

    lda #<irq_routine1
    sta irq_mod
    lda #>irq_routine1
    sta irq_mod+1

    lda #line1
    rts

irq_routine1:
    lda color_blink
    sta $d020

    lda #<irq_routine2
    sta irq_mod
    lda #>irq_routine2
    sta irq_mod+1

    lda #line2
    rts

irq_routine2:
    lda color_backgr
    sta $d021
    sta $d020

    lda #<irq_routine3
    sta irq_mod
    lda #>irq_routine3
    sta irq_mod+1
enable_music:
    jsr music_play

    lda #line3
    rts

irq_routine3:
!if KEEPCOLOR = 0 {
    lda color_border
} else {
    lda #color0
}
    sta $d020
    sta $d021
    lda #$00
d016_bits012 =*+1
    ora #0
    sta $d016
    lda #<irq_routine4
    sta irq_mod
    lda #>irq_routine4
    sta irq_mod+1

    lda #line4
    rts

irq_routine4:
    lda color_backgr
    sta $d020
    sta $d021
    lda #$08
    sta $d016

    lda #$01
    sta irq_ready

    lda #<irq_routine5
    sta irq_mod
    lda #>irq_routine5
    sta irq_mod+1

    lda #line5
    rts

irq_routine5:
    lda color_blink
    sta $d020

    lda #<irq_routine6
    sta irq_mod
    lda #>irq_routine6
    sta irq_mod+1

    lda #line6
    rts

irq_routine6:
    lda color_border
    sta $d020

!if DEBUG = 1 {
    inc $d020
}
scan_addr =*+1
    lda music_bd_addr
!if DEBUG = 1 {
    sta $07e7
}
    cmp #music_bd_instr
    bne +
    lda #color3
    !byte $2c
+
    lda #color0
    sta color_border

    lda music_sd_addr
    cmp #music_sd_instr
    bne +
    lda #color2
    !byte $2c
+
    lda #color4
    sta color_blink
enable_count_seconds:
    jsr count_seconds

    ldx #music_time_length
-   lda music_time,x
    sta line_time+music_time_center,x
    dex
    bpl -

    jsr check_end

    lda #<irq_routine0
    sta irq_mod
    lda #>irq_routine0
    sta irq_mod+1

!if DEBUG = 1 {
    dec $d020
}

    lda #line0
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
!zone MEMFILL {
memfill:
    stx .from_hi
    sty .to_hi
.loop:
    ldx #0
-
.from_hi =*+2
    sta $0000,x
    inx
    bne -

    inc .from_hi
    ldy .from_hi
.to_hi =*+1
    cpy #0
    bne .loop
    rts
}
; ==============================================================================
!zone COUNT_SECONDS

count_seconds:
    dec .counter
    beq +
    rts
+
    lda sec_cnt_lo
    cmp #$39
    bne ++++
    lda #$2f
    sta sec_cnt_lo

    lda sec_cnt_hi
    cmp #$35
    bne +++
    lda #$2f
    sta sec_cnt_hi

    lda min_cnt_lo
    cmp #$39
    bne ++
    lda #$2f
    sta min_cnt_lo

    lda min_cnt_hi
    cmp #$35
    bne +
    lda #$2f
    sta min_cnt_hi
+
    inc min_cnt_hi
++
    inc min_cnt_lo
+++
    inc sec_cnt_hi
++++
    inc sec_cnt_lo

    lda #50
    sta .counter
    rts
.counter:
    !byte 50
count_seconds_end:
; ==============================================================================
!zone CHECK_END

check_end:
!if MODE = 0 {
    nop
} else {
    rts
}
    lda min_cnt_hi
    cmp min_end_hi
    beq +
    rts
+
    lda min_cnt_lo
    cmp min_end_lo
    beq +
    rts
+
    lda sec_cnt_hi
    cmp sec_end_hi
    beq +
    rts
+
    lda sec_cnt_lo
    cmp sec_end_lo
    beq +
    rts
+
    lda #disable
    sta enable_music
    sta enable_count_seconds
    lda #1
    sta tune_end_flag
    lda #$60
    sta check_end
    rts
; ==============================================================================
!zone INSTRUCTIONS

print_instructions:
    ldx #$27
-   lda .text+(0*40),x
    sta line_instructions+(0*40),x
    lda .text+(1*40),x
    sta line_instructions+(1*40),x
    lda .text+(2*40),x
    sta line_instructions+(2*40),x
    lda .text+(3*40),x
    sta line_instructions+(4*40),x
    dex
    bpl -
    rts

.text
;   !scr "0123456789012345678901234567890123456789"
    !scrxor $80, "F1"
    !scr ": Restart Tune ......................."
    !scrxor $80, "F3"
    !scr ": Pause / Resume Tune ................"
    !scrxor $80, "F5"
    !scr ": Switch Compo / Loop Mode ..........."
    !scr ".................... Current Mode: "
!if MODE = 0 {
    !scrxor $80, "Compo"
} else {
    !scrxor $80, "Loop!"
}
; ==============================================================================
!zone WAIT_IRQ
wait_irq:
    lda #0
    sta irq_ready

-   lda irq_ready
    beq -
    rts
; ==============================================================================
!zone KEYBOARD

keyboard_get:
.debounce =*+1
    lda #0
    beq +
    dec .debounce
    rts
+
    lda #$00                  ; set data direction for keyboard
    sta $dc03                 ; PORT B : INPUT
    lda #$ff
    sta $dc02                 ; PORT A : OUTPUT
.key_f1:
    lda #%11111110            ; check keyboard for
    sta $dc00                 ; F1

    lda $dc01
    and #%00010000
    sta $dc01
    bne .key_f3               ; no -> skip
.restart:                     ; yes:
    jsr tune_restart          ; restart tune

    jmp .exit
.key_f3:
    lda #%11111110            ; check keyboard for
    sta $dc00                 ; F3

    lda $dc01
    and #%00100000
    sta $dc01
    bne .key_f5               ; no -> skip
                              ; yes:
    lda enable_music
    eor #(enable XOR disable)
    sta enable_music

    lda enable_count_seconds
    eor #(enable XOR disable)
    sta enable_count_seconds

    lda pause_flag
    eor #(0 XOR 1)
    sta pause_flag

    lda enable_music
    cmp #disable
    bne +

    lda #$00
    sta $d418
+
    jmp .exit
.key_f5:
    lda #%11111110            ; check keyboard for
    sta $dc00                 ; F5

    lda $dc01
    and #%01000000
    sta $dc01
    bne ++
    lda line_mode_pos+0       ; change current mode screen text
    eor #('C' XOR 'L')
    sta line_mode_pos+0

    lda line_mode_pos+2
    eor #('m' XOR 'o')
    sta line_mode_pos+2

    lda line_mode_pos+4
    eor #('o' XOR 'A')
    sta line_mode_pos+4

    lda current_mode          ; change current mode flag
    eor #(0 XOR 1)
    sta current_mode

    lda check_end             ; switch end check routine
    eor #($60 XOR $ea)        ; RTS or NOP
    sta check_end

    lda enable_music
    cmp #disable              ; check if music has already ended
    bne +                     ; if no -> skip

    lda pause_flag            ; if yes: check pause flag
    bne +                     ; if set -> skip
    jmp .restart              ; if not set -> restart tune
+
.exit:
    lda #$10
    sta .debounce
++
    rts
; ==============================================================================
!zone TUNE_RESTART
tune_restart:
    sei
    lda #$0b
    sta $d011

    lda #SUBTUNE
    jsr music_init            ; init music

    lda #0
    sta pause_flag            ; clear pause flag

    lda #'0'                  ; reset min/sec counter
    sta min_cnt_hi
    sta min_cnt_lo
    sta sec_cnt_hi
    sta sec_cnt_lo

    lda #50                   ; reset 50 frames counter
    sta count_seconds_end-1

    lda #enable               ; enable music and counter
    sta enable_music
    sta enable_count_seconds

    lda current_mode          ; check current mode
    beq +
    lda #$60                  ; if 1 (loop) -> RTS
    !byte $2c
+
    lda #$ea                  ; if 0 (compo) -> NOP
    sta check_end             ; at the beginning of check end routine

    lda #$1b
    sta $d011
    asl $d019
    cli
    rts
; ==============================================================================
!zone SCROLLER

!if SCROLLER = 0 {
    scrolltext = music_title
}
scroller:
.need_new =*+1
    lda #0
    cmp #8
    bne +
    lda #0
    sta .need_new
    jsr .get_text
    jsr .new_char
+
.scroll =*+1
    lda #$07
    sec
    sbc #$04
    bcs +
    jsr .hardscroll
    lda #$07
+
    sta .scroll
    sta d016_bits012
    rts

.get_text:
.pt_scrolltext =*+1
    lda scrolltext
    cmp #$ff
    beq .text_reset
    tay
    clc
    lda .pt_scrolltext
    adc #$01
    sta .pt_scrolltext
    lda .pt_scrolltext+1
    adc #$00
    sta .pt_scrolltext+1
    tya
    rts
.text_reset:
    lda #<scrolltext
    sta .pt_scrolltext
    lda #>scrolltext
    sta .pt_scrolltext+1

    lda #' '
    rts
.new_char:
    tay

    lda #$00
    sta pt_charset
    lda #$d8
    sta pt_charset+1

    lda #0
    sta .char_hi

    tya
    asl
    rol .char_hi
    asl
    rol .char_hi
    asl
    rol .char_hi
    clc
    adc pt_charset
    sta pt_charset

.char_hi =*+1
    lda #0
    adc pt_charset+1
    sta pt_charset+1
!if DEBUG = 1 {
    lda pt_charset
    sta $0400
    lda pt_charset+1
    sta $0401
}
    lda #$33
    sta $01

    ldy #$07
-   lda (pt_charset),y
    sta .charbuffer,y
    dey
    bpl -

    lda #$35
    sta $01
    rts

.hardscroll:
    lda #<line_scroller
    sta pt_screenpos
    lda #>line_scroller
    sta pt_screenpos+1

    ldx #$00
-
    ldy #' '
    asl .charbuffer,x
    bcc +

    ldy #105
+
    tya
    ldy #$27
    sta (pt_screenpos),y

    clc
    lda pt_screenpos
    adc #$28
    sta pt_screenpos
    bcc +
    inc pt_screenpos+1
+
    inx
    cpx #$08
    bne -

    ldx #0
-
!for i, 0, 7 {
    lda line_scroller+(i*40)+1,x
    sta line_scroller+(i*40),x
}
    inx
    cpx #$27
    bne -

    inc .need_new
    rts
.charbuffer:
    !byte $00, $00, $00, $00, $00, $00, $00
; ==============================================================================
code_end:
; ==============================================================================
!zone SPRITE

*= $0f00
!if SPRITE = 1 {
    !bin "sprite.bin"
} else {
    !fi $40, 0
}
; ==============================================================================
!zone IRQ

*= $0f40
irq0:
    sta savea
    stx savex
    sty savey

    ldx #6
-   dex
    bne -

    nop

irq_mod = *+1
    jsr irq_routine0

    sta $d012

    lda $d012
-   cmp $d012
    beq -

    lda #$1b
    sta $d011

    asl $d019

    lda savea
    ldx savex
    ldy savey
nmi:
    rti
nmi_debug:
!if DEBUG = 1 {
    sta savea
    clc
    lda scan_addr
    adc #1
    sta scan_addr
    lda scan_addr+1
    adc #0
    sta scan_addr+1
    lda savea
    rti
}
