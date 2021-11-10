!cpu 6510
music_start = $1000

    *= $1000
    jmp +
    !bin "tune.sid",,$7e+3
+
    pha
    lda #$ff  ;Set frequency in voice 3 to $ffff
    sta $d412 ;...and set testbit (other bits doesn't matter) in $d012 to disable oscillator
    sta $d40e
    sta $d40f
    lda #$20  ;Sawtooth wave and gatebit OFF to start oscillator again.
    sta $d412
    lda $d41b ;Accu now has different value depending on sid model (6581=3/8580=2)
    lsr   ;...that is: Carry flag is set for 6581, and clear for 8580.
    bcs +
    lda #$30
    sta music_start+$055c
    lda #$48
    sta music_start+$0560
    lda #$50
    sta music_start+$0564
    lda #$70
    sta music_start+$0569
+
    pla
    jmp *
    *= *-2
    !bin "tune.sid",2,$7e+1
