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
  xor a ; a = 0
  ld [rLCDC], a ; turn off LCD

  ld a, %11111100 ; b&w palette
  ld [rOBP0], a

  call CopyTilesToVRAM
  call ResetVariables

  ; Load the Splash Screen
  ld de, SplashScreen
  ld hl, _SCRN0
  ld b, 18
  call LoadBG

  ; Load Level Complete Screen
  ld de, LevelWinScreen
  ld hl, _SCRN1
  ld b, 18
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

Splash:
  call readKeys
  bit PADB_START, b
  jr z, Splash        ; Wait for start button to be pressed
  ld a, LEVEL_LOAD_STATE
  ld [state], a
  xor a ; a = 0
  ld [level], a
  ret

LevelLoad:
  ; Clear the counter
  xor a
  ld [box_num], a
  ld [step], a
  ld [can_undo], a
  ; Select level and load it
  ld a, [level]
  ld hl, LevelTable
  ld e, a
  ld d, 0
  add hl, de
  add hl, de
  add hl, de        ; 3 bytes per entry
  ld e, [hl]
  inc hl
  ld d, [hl]        ; de = address of the level map
  inc hl
  ld b, [hl]        ; b = number of rows to load >= 3
  ld a, 18
  sub b
  swap a            ; a = floor((18 - b) / 2) * 32 <= 224, no overflow
  and %11100000     ; optimized as in labnotes.html#divide-a-by-16-shift-a-right-4-bits
  ld c, a           ; c = number of bytes to skip

  ; Turn off LCD
  call WaitVBlank
  xor a             ; a = 0
  ld [rLCDC], a

  ; Reset BG
  ld hl, _SCRN0
  push bc
  call ResetBG
  pop bc
  ; Write into BG
  ld h, $98         ; h = $98 since _SCRN0 = $9800
  ld l, c           ; hl += 0c <=> l = c as no overflow
  call LoadLevelMap

  ld a, "L"
  ld [_SCRN0 + START_POINT_OF_LEVEL_NAME], a
  ld a, "V"
  ld [_SCRN0 + START_POINT_OF_LEVEL_NAME + 1], a ; Write "LV" at the top left corner

  ; Load Level name and steps
  ld a, [level]
  inc a
  call binToDec
  ld de, _SCRN0 + START_POINT_OF_LEVEL_NAME + 2
  call copyDigitsRev

  ld hl, _SCRN0 + START_POINT_OF_STEP_NUM
  ld a, "0"
  ld [hl+], a
  ld [hl+], a
  ld [hl], a ; Write "000" at the top right corner

  ld a, LCDCF_ON | LCDCF_OBJON | LCDCF_BGON | LCDCF_BG8000 | LCDCF_BG9800
  ld [rLCDC], a

  ; Change state
  ld a, LEVEL_PLAY_STATE
  ld [state], a     ; Set state to LevelPlay
  ret

LevelPlay:
  call WaitVBlank ; Avoid jitter
  call readKeys
  ; bit 7: down
  ; bit 6: up
  ; bit 5: left
  ; bit 4: right
  ; bit 3: start
  ; bit 2: select
  ; bit 1: B button
  ; bit 0: A button
  ld a, c
  ; Continue readkey if no key has touched
  cp 0
  ld b, a
  jr z, LevelPlay

  ; Get the position of the player
  ; hl The BG0 place
  ; de man's additional pos
  call ReadManLocation
  
  ld a, b
  ; Get the object where the person will move
  bit 7, b
  jr nz, .move_down
  bit 6, b
  jr nz, .move_up
  bit 5, b
  jr nz, .move_left
  bit 4, b
  jr nz, .move_right
  bit 3, b
  jr nz, .reset
  bit 2, b
  jp nz, undo_last_step
  ret
.reset:
  ld a, LEVEL_LOAD_STATE
  ld [state], a      ; Set state to LevelWin
  ret
;Output:
.move_down:
  ld de, 32
  jr move
.move_up:
  ld de, -32
  jr move
.move_left:
  ld de, -1
  jr move
.move_right:
  ld de, 1
  jr move
move:
  ; Reset Variables
  call WaitVBlank
  ; Save man's position into bc
  ld b, h
  ld c, l ; bc = hl
  add hl, de
  ld a, [hl]
  ; Cannot move
  cp a, WALL ; cannot move
  ret z
  ; Will not move the box
  ld a, [hl]
  cp a, SPACE
  jr z, .movespace ; move to space
  cp a, GOAL
  jr z, .movegoal

  ; The only possbility now is the box or BOX_ON_GOAL
  ; Let hl += de. Move hl pointer two steps from man's position
  add hl, de
  ld b, a
  ld a, [hl]
  cp a, WALL
  ret z      ; We cannot move the box
  cp a, BOX
  ret z      ; We cannot move the box
  cp a, BOX_ON_GOAL
  ret z      ; We cannot move the box
.movebox:
  ; Write de into variable direction (move)
  call SaveDirection

  ld a, 1
  ld [move_box], a ;  Record that we move the box in this step
  
  ld a, [hl]
  cp a, GOAL
  ld a, BOX ; will be written as goal_on_box by calling
  ld [hl], a ; Move the box
  call z, .tobox_to_goal

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

  ; Record person's position since the man move one step (move the box)
  call SaveManLocation

  ld a, [hl]
  cp a, BOX_ON_GOAL
  ld a, MAN ; will be written as goal by calling
  ld [hl], a
  call z, .toman_to_goal
  ; Processing the original man's position
  add hl, de
  ld a, [hl]
  cp a, MAN_ON_GOAL
  ld a, SPACE
  ld [hl], a
  jr z, .togoal
  jr .win

.tobox_to_goal:
  ld a, BOX_ON_GOAL
  ld [hl], a
  ld a, [box_num]
  dec a
  ld [box_num], a
  ret
.toman_to_goal:
  ld a, MAN_ON_GOAL
  ld [hl], a
  ld a, [box_num]
  inc a
  ld [box_num], a
  ret
.togoal:
  ld a, GOAL
  ld [hl], a
  jr .win ; the last function; don't need to call/ret
.movespace:
  ; Write de into variable direction (move)
  call SaveDirection

  ; Record person's position
  call SaveManLocation

  ld a, MAN
  ld [hl], a

  ld a, [bc]
  cp MAN
  jr z, .mantospace
  jr .mantogoal
.movegoal
  ; Write de into variable direction (move)
  call SaveDirection

  ; Record person's position
  call SaveManLocation

  ld a, MAN_ON_GOAL
  ld [hl], a

  ld a, [bc]
  cp MAN
  jr z, .mantospace
  ; jr .mantogoal
.mantogoal:
  ld a, GOAL
  ld [bc], a
  jr .win
.mantospace:
  ld a, SPACE
  ld [bc], a
.win:
  ld a, 1 
  ld [can_undo], a

  ; Add addtional step
  ld a, [step]
  inc a
  ld [step], a
  call binToDec
  ld de, _SCRN0 + START_POINT_OF_STEP_NUM
  call copyDigitsRev
  ; Check whether win or not
  ld a, [box_num]
  cp 0
  ret nz

  ; Change state if win
  ld a, LEVEL_WIN_STATE
  ld [state], a      ; Set state to LevelWin
  ret

LevelWin:
  ld a, [level]
  cp LEVEL_NUM - 1
  ld a, GAME_WIN_STATE
  ld [state], a
  ret z
  call WaitVBlank
  ld a, LCDCF_ON | LCDCF_OBJON | LCDCF_BGON | LCDCF_BG8000 | LCDCF_BG9C00 ; Switch to _SCRN1
  ld [rLCDC], a
.loop:
  call readKeys
  bit PADB_START, b
  jr z, .loop
  ld a, LEVEL_LOAD_STATE
  ld [state], a
  ld hl, level
  inc [hl]
  ret

GameWin:
  call WaitVBlank
  xor a                 ; a = 0
  ld [rLCDC], a         ; turn off the screen
  ld de, GameWinScreen
  ld hl, _SCRN1
  ld b, 18
  call LoadBG           ; Load the Game Win Screen
  ld a, LCDCF_ON | LCDCF_OBJON | LCDCF_BGON | LCDCF_BG8000 | LCDCF_BG9C00 ; Switch to _SCRN1
  ld [rLCDC], a
.loop:
  jr .loop
  ret


SECTION "Functions", ROM0
undo_last_step:
  ; No inputs and outputs
  ; All variables will be used without save
  ld a, [can_undo]
  cp a, 0
  ret z ; There is no last step.

  ld a, 0
  ld [can_undo], a

  ld a, [step]
  dec a
  ld [step], a
  call binToDec
  ld de, _SCRN0 + START_POINT_OF_STEP_NUM
  call copyDigitsRev

  ld a, [direction]
  ld b, a
  ld a, [direction + 1]
  ld c, a

  ; de = bc
  ld d, b
  ld e, c
  ; Reverse bc
  ld a, b
  cpl 
  ld b, a
  ld a, c
  cpl 
  ld c, a
  inc bc

  ld a, [move_box]
  cp 1

  ; Get the position of the player
  ; hl The man's position
  call ReadManLocation
  
  jr z, .undo_move_box
.undo_not_move_box:
  call WaitVBlank
  
  ld a, [hl]
  cp MAN_ON_GOAL
  call z, .togoal
  call nz, .tospace
  add hl, bc ; + direction

  call SaveManLocation

  ld a, [hl]
  cp SPACE
  call z, .toman
  call nz, .toman_on_goal
  ret
.undo_move_box:
  call WaitVBlank
  ; Input hl the character
  ; bc: the reverse of direction
  ; de: direction
  ; hl + de : the box
  ; hl + bc : the original place
  ld a, [hl]
  cp a, MAN_ON_GOAL
  call nz, .tobox
  call z, .tobox_on_goal
  
  add hl, de
  ld a, [hl]
  cp a, BOX
  call z, .tospace
  call nz, .togoal
  call nz, .inc_box_num

  ; To the original place
  add hl, bc
  add hl, bc

  ld a, l
  ld [man_pos], a
  ld a, h
  ld [man_pos + 1], a

  ld a, [hl]
  cp a, SPACE
  call z, .toman
  call nz, .toman_on_goal
  ret
.togoal:
  ld a, GOAL
  ld [hl], a
  ret
.tospace:
  ld a, SPACE
  ld [hl], a
  ret
.toman:
  ld a, MAN
  ld [hl], a
  ret
.toman_on_goal:
  ld a, MAN_ON_GOAL
  ld [hl], a
  ret
.tobox:
  ld a, BOX
  ld [hl], a
  ret
.tobox_on_goal:
  ; Warn: This will change z/nz
  ld a, BOX_ON_GOAL
  ld [hl], a
  ld a, [box_num]
  dec a
  ld [box_num], a
  ret
.inc_box_num:
  ld a, [box_num]
  inc a
  ld [box_num], a
  ret

ReadManLocation:
; Output: 
; * hl: man's location
  ld a, [man_pos]
  ld l, a
  ld a, [man_pos + 1]
  ld h, a
  ret 
SaveManLocation:
; Input: 
; * hl: man's location
  ld a, l
  ld [man_pos], a
  ld a, h
  ld [man_pos + 1], a
  ret 
SaveDirection:
; input: 
; * DE: diretion
  ld a, d
  ld [direction], a
  ld a, e
  ld [direction + 1], a
  ld a, 0
  ld [move_box], a
  ret
LoadLevelMap:
; Load the level data from DE into BG
; while scanning the map for the player and boxes
; input:
; * DE: location of the map data
; * HL: location of the BG area in VRAM
; * B: number of rows to load
.row_loop:
  ld c, 5
.tiles_loop:
  ; Loop unrolled for 4 tiles
REPT 4
  ld a, [de]
  inc de
  ld [hl], a
  cp MAN
  call z, SaveManLocation
  cp MAN_ON_GOAL
  call z, SaveManLocation
  cp BOX
  call z, ProcessBoxTile
  inc hl
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

binToDec:
; Input:
; * A: the 8 bit integer to convert to decimal
; Output:
; * HL: pointer to the end of the 3 bytes buffer
;       to store the decimal digits
  ld hl, buffer
  ; Loop unrolled for 3 digits
  ; First digit
  ld b, 0
.div_1:
  sub 10
  jr c, .end_1
  inc b
  jr .div_1
.end_1:
  add 10
  ld [hl+], a
  ld a, b

  ; Second digit
  ld b, 0
.div_2:
  sub 10
  jr c, .end_2
  inc b
  jr .div_2
.end_2:
  add 10
  ld [hl+], a
  ld a, b

  ; Third digit
  ld b, 0
.div_3:
  sub 10
  jr c, .end_3
  inc b
  jr .div_3
.end_3:
  add 10
  ld [hl], a
  ld a, b

  ret

copyDigitsRev:
; Input:
; * DE: the starting point of BG to write
; * HL: the location of the digits to write
  ld a, [hl-]
  ld [de], a
  inc de
  ld a, [hl-]
  ld [de], a
  inc de
  ld a, [hl-]
  ld [de], a
  inc de
  ret

ProcessBoxTile:
; For LevelLoad
  ld a, [box_num]
  inc a
  ld [box_num], a
  ret

LoadBG:
; input:
; * DE: location of the map data
; * HL: location of the BG area in VRAM
; * B: number of rows to load (18 rows for 18x20 map)
.row_loop:
  ld c, 5
.tiles_loop:
  ; Loop unrolled for 4 tiles
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

ResetBG:
; Reset the background area in VRAM
; input:
; * HL: location of the BG area in VRAM
  ld bc, 1024
  ld a, SPACE
.loop:
  ld [hl+], a
  dec c
  jr nz, .loop
  dec b
  jr nz, .loop

  ; xor a ; a = 0
  xor a
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
  xor a ; a = 0
.loop:
  ld [hl], a
  inc hl
  dec b
  jr nz, .loop
  ret

ResetVariables:
; Initialize all variables of the program to 0,
; including the OAM
  ld hl, _OAMRAM
  call ResetOAM
  xor a ; a = 0
  ld [state], a
  ld [level], a
  ld [previous], a
  ld [current], a
  ld [man_pos], a
  ld [man_pos + 1], a
  ld [box_num], a
  ld [move_box], a
  ld [direction], a
  ld [can_undo], a
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
  and $0F           ; lower nibble has down, up, left, right
  swap a            ; becomes high nibble
  ld b, a
  ld a, $10
  ldh [rP1], a
  ldh a, [rP1] :: ldh a, [rP1] :: ldh a, [rP1]
  ldh a, [rP1] :: ldh a, [rP1] :: ldh a, [rP1]
  cpl
  and $0F           ; lower nibble has start, select, B, A
  or b
  ld b, a

  ld a, [previous]  ; load previous state
  xor b             ; result will be 0 if it's the same as current read
  and b             ; keep buttons that were pressed during this read only
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
previous:  DS 1  ; Used by readKeys
current:   DS 1  ; Used by readKeys
man_pos:   DS 2
box_num:   DS 1
buffer:    DS 3
step:      DS 1
move_box:  DS 1  ; If the last step move boxes
direction: DS 2  ; The direction of the last step
can_undo:  DS 1
