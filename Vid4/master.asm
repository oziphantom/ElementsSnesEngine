; LoROM FAST SNES Master
.cpu "65816"

; setup the ROM MAP
* = $000000        ; FILE OFFSET
.logical $808000   ; SNES ADDRESS
.dsection sBank80
.cerror * > $80FFB0, "Bank 80 overflow by ", *-$80FFB0
* = $80FFB0
.dsection sHeader
*= $80FFE4
.dsection s65816Vectors
*= $80FFF4
.dsection s6502Vectors
.here              ; back to file


* = $008000        ; FILE OFFSET
.logical $818000   ; SNES ADDRESS
.dsection sBank81
.here
.cerror * > $10000, "Bank 81 overflow by ", *-$10000

* = $010000        ; FILE OFFSET
.logical $828000   ; SNES ADDRESS
.dsection sBank82
.here
.cerror * > $18000, "Bank 82 overflow by ", *-$18000

; .. add more banks here ..


; *** virtual address ***
; these exist to the code but are not part of the output file
*=$0000
.dsection sDP
.cerror * > $100, "Direct Page overflow by ", *-$100
gSharedRamStart
.dsection sSharedWRAM
.cerror * > $1FC0, "Shared WRAM overflow by ", *-$1FC0
*=$7e2000
.dsection sLoWRAM
.cerror * > $7F0000, "Lo WRAM overflow by ", *-$7F0000
*=$7f0000
.dsection sHiWRAM
.cerror * > $800000, "High WRAM overflow by ", *-$800000


.section sDP
    ZPTemp1 .byte ?
    ZPTemp2 .byte ?
    ZPTemp3 .byte ?
    ZPTemp4 .byte ?
    ZPTemp5 .byte ?
    ZPTemp6 .byte ?
.send

; *** instance headers and vectors 
.section sHeader
    .word 0
    .text "TEST"
    .fill 7,0
    .byte 0 ; RAM
    .byte 0 ; special version
    .byte 0 ; cart type
    ;               111111111112
    ;      123456789012345678901
    .text "this is a dummy name "
.cerror * != $80ffd5, "name is too short", *
    .byte $30   ; Mapping
    .byte $00   ; Rom
    .byte $07   ; 128K
    .byte $00   ; 0 SRAM
    .byte $02   ; PAL
    .byte $33   ; Version 3
    .byte $00   ; rom version 0
    .word $0000 ; complement
    .word $0000 ; CRC
.send ; sHeader

.section s65816Vectors
.block; scope this so we don't get name clashes
vCOP   .word <>Bank80.justRTI ; COP is a assembly mnemonic so add v
vBRK   .word <>Bank80.justRTI ; BRK is a assembly mnemonic so add v
ABORT  .word <>Bank80.justRTI
NMI    .word <>Bank80.NMI
RESET  .word <>Bank80.justRTI
IRQ    .word <>Bank80.justRTI
.bend
.send ; s65816Vectors

.section s6502Vectors
.block; scope this so we don't get name clashes
vCOP   .word <>Bank80.justRTI  ; COP is a assembly mnemonic so add v
vBRK   .word <>Bank80.justRTI  ; BRK is a assembly mnemonic so add v
ABORT  .word <>Bank80.justRTI
NMI    .word <>Bank80.justRTI
RESET  .word <>Bank80.RESET
IRQ    .word <>Bank80.justRTI
.bend
.send ; s65816Vectors

.comment ; by the way you can use this to comment out a block
master.asm:83:14: error: too large for a 16 bit unsigned integer bits '$80816d'
 vCOP   .word Bank80.justRTI ; COP is a assembly mnemonic so add v
.endc

; *** instance banks ***
.section sBank80
Bank80 .binclude "Bank80.asm"
.send

.section sBank81
AnimCode .binclude "AnimCode.asm"
AnimDataLo .binclude "AnimDataLo.asm"
.send

.section sBank82
.union
    .fill 32*1024,$AA
    SpriteData .binary "SpriteData.bin"
.endu
.send

HLWord .union
    .word ?
    .struct
        lo .byte ?
        hi .byte ?
    .ends
.endu

HLBLong .union
    .long ?
    .struct
        lo   .byte ?
        hi   .byte ?
        bank .byte ?
    .ends
    .struct
        loWord .word ?
        dummy1 .byte ?
    .ends
    .struct
        dummy2 .byte ?
        hiWord .word ?
    .ends
.endu
.comment
myWord .dunion HLWord
myLong .dunion HLBLong

lda myWord+1
;vs
lda myWord.hi

lda myLong+2
;vs
lda myLong.bank

lda myLong.loWord
sta $0000
lda myLong.hiWord
sta $0001
;vs
lda myLong
sta $0000
lda myLong+1
sta $0001
.endc
