; Bank 80
.virtual $800000+gSharedRamStart
.dsection sSharedWRAM
.endv

.as               ; Assume A8
.xs               ; Assume X8
.autsiz           ; Auto size detect
.databank $00     ; databank is 00
.dpage $0000      ; dpage is 0000

RESET
    CLC
    XCE
    LDA #$01
    STA $420D
    JML RESETHi
RESETHi
    REP #$30        ; AXY 16
    LDX #$1FFF
    TXS
    PHK
    PLB
.databank $80
    LDA #0000
    TCD
    LDA #$008F      ; FORCE BLANK, SET OBSEL TO 0
    STA $802100
ClearWRAM
    LDA #$8008      ; A -> B, FIXED SOURCE, WRITE BYTE | WRAM
    STA $804300
    LDA #<>DMAZero  ; 64Tass | get low word
    STA $804302
    LDA #`DMAZero   ; 64Tass | get bank
    STA $804304
    STZ $802181
    STZ $802182     ; START AT 7E:0000
    STZ $804305     ; DO 64K
    LDA #$0001
    STA $80420B     ; FIRE DMA
    STA $80420B     ; FIRE IT AGAIN, FOR NEXT 64k
InitSNESAndMirror
    REP #$20        ; a16
    LDA #$008F      ; FORCE BLANK, SET OBSEL TO 0
    STA $802100
    STA mINIDISP
    ;STZ mOBSEL
    STZ $802105 ;6
    ;STZ mBGMODE
    ;STZ mMOSIAC
    STZ $802107 ;8
    ;STZ mBG1SC
    ;STZ mBG2SC
    STZ $802109 ;A
    ;STZ mBG3SC
    ;STZ mBG4SC
    STZ $80210B ;C
    ;STZ mBG12NBA
    ;STZ mBG23NBA
    STZ $80210D ;E
    STZ $80210D ;E
    ;STZ mBG1HOFS
    ;STZ mBG1VOFS
    STZ $80210F ;10
    STZ $80210F ;10
    ;STZ mBG2HOFS
    ;STZ mBG2VOFS
    STZ $802111 ;12
    STZ $802111 ;12
    ;STZ mBG3HOFS
    ;STZ mBG3VOFS
    STZ $802113 ;14
    STZ $802113 ;14
    ;STZ mBG4HOFS
    ;STZ mBG4VOFS
    STZ $802119 ;1A to get Mode7
    STZ $80211B ;1C these are write twice
    STZ $80211B ;1C regs
    STZ $80211D ;1E
    STZ $80211D ;1E
    STZ $80211F ;20
    STZ $80211F ;20
    ; add mirrors here if you are doing mode7
    STZ $802123 ;24
    ;STZ mW12SEL
    ;STZ mW34SEL
    STZ $802125 ;26
    ;STZ mWOBJSEL
    STZ $802126 ;27 YES IT DOUBLES OH WELL
    STZ $802128 ;29
    ;STZ mWH0
    ;STZ mWH1
    ;STZ mWH2
    ;STZ mWH3
    STZ $80212A ;2B
    ;STZ mWBGLOG
    ;STZ mOBJLOG
    STZ $80212C ;2D
    STZ $80212E ;2F
    ;STZ mTM
    ;STZ mTS
    ;STZ mTMW
    ;STZ mTSW
    LDA #$00E0
    STA $802132
    STA mCOLDATA
    ;STZ mSETINI
    ;ONTO THE CPU I/O REGS
    LDA #$FF00
    STA $804201
    ;STZ mNMITIMEN
    STZ $804202 ;3
    STZ $804204 ;5
    STZ $804206 ;7
    STZ $804208 ;9
    STZ $80420A ;B
    STZ $80420C ;D
    ; CLEAR VRAM
    REP #$20       ; A16
    LDA #$1809     ; A -> B, FIXED SOURCE, WRITE WORD | VRAM
    STA $804300
    LDA #<>DMAZero ; THIS GET THE LOW WORD, YOU WILL NEED TO CHANGE IF NOT USING 64TASS
    STA $804302
    LDA #`DMAZero  ; THIS GETS THE BANK, YOU WILL NEED TO CHANGE IF NOT USING 64TASS
    STA $804304    ; AND THE UPPER BYTE WILL BE 0
    STZ $804305    ; DO 64K
    LDA #$80       ; INC ON HI WRITE
    STA $802115
    STZ $802116    ; START AT 00
    LDA #$01
    STA $80420B    ; FIRE DMA
    ; CLEAR CG-RAM
    LDA #$2208     ; A -> B, FIXED SOURCE, WRITE BYTE | CG-RAM
    STA $804300
    LDA #$200      ; 512 BYTES
    STA $804305
    SEP #$20       ; A8
    STZ $802121    ; START AT 0
    LDA #$01
    STA $80420B    ; FIRE DMA
    STZ NMIReadyNF
    CLI
    ; do bunch of other things here
    ; set up VRAM
    ; copy data
    ; enable NMI VBlank etc

MainLoop
    SEP   #$20                ; A8
MainLoopWait
    LDA   NMIReadyNF
    BPL   MainLoopWait        ; Read Flag
    STZ   NMIReadyNF        ; Clear Flag
    ; code here
    JMP   MainLoop
 
.section sDP
NMIReadyNF .byte ?
.send ; sDP

.section sSharedWRAM
mINIDISP  .word ?
mOBSEL    .word ?
mBGMODE   .word ?
mMOSIAC   .word ?
mBG1SC    .word ?
mBG2SC    .word ?
mBG3SC    .word ?
mBG4SC    .word ?
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
mW12SEL   .word ?
mW34SEL   .word ?
mWOBJSEL  .word ?
mWH0      .word ?
mWH1      .word ?
mWH2      .word ?
mWH3      .word ?
mWBGLOG   .word ?
mOBJLOG   .word ?
mTM       .word ?
mTS       .word ?
mTMW      .word ?
mTSW      .word ?
mCOLDATA  .word ?
mSETINI   .word ?
mNMITIMEN .word ?
.send  ; sSharedWRAM


DMAZero .word $0000

NMI
    JML NMIFast               ; Move To 8X:XXXX for speed
NMIFast
    PHB                       ; Save Data Bank
    PHK
    PLB                       ; Set Data Bank to Match Program Bank
    SEP   #$20                ; A8
    BIT   $804210             ; Ack NMI
    BIT@W NMIReadyNF,b        ; Check if this is safe
    BPL   _ready
        PLB                   ; No, restore Data Bank
        RTI                   ; Exit
_ready                        ; Safe
    REP   #$30                ; A16 XY16
    PHA
    PHX
    PHY                       ; Save A,X,Y
    PHD                       ; Save the DP register
    LDA   #0000               ; or where ever you want your NMI DP
    TCD                       ; set DP to known value
    ; do update code here
    SEP   #$20                ; A8
    LDA   #$FF                ; Doing this is slightly faster than DEC, but 2 more bytes
    STA   NMIReadyNF          ; set NMI Done Flag
    REP   #$30                ; A16 XY16
    PLD                       ; restore DP page
    PLY
    PLX
    PLA                       ; Restore A,X,Y
    PLB                       ; Restore Data Bank
justRTI
    RTI                       ; Exit


