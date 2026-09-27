
; c64_centered_text_raster.s
; Copyright (C) 2026 Ulf Bertilsson
; SPDX-License-Identifier: GPL-3.0-or-later
; PAL-safe, single-IRQ rasterbars + tiny SID arpeggio.
; Uses the embedded custom 1bpp text charset at $1000 and prints:
;   "UBER CREW" (row 8) and "2025" (row 10) centered in white.
;
; Build:
;   acme --strict-segments -I . -f cbm -o c64_centered_text_raster.prg c64_centered_text_raster.s
; Run:
;   x64sc -autostart c64_centered_text_raster.prg

; ---------------- BASIC stub: 10 SYS6144 ----------------
* = $0801
!word $080b
!word 10
!byte $9e
!text "6144"
!byte 0
!word 0

; ---------------- Constants ----------------
BORDERCOL   = $d020
BGCOL       = $d021
RASTER      = $d012
CTRL1       = $d011
CTRL2       = $d016
MEMPTR      = $d018
VICIRQEN    = $d01a
VICIRQFLAG  = $d019
CIA2_PRA    = $dd00
CIA2_DDRA   = $dd02
CIA1_ICR    = $dc0d
CIA2_ICR    = $dd0d

SCREEN      = $0400
COLOR       = $d800
CHARSET     = $1000
FIRST_RASTER = 32

; ---------------- Zero Page ----------------
ZP_SrcLo    = $fb   ; general pointer/param
ZP_SrcHi    = $fc
ZP_DstLo    = $fd
ZP_DstHi    = $fe
ZP_Tmp      = $ff   ; scratch / color

; ---------------- Small variables ----------------
Len         = $0340
FrameCount  = $0341
ArpIdx      = $0342
ScrIdx      = $0343
Smooth      = $0344
RowTmp      = $0345

; ---------------- Tables ----------------
* = $0C00
RowScrLo:  !for i,0,24 { !byte <(SCREEN + i*40) }
RowScrHi:  !for i,0,24 { !byte >(SCREEN + i*40) }
RowColLo:  !for i,0,24 { !byte <(COLOR  + i*40) }
RowColHi:  !for i,0,24 { !byte >(COLOR  + i*40) }

; Badline-safe raster hits (y % 8 == 2 with $1B Y-scroll=3)
RasterLines: !byte 50,58,66,74,82,90,98,106,114,122,130,138,146,154,162,170
BarColors:   !byte 2,6,3,1,3,6,2,0,2,6,3,1,3,6,2,0

; Gradient for logo rows (white->light grey->grey->blue-ish via safe C64 colors)
LogoGrad16: !byte 1,15,14,6,14,15,1,1,15,14,6,14,15,1,1,1

; Scroller text (PETSCII mapped to our custom font)
ScrollTxt:
!scr "  UBER CREW 2025  -  GREETINGS TO: NTEB, DOMUS, JSWIKI, ULF, MAGNUS, THOMAS, ALEKS  -  "
!scr "  MADE WITH LOVE ON REAL C64  "
!byte 0




; ---------------- Custom charset for text mode at $1000 ----------------
* = $1000
!bin "custom_charset_1bpp.bin"



* = $1800
    jmp Start

; ---------------- Code ----------------
Start:
    sei
    ; Disable CIA sources before installing the raster-only handler.
    lda #$7f
    sta CIA1_ICR
    sta CIA2_ICR
    lda CIA1_ICR
    lda CIA2_ICR
    ; VIC bank 0 ($0000-$3FFF)
    lda CIA2_PRA
    and #%11111100
    ora #%00000011
    sta CIA2_PRA
    ; Make the VIC bank-select bits outputs without disturbing IEC lines.
    lda CIA2_DDRA
    ora #%00000011
    sta CIA2_DDRA

    ; Screen=$0400, custom charset=$1000
    lda #$14
    sta MEMPTR

    ; Standard display
    lda #$1b
    sta CTRL1
    lda #$08
    sta CTRL2

    lda #0
    sta FrameCount
    sta ArpIdx

    jsr ClearScreen
    jsr ClearColor

    ; Draw centered text using custom font
    lda #8                      ; row
    lda #<Uber1
    sta ZP_SrcLo
    lda #>Uber1
    sta ZP_SrcHi
    lda #1                      ; white
    sta ZP_Tmp
    lda #8                      ; row again
    jsr CenterPrintRow

    lda #10
    lda #<Uber2
    sta ZP_SrcLo
    lda #>Uber2
    sta ZP_SrcHi
    lda #1
    sta ZP_Tmp
    lda #10
    jsr CenterPrintRow

    ; IRQ setup
    jsr IRQ_Init
    jsr InitScroller
    jsr ColorizeLogo
    jsr SID_Init
    cli
Forever:
    jmp Forever

; ---------------- Text ----------------
Uber1: !scr "UBER CREW"
!byte 0
Uber2: !scr "2025"
!byte 0

; ---------------- Centered row print ----------------
; In:  A=row (0..24), (ZP_SrcLo/ZP_SrcHi)=ptr to 0-terminated text, ZP_Tmp=color
CenterPrintRow:
    sta RowTmp
    ; compute length -> Len
    ldy #0
@len_loop:
    lda (ZP_SrcLo),y
    beq @got_len
    iny
    bne @len_loop
@got_len:
    sty Len

    ; startcol = (40 - len)/2  -> store in ZP_DstLo
    tya                 ; A=len
    eor #$ff
    clc
    adc #41
    lsr
    sta ZP_DstLo        ; startcol

    ; get screen row base -> ZP_DstLo/ZP_DstHi (will overwrite startcol so save it)
    pha                 ; save startcol
    tax                 ; also keep startcol in X if needed
    ldy RowTmp          ; Y=row index for table lookups
    lda RowScrLo,y
    sta ZP_DstLo
    lda RowScrHi,y
    sta ZP_DstHi
    pla                 ; restore startcol to A

    ; advance pointer by startcol
    tax
@adv_sc:
    cpx #0
    beq @write
    inc ZP_DstLo
    bne @adv_ok
    inc ZP_DstHi
@adv_ok:
    dex
    bne @adv_sc

@write:
    ldy #0
@wloop:
    cpy Len
    beq @colors
    lda (ZP_SrcLo),y
    sta (ZP_DstLo),y
    iny
    bne @wloop

@colors:
    ; Recompute the centered color span using the preserved row index.
    lda Len
    eor #$ff
    clc
    adc #41
    lsr
    tax
    ldy RowTmp
    lda RowColLo,y
    sta ZP_DstLo
    lda RowColHi,y
    sta ZP_DstHi
@color_adv:
    cpx #0
    beq @color_write
    inc ZP_DstLo
    bne @color_ok
    inc ZP_DstHi
@color_ok:
    dex
    bne @color_adv
@color_write:
    ldy #0
@color_loop:
    cpy Len
    beq @done_colors
    lda ZP_Tmp
    sta (ZP_DstLo),y
    iny
    bne @color_loop
@done_colors:
    rts


; ---------------- Colorize logo rows with gradient ----------------
ColorizeLogo:
    ; row 8
    ldx #8
    jsr ColorizeRowGrad
    ; row 10
    ldx #10
    jsr ColorizeRowGrad
    rts

; X=row index
ColorizeRowGrad:
    lda RowColLo,x
    sta ZP_DstLo
    lda RowColHi,x
    sta ZP_DstHi
    ldy #0
@loop:
    lda LogoGrad16,y
    sta (ZP_DstLo),y
    iny
    cpy #16
    bne @loop
    ; repeat gradient across 40 cols (write 3 blocks: 16+16+8)
    ldy #16
@rep1:
    lda LogoGrad16-16,y  ; wrap from start
    sta (ZP_DstLo),y
    iny
    cpy #32
    bne @rep1
    ldy #32
@rep2:
    lda LogoGrad16-32,y
    sta (ZP_DstLo),y
    iny
    cpy #40
    bne @rep2
    rts

; ---------------- Bottom scroller (row 21) ----------------
InitScroller:
    lda #0
    sta ScrIdx
    lda #7
    sta Smooth
    ; clear row 21
    ldx #0
@cl:
    lda #$20
    sta SCREEN+21*40,x
    inx
    cpx #40
    bne @cl
    rts

Scroller_Tick:
    lda Smooth
    beq @shift
    dec Smooth
    ; set fine scroll and return
    lda Smooth
    ora #$08
    sta CTRL2
    rts
@shift:
    lda #7
    sta Smooth
    lda #$0f
    sta CTRL2
    ; shift left
    ldx #0
@mv:
    lda SCREEN+21*40+1,x
    sta SCREEN+21*40+0,x
    inx
    cpx #39
    bne @mv
    ; inject next char
    ldx ScrIdx
    lda ScrollTxt,x
    bne @ok
    ldx #0
    lda ScrollTxt,x
@ok:
    sta SCREEN+21*40+39
    inx
    stx ScrIdx
    ; color last cell
    lda #1
    sta COLOR+21*40+39
    rts

IRQ_Handler:
    lda VICIRQFLAG
    and #$01
    beq .rti

    pha
    txa : pha
    tya : pha

    ; ACK raster
    lda VICIRQFLAG
    sta VICIRQFLAG

    ; music tick + frame count
    jsr SID_Tick
    jsr Scroller_Tick
    inc FrameCount

    ; ensure MSB cleared
    lda CTRL1
    and #$7f
    sta CTRL1

    ldx #0
@nextbar:
@w1: lda RASTER
    cmp RasterLines,x
    bne @w1
    txa
    clc
    adc FrameCount
    and #$0f
    tay
    lda BarColors,y
    sta BGCOL
    lda #0
    sta BORDERCOL
    inx
    cpx #16
    bne @nextbar

    lda #FIRST_RASTER
    sta RASTER
    lda CTRL1
    and #$7f
    sta CTRL1
    lda #$01
    sta VICIRQEN

    pla : tay
    pla : tax
    pla
.rti:
    rti

IRQ_Init:
    lda VICIRQFLAG
    sta VICIRQFLAG
    lda CTRL1
    and #$7f
    sta CTRL1
    lda #FIRST_RASTER
    sta RASTER
    lda #$01
    sta VICIRQEN
    lda #<IRQ_Handler
    sta $0314
    lda #>IRQ_Handler
    sta $0315
    rts

; ---------------- SID (tiny arpeggio) ----------------
SID_Init:
    ; Establish a deterministic voice instead of relying on power-on SID state.
    lda #0
    sta $d400
    sta $d401
    sta $d402
    sta $d403
    sta $d404
    lda #$12
    sta $d405
    lda #$f8
    sta $d406
    lda #$0f
    sta $d418
    lda NoteLo
    sta $d400
    lda NoteHi
    sta $d401
    lda #$11                ; triangle + gate
    sta $d404
    rts

NoteLo: !byte <$11ED, <$0FEA, <$0E10
NoteHi: !byte >$11ED, >$0FEA, >$0E10
ArpSeq: !byte 0,1,2,0,1,2,0,1,2,0,1,2,0,1,2,0

SID_Tick:
    ldx ArpIdx
    lda ArpSeq,x
    tay
    lda NoteLo,y
    sta $d400
    lda NoteHi,y
    sta $d401
    lda #$11
    sta $d404
    inx
    txa
    and #$0f
    sta ArpIdx
    rts

; ---------------- Clear helpers ----------------
ClearScreen:
    lda #$20
    ldx #0
@1: sta $0400,x
    sta $0500,x
    sta $0600,x
    inx
    bne @1
    ldx #231
@2: sta $0700,x
    dex
    bpl @2
    rts

ClearColor:
    lda #$01            ; white for readability
    ldx #0
@3: sta $d800,x
    sta $d900,x
    sta $da00,x
    inx
    bne @3
    ldx #231
@4: sta $db00,x
    dex
    bpl @4
    rts
