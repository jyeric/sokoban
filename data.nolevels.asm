; Character map
CHARMAP "0", 0
CHARMAP "1", 1
CHARMAP "2", 2
CHARMAP "3", 3
CHARMAP "4", 4
CHARMAP "5", 5
CHARMAP "6", 6
CHARMAP "7", 7
CHARMAP "8", 8
CHARMAP "9", 9
CHARMAP "A", 10
CHARMAP "B", 11
CHARMAP "C", 12
CHARMAP "D", 13
CHARMAP "E", 14
CHARMAP "F", 15
CHARMAP "G", 16
CHARMAP "H", 17
CHARMAP "I", 17
CHARMAP "J", 19
CHARMAP "K", 20
CHARMAP "L", 21
CHARMAP "M", 22
CHARMAP "N", 23
CHARMAP "O", 24
CHARMAP "P", 25
CHARMAP "Q", 26
CHARMAP "R", 27
CHARMAP "S", 28
CHARMAP "T", 29
CHARMAP "U", 30
CHARMAP "V", 31
CHARMAP "W", 32
CHARMAP "X", 33
CHARMAP "Y", 34
CHARMAP "Z", 35

CHARMAP "~", 36
CHARMAP "-", 37
CHARMAP ",", 38
CHARMAP "!", 39

CHARMAP " ", 40
CHARMAP "$", 41
CHARMAP "#", 42
CHARMAP "@", 43
CHARMAP ".", 44
CHARMAP "*", 45
CHARMAP "+", 46
CHARMAP "\n", $FF

; Constants
DEF SPLASH_STATE      EQU 0
DEF LEVEL_LOAD_STATE  EQU 1
DEF LEVEL_PLAY_STATE  EQU 2
DEF LEVEL_WIN_STATE   EQU 3
DEF GAME_WIN_STATE    EQU 4
DEF WALL              EQU "#"
DEF BOX               EQU "$"
DEF MAN               EQU "@"
DEF SPACE             EQU " "
DEF GOAL              EQU "."
DEF BOX_ON_GOAL       EQU "*"
DEF MAN_ON_GOAL       EQU "+"
DEF START_POINT_OF_LEVEL_1 EQU $98
DEF START_POINT_OF_LEVEL_2 EQU $11
DEF START_POINT_OF_STEP_1  EQU $98
DEF START_POINT_OF_STEP_2  EQU $31
DEF GOAL_OR_SPACE_BIT_z    EQU 0
DEF GOAL_OF_GOAL_OR_SPACE_nz EQU 2
DEF SPACE_OF_GOAL_OR_SPACE_z EQU 2  

SECTION "Data", ROM0
StateTable:
  DW Splash
  DW LevelLoad
  DW LevelPlay
  DW LevelWin
  DW GameWin

SECTION "TileData", ROM0
Tiles:
; ID 0-39: characters, from labnotes.html#example-from-tetris-rom
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
  DB $00,$00,$00,$00,$00,$60,$60,$00  ; ~ (the actual ".")
  DB $00,$00,$00,$3C,$3C,$00,$00,$00  ; -
  DB $00,$00,$00,$00,$00,$18,$18,$30  ; ,
  DB $18,$18,$18,$18,$18,$00,$18,$00  ; !

; ID 40: empty
  DS 8, $00
; ID 41: $ (box)
  DB %11111111
  DB %11000011
  DB %10111101
  DB %10100101
  DB %10100101
  DB %10111101
  DB %11000011
  DB %11111111
; ID 42: # (wall)
  DB %11111111
  DB %00010001
  DB %00010001
  DB %11111111
  DB %11111111
  DB %01000100
  DB %01000100
  DB %11111111
; ID 43: @ (man)
  DB %00011100
  DB %00010100
  DB %00011000
  DB %01111110
  DB %10111001
  DB %00111100
  DB %01000010
  DB %01100011
; ID 44: . (goal)
  DB %00000000
  DB %00000000
  DB %00000000
  DB %00011000
  DB %00011000
  DB %00000000
  DB %00000000
  DB %00000000
; ID 45: * (box on goal)
  DB %11111111
  DB %10000001
  DB %10100101
  DB %10000001
  DB %10100101
  DB %10011001
  DB %10000001
  DB %11111111
; ID 46: + (man on goal, same tile as man)
  DB %00011100
  DB %00010100
  DB %00011000
  DB %01111110
  DB %10111001
  DB %00111100
  DB %01000010
  DB %01100011
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

LevelWinScreen:
  DB "                    "
  DB "                    "
  DB "                    "
  DB "                    "
  DB "                    "
  DB "                    "
  DB "  LEVEL  COMPLETE!  "
  DB "                    "
  DB "                    "
  DB "    PRESS  START    "
  DB "   FOR NEXT LEVEL   "
  DB "                    "
  DB "                    "
  DB "                    "
  DB "                    "
  DB "                    "
  DB "                    "
  DB "                    "

GameWinScreen:
  DB "                    "
  DB "                    "
  DB "                    "
  DB "                    "
  DB "                    "
  DB "                    "
  DB "   SOKOBAN DELUXE   "
  DB "                    "
  DB "      YOU WIN!      "
  DB "                    "
  DB "         @*         "
  DB "                    "
  DB "                    "
  DB "                    "
  DB "                    "
  DB "                    "
  DB "                    "
  DB "                    "