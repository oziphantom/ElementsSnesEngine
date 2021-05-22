; ----- @Sprite Engine@ -----
.section sSharedWRAM
OAMMirror .fill 256*2
OAMMirrorHigh .fill 32
.send ; sSharedWRAM


dmaOAM_xx
   PHP
   REP #$10          ; XY 16
   SEP #$20          ; A 8
   STZ $802102       ; OAM is zero
   STZ $802103       ; A is 8bits LDX #0000 STX ABS is slower     
   LDX #$0400        ; A -> B, INC, Write BYTE | OAM    
   STX $804310
   LDX #<>OAMMirror  ; THIS GET THE LOW WORD, YOU WILL NEED TO CHANGE IF NOT USING 64TASS
   STX $804312
   LDX #$207E        ; We want bank 7e and we are trasfereing 512+32 bytes
   STX $804314
   LDA #$02
   STA $804316
   STA $80420B      ; DMA channel 1 saves a load
   PLP
   RTS

SpriteEmptyVal   .byte 224
SpriteUpperEmpty .byte $55

;Startup
JSR clearSpritesMirror_xx
JSR dmaOAM_xx

clearSpritesMirror_xx
   PHP
   REP #$10                       ; XY 16
   SEP #$20                       ; A 8
   ; Do Main 256 words 
   LDX #$8018                     ; A -> B, FIXED SOURCE, WRITE BYTE | WRAM
   STX $804310
   LDX #<>SpriteEmptyVal          ; THIS GETS THE LOW WORD, YOU WILL NEED TO CHANGE IF NOT USING 64TASS
   STX $804312
   LDX #`SpriteEmptyVal           ; THIS GETS THE BANK, YOU WILL NEED TO CHANGE IF NOT USING 64TASS
   STX $804314                    ; AND THE UPPER BYTE WILL BE 0
   LDX #<>OAMMirror
   STX $802181
   STZ $802183                    ; START AT OAM
   LDA #2
   STA $804316                    ; DO 512 BYTES
   STA $80421B                    ; FIRE DMA
; Do upper 16 words
;   LDX #$8018                    ; A -> B, FIXED SOURCE, WRITE BYTE | WRAM
;   STX $804310
   LDX #<>SpriteUpperEmpty        ; THIS GET THE LOW WORD, YOU WILL NEED TO CHANGE IF NOT USING 64TASS
   STX $804312
   LDX #(32<<8)|`SpriteUpperEmpty ; THIS GETS THE BANK, YOU WILL NEED TO CHANGE IF NOT USING 64TASS
   STX $804314                    ; AND THE UPPER BYTE WILL BE 32
   STZ $804316                    ; DO 32 BYTES
;   LDX #<>OAMMirrorHigh
;   STX $802181                   ; IF THIS IS DIRECTLY AFTER LO, WRAM ALREADY POINTS TO IT
;   STZ $802183                   ; START AT HIGH
;   LDA #$02
   STA $80420B                    ; FIRE DMA
   PLP
   RTS
