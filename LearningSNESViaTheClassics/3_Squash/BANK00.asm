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

kRacketStartX = 128
kRacketStartY = 188

kRacketColWidth = 24
kRacketColHeight = 4

kBallColWidth = 6
kBallColHeight = 6

*=$0
; DP variables go here
DPPointer1 .long ?
DPPointer2 .long ?

*=$100
; Normal variables go here
seed .byte ?
NMIDoneNF .byte ?
BallX .byte ?
BallY .byte ?
BallDeltaX .byte ?
BallDeltaY .byte ?
RacketX .byte ?
RacketY .byte ?

*=$200
ScreenMirror  .fill $800
OAMMirror     .fill 512
OAMMirrorHigh .fill 32

ScoreCounter     = ScreenMirror+(16*2)
BestScoreCounter = ScreenMirror+(27*2)

* = $8000
.as               ; Assume A8
.xs               ; Assume X8
.autsiz           ; Auto size detect
.databank $00     ; databank is 00
.dpage $0000      ; dpage is 0000
RESET
   clc
   xce ; enter 65816 mode
   #AXY16
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
   #A16
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
   #A16
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
   #A8
   stz $2121       ; start at 0
   lda #$01
   sta $420B       ; fire dma
   ; INIT OAM Mirror
   jsr ClearOAMMirror_ff
   ; INIT OAM
   jsr DMAOAMMirrorToOAM_ff
   ; DMA Petscii Font
   #AXY16
   lda #<>PETSCII_Chars
   sta $4302
   #A8
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
   ; DMA Sprite Chars
   ldx #<>Sprite_Chars
   stx $4302
   lda #`Sprite_Chars
   sta $4304
   ldx #size(Sprite_Chars)
   stx $4305
   ldx #%00000001 | $1800   ; A->B, Inc, Write WORD, $2118
   stx $4300
   ldx #$6000					 ; put Sprites chars at $$6000/$C000
   stx $2116
   lda #$80
   sta $2115                ; inc VRAM port address
   lda #1
   sta $420B
   ; DMA Pallete
   ldx #<>Sprite_Pal
   stx $4302
   lda #`Sprite_Pal
   sta $4304
   ldx #16
   stx $4305
   ldx #%00000010 | $2200  ; A->B, Inc, Write 2 Bytes, $2122
   stx $4300
   lda #128						; sprite pal starts at entry 128
   sta $2121
   lda #1
   sta $420B
   #A16
	; the status row
	ldx #62
-	lda StatusRow,x
	sta ScreenMirror,x
	dex
	dex
	bpl -
	jsr DMAScreenToVRAM_ff
	#A8
   ; set up screen addresses
   stz $2107 ; we want the screen at $$0000 and size 32x32
   lda #1
   sta $210B ; we want BG1 tile data to be $$1000 which is the first 4K word step
   stz $2105 ; 8x8 chars and Mode 0
   lda #$11
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
   lda #3
	sta $2101
	; init game state
initGame_xx
   #A16
   lda #'0'
   sta ScoreCounter
   sta ScoreCounter+2
   sta ScoreCounter+4
   sta ScoreCounter+6
	#AXY8
	lda #32			   ; x at 32
	sta OAMMirror
	sta BallX
	lda #112-4			; y at 122
	sta OAMMirror+1
	sta BallY
	lda #0				; tile number 0
	sta OAMMirror+2
	lda #0				; tile number 0, pal 0, no flipped, normal priority
	sta OAMMirror+3
	lda #1
	sta BallDeltaX
	sta BallDeltaY
	ldx #11
-	lda RacketSpriteTable,x
	sta OAMMirror+4,x
	dex
	bpl -
	lda #kRacketStartX
	sta RacketX
	lda #kRacketStartY
	sta RacketY
mainLoop
	#AXY8
   stz NMIDoneNF ; clear any pending NMI
-	lda NMIDoneNF ; wait for the next one
	bpl -
	; NMI is finished so we can update
	; update the ball
	lda BallX
	clc
	adc BallDeltaX
	sta BallX
	sec
	sbc #4         ; update the position from centre to top left
	sta OAMMirror
	lda BallY
	clc
	adc BallDeltaY
	sta BallY
	sec
	sbc #4         ; update the position from centre to top left
	sta OAMMirror+1
	lda BallX
	cmp #12
	bcc _flipX
	cmp #244
	bcs _flipX
_checkY
	lda BallY
	cmp #20
	bcc _flipY
	cmp #220
	bcc _wallCollisionDone
		#XY8
		#A16
		jmp gameOver_Ax
		.as ; since this code jumps, we have to restore the before sizes for the assembler otherwise
		.xs ; it will assemble below this point with Axy which is wrong and the code will crash
	_flipY
		lda BallDeltaY	
		eor #$ff	
		clc	
		adc #1	
		sta BallDeltaY
		bra _wallCollisionDone
	_flipX
		lda BallDeltaX
		eor #$ff	
		clc	
		adc #1	
		sta BallDeltaX
		bra _checkY
_wallCollisionDone
	lda BallDeltaY
	bmi _YOutOfRange
	lda BallY
	sec
	sbc RacketY				                   ; this is the middle Y
	clc                                     ; we would subtract this from RacketY which would cause
	adc #kRacketColHeight+kBallColHeight/2  ; us to subtract 4 less, so we add 4 to compensate
	bmi _YOutOfRange		                   ; the Racket Y was too much pushing us negative, so ball is above 			 
	cmp #kRacketColHeight+kBallColHeight    ; is it less than the thicknes of the expanded Racket
	bcs _yOutOfRange								 ; it is over
		; Y in range, lets check the X
		lda BallX
		sec
		sbc RacketX
		clc
		adc #kRacketColWidth/2+kBallColWidth/2
		bmi _YOutOfRange							; actually is X but why make 2 labels
		cmp #kRacketColWidth+kBallColWidth
		bcs _YOutOfRange
			; we hit the bat
			lda BallDeltaY
			eor #$ff	
			clc	
			adc #1	
			sta BallDeltaY
			jsr awardPoint_ax			
_YOutOfRange
	#XY8
	; update the heading direction
	lda $4218+1
	bit #>kJoypad.DirLeft
	beq _notLeft
		lda RacketX
		cmp #13           ; add 1 because 
		bcc _noMoveChange ; this is < not <=
		sec
		sbc #1
		sta RacketX
		bra _setNew
_notLeft
	bit #>kJoypad.DirRight
	beq _noMoveChange
		lda RacketX
		cmp #244
		bcS _noMoveChange
		clc
		adc #1
		sta RacketX
_setNew
	lda RacketX
	sec
	sbc #12
	sta OAMMirror+4
	clc
	adc #8
	sta OAMMirror+8
	clc
	adc #8
	sta OAMMirror+12
_noMoveChange	
	#A8
	jmp mainLoop

RacketSpriteTable 
	.byte kRacketStartX-12,kRacketStartY-4,1,0
	.byte kRacketStartX-4,kRacketStartY-4,2,0
	.byte kRacketStartX+4,kRacketStartY-4,1,$40

.al
.xs
gameOver_Ax
	ldx #(8*2)
-	lda GameoverText,x
	sta ScreenMirror+(11*64)+(12*2),x
	dex
	dex
	bpl -
	lda ScoreCounter
	cmp BestScoreCounter
	beq _100s
	bcs _newBest
	bcc _noNewBest
_100s
	lda ScoreCounter+2
	cmp BestScoreCounter+2
	beq _10s
	bcs _newBest
	bcc _noNewBest
_10s
	lda ScoreCounter+4
	cmp BestScoreCounter+4
	beq _1s
	bcs _newBest
	bcc _noNewBest
_1s
	lda ScoreCounter+6
	cmp BestScoreCounter+6
	beq _noNewBest ; its the same score
	bcc _noNewBest
_newBest	
	; new best score so copy the current one to the best
	ldx #6	
-	lda ScoreCounter,x	
	sta BestScoreCounter,x	
	dex		
	dex		
	bpl -		
_noNewBest	
	lda $4218
	and #kJoypad.BtnA|kJoypad.BtnB|kJoypad.BtnX|kJoypad.BtnY|kJoypad.BtnStart|kJoypad.BtnSelect
	beq _noNewBest ; actually wait for face button
	#A8
	#XY16
	jsr clearGameScreen_aXY
	jmp initGame_xx

.as
.xs
.enc "screen"
awardPoint_ax
	ldx #6
-	lda ScoreCounter,x
	clc
	adc #1
	sta ScoreCounter,x
	cmp #'9'
	bne _exit
		lda #'0'
		sta ScoreCounter,x
		dex
		dex
		bpl -
_exit
	rts

.enc "screen"
                ;          1111111111122222222233
                ;01234567890123456789012345678901
StatusRow .word ' ','s','q','u','a','s','h',' ',' ',' ','s','c','o','r','e',':','0','0','0','0',' ',' ','b','e','s','t',':','0','0','0','0',' ' 
GameoverText .word 'g','a','m','e',' ','o','v','e','r'

DMAScreenToVRAM_ff
	php
	#XY16
	#A8
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
   
ClearOAMMirror_ff
	php
	#XY16
	#A8
	ldx #$8008      ; A -> B, FIXED SOURCE, WRITE BYTE | WRAM
   stx $4300
   ldx #OAMMirror
   stx $2181
   stz $2183       ; START AT 7E:OAMMirror
   ldx #<>DMA240   ; this get the low word, you will need to change if not using 64tass
   stx $4302
   lda #`DMA240    ; this gets the bank, you will need to change if not using 64tass
   sta $4304       ; and the upper byte will be 0
   ldx #512
   stx $4305
   lda #$01
   sta $420b
   ; now we clear the High part
   ; the WRAM port is already in place
   ldx #<>DMAZero   ; this get the low word, you will need to change if not using 64tass
   stx $4302
   lda #`DMAZero    ; this gets the bank, you will need to change if not using 64tass
   sta $4304        ; and the upper byte will be 0
   ldx #32
   stx $4305
   lda #$01
   sta $420b
	plp
	rts
	
DMAOAMMirrorToOAM_ff
	php
	#XY16
	#A8
	ldx #$0402       ; A -> B, INC SOURCE, WRITE BYTE,BYTE TWICE | OAMDATA
   stx $4300
   stz $2102        ; START AT OAM $0000
   stz $2103        ; PRIORITY 0
   ldx #<>OAMMirror ; this get the low word, you will need to change if not using 64tass
   stx $4302
   lda #`OAMMirror  ; this gets the bank, you will need to change if not using 64tass
   sta $4304        ; and the upper byte will be 0
   ldx #512+32
   stx $4305
   lda #$01
   sta $420b
	plp
	rts

DMA240 .byte 240

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
   #A16
   .enc 'screen'
   lda #'{space}'+128  ; solid char
   ldx #62
-	sta ScreenMirror+(1*32*2),x
   ; sta ScreenMirror+(23*32*2),x <- remove this line
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
	#A8 ; return with A8 as promised
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
			
NMI_ISR
	#AXY16
	pha
	phx
	phy
	phb
	phk
	plb
   jsr DMAScreenToVRAM_ff
   jsr DMAOAMMirrorToOAM_ff
   #A8
   lda #$ff
   sta NMIDoneNF
   jsr getRND_ad ; throw away a random number to improve randomness
   #A16
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

Sprite_Chars .binary "sprite.chr"
Sprite_Pal .binary "sprite.pal"

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