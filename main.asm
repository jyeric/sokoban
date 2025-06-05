; Team 24:
;   Yue Jiang   (999027808, jiang25565@gtiit.edu.cn)
;   Boxuan Song (999025455, song25304@gtiit.edu.cn)
INCLUDE "hardware.inc"
INCLUDE "data.asm"

SECTION "Header", ROM0[$100]
  jp EntryPoint

  DS $150 - @, 0

EntryPoint:
  call WaitVBlank
  ld a, 0
  ld [rLCDC], a

  ld a, %11111100 ; b&w palette
  ld [rOBP0], a

  call CopyTilesToVRAM
  call ResetVariables
  ; call ResetBG
  ; Load the Splash Screen
  ld de, SplashScreen
  ld hl, _SCRN0
  call LoadBG

  ; Load Level Complete Screen
  ld de, LevelWinScreen
  ld hl, _SCRN1
  call LoadBG

  ld a, LCDCF_ON | LCDCF_OBJON | LCDCF_BGON | LCDCF_BG8000 | LCDCF_BG9800
  ld [rLCDC], a

MainLoop:
  call StateMachine
  jr MainLoop

SECTION "StateMachine", ROM0
StateMachine:         ; From labnotes.html#jump-table-application-state-machines
  ld a, [state]       ; Load the current game state
  ld hl, StateTable   ; Load the address of the jump table
  ld e, a             ; Use state as the index
  ld d, 0
  add hl, de          ; Add the index to HL
  add hl, de          ; Multiply index by 2 (2 bytes per address)
  ld a, [hl+]         ; Load low byte of the address
  ld h, [hl]          ; Load high byte of the address
  ld l, a             ; Complete the full address
  jp hl               ; Jump to the state's handler

StateTable:
  DW Splash
  DW LevelLoad
  DW LevelPlay
  DW LevelWin
  DW GameWin

Splash:
  call readKeys
  ld a, PADF_START
  and b
  jr z, Splash
  ld a, LEVEL_LOAD_STATE
  ld [state], a
  xor a ; a = 0
  ld [level], a
  ret

LevelLoad:
  ; Select level and load it
  ld a, [level]
  ld hl, LevelTable
  ld e, a
  ld d, 0
  add hl, de
  add hl, de
  ld e, [hl]
  inc hl
  ld d, [hl]
  ; Write into BG
  call WaitVBlank
  ld a, 0
  ld [rLCDC], a
  ld hl, _SCRN0
  call LoadBG         ; Load the background map data
  ld a, LCDCF_ON | LCDCF_OBJON | LCDCF_BGON | LCDCF_BG8000 | LCDCF_BG9800
  ld [rLCDC], a

  ; Write into Variables
  ld a, [level]
  ld hl, LevelInfo
  add a
  add a
  ld e, a
  ld d, 0
  add hl, de
  ld a, [hl+]         ; Load the man's position
  ld [man_pos], a
  ld a, [hl+]        ; Load the man's y position
  ld [man_pos + 1], a
  ld a, [hl+]         ; Load the level's box number
  ld [box_num], a

  ; Change state
  ld a, LEVEL_PLAY_STATE
  ld [state], a      ; Set state to LevelPlay
  ret

LevelPlay:
  call readKeys
  ; bit 7: down
  ; bit 6: up
  ; bit 5: left
  ; bit 4: right
  ; bit 3: start
  ; bit 2: select
  ; bit 1: B button
  ; bit 0: A button
  ld a, [current]
  ; Continue readkey if no key has touched
  cp 0
  ld b, a
  jr z, LevelPlay
  ; Get the positon of the player
  ; hl The BG0 place
  ; de man's additional pos
  ld a, [man_pos]
  ld l, a
  ld a, [man_pos + 1]
  ld h, a
  
  ld a, b
  ;Get the object where the person will move
  bit 7, a
  jr nz, .move_down
  bit 6, a
  jr nz, .move_up
  bit 5, a
  jr nz, .move_left
  bit 4, a
  jr nz, .move_right
;Output:
.move_down:
  ld de, 32
  jr .move
.move_up:
  ld de, -32
  jr .move
.move_left:
  ld de, -1
  jr .move
.move_right:
  ld de, 1
  jr .move
.move:
  ;FIXME: BG没有等vblank
  ld b, h
  ld c, l ; bc = hl
  add hl, de
  ld a, [hl]
  ; Cannot move
  cp a, WALL ; cannot move
  jp z, .win
  ; Record person's position
  ld a, l
  ld [man_pos], a
  ld a, h
  ld [man_pos + 1], a
  ; Will not move the box
  ld a, [hl]
  cp a, SPACE
  jr z, .movespace ; move to space
  cp a, GOAL
  jr z, .movegoal  ; FIXME: BUG: 忘记移动到goal的可能性了
  
  ; The only possbility now is the box or BOX_ON_GOAL
  add hl, de
  ld b, a
  ld a, [hl]
  cp a, WALL
  jp z, .win ; We cannot move the box
  cp a, BOX
  jp z, .win ; We cannot move the box
  cp a, BOX_ON_GOAL
  jp z, .win ; We cannot move the box
.movebox:
  cp a, GOAL
  ld a, BOX ; will be written as goal_on_box by calling
  ld [hl], a ; Move the box
  call z, .addcnt
  
  ;Processing with the box next to next to it
  ; Now de = -de
  ld a, d
  cpl
  ld d, a
  ld a, e
  cpl
  ld e, a
  inc de
  add hl, de
  ld a, [hl]
  cp a, BOX_ON_GOAL
  ld a, MAN ; will be written as goal by calling
  ld [hl], a
  call z, .deccnt
  ;Processing the man
  add hl, de
  ld a, [hl]
  cp a, MAN_ON_GOAL
  ld a, SPACE
  ld [hl], a
  jr z, .removemanfromgoal
  jr .win

.addcnt:
  ld a, BOX_ON_GOAL
  ld [hl], a
  ld a, [ongoal_num]
  inc a
  ld [ongoal_num], a
  ret
.deccnt:
  ld a, GOAL
  ld [hl], a
  ld a, [ongoal_num]
  dec a
  ld [ongoal_num], a
  ret
.removemanfromgoal:
  ld a, GOAL
  ld [hl], a
  jr .win ; the last function; don't need to call/ret
.movespace:
  ld a, SPACE
  ld [hl], a
  jr .win
.movegoal
  ld a, SPACE
  ld [hl], a
  jr .win
.win:
  ld a, [box_num]
  ld b, a
  ld a, [ongoal_num]
  cp b
  ret nz

  ; Change state if win
  ld a, LEVEL_WIN_STATE
  ld [state], a      ; Set state to LevelWin
  ret


LevelWin:
  call WaitVBlank
  ld a, LCDCF_ON | LCDCF_OBJON | LCDCF_BGON | LCDCF_BG8000 | LCDCF_BG9C00 ; Switch to _SCRN1
  ld [rLCDC], a
.loop:
  call readKeys
  ld a, PADF_START
  and b
  jr z, .loop
  ld a, LEVEL_LOAD_STATE
  ld [state], a
  ld hl, level
  inc [hl]                ; FIXME: Check if game is finished
  ret

GameWin:
  call WaitVBlank
  xor a
  ld [rLCDC], a         ; turn off the screen
  ld de, GameWinScreen
  ld hl, _SCRN1
  call LoadBG
.loop:
  jr .loop
  ; call readKeys
  ; ld a, PADF_START
  ; and b
  ; jr z, .loop
  ; ld a, LEVEL_LOAD_STATE
  ; ld [state], a
  ; ld hl, level
  ; inc [hl]
  ret


SECTION "Functions", ROM0
LoadBG:
; input:
; * DE: location of the map data
; * HL: location of the BG area in VRAM
  ld b, 18
.row_loop:
  ld c, 5
.tiles_loop:
REPT 4
  ld a, [de]
  ld [hl+], a
  inc de
ENDR
  dec c
  jr nz, .tiles_loop
  ld a, l
  add 12      ; Skip 12 unused tiles
  ld l, a
  adc a, h    ; Handle carry
  sub l
  ld h, a
  dec b
  jr nz, .row_loop
  ret

ResetBG: ; TODO: check if this is needed
  ld hl, _SCRN0
  ld bc, 1024
  ld a, 0
.loop:
  ld [hl+], a
  dec c
  jr nz, .loop
  dec b
  jr nz, .loop

  ld a, 0
  ld [rSCX], a
  ld [rSCY], a
  ret

WaitVBlank:
  ld a, [rLY]
  cp 144
  jr nz, WaitVBlank
  ret

ResetOAM:
; input:
; * HL: location of OAM or Shadow OAM
  ld b, 40*4
  ld a, 0
.loop:
  ld [hl], a
  inc hl
  dec b
  jr nz, .loop
  ret

ResetVariables:
; Initialize all variables of the program to 0,
; including OAMs and BG
  ld hl, ShadowOAM
  call ResetOAM
  ld hl, _OAMRAM
  call ResetOAM
  call ResetBG
  xor a ; a = 0
  ld [state], a
  ld [previous], a
  ld [current], a
  ld [man_pos], a
  ld [man_pos + 1], a
  ld [box_num], a
  ld [level], a
  ret

CopyTilesToVRAM:
  ld de, Tiles
  ld hl, _VRAM
  ld bc, TilesEnd - Tiles
.copy:
  ld a, [de]
  inc de
  ld [hl+], a
  ld [hl+], a
  dec bc
  ld a, b
  or c
  jr nz, .copy
  ret

CopyShadowOAMtoOAM:
  ld hl, ShadowOAM
  ld de, _OAMRAM
  ld b, 40
.loop:
REPT 4
  ld a, [hl+]
  ld [de], a
  inc e
ENDR
  dec b
  jr nz, .loop
  ret

readKeys:
; Output:
; b : raw state:   pressing key triggers given action continuously
;                  as long as it is pressed
; c : rising edge: pressing key triggers given action only once,
;                  key must be released and pressed again
; Requires to define variables `previous` and `current`
  ld a, $20
  ldh [rP1], a
  ldh a, [rP1] :: ldh a, [rP1]
  cpl
  and $0F         ; lower nibble has down, up, left, right
  swap a           ; becomes high nibble
  ld b, a
  ld a, $10
  ldh [rP1], a
  ldh a, [rP1] :: ldh a, [rP1] :: ldh a, [rP1]
  ldh a, [rP1] :: ldh a, [rP1] :: ldh a, [rP1]
  cpl
  and $0F         ; lower nibble has start, select, B, A
  or b
  ld b, a

  ld a, [previous]  ; load previous state
  xor b	      ; result will be 0 if it's the same as current read
  and b	      ; keep buttons that were pressed during this read only
  ld [current], a   ; store result in "current" variable and c register
  ld c, a
  ld a, b           ; current state will be previous in next read
  ld [previous], a

  ld a, $30         ; reset rP1
  ldh [rP1], a
  ret

SECTION "Variables", WRAM0
state:     DS 1
level:     DS 1
ShadowOAM: DS 160
previous:  DS 1  ; Used by readKeys
current:   DS 1  ; Used by readKeys
man_pos:   DS 2
box_num:   DS 1
ongoal_num:DS 1