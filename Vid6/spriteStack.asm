; THIS IS PSUDEO CODE NOT THE COMPLETE
; ASM, AS IT WILL VARY DEPENDING UPON
; YOUR NEEDS

    ; Set DP to OAMMirrorUpperBits
    ; set Stack to OAMMirror+511
; X Holds Current Conceptual Sprite Index 
; Y Holds Offset into Bank For Current Meta Sprite
    LDA $8000,Y              ; read the number of Frames in this sprite
    STA Counter              ; This needs to be ABS
    LDA #3
    STA HighCounter          ; keep count of each 4 sprites
_metaLoop
    REP #$20                 ; I'm doing 16 bit maths for ease of demonstration
; Do X
    PHX                      ; borrow byte from sprites
    TXA
    ASL A
    TAX
    LDA Concept.X,X
    PLX                      ; restore X
    BIT Concept.Attributes,X ; store your flipped needs in attributes
    BVS _XFlipped            ; branch on Bit 6 set
    CLC
    ADC $8001,Y              ; Your maths will need to be better
    BRA +
_XFlipped
    SEC
    SBC $8001,Y
+   SEP #$20                 ; needs to be 8 bits for this
    PHA                      ; write the X to Mirror
    XBA                      ; for this I'm just assuming 16 bit maths, no sign extend etc
    LSR A                    ; this is just to show the 'point' ;)
    ROR $00                  ; push the upper 9th bit in to Mirror Upper Bits
; DO Y
    LDA $8002,Y              ; read Y Delta
    CLC                      ; should actually be clear already
    ADC Concept.Y,X          ; offset by Base Y
    PHA                      ; Write Y to the Mirror
    LDA Concept.Tile,X       ; If you have dynamic tiles you need to offset other wise skip
    ADC $8003,Y              ; if no delta on this, just LDA it
    PHA                      ; Write  Tile
    LDA Concept.Attributes,X ; Get base extra Attributes
    CLC
    ADC $8004,Y              ; Add any deltas and 9th tile bit
    PHA                      ; Write Attributes
    LDA $8005,y              ; Read Size
    LSR A
    ROR $00                  ; Set Size
    TYA
    CLC                      ; This will be 0 actually
    ADC #5                   ; offset to next Meta
    TAY
    DEC HighCounter          ; Dec high counter
    BNE _Normal
        TDC
        INC A                ; advance DP by 1
        TCD                 
        DEX                  ; DP+1 moves X forward one, so DEX to restore
_Normal
    DEC Counter
    BPL _metaLoop
    INX
    CPX NumConcpetualSprites
    BNE _metaLoop
    ; restore DP, Stack, DBR etc

; WARNING THIS CODE IS OFF THE TOP OF MY HEAD SO
; MIGHT HAVE A BUG IN IT
; BUT ITS TO SHOW THE CONCEPT MORE THAN ANYTHING


43x0h - DMAPx - DMA/HDMA Parameters (R/W)

  7     Transfer Direction (0=A:CPU to B:I/O, 1=B:I/O to A:CPU)
  6     Addressing Mode    (0=Direct Table, 1=Indirect Table)    (HDMA only)
  5     Not used (R/W) (unused and unchanged by all DMA and HDMA)
  4-3   A-BUS Address Step  2=Decrement <------
  2-0   Transfer Unit Select (0-4=see below, 5-7=Reserved)

DMA OAM Mirror + 511 Backwards -> OAM 0000
DMA OAM Mirror Upper Bits Forwards -> OAM 256


Concept .struct
    X .fill 64           ; this is messy with 16 bit maths though
    Y .fill 32
    Tile .fill 32
    Attributes .fill 32
.ends
