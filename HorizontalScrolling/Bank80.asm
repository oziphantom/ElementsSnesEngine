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
	stz $802130 ;31
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
	jsr map_fillColumnBufferRightEdge_xx	; draw the right edge to the buffer
	jsr dmaColumn_xx								; put it the screen
	jsr map_advancePointersRightEdge_ra8	; move the right over, just the right
	lda MapVRAMRight								; have we done the screen + 1
	cmp #33
	bcc _loop										; no, go again

	#A8
	lda #fBGBaseSize(kVRAM.gameScreen,kBaseSize_64x32)
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
	bit #1					; right?
	beq _noRight
		#A16
		lda ScreenXOffset	; cache current Screen X offset
		sta MapTempWord
		clc
		adc #3				; x += 3
		sta ScreenXOffset
		eor MapTempWord	; if the bits are the same this will go to 0, not 0 otherwise
		and #$FFF8			; I only want to know if we have crossed over 8 pixels, i.e the 
		#A8					; upper 13 bits have changed, so mask away the lower 3bits (0-7)
		beq _noHold			; same, not crossed char boundary
			jsr map_fillColumnBufferRightEdge_xx	; draw current next edge
			jsr map_advancePointersRightEdge_ra8	; move right edge
			jsr map_advancePointersLeftEdge_ra8		; move left edge
			;#A8
			bra _noHold
_noRight
	bit #2					; left?
	beq _noLeft
		#A16
		lda ScreenXOffset	; cache current Screen X offset
		sta MapTempWord
		sec
		sbc #3				; X =- 3
		sta ScreenXOffset
		eor MapTempWord
		and #$FFF8			; have we gone over 8 barrier?
		#A8
		beq _noHold
			jsr map_fillColumnBufferLeftEdge_xx		; draw current next edge
			jsr map_retreatPointersRightEdge_ra8	; move right edge
			jsr map_retreatPointersLeftEdge_ra8		; move left edge
			;#A8
			bra _noHold
_noLeft  
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
	sep	#$20				; A8
	bit	$4210,b			 ; Ack NMI
	bit@W NMIReadyNF,b		; Check if this is safe
	bpl	_ready
		plb					; No, restore Data Bank
		rti					; Exit
_ready						; Safe
	rep	#$30				; A16 XY16
	pha
	phx
	phy						; Save A,X,Y
	phd						; Save the DP register
	lda	#0000				; or where ever you want your NMI DP
	tcd						; set DP to known value
	lda MapBufferTarget	; do we have something in the Map Column Buffer
	bmi _noColumnDMA
		jsr dmaColumn_xx	; draw it
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
	lda ScreenXOffset.lo ; update current X Scroll Offset
	sta $210d,b
	lda ScreenXOffset.hi
	sta $210d,b
	sep	#$20				; A8
	lda	#$FF				; Doing this is slightly faster than DEC, but 2 more bytes
	sta	NMIReadyNF		; set NMI Done Flag
	rep	#$30				; A16 XY16
	pld						; restore DP page
	ply
	plx
	pla						; Restore A,X,Y
	plb						; Restore Data Bank
justRTI
	rti						; Exit
; ----- @DMA functions@ -----

.section sDataBank
SpottyPal .binary "spotty.pal"		; this will be in bank 81
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
SpottyChars .binary "spotty.chr"		; this will be in bank 81
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
MapBlockIndexLeft		.byte ?				; the left edge block index
MapBlockIndexRight	.byte ?				; for the right
MapSubCharLeft			.byte ?				; which char in the block, pre multiplied by 2
MapSubCharRight		.byte ?
MapVRAMLeft				.DUNION HLWORD		; the top char memory location in VRAM
MapVRAMRight			.DUNION HLWORD
MapTempWord				.DUNION HLWORD		; used to hold data for the map functions
ScreenXOffset			.DUNION HLWORD		; current screen X scroll
MapBufferTarget		.DUNION HLWORD		; where we want NMI to dma the buffer to
.send ;sDP

.section sSharedWRAM
MapColumnBuffer .fill 32*2					; buffer of 32 chars to be DMA'd in the NMI
MapColumnBufferEnd = * - 1					; stack pushes then decs so we point to the last element
MapStackStore .word ?						; Temp store to hold the stack value for restoration
.send ; sSharedWRAM

.section sDataBank							; bank 81
MapData .block
	kRowLen = 243
	.union
	.binary "spotty.map"						; splice the map data by rows
	.struct
		Row1 .fill kRowLen
		Row2 .fill kRowLen
		Row3 .fill kRowLen
		Row4 .fill kRowLen
		Row5 .fill kRowLen
		Row6 .fill kRowLen
	.ends
	.endu
.bend	
BlockData .block
	col1 .binary "spotty_col1.blk"
	col2 .binary "spotty_col2.blk"
	col3 .binary "spotty_col3.blk"
	col4 .binary "spotty_col4.blk"
.bend
.send ; sDataBank

.databank `DataBankStart				; make sure we are back into the DataBank err Bank

map_InitEmptyScreen_xx
_ASSERT_JSR
	php
	#AXY8
	lda #255
	sta MapBlockIndexLeft		; left starts at the last map position, -1
	stz MapBlockIndexRight		; right starts at 0 so we can use the system
	lda #6							; to draw the screen by looping it
	sta MapSubCharLeft
	stz MapSubCharRight			; left  = block 255, subChar 6, VRAM column 63
	#AXY16							; right = block 0  , subChar 0, VRAM column 0
	lda #63
	sta MapVRAMLeft
	stz MapVRAMRight
	stz ScreenXOffset
	stz MapBufferTarget			; we want this to be negative, so set 0
	dec MapBufferTarget			; dec 1 to be -1
	plp
	rts

map_fillColumnBufferLeftEdge_xx
_ASSERT_JSR	
	php	
	#AXY16
	lda MapVRAMLeft			; which column do we need to write it to
	cmp #32						; 0-31 are $000 and then 32-63 are $400w plus
	bcc _justStore
		and #31
		adc #$3ff 				; C is set as per CMP so this add $400
_justStore						; if the vram was not at $0000 you would add the base here
	sta MapBufferTarget
	tsx	
	stx <MapStackStore,d			; save the stack	
	ldx #<>MapColumnBufferEnd
	txs								; set the stack to the buffer
	lda MapBlockIndexLeft		; which block do we want
	and #$ff							; convert word to byte
	tay
	lda MapSubCharLeft
	bra map_FillColumBufferEdgeCommon
	
map_fillColumnBufferRightEdge_xx
_ASSERT_JSR	
	php	
	#AXY16
	lda MapVRAMRight			; which column do we need to write it to
	cmp #32						; 0-31 are $000 and then 32-63 are $400w plus
	bcc _justStore
		and #31
		adc #$3ff 				; C is set as per CMP so this add $400
_justStore						; if the vram was not at $0000 you would add the base here
	sta MapBufferTarget
	tsx	
	stx <MapStackStore,d			; save the stack	
	ldx #<>MapColumnBufferEnd
	txs								; set the stack to the buffer
	lda MapBlockIndexRight		; which block do we want
	and #$ff							; convert word to byte
	tay
	lda MapSubCharRight
map_FillColumBufferEdgeCommon
	and #$ff
	tax
	jmp (+,x)
+ .word <>(_col1,_col2,_col3,_col4)
_col1
	tyx
	lda MapData.Row1,x			; get the block index
	#mMap_PushCol BlockData.col1
	lda MapData.Row2,x			; and row 2
	#mMap_PushCol BlockData.col1
	lda MapData.Row3,x			; and row 3
	#mMap_PushCol BlockData.col1
	lda MapData.Row4,x			; and row 4
	#mMap_PushCol BlockData.col1
	lda MapData.Row5,x			; and row 5
	#mMap_PushCol BlockData.col1
	lda MapData.Row6,x			; and row 6
	#mMap_PushCol BlockData.col1
	jmp _exit
_col2
	tyx
	lda MapData.Row1,x			; get the block index
	#mMap_PushCol BlockData.col2
	lda MapData.Row2,x			; and row 2
	#mMap_PushCol BlockData.col2
	lda MapData.Row3,x			; and row 3
	#mMap_PushCol BlockData.col2
	lda MapData.Row4,x			; and row 4
	#mMap_PushCol BlockData.col2
	lda MapData.Row5,x			; and row 5
	#mMap_PushCol BlockData.col2
	lda MapData.Row6,x			; and row 6
	#mMap_PushCol BlockData.col2
	jmp _exit	
_col3
	tyx
	lda MapData.Row1,x			; get the block index
	#mMap_PushCol BlockData.col3
	lda MapData.Row2,x			; and row 2
	#mMap_PushCol BlockData.col3
	lda MapData.Row3,x			; and row 3
	#mMap_PushCol BlockData.col3
	lda MapData.Row4,x			; and row 4
	#mMap_PushCol BlockData.col3
	lda MapData.Row5,x			; and row 5
	#mMap_PushCol BlockData.col3
	lda MapData.Row6,x			; and row 6
	#mMap_PushCol BlockData.col3
	jmp _exit
_col4
	tyx
	lda MapData.Row1,x			; get the block index
	#mMap_PushCol BlockData.col4
	lda MapData.Row2,x			; and row 2
	#mMap_PushCol BlockData.col4
	lda MapData.Row3,x			; and row 3
	#mMap_PushCol BlockData.col4
	lda MapData.Row4,x			; and row 4
	#mMap_PushCol BlockData.col4
	lda MapData.Row5,x			; and row 5
	#mMap_PushCol BlockData.col4
	lda MapData.Row6,x			; and row 6
	#mMap_PushCol BlockData.col4
_exit	
	ldx <MapStackStore
	txs							; restore stack
	plp
	rts	
		
dmaColumn_xx
	php	
	#A8
	#XY16	
	ldx MapBufferTarget		; set the target VRAM address
	stx $2116,b
	ldx #$FFFF
	stx MapBufferTarget		; clear the flag
	ldx #<>MapColumnBufferEnd
	stx $4302,b					; set the source as the last pos in the buffer
	#A8
	lda #`MapColumnBufferEnd
	sta $804304
	ldx #64						; 32 words
	stx $4305,b
	ldx #%00010001 | $1800	; A->B, Dec, Write WORD, $2118
	stx $4300,b
	lda #$81
	sta $2115,b					; inc VRAM port address by 32
	lda #1
	sta $420B,b
	plp
	rts

mMap_PushCol .macro col 		
	and #$ff
	asl a								; convert to word index
	asl a
	asl a								; x4 as each block is 4x4 words 
	tay		
	lda \col+0,y		; push col1 data
	pha
	lda \col+2,y
	pha
	lda \col+4,y
	pha
	lda \col+6,y
	pha	
.endm	


map_advancePointersRightEdge_ra8
_ASSERT_JSR
	#A8
	lda MapSubCharRight				; we shift the char by 2 as it stored as words
	clc
	adc #2
	sta MapSubCharRight
	cmp #8								; done a whole block? 4 chars?
	bcc _next
		inc MapBlockIndexRight		; move to the next block
		stz MapSubCharRight			; first column in it
	_next
	lda MapVRAMRight					; move the VRAM column over one as well
	clc
	adc #1
	and #63								; wrap to the screen
	sta MapVRAMRight
	rts
  
map_advancePointersLeftEdge_ra8
_ASSERT_JSR
	#A8
	lda MapSubCharLeft				; same as above but for the left edge
	clc
	adc #2
	sta MapSubCharLeft
	cmp #8
	bcc _next
		inc MapBlockIndexLeft
		stz MapSubCharLeft
	_next
	lda MapVRAMLeft
	clc
	adc #1
	and #63
	sta MapVRAMLeft
	rts
	
map_retreatPointersRightEdge_ra8
_ASSERT_JSR
	#A8
	lda MapSubCharRight			; sub 2 as we are dealing with words
	sec
	sbc #2
	sta MapSubCharRight
	bcs _next						; under flowed?
		dec MapBlockIndexRight	; previous block
		lda #6
		sta MapSubCharRight		; last column of it
	_next
	lda MapVRAMRight				; move VRAM column back 1
	sec
	sbc #1
	and #63							; wrap to VRAM memory
	sta MapVRAMRight
	rts
	
map_retreatPointersLeftEdge_ra8
_ASSERT_JSR
	#A8
	lda MapSubCharLeft			; same as above but for the left edge
	sec
	sbc #2
	sta MapSubCharLeft
	bcs _next
		dec MapBlockIndexLeft
		lda #6
		sta MapSubCharLeft
	_next
	lda MapVRAMLeft
	sec
	sbc #1
	and #63
	sta MapVRAMLeft
	rts