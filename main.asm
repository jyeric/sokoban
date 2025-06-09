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
  ld a, PADF_START
  and b
  jr z, Splash
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
  ld [can_withdraw], a
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
  ld d, [hl]
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

  ; Load Level name and steps
  ld a, [level]
  inc a
  call binToDec
  ld d, START_POINT_OF_LEVEL_1
  ld e, START_POINT_OF_LEVEL_2
  call copyDigitsRev

  ld a, 0
  call binToDec
  ld d, START_POINT_OF_STEP_1
  ld e, START_POINT_OF_STEP_2
  call copyDigitsRev

  ld a, LCDCF_ON | LCDCF_OBJON | LCDCF_BGON | LCDCF_BG8000 | LCDCF_BG9800
  ld [rLCDC], a

  ; Change state
  ld a, LEVEL_PLAY_STATE
  ld [state], a     ; Set state to LevelPlay
  ret

LevelPlay:
  call WaitVBlank
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
  ld a, [man_pos]
  ld l, a
  ld a, [man_pos + 1]
  ld h, a
  
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
  jp nz, .withdraw_last_step
.reset:
  ld a, LEVEL_LOAD_STATE
  ld [state], a      ; Set state to LevelWin
  ret
;Output:
.move_down:
  ld de, 32
  jr .move
.move_up:
  ld de, -32
  ld [direction], a
  jr .move
.move_left:
  ld de, -1
  jr .move
.move_right:
  ld de, 1
  jr .move
.move:
  ; Reset Variables
  ld a, 0
  ld [move_box], a

  ; Write de into variable direction (move)
  ld a, d
  ld [direction], a
  ld a, e
  ld [direction + 1], a

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
  ld a, 1
  ld [move_box], a ;  Record that we move the box in this step
  call WaitVBlank
  ld a, [hl]
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

  ; Record person's position since the man move one step (move the box)
  ld a, l
  ld [man_pos], a
  ld a, h
  ld [man_pos + 1], a

  call WaitVBlank
  ld a, [hl]
  cp a, BOX_ON_GOAL
  ld a, MAN ; will be written as goal by calling
  ld [hl], a
  call z, .deccnt
  ; Processing the original man's position
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
  ld a, [box_num]
  dec a
  ld [box_num], a
  ret
.deccnt:
  ld a, MAN_ON_GOAL
  ld [hl], a
  ld a, [box_num]
  inc a
  ld [box_num], a
  ret
.removemanfromgoal:
  ld a, GOAL
  ld [hl], a
  jr .win ; the last function; don't need to call/ret
.movespace:
  ; Record person's position
  call WaitVBlank
  ld a, l
  ld [man_pos], a
  ld a, h
  ld [man_pos + 1], a

  ld a, MAN
  ld [hl], a

  ld a, [bc]
  cp MAN
  jr z, .mantospace
  jr .mantogoal
.movegoal
  ; Record person's position
  call WaitVBlank
  ld a, l
  ld [man_pos], a
  ld a, h
  ld [man_pos + 1], a

  ld a, MAN_ON_GOAL
  ld [hl], a

  ld a, [bc]
  cp MAN
  jr z, .mantospace
  ; jr .mantogoal
.mantogoal:
  ld a, GOAL
  ld [bc], a
  jp .win
.mantospace:
  ld a, SPACE
  ld [bc], a
.win:
  ld a, 1 
  ld [can_withdraw], a

  ; Add addtional step
  ld a, [step]
  inc a
  ld [step], a
  call binToDec
  ld d, START_POINT_OF_STEP_1
  ld e, START_POINT_OF_STEP_2
  call copyDigitsRev
  ; Check whether win or not
  ld a, [box_num]
  cp 0
  ret nz

  ; Change state if win
  ld a, LEVEL_WIN_STATE
  ld [state], a      ; Set state to LevelWin
  ret

.withdraw_last_step:
  ld a, [can_withdraw]
  cp a, 0
  ret z ; There is no last step.

  ld a, 0
  ld [can_withdraw], a

  ld a, [step]
  dec a
  ld [step], a
  call binToDec
  ld d, START_POINT_OF_STEP_1
  ld e, START_POINT_OF_STEP_2
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
  ld a, [man_pos]
  ld l, a
  ld a, [man_pos + 1]
  ld h, a

  jr z, .withdraw_move_box
.withdraw_not_move_box:
  call WaitVBlank
  
  ld a, [hl]
  cp MAN_ON_GOAL
  call z, .togoal
  call nz, .tospace
  add hl, bc ; + direction

  
  ld a, l
  ld [man_pos], a
  ld a, h
  ld [man_pos + 1], a

  ld a, [hl]
  cp SPACE
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
.withdraw_move_box:
  call WaitVBlank
  ; Input hl the character
  ; bc: the reverse of direction
  ; de: direction
  ; hl + de : the box
  ; hl + bc : the original place
  ld a, [hl]
  cp a, MAN_ON_GOAL
  call z, .tobox_on_goal
  call nz, .tobox
  call z, .inccnt2
  
  add hl, de
  ld a, [hl]
  cp a, BOX
  call z, .tospace
  call nz, .togoal
  call nz, .deccnt2

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
.tobox:
  ld a, BOX
  ld [hl], a
  ret
.tobox_on_goal:
  ld a, BOX_ON_GOAL
  ld [hl], a
  ret
.deccnt2:
  ld a, [box_num]
  inc a
  ld [box_num], a
  ret
.inccnt2:
  ld a, [box_num]
  dec a
  ld [box_num], a
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
  ld a, PADF_START
  and b
  jr z, .loop
  ld a, LEVEL_LOAD_STATE
  ld [state], a
  ld hl, level
  inc [hl]
  ret

GameWin:
  call WaitVBlank
  xor a
  ld [rLCDC], a         ; turn off the screen
  ld de, GameWinScreen
  ld hl, _SCRN1
  ld b, 18
  call LoadBG
  ld a, LCDCF_ON | LCDCF_OBJON | LCDCF_BGON | LCDCF_BG8000 | LCDCF_BG9C00 ; Switch to _SCRN1
  ld [rLCDC], a
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
REPT 4
  ld a, [de]
  inc de
  ld [hl+], a
  cp MAN
  call z, ProcessManTile
  cp MAN_ON_GOAL
  call z, ProcessManTile
  cp BOX
  call z, ProcessBoxTile
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
; Input: a, the 16 bit digit
; Output: b, the third digit
;         c, the second digit
;         d, the first digit
  ld hl, temp_digit
  ld b, 0
  ld c, 0
  ld d, 0
  ld e, a
.getThirdDigit
  cp 100 ;a < 100
  jr c, .getSecondDigit
  sub 100
  inc b
  jr .getThirdDigit
.getSecondDigit
  cp 10 ;a < 10
  jr c, .getFirstDigit
  sub 10
  inc c
  jr .getSecondDigit
.getFirstDigit
  cp 1 ;a < 1
  jr c, .end
  sub 1
  inc d
  jr .getFirstDigit
.end:
  ld [hl], d
  inc hl
  ld [hl], c
  inc hl
  ld [hl], b
  ret

copyDigitsRev:
  ; Input: de: the starting point of BG to write
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

ProcessManTile:
  ld a, l
  dec a
  ld [man_pos], a
  ld a, h
  ld [man_pos + 1], a
  ret

ProcessBoxTile:
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
; including OAMs
  ld hl, ShadowOAM
  call ResetOAM
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
  ld [can_withdraw], a
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
ShadowOAM: DS 160
previous:  DS 1  ; Used by readKeys
current:   DS 1  ; Used by readKeys
man_pos:   DS 2
box_num:   DS 1
temp_digit:DS 3
step:      DS 1
move_box:  DS 1  ;If the last step move boxes
direction:  DS 2  ;The direction of the last step
can_withdraw: DS 1
