; Bank 80
.virtual $800000+gSharedRamStart
.dsection sSharedWRAM
.endv

kVRAM .block
	gameScreen		= $0000/2
	font				= $1000/2
	gameChars		= $2000/2
.bend

.as					; Assume A8
.xs					; Assume X8
.autsiz				; Auto size detect
.databank $00	 	; databank is 00
.dpage $0000		; dpage is 0000

RESET
	clc
	xce
	lda #$01
	sta $420D
	jml RESETHi
RESETHi
	rep #$30			; AXY 16
	ldx #$1FFF
	txs
	phk
	plb
.databank $80
	lda #0000
	tcd
	lda #$008F		; FORCE BLANK, SET OBSEL TO 0
	sta $802100
ClearWRAM
	lda #$8008		; A -> B, FIXED SOURCE, WRITE BYTE | WRAM
	sta $804300
	lda #<>DMAZero	; 64Tass | get low word
	sta $804302
	lda #`DMAZero	; 64Tass | get bank
	sta $804304
	stz $802181
	stz $802182		; START AT 7E:0000
	stz $804305		; DO 64K
	lda #$0001
	sta $80420B		; FIRE DMA
	sta $80420B		; FIRE IT AGAIN, FOR NEXT 64k
InitSNESAndMirror
	rep #$20			; a16
	lda #$008F		; FORCE BLANK, SET OBSEL TO 0
	sta $802100
	sta mINIDISP
	;stz mOBSEL
	stz $802105 	;6
	;stz mBGMODE
	;stz mMOSIAC
	stz $802107		;8
	;stz mBG1SC
	;stz mBG2SC
	stz $802109		;A
	;stz mBG3SC
	;stz mBG4SC
	stz $80210B		;C
	;stz mBG12NBA
	;stz mBG23NBA
	stz $80210D		;E
	stz $80210D		;E
	;stz mBG1HOFS
	;stz mBG1VOFS
	stz $80210F		;10
	stz $80210F		;10
	;stz mBG2HOFS
	;stz mBG2VOFS
	stz $802111		;12
	stz $802111		;12
	;stz mBG3HOFS
	;stz mBG3VOFS
	stz $802113		;14
	stz $802113		;14
	;stz mBG4HOFS
	;stz mBG4VOFS
	stz $802119 ;1A to get Mode7
	stz $80211B ;1C these are write twice
	stz $80211B ;1C regs
	stz $80211D ;1E
	stz $80211D ;1E
	stz $80211F ;20
	stz $80211F ;20
	; add mirrors here if you are doing mode7
	stz $802123 ;24
	;stz mW12SEL
	;stz mW34SEL
	stz $802125 ;26
	;stz mWOBJSEL
	stz $802126 ;27 YES IT DOUBLES OH WELL
	stz $802128 ;29
	;stz mWH0
	;stz mWH1
	;stz mWH2
	;stz mWH3
	stz $80212A ;2B
	;stz mWBGLOG
	;stz mOBJLOG
	stz $80212C ;2D
	stz $80212E ;2F
	;stz mTM
	;stz mTS
	;stz mTMW
	;stz mTSW
	lda #$00E0
	sta $802132
	sta mCOLDATA
	;stz mSETINI
	;ONTO THE CPU I/O REGS
	lda #$FF00
	sta $804200
	;stz mNMITIMEN
	stz $804202 ;3
	stz $804204 ;5
	stz $804206 ;7
	stz $804208 ;9
	stz $80420A ;B
	stz $80420C ;D
	; CLEAR VRAM
	rep #$20			; A16
	lda #$1809		; A -> B, FIXED SOURCE, WRITE WORD | VRAM
	sta $804300
	lda #<>DMAZero	; THIS GET THE LOW WORD, YOU WILL NEED TO CHANGE IF NOT USING 64TASS
	sta $804302
	lda #`DMAZero	; THIS GETS THE BANK, YOU WILL NEED TO CHANGE IF NOT USING 64TASS
	sta $804304		; AND THE UPPER BYTE WILL BE 0
	stz $804305		; DO 64K
	lda #$80			; INC ON HI WRITE
	sta $802115
	stz $802116		; START AT 00
	lda #$01
	sta $80420B		; FIRE DMA
	; CLEAR CG-RAM
	lda #$2208		; A -> B, FIXED SOURCE, WRITE BYTE | CG-RAM
	sta $804300
	lda #$200		; 512 BYTES
	sta $804305
	sep #$20			; A8
	stz $802121		; START AT 0
	lda #$01
	sta $80420B		; FIRE DMA
	stz NMIReadyNF
	cli
	jsr dmaPalletes_xx		; install the game pallete
	jsr dmaLevelChars_xx		; install the char set
	#A8
	lda #`DataBankStart
	pha
	plb								; set the data bank to the common bank
.databank `DataBankStart		; tell the assembler as well
	jsr map_InitEmptyScreen_xx	; reset the map pointers
_loop
	jsr map_fillRowBufferTopEdge_xx		; draw the right edge to the buffer
	jsr dmaRow_xx								; put it the screen
	jsr map_retreatPointersTopEdge_ra16	; move the right over, just the right
	;#A16
	.al
	lda MapVRAMTop								; have we done the screen + 1
	cmp #32*32
	bne _loop									; no, go again
	#A8
	lda #fBGBaseSize(kVRAM.gameScreen,kBaseSize_32x64)
	sta $2107,b									; set the BG1 to the Game Screen
	lda #fBGCharAddress(kVRAM.gameChars,0,0,0) 
	sta $210b,b									; set the chars to the in game set
	lda #1
	sta $2105,b									; mode 1
	lda #%00000001
	sta $212C,b									; make BG1 on Main Screen
	lda #%10000001
	sta $4200,b									; enable VBlank NMI and enable auto Joypad reading
	lda #$0f
	sta $2100,b									; turn screen on

; ----- @Main Loop@ -----
MainLoop
	#A8
MainLoopWait
	lda NMIReadyNF
	bpl MainLoopWait		; Read Flag
	stz NMIReadyNF			; Clear Flag
	lda JoyHi
	bit #4					; down
	beq _noDown
		#A16
		lda ScreenYOffset	; cache current Screen Y offset
		sta MapTempWord
		clc
		adc #3				; Y += 3
		sta ScreenYOffset
		eor MapTempWord	; if the bits are the same this will go to 0, not 0 otherwise
		and #$FFF8			; I only want to know if we have crossed over 8 pixels, i.e the 
		#A8					; upper 13 bits have changed, so mask away the lower 3bits (0-7)
		beq _noHold			; same, not crossed char boundary
			jsr map_fillRowBufferBotEdge_xx		; draw current next edge
			jsr map_advancePointersTopEdge_ra16	; move top edge
			jsr map_advancePointersBotEdge_ra16	; move bottom edge
			#A8
			bra _noHold
_noDown
	bit #8					; up
	beq _noUp
		#A16
		lda ScreenYOffset	; cache current Screen Y offset
		sta MapTempWord
		sec
		sbc #3				; Y =- 3
		sta ScreenYOffset
		eor MapTempWord
		and #$FFF8			; have we gone over 8 barrier?
		#A8
		beq _noHold
			jsr map_fillRowBufferTopEdge_xx		; draw current next edge
			jsr map_retreatPointersTopEdge_ra16	; move top edge
			jsr map_retreatPointersBotEdge_ra16	; move bottom edge
			#A8
			bra _noHold
_noUp  
_noHold
	jmp	MainLoop
 
.section sDP
NMIReadyNF		.byte ?
JoyHi				.byte ?
JoyHiOld			.byte ?
JoyHiEvent		.byte ?
JoyHoldCounter .byte ?
.send ; sDP

.section sSharedWRAM
mINIDISP  .word ?
mOBSEL	.word ?
mBGMODE	.word ?
mMOSIAC	.word ?
mBG1SC	.word ?
mBG2SC	.word ?
mBG3SC	.word ?
mBG4SC	.word ?
mBG12NBA  .word ?
mBG23NBA  .word ?
mBG1HOFS  .dunion HLWord
mBG1VOFS  .dunion HLWord
mBG2HOFS  .dunion HLWord
mBG2VOFS  .dunion HLWord
mBG3HOFS  .dunion HLWord
mBG3VOFS  .dunion HLWord
mBG4HOFS  .dunion HLWord
mBG4VOFS  .dunion HLWord
mW12SEL	.word ?
mW34SEL	.word ?
mWOBJSEL  .word ?
mWH0	  .word ?
mWH1	  .word ?
mWH2	  .word ?
mWH3	  .word ?
mWBGLOG	.word ?
mOBJLOG	.word ?
mTM		.word ?
mTS		.word ?
mTMW	  .word ?
mTSW	  .word ?
mCOLDATA  .word ?
mSETINI	.word ?
mNMITIMEN .word ?
.send  ; sSharedWRAM


DMAZero .word $0000

NMI
	jml NMIFast				; Move To 8X:XXXX for speed
NMIFast
	phb						; Save Data Bank
	lda #`DataBankStart
	pha
	plb						; Set Data Bank to default databank
.databank `DataBankStart
	sep #$20				; A8
	bit $4210,b			; Ack NMI
	bit@W NMIReadyNF,b	; Check if this is safe
	bpl _ready
		plb					; No, restore Data Bank
		rti					; Exit
_ready						; Safe
	rep #$30					; A16 XY16
	pha
	phx
	phy						; Save A,X,Y
	phd						; Save the DP register
	lda #0000				; or where ever you want your NMI DP
	tcd						; set DP to known value
	lda MapBufferTarget	; do we have something in the Map Column Buffer
	bmi _noColumnDMA
		jsr dmaRow_xx		; draw it
_noColumnDMA
	#A8
	lda #1					; since we don't have an OAM DMA to stall the start
-	bit $4212,b				; of the NMI, we have to wait for the joypad registers
	bne -						; to be valid.
	lda JoyHi				; read the joypad
	sta JoyHiOld			; for this example I only care about Left and Right
	lda $4219,b				; so I only read the upper 8 bits
	sta JoyHi
	and JoyHiOld
	eor JoyHi
	sta JoyHiEvent			; generate down event, this was handy for testing
	lda ScreenYOffset.lo ; update current Y Scroll Offset
	sta $210e,b
	lda ScreenYOffset.hi
	sta $210e,b
	sep #$20					; A8
	lda #$FF					; Doing this is slightly faster than DEC, but 2 more bytes
	sta NMIReadyNF			; set NMI Done Flag
	rep #$30					; A16 XY16
	pld						; restore DP page
	ply
	plx
	pla						; Restore A,X,Y
	plb						; Restore Data Bank
justRTI
	rti						; Exit
; ----- @DMA functions@ -----

.section sDataBank
SpottyPal .binary "outlaw.pal"		; this will be in bank 81
.send ;sDataBank

dmaPalletes_xx
_ASSERT_JSR
	php
		#A8									; DMA the Charset pallete which is 16 colours to slot 0
		#XY16
		ldx #<>SpottyPal
		stx $4302,b
		lda #`SpottyPal
		sta $4304,b
		ldx #32
		stx $4305,b
		ldx #%00000010 | $2200			; A->B, Inc, Write 2 Bytes, $2122
		stx $4300,b
		stz $2121,b							; start of Pallete
		lda #1
		sta $420B,b
	plp
	rts

.section sDataBank
SpottyChars .binary "outlaw.chr"		; this will be in bank 81
.send ;sDataBank

dmaLevelChars_xx
_ASSERT_JSR
	php
		#AXY16								; this copies the per level chars
		lda #<>SpottyChars
		sta $4302,b
		#A8
		lda #`SpottyChars
		sta $4304,b
		ldx #size(SpottyChars)
		stx $4305,b
		ldx #%00000001 | $1800			; A->B, Inc, Write WORD, $2118
		stx $4300,b
		ldx #kVRAM.gameChars
		stx $2116,b
		lda #$80
		sta $2115,b							; inc VRAM port address
		lda #1
		sta $420B,b
	plp
	rts

; ----- @Map Functions@ -----
.section sDP
MapBlockIndexTop	.word ?				; the left edge block index
MapBlockIndexBot	.word ?				; for the right
MapSubRowTop		.byte ?				; which row in the block, pre multiplied by 2
MapSubRowBot		.byte ?
MapVRAMTop			.DUNION HLWORD		; the top char memory location in VRAM
MapVRAMBot			.DUNION HLWORD
MapTempWord			.DUNION HLWORD		; used to hold data for the map functions
ScreenYOffset		.DUNION HLWORD		; current screen X scroll
MapBufferTarget	.DUNION HLWORD		; where we want NMI to dma the buffer to
.send ;sDP

.section sSharedWRAM
MapColumnBuffer .fill 40*2					; buffer of 32 chars to be DMA'd in the NMI
MapColumnBufferEnd = * - 1					; stack pushes then decs so we point to the last element
MapStackStore .word ?						; Temp store to hold the stack value for restoration
.send ; sSharedWRAM

.section sDataBank							; bank 81
MapData .block
	kColLen = 512
	col1 .binary "outlaw_col0.map"
	col2 .binary "outlaw_col1.map"
	col3 .binary "outlaw_col2.map"
	col4 .binary "outlaw_col3.map"
	col5 .binary "outlaw_col4.map"
	col6 .binary "outlaw_col5.map"
	col7 .binary "outlaw_col6.map"
	col8 .binary "outlaw_col7.map"
.bend	
BlockData .block
	row1 .binary "outlaw_row1.blk"
	row2 .binary "outlaw_row2.blk"
	row3 .binary "outlaw_row3.blk"
	row4 .binary "outlaw_row4.blk"
	row5 .binary "outlaw_row5.blk"
.bend
.send ; sDataBank

.databank `DataBankStart				; make sure we are back into the DataBank err Bank

map_InitEmptyScreen_xx
_ASSERT_JSR
	php
	#AXY8
	lda #8							; to draw the screen by looping it
	sta MapSubRowTop
	stz MapSubRowBot				; top    = block 511, subChar 4, VRAM row 63
	#AXY16							; bottom = block 512, subChar 0, VRAM row 0
	lda #512
	sta MapBlockIndexBot			; bot starts at the last map position, -1
	lda #511
	sta MapBlockIndexTop			; top starts at 511 so we can use the system
	lda #63*32
	sta MapVRAMTop
	stz MapVRAMBot
	lda #512-224
	sta ScreenYOffset				; start the Y at the bottom of the screen
	stz MapBufferTarget			; we want this to be negative, so set 0
	dec MapBufferTarget			; dec 1 to be -1
	plp
	rts
	
map_fillRowBufferTopEdge_xx
_ASSERT_JSR
	php
	#AXY16
	lda MapVRAMTop			; which row do we need to write it to
	sta MapBufferTarget	; MapVramTop is premultiplied by 32
	tsx
	stx <MapStackStore,d
	ldx #<>MapColumnBufferEnd
	txs								; set the stack to the buffer
	ldy MapBlockIndexTop			; which block do we want
	lda MapSubRowTop	
	and #$ff	
	tax	
	bra map_fillRowBufferEdgeCommon	

map_fillRowBufferBotEdge_xx
_ASSERT_JSR
	php
	#AXY16
	lda MapVRAMBot			; which row do we need to write it to
	sta MapBufferTarget	; MapVRAMBot is premultiplied by 32
	tsx
	stx <MapStackStore,d
	ldx #<>MapColumnBufferEnd
	txs								; set the stack to the buffer
	ldy MapBlockIndexBot			; which block do we want
	lda MapSubRowBot
	and #$ff	
	tax
; bra map_fillRowBufferEdgeCommon		
; fall through
map_fillRowBufferEdgeCommon
	jmp (+,x)
+ .word <>(_Row1,_Row2,_Row3,_Row4,_Row5)
_Row1
	#mColRowPlot MapData.col8,BlockData.row1
	#mColRowPlot MapData.col7,BlockData.row1
	#mColRowPlot MapData.col6,BlockData.row1
	#mColRowPlot MapData.col5,BlockData.row1
	#mColRowPlot MapData.col4,BlockData.row1
	#mColRowPlot MapData.col3,BlockData.row1
	#mColRowPlot MapData.col2,BlockData.row1
	#mColRowPlot MapData.col1,BlockData.row1
	jmp _exit
_Row2
	#mColRowPlot MapData.col8,BlockData.row2
	#mColRowPlot MapData.col7,BlockData.row2
	#mColRowPlot MapData.col6,BlockData.row2
	#mColRowPlot MapData.col5,BlockData.row2
	#mColRowPlot MapData.col4,BlockData.row2
	#mColRowPlot MapData.col3,BlockData.row2
	#mColRowPlot MapData.col2,BlockData.row2
	#mColRowPlot MapData.col1,BlockData.row2
	jmp _exit
_Row3
	#mColRowPlot MapData.col8,BlockData.row3
	#mColRowPlot MapData.col7,BlockData.row3
	#mColRowPlot MapData.col6,BlockData.row3
	#mColRowPlot MapData.col5,BlockData.row3
	#mColRowPlot MapData.col4,BlockData.row3
	#mColRowPlot MapData.col3,BlockData.row3
	#mColRowPlot MapData.col2,BlockData.row3
	#mColRowPlot MapData.col1,BlockData.row3
	jmp _exit
_Row4
	#mColRowPlot MapData.col8,BlockData.row4
	#mColRowPlot MapData.col7,BlockData.row4
	#mColRowPlot MapData.col6,BlockData.row4
	#mColRowPlot MapData.col5,BlockData.row4
	#mColRowPlot MapData.col4,BlockData.row4
	#mColRowPlot MapData.col3,BlockData.row4
	#mColRowPlot MapData.col2,BlockData.row4
	#mColRowPlot MapData.col1,BlockData.row4
	jmp _exit
_Row5
	#mColRowPlot MapData.col8,BlockData.row5
	#mColRowPlot MapData.col7,BlockData.row5
	#mColRowPlot MapData.col6,BlockData.row5
	#mColRowPlot MapData.col5,BlockData.row5
	#mColRowPlot MapData.col4,BlockData.row5
	#mColRowPlot MapData.col3,BlockData.row5
	#mColRowPlot MapData.col2,BlockData.row5
	#mColRowPlot MapData.col1,BlockData.row5
_exit
	ldx <MapStackStore
	txs							; restore stack
	plp
	rts	
	
mColRowPlot .macro col, row
	lda \col,y
	and #$ff
	sta MapTempWord
	asl a
	asl a
	adc MapTempWord; x5
	asl a ; x10
	tax
	;ldx #10 ; tile 1
	lda \row+8,x
	pha
	lda \row+6,x
	pha
	lda \row+4,x
	pha
	lda \row+2,x
	pha
	lda \row,x
	pha
.endm
	
dmaRow_xx
	php	
	#A8
	#XY16	
	ldx MapBufferTarget		; set the target VRAM address
	stx $2116,b
	ldx #$FFFF
	stx MapBufferTarget		; clear the flag
	ldx #<>MapColumnBuffer+8
	stx $4302,b					; set the source as the last pos in the buffer
	#A8
	lda #`MapColumnBuffer
	sta $804304
	ldx #64						; 32 words
	stx $4305,b
	ldx #%00000001 | $1800	; A->B, Inc, Write WORD, $2118
	stx $4300,b
	lda #$80
	sta $2115,b					; inc VRAM port address by 1
	lda #1
	sta $420B,b
	plp
	rts

map_advancePointersTopEdge_ra16
_ASSERT_JSR
	#A8
	lda MapSubRowTop					; we shift the char by 2 as it stored as words
	clc
	adc #2
	sta MapSubRowTop
	cmp #10								; done a whole block? 5 chars?
	bcc _next
		stz MapSubRowTop				; first row in it
		#A16
		inc MapBlockIndexTop			; move to the next block
	_next
	#A16
	lda MapVRAMTop						; move the VRAM row down one as well
	clc
	adc #32								; move to the next line
	and #$7ff							; wrap to the screen
	sta MapVRAMTop
	rts
  
map_advancePointersBotEdge_ra16
_ASSERT_JSR
	#A8
	lda MapSubRowBot					; same as above but for the bottom edge
	clc
	adc #2
	sta MapSubRowBot
	cmp #10
	bcc _next
		stz MapSubRowBot
		#A16
		inc MapBlockIndexBot		
	_next
	#A16
	lda MapVRAMBot
	clc
	adc #32
	and #$7ff
	sta MapVRAMBot
	rts
	
map_retreatPointersTopEdge_ra16
_ASSERT_JSR
	#A8
	lda MapSubRowTop				; sub 2 as we are dealing with words
	sec
	sbc #2
	sta MapSubRowTop
	bcs _next						; under flowed?
		lda #8
		sta MapSubRowTop			; last row of it
		#A16
		dec MapBlockIndexTop		; previous block		
	_next
	#A16
	lda MapVRAMTop					; move VRAM row back 1
	sec
	sbc #32
	and #$7ff						; wrap to VRAM memory
	sta MapVRAMTop
	rts
	
map_retreatPointersBotEdge_ra16
_ASSERT_JSR
	#A8
	lda MapSubRowBot				; sub 2 as we are dealing with words
	sec
	sbc #2
	sta MapSubRowBot
	bcs _next						; under flowed?
		lda #8
		sta MapSubRowBot			; last row of it
		#A16
		dec MapBlockIndexBot		; previous block
	_next
	#A16
	lda MapVRAMBot					; move VRAM row back 1
	sec
	sbc #32
	and #$7ff						; wrap to VRAM memory
	sta MapVRAMBot
	rts
