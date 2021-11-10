; optional scrolltext (no = 0, yes = 1)
; if set to 0 scrolltext will be the tune title
SCROLLER = 0
; start mode (compo = 0, loop = 1)
MODE = 0

THEME = 2
; include sprite.bin (no = 0, yes = 1)
SPRITE = 1

SUBTUNE = 0

music_init = $1000
music_play = music_init+3

music_bd_addr = music_init+$5a
music_bd_instr = $03
music_sd_addr = music_init+$5a
music_sd_instr = $04

*= music_init
  !bin "creationr01.sid",,$7e

music_title:
  !scr "Creation Reconciled"
music_title_end:
  !byte $ff             ; IMPORTANT: scrolltext end sign

music_time:
  !scr "00:00 / 03:29"
  ;     0123456789012
music_time_end:

music_author:
  !scr "by Spider Jerusalem"
music_author_end:

music_sidinfo:
  !scr "for 8580 SID"
music_sidinfo_end:

music_end:
; ==============================================================================
; optional scrolltext
; ==============================================================================
!if SCROLLER = 1 {
scrolltext:
  !scr "Here could be an optional Scrolltext, that is only shown "
  !scr "if SCROLLER is set to 1 ... "
scrolltext_end:
  !byte $ff             ; IMPORTANT: scrolltext end sign
}
; ==============================================================================
; calculated vars
; ==============================================================================
music_title_length = music_title_end - 1 - music_title
music_title_center = ( 40 - music_title_length ) / 2

music_time_length = music_time_end -1 - music_time
music_time_center = ( 40 - music_time_length ) / 2

music_sidinfo_length = music_sidinfo_end -1 - music_sidinfo
music_sidinfo_center = ( 40 - music_sidinfo_length ) / 2

music_author_length = music_author_end -1 - music_author
music_author_center = ( 40 - music_author_length ) / 2

min_cnt_hi = music_time+0
min_cnt_lo = music_time+1
sec_cnt_hi = music_time+3
sec_cnt_lo = music_time+4

min_end_hi = music_time+8
min_end_lo = music_time+9
sec_end_hi = music_time+11
sec_end_lo = music_time+12

!if THEME = 0 {
  ; color for top/bottom border
  color0 = blue
  ; color for main screen
  color1 = black
  ; color for slim border-line
  color4 = light_blue
  ; color for sd hit
  color2 = light_grey
  ; color for bd hit
  color3 = purple
  ; color for COLRAM / spider sprite
  color5 = light_blue
  ; color for SCROLLTEXT
  color6 = white
  KEEPCOLOR = 0
}

!if THEME = 1 {
  ; color for top/bottom border
  color0 = dark_grey
  ; color for main screen
  color1 = black
  ; color for slim border-line
  color4 = light_grey
  ; color for sd hit
  color2 = white
  ; color for bd hit
  color3 = grey
  ; color for COLRAM / spider sprite
  color5 = grey
  ; color for SCROLLTEXT
  color6 = black
  KEEPCOLOR = 0
}

!if THEME = 2 {
  ; color for top/bottom border
  color0 = blue
  ; color for main screen
  color1 = cyan
  ; color for slim border-line
  color4 = light_green
  ; color for sd hit
  color2 = white
  ; color for bd hit
  color3 = light_blue
  ; color for COLRAM / spider sprite
  color5 = blue
  ; color for SCROLLTEXT
  color6 = light_green
  KEEPCOLOR = 1
}

!if THEME = 3 {
  ; color for top/bottom border
  color0 = black
  ; color for main screen
  color1 = red
  ; color for slim border-line
  color4 = red
  ; color for sd hit
  color2 = pink
  ; color for bd hit
  color3 = red
  ; color for COLRAM / spider sprite
  color5 = black
  ; color for SCROLLTEXT
  color6 = pink
  KEEPCOLOR = 1
}
