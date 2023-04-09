AXY16 .macro 
rep #$30 ; AXY 16
.endm

A16 .macro
rep #$20 ; A16
.endm 

XY16 .macro
rep #$10 ; XY16
.endm

AXY8 .macro 
sep #$30 ; AXY 8
.endm

A8 .macro
sep #$20 ; A8
.endm

XY8 .macro
sep #$10  ; X8	
.endm


*=$000000               ; file offset
.logical $008000        ; memory address
.include "BANK00.asm"   ; put everything in BANK00.asm file here
.here                   ; exit out of the memory adress and return to file address
*=$008000               ; file offset
.logical $018000        ; memory address
; .include "BANK01.asm" ; placeholder commented out for now
.here                   ; exit out of the memory adress and return to file address
*=$010000               ; file offset
.logical $028000        ; memory address
; .include "BANK02.asm" ; placeholder commented out for now
.here                   ; exit out of the memory adress and return to file address
*=$018000               ; file offset
.logical $038000        ; memory address
; .include "BANK03.asm" ; placeholder commented out for now
.here                   ; exit out of the memory adress and return to file address
*=$01FFFF               ; make sure all 128K is output set we set the file offset to the last byte
.byte 0                 ; place empty byte to force full output