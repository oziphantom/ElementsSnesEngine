kJoypad .block
	BtnR      = 16
	BtnL      = 32
	BtnX      = 64
	BtnA      = 128
	DirRight  = 256
	DirLeft   = 512
	DirDown   = 1024
	DirUp     = 2048
	BtnStart  = 4096
	BtnSelect = 8192
	BtnY      = 16384
	BtnB      = 32768
.bend

kHead .block
	none = 0
	right = 1
	up = 2
	left = 3
	down = 4
.bend

*=$0
; DP variables go here
DPPointer1 .long ?
DPPointer2 .long ?

*=$100
; Normal variables go here
HeadX .byte ?
HeadY .byte ?
TailX .byte ?
TailY .byte ?
TargetX .byte ?
TargetY .byte ?
HeadIndex .word ?
TailIndex .word ?
CurrentHeading .byte ?
SpeedCounter .byte ?
SpeedDecCounter .byte ?
SpeedValue .byte ?
seed .byte ?
NMIDoneNF .byte ?
SkipRemoveTaleNF .byte ?

*=$200
ScreenMirror .fill $800
SnakeArray .fill $400

CollectedCounter     = ScreenMirror+(16*2)
BestCollectedCounter = ScreenMirror+(27*2)

* = $8000
.as               ; Assume A8
.xs               ; Assume X8
.autsiz           ; Auto size detect
.databank $00     ; databank is 00
.dpage $0000      ; dpage is 0000
RESET
   clc
   xce ; enter 65816 mode
   rep #$30 ; AXY 16
   ldx #$1FFF
   txs      ; set the stack
   phk
   plb
   lda #0000
   tcd
   lda #$008f
   sta $2100      ; turn the screen off 
   lda #$8008     ; A -> B, FIXED SOURCE, WRITE BYTE | WRAM
   sta $4300
   lda #<>DMAZero ; 64Tass | get low word
   sta $4302
   lda #`DMAZero  ; 64Tass | get bank
   sta $4304
   stz $2181
   stz $2182      ; START AT 7E:0000
   stz $4305      ; DO 64K
   lda #$0001
   sta $420B      ; FIRE DMA
   sta $420B      ; FIRE IT AGAIN, FOR NEXT 64k
   rep #$20       ; A16
   lda #$008F     ; FORCE BLANK, SET OBSEL TO 0
   sta $2100
   stz $2105 ;6
   stz $2107 ;8
   stz $2109 ;A
   stz $210B ;C
   stz $210D ;E
   stz $210D ;E
   stz $210F ;10
   stz $210F ;10
   stz $2111 ;12
   stz $2111 ;12
   stz $2113 ;14
   stz $2113 ;14
   stz $2119 ;1A to get Mode7
   stz $211B ;1C these are write twice
   stz $211B ;1C regs
   stz $211D ;1E
   stz $211D ;1E
   stz $211F ;20
   stz $211F ;20
   stz $2123 ;24
   stz $2125 ;26
   stz $2126 ;27 YES IT DOUBLES OH WELL
   stz $2128 ;29
   stz $212A ;2B
   stz $212C ;2D
   stz $212E ;2F
   stz $2130 ;31
   lda #$00E0
   sta $2132
   ;ONTO THE CPU I/O REGS
   lda #$FF00
   sta $4200
   stz $4202 ;3
   stz $4204 ;5
   stz $4206 ;7
   stz $4208 ;9
   stz $420A ;B
   stz $420C ;D   
   ; CLEAR VRAM
   rep #$20        ; A16
   lda #$1809      ; A -> B, fixed source, write word | vram
   sta $4300
   lda #<>DMAZero  ; this get the low word, you will need to change if not using 64tass
   sta $4302
   lda #`DMAZero   ; this gets the bank, you will need to change if not using 64tass
   sta $4304       ; and the upper byte will be 0
   stz $4305       ; do 64k
   lda #$80        ; inc on hi write
   sta $2115
   stz $2116       ; start at $$0000
   lda #$01
   sta $420B       ; fire dma
   ; CLEAR CG-RAM
   lda #$2208      ; a -> b, fixed source, write byte | cg-ram
   sta $4300
   lda #$200       ; 512 bytes
   sta $4305
   sep #$20        ; A8
   stz $2121       ; start at 0
   lda #$01
   sta $420B       ; fire dma
   ; DMA Petscii Font
   rep #$30        ; AXY 16
   lda #<>PETSCII_Chars
   sta $4302
   sep #$20        ; A8
   lda #`PETSCII_Chars
   sta $4304
   ldx #size(PETSCII_Chars)
   stx $4305
   ldx #%00000001 | $1800   ; A->B, Inc, Write WORD, $2118
   stx $4300
   ldx #$1000
   stx $2116
   lda #$80
   sta $2115                ; inc VRAM port address
   lda #1
   sta $420B
   ; DMA Pallete
   ldx #<>PETSCII_Pal
   stx $4302
   lda #`PETSCII_Pal
   sta $4304
   ldx #16
   stx $4305
   ldx #%00000010 | $2200  ; A->B, Inc, Write 2 Bytes, $2122
   stx $4300
   stz $2121               ; start of Pallete
   lda #1
   sta $420B
   jsr clearGameScreen_aXY
   rep #$20                ; A16
	; the status row
	ldx #62
-	lda StatusRow,x
	sta ScreenMirror,x
	dex
	dex
	bpl -
	jsr DMAScreenToVRAM_ff
	sep #$20  ; A8
   ; set up screen addresses
   stz $2107 ; we want the screen at $$0000 and size 32x32
   lda #1
   sta $210B ; we want BG1 tile data to be $$1000 which is the first 4K word step
   stz $2105 ; 8x8 chars and Mode 0
   lda #1
   sta $212c ; BG1 is on the Main Screen
   lda #$ff
   sta $210e ; we also need to scroll up 1 pixel ( so do -1 )
   lda #$03
   sta $210e ; because the first line is not drawn
   lda #$0f
   sta $2100 ; don't blank, so show the screen at full brightness
   ; enable NMI to get us a game loop
   lda #%10000001 ; enable NMI VBlanks and Gamepad scanning 
   sta $4200
	; init game state
initGame_xx
	sep #$30  ; AXY8
   lda #10
   sta SpeedCounter   
   stz SpeedValue
   stz SkipRemoveTaleNF
   lda #16 
   sta HeadX
   sta TailX
   lda #12
   sta HeadY
   sta TailY
   stz CurrentHeading
   stz SpeedDecCounter
   jsr getRandomTarget_ad
   rep #$20 ; A16
   stz HeadIndex
   stz TailIndex
   lda #'0'
   sta CollectedCounter
   sta CollectedCounter+2
   sta CollectedCounter+4
   sta CollectedCounter+6
   sep #$10 ; XY8
   jsr drawHeadToScreen_Ax
   jsr drawTargetToScreen_Ax
   rep #$10 ; AXY16
   jsr pushCurrentToQueue_AX

mainLoop
	sep #$20      ; A8
   stz NMIDoneNF ; clear any pending NMI
-	lda NMIDoneNF ; wait for the next one
	bpl -
	; NMI is finished so we can update
	sep #$10 ; XY8
	; update the heading direction
	lda $4218+1
	bit #>kJoypad.DirUp
	beq _notUp
		ldx #kHead.up
		bne _setNew
_notUp
	bit #>kJoypad.DirDown
	beq _notDown
		ldx #kHead.down
		bne _setNew
_notDown
	bit #>kJoypad.DirLeft
	beq _notLeft
		ldx #kHead.left
		bne _setNew
_notLeft
	bit #>kJoypad.DirRight
	beq _noMoveChange
		ldx #kHead.right
_setNew
	stx CurrentHeading
_noMoveChange
	dec SpeedValue
	bpl MainLoop
	
	lda SpeedCounter
	sta SpeedValue
	ldx CurrentHeading
	clc
	lda XDelta,x
	adc HeadX
	sta HeadX
	clc
	lda YDelta,x
	adc HeadY
	sta HeadY
	lda HeadX
	cmp TargetX
	bne _noCollection
		lda HeadY
		cmp TargetY
		bne _noCollection
			; we are on top of the target
			lda CollectedCounter+6
			clc
			adc #1
			sta CollectedCounter+6
			cmp #'0'+10
			bne _getNextTarget
				lda #'0'
				sta CollectedCounter+6
				lda CollectedCounter+4
				clc
				adc #1
				sta CollectedCounter+4
				cmp #'0'+10
				bne _getNextTarget
					lda #'0'
					sta CollectedCounter+4
					lda CollectedCounter+2
					clc
					adc #1
					sta CollectedCounter+2
					cmp #'0'+10
					bne _getNextTarget
						inc CollectedCounter
	_getNextTarget
		lda #$ff
		sta SkipRemoveTaleNF
	   inc SpeedDecCounter
      lda SpeedDecCounter
      cmp #5 ; make this higher for an easier game
      bne +
         lda SpeedCounter
         cmp #1             ; make sure we don't go below 1
         beq +
            dec SpeedCounter  ; start going faster
            stz SpeedDecCounter
   +
		jsr getRandomTarget_ad		; get the next target
		rep #$20
		sep #$10
		jsr drawTargetToScreen_Ax	; put it on the screen
_noCollection
	sep #$20								; A8
	bit SkipRemoveTaleNF
	bmi _noTailUpdate
	rep #$30                      ; AXY16
	jsr updateTailFromQueue_AX
	sep #$10                      ; XY8
	jsr clearTailOnScreen_Ax
	sep #$20								; A8
_noTailUpdate
	stz SkipRemoveTaleNF				; clear the flag
	rep #$20 ; A16
	jsr readHeadFromScreen_Ax
	and #$00ff ; make sure we only check the lower 8 bits
	cmp #' '+128
	bne _safeToMove
		jmp gameOver_Ax
_safeToMove
	jsr drawHeadToScreen_Ax
	rep #$30								; AXY16
	jsr pushCurrentToQueue_AX
	sep #$20                      ; A8
	jmp mainLoop

.al
.xs
gameOver_Ax
	ldx #(8*2)
-	lda GameoverText,x
	sta ScreenMirror+(11*64)+(12*2),x
	dex
	dex
	bpl -
	lda CollectedCounter
	cmp BestCollectedCounter
	beq _100s
	bcs _newBest
	bcc _noNewBest
_100s
	lda CollectedCounter+2
	cmp BestCollectedCounter+2
	beq _10s
	bcs _newBest
	bcc _noNewBest
_10s
	lda CollectedCounter+4
	cmp BestCollectedCounter+4
	beq _1s
	bcs _newBest
	bcc _noNewBest
_1s
	lda CollectedCounter+6
	cmp BestCollectedCounter+6
	beq _noNewBest ; its the same score
	bcc _noNewBest
_newBest	
	; new best score so copy the current one to the best
	ldx #6	
-	lda CollectedCounter,x	
	sta BestCollectedCounter,x	
	dex		
	dex		
	bpl -		
_noNewBest	
	lda $4218
	and #kJoypad.BtnA|kJoypad.BtnB|kJoypad.BtnX|kJoypad.BtnY|kJoypad.BtnStart|kJoypad.BtnSelect
	beq _noNewBest ; actually wait for face button
	sep #$20 ; A8
	rep #$10 ; XY16
	jsr clearGameScreen_aXY
	jmp initGame_xx


XDelta .char  0, 1, 0,-1, 0
YDelta .char  0, 0,-1, 0, 1

.enc "screen"
                ;          1111111111122222222233
                ;01234567890123456789012345678901
StatusRow .word ' ','s','n','a','k','e','s',' ',' ',' ','s','c','o','r','e',':','0','0','0','0',' ',' ','b','e','s','t',':','0','0','0','0',' ' 
GameoverText .word 'g','a','m','e',' ','o','v','e','r'

DMAScreenToVRAM_ff
	php
	rep #$10            ; XY16
	sep #$20            ; A8
   ldx #$1801          ; A -> B, copy source, write word | vram
   stx $4300
   ldx #<>ScreenMirror ; this get the low word, you will need to change if not using 64tass
   stx $4302
   lda #`ScreenMirror  ; this gets the bank, you will need to change if not using 64tass
   sta $4304           ; and the upper byte will be 0
   ldx #$800           ; DMA counts bytes not words so we must give a byte size not a word size
   stx $4305           ; do $$400 words
   lda #$80            ; inc on hi write
   sta $2115
   stz $2116       
   stz $2117           ; start at $$0000
   lda #$01
   sta $420B           ; fire dma
   plp
   rts

.as
.xl
clearGameScreen_aXY
_ASSERT_a8
_ASSERT_xy16
 	; fill the screen with ' '
   ldx #$8008      ; A -> B, FIXED SOURCE, WRITE BYTE | WRAM
   stx $4300
   ldx #ScreenMirror+64
   stx $2181
   stz $2183       ; START AT 7E:ScreenMirror+64   
   ldx #<>DMASpace ; this get the low word, you will need to change if not using 64tass
   stx $4302
   lda #`DMASpace  ; this gets the bank, you will need to change if not using 64tass
   sta $4304       ; and the upper byte will be 0
   ldx #$800-64    ; DMA counts bytes not words so we must give a byte size not a word size
   stx $4305       ; do 2048-64 bytes
   lda #$01
   sta $420B       ; fire dma
   ; pre fill the Screen mirror with our arena
   ; first the outlines
   ; the top and bottom line
   rep #$20            ; A16
   .enc 'screen'
   lda #'{space}'+128  ; solid char
   ldx #62
-	sta ScreenMirror+(1*32*2),x
   sta ScreenMirror+(23*32*2),x
   dex
   dex
   bpl -
   ; the veritcal lines
   lda #ScreenMirror+(2*32*2)
   sta DPPointer1
   ldx #20
-	lda #'{space}'+128  ; solid char
	ldy #0
	sta (DPPointer1),y
	ldy #31*2
	sta (DPPointer1),y
	clc
	lda DPPointer1
	adc #32*2
	sta DPPointer1
	dex
	bpl -
	sep #$20 ; return with A8 as promised
	rts
	
.al   
.xs              ; tell the assembler this routine expects A16,XY8   
drawHeadToScreen_Ax
_ASSERT_a16
_ASSERT_xy8
	lda HeadY
	and #$00ff
	asl a        ;2x
	asl a        ;4x
	asl a        ;8x
	asl a        ;16x
	asl a        ;32x
	asl a			 ;64x
	clc
	adc #ScreenMirror
	sta DPPointer1
	lda HeadX
	asl a
	tay
	lda #'{space}'+128
	sta (DPPointer1),y
	rts

.al   
.xs              ; tell the assembler this routine expects A16,XY8   
clearTailOnScreen_Ax
_ASSERT_a16
_ASSERT_xy8
	lda TailY
	and #$00ff
	asl a        ;2x
	asl a        ;4x
	asl a        ;8x
	asl a        ;16x
	asl a        ;32x
	asl a			 ;64x
	clc
	adc #ScreenMirror
	sta DPPointer1
	lda TailX
	asl a
	tay
	lda #'{space}'
	sta (DPPointer1),y
	rts	

.al   
.xs              ; tell the assembler this routine expects A16,XY8   
readTargetFromScreen_Ax
_ASSERT_a16
_ASSERT_xy8
	lda TargetY
	and #$00ff
	asl a        ;2x
	asl a        ;4x
	asl a        ;8x
	asl a        ;16x
	asl a        ;32x
	asl a			 ;64x
	clc
	adc #ScreenMirror
	sta DPPointer1
	lda TargetX
	asl a
	tay
	lda (DPPointer1),y
	rts	

.al   
.xs              ; tell the assembler this routine expects A16,XY8   
readHeadFromScreen_Ax
_ASSERT_a16
_ASSERT_xy8
	lda HeadY
	and #$00ff
	asl a        ;2x
	asl a        ;4x
	asl a        ;8x
	asl a        ;16x
	asl a        ;32x
	asl a			 ;64x
	clc
	adc #ScreenMirror
	sta DPPointer1
	lda HeadX
	asl a
	tay
	lda (DPPointer1),y
	rts	
	
.al   
.xs              ; tell the assembler this routine expects A16,XY8   
drawTargetToScreen_Ax
_ASSERT_a16
_ASSERT_xy8
	lda TargetY
	and #$00ff
	asl a        ;2x
	asl a        ;4x
	asl a        ;8x
	asl a        ;16x
	asl a        ;32x
	asl a			 ;64x
	clc
	adc #ScreenMirror
	sta DPPointer1
	lda TargetX
	asl a
	tay
	lda #'{shift-x}'+$400 ; this is a club, we could put a unicode character here but encodings will cause pain, make it red
	sta (DPPointer1),y
	rts		
		
.al
.xl
pushCurrentToQueue_AX
_ASSERT_a16
_ASSERT_xy16
	clc
	lda HeadIndex
	adc #1			 ; add 1
	and #1024-1     ; wrap arround size
	sta HeadIndex
	tax
	sep #$20        ; A8
	lda CurrentHeading
	sta SnakeArray,x
	rep #$20        ; A16
	rts

.al
.xl
updateTailFromQueue_AX	
_ASSERT_a16
_ASSERT_xy16
	; update tail
	clc
	lda TailIndex
	adc #1			 ; add 1
	and #1024-1     ; wrap arround size
	sta TailIndex
	tax
	lda SnakeArray,x
	and #$ff			; don't set A to 8bit or you will get a 16 bit value into X
	tax
	sep #$20        ; A8
	clc
	lda XDelta,x
	adc TailX
	sta TailX
	clc
	lda YDelta,x
	adc TailY
	sta TailY
	rep #$20       ; A16
	rts

.as	
.xs	
getRND_ad
_ASSERT_a8
	lda seed
	beq _doEor
		asl
		beq _noEor ;if the input was $80, skip the EOR
		bcc _noEor
_doEor
	eor #$1d
_noEor  
	sta seed
	rts

.as
.xs
getRandomTarget_ad
_ASSERT_a8
	php
_tryAgain
	jsr getRND_ad ; 1-31
	and #31
-	cmp #29
	bcc +
		sec
		sbc #29
		jmp -	
+	clc
	adc #1
	sta TargetX		
	jsr getRND_ad ; 2-23
	and #31
-	cmp #21
	bcc +
		sec
		sbc #21
		jmp -	
+	clc
	adc #1
	sta TargetY		
	rep #$20  ; A16	
	sep #$10  ; X8	
	jsr readTargetFromScreen_Ax			
	sep #$20  ; A8			
	cmp #'{space}'			
	bne _tryAgain		
	plp		
	rts			
			
NMI_ISR
	rep #$30 ; AXY16
	pha
	phx
	phy
	phb
	phk
	plb
   jsr DMAScreenToVRAM_ff
   sep #$20 ; A8
   lda #$ff
   sta NMIDoneNF
   jsr getRND_ad ; throw away a random number to improve randomness
   rep #$20 ; A16
   plb
   ply
   plx
   pla
justRTI
   rti

.enc "screen" ; tell 64Tass we want the text to be written in C64 Screen codes encoding
DMASpace .word ' '

PETSCII_Chars .binary "petscii.chr"

PETSCII_Pal .binary "petscii.pal"
.word %0_00000_00000_00000 ; 0, 0, 0 BGR
.word %0_00000_00000_11111 ; 0, 0,31 BGR
.word %0_00000_00000_00000 ; 0, 0, 0 BGR
.word %0_00000_00000_00000 ; 0, 0, 0 BGR

* = $ffb0
    .enc "none"
DMAZero
    .fill 16,0
    ;               111111111112
    ;      123456789012345678901
    .text "this is a dummy name "
.cerror * != $00ffd5, "name is too short", *
    .byte $20   ; Mapping
    .byte $00   ; Rom
    .byte $07   ; 128K
    .byte $00   ; 0 SRAM
    .byte $02   ; PAL
    .byte $33   ; Version 3
    .byte $00   ; rom version 0
    .word $FFFF ; complement
    .word $0000 ; CRC
    
; 65816 vectors
* = $ffe4
v16_COP    .word justRTI
v16_BRK    .word justRTI
v16_ABORT  .word justRTI
v16_NMI    .word NMI_ISR
v16_RESET  .word justRTI
v16_IRQ    .word justRTI

; 6502 vectors
* = $fff4
v02_COP    .word justRTI
v02_BRK    .word justRTI
v02_ABORT  .word justRTI
v02_NMI    .word justRTI
v02_RESET  .word RESET
v02_IRQ    .word justRTI   