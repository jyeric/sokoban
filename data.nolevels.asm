; Character map
CHARMAP " ", 0
CHARMAP "$", 1
CHARMAP "#", 2
CHARMAP "@", 3
CHARMAP "0", 4
CHARMAP "1", 5
CHARMAP "2", 6
CHARMAP "3", 7
CHARMAP "4", 8
CHARMAP "5", 9
CHARMAP "6", 10
CHARMAP "7", 11
CHARMAP "8", 12
CHARMAP "9", 13
CHARMAP "A", 14
CHARMAP "B", 15
CHARMAP "C", 16
CHARMAP "D", 17
CHARMAP "E", 18
CHARMAP "F", 19
CHARMAP "G", 20
CHARMAP "H", 21
CHARMAP "I", 22
CHARMAP "J", 23
CHARMAP "K", 24
CHARMAP "L", 25
CHARMAP "M", 26
CHARMAP "N", 27
CHARMAP "O", 28
CHARMAP "P", 29
CHARMAP "Q", 30
CHARMAP "R", 31
CHARMAP "S", 32
CHARMAP "T", 33
CHARMAP "U", 34
CHARMAP "V", 35
CHARMAP "W", 36
CHARMAP "X", 37
CHARMAP "Y", 38
CHARMAP "Z", 39
CHARMAP ".", 40
CHARMAP "-", 41
CHARMAP ",", 42
CHARMAP "!", 43
CHARMAP "~", 44 ; (actual ".")
CHARMAP "*", 45
CHARMAP "+", 46
CHARMAP "\n", $FF

; Constants
DEF SPLASH_STATE      EQU 0
DEF LEVEL_LOAD_STATE  EQU 1
DEF LEVEL_PLAY_STATE  EQU 2
DEF LEVEL_WIN_STATE   EQU 3
DEF GAME_WIN_STATE    EQU 4

SECTION "TileData", ROM0
Tiles:
; ID 0: empty
  DS 8, $00
; ID 1: box
  DB %11111111
  DB %11000011
  DB %10111101
  DB %10100101
  DB %10100101
  DB %10111101
  DB %11000011
  DB %11111111
; ID 2: wall
  DB %11111111
  DB %00010001
  DB %00010001
  DB %11111111
  DB %11111111
  DB %01000100
  DB %01000100
  DB %11111111
; ID 3: man
  DB %00011100
  DB %00010100
  DB %00011000
  DB %01111110
  DB %10111001
  DB %00111100
  DB %01000010
  DB %01100011
; ID 4-44: characters, from labnotes.html#example-from-tetris-rom
  DB $00,$3C,$66,$66,$66,$66,$3C,$00 ; 0
  DB $00,$18,$38,$18,$18,$18,$3C,$00 ; 1
  DB $00,$3C,$4E,$0E,$3C,$70,$7E,$00
  DB $00,$7C,$0E,$3C,$0E,$0E,$7C,$00
  DB $00,$3C,$6C,$4C,$4E,$7E,$0C,$00
  DB $00,$7C,$60,$7C,$0E,$4E,$3C,$00
  DB $00,$3C,$60,$7C,$66,$66,$3C,$00
  DB $00,$7E,$06,$0C,$18,$38,$38,$00
  DB $00,$3C,$4E,$3C,$4E,$4E,$3C,$00 ; 8
  DB $00,$3C,$4E,$4E,$3E,$0E,$3C,$00 ; 9
  DB $00,$3C,$4E,$4E,$7E,$4E,$4E,$00 ; A
  DB $00,$7C,$66,$7C,$66,$66,$7C,$00 ; B
  DB $00,$3C,$66,$60,$60,$66,$3C,$00 ; C
  DB $00,$7C,$4E,$4E,$4E,$4E,$7C,$00
  DB $00,$7E,$60,$7C,$60,$60,$7E,$00
  DB $00,$7E,$60,$60,$7C,$60,$60,$00
  DB $00,$3C,$66,$60,$6E,$66,$3E,$00
  DB $00,$46,$46,$7E,$46,$46,$46,$00
  DB $00,$3C,$18,$18,$18,$18,$3C,$00
  DB $00,$1E,$0C,$0C,$6C,$6C,$38,$00
  DB $00,$66,$6C,$78,$78,$6C,$66,$00
  DB $00,$60,$60,$60,$60,$60,$7E,$00
  DB $00,$46,$6E,$7E,$56,$46,$46,$00
  DB $00,$46,$66,$76,$5E,$4E,$46,$00
  DB $00,$3C,$66,$66,$66,$66,$3C,$00
  DB $00,$7C,$66,$66,$7C,$60,$60,$00
  DB $00,$3C,$62,$62,$6A,$64,$3A,$00
  DB $00,$7C,$66,$66,$7C,$68,$66,$00
  DB $00,$3C,$60,$3C,$0E,$4E,$3C,$00
  DB $00,$7E,$18,$18,$18,$18,$18,$00
  DB $00,$46,$46,$46,$46,$4E,$3C,$00
  DB $00,$46,$46,$46,$46,$2C,$18,$00
  DB $00,$46,$46,$56,$7E,$6E,$46,$00
  DB $00,$46,$2C,$18,$38,$64,$42,$00  ; X
  DB $00,$66,$66,$3C,$18,$18,$18,$00  ; Y
  DB $00,$7E,$0E,$1C,$38,$70,$7E,$00  ; Z
  DB $00,$00,$00,$18,$18,$00,$00,$00  ; . (for goal squares)
  DB $00,$00,$00,$3C,$3C,$00,$00,$00  ; -
  DB $00,$00,$00,$00,$00,$18,$18,$30  ; ,
  DB $18,$18,$18,$18,$18,$00,$18,$00  ; !
  DB $00,$00,$00,$00,$00,$60,$60,$00  ; ~ (the actual ".")
  ; ID 45: box on goal
  DB %11111111
  DB %11000011
  DB %10111101
  DB %10100101
  DB %10100101
  DB %10111101
  DB %11000011
  DB %11111111
  ; ID 46: man on goal
TilesEnd:

SECTION "TileMap", ROM0
SplashScreen:
  DB "                    "
  DB "                    "
  DB "                    "
  DB "                    "
  DB "                    "
  DB "   SOKOBAN DELUXE   "
  DB "                    "
  DB "    PRESS  START    "
  DB "                    "
  DB "      ########      "
  DB "      #.$  $.#      "
  DB "      #.$@ $.#      "
  DB "      ########      "
  DB "                    "
  DB "                    "
  DB "                    "
  DB "                    "
  DB "                    "
