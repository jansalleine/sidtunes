SUBTUNE             = 0
music_start         = $1000
music_init          = $1000
music_play          = $1003
; ==============================================================================
                    *= music_start
                    !bin "../../includes/Doctor_help_me!_I'm_sick..sid",,$7e
music_end:          !fi $100-(<*), $20            ; page align with 'space'
