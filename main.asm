; from https://moodle.gtiit.edu.cn/moodle/pluginfile.php/174051/mod_folder/content/0/first.asm
INCLUDE "hardware.inc"
INCLUDE "data.asm"

SECTION "Header", ROM0[$100]
  jp EntryPoint

  DS $150 - @, 0

EntryPoint:
  call WaitVBlank
  ld a, 0
  ld [rLCDC], a

  ld a,%11111100 ; b&w palette
  ld [rOBP0], a

  call   CopyTilesToVRAM

  ld     hl, _OAMRAM
  call   ResetOAM

  ld hl, _OAMRAM
  ld [hl],50  ; Y coordinate
  inc hl
  ld [hl],80  ; X coordinate
  inc hl

; LCD on, enable object layer (no background)
  ld a, LCDCF_ON | LCDCF_OBJON
  ld [rLCDC], a

MainLoop:
  jp MainLoop

SECTION "Functions", ROM0
WaitVBlank:
  ld a, [rLY]
  cp 144
  jr nz, WaitVBlank
  ret

ResetOAM:
; input:
; * HL: location of OAM or Shadow OAM
  ld b,40*4
  ld a,0
.loop:
  ld [hl],a
  inc hl
  dec b
  jr nz,.loop
  ret

CopyTilesToVRAM:
  ld de, Tiles
  ld hl, _VRAM
  ld bc, TilesEnd - Tiles
.copy:
  ld a,[de]
  inc de
  ld [hl],a
  inc hl
  ld [hl],a
  inc hl
  dec bc
  ld a,b
  or c
  jr nz, .copy
  ret

SECTION "Data", ROM0
Tiles:
; ID 0: smiling face
 DB %01111110
 DB %10000001
 DB %10100101
 DB %10000001
 DB %10100101
 DB %10011001
 DB %10000001
 DB %01111110
TilesEnd:
