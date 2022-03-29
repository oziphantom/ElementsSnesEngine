kSPri_0 = 0<<4
kSPri_1 = 1<<4
kSPri_2 = 2<<4
kSPri_3 = 3<<4

kSPal_0 = 0<<1
kSPal_1 = 1<<1
kSPal_2 = 2<<1
kSPal_3 = 3<<1
kSPal_4 = 4<<1
kSPal_5 = 5<<1
kSPal_6 = 6<<1
kSPal_7 = 7<<1

kSFlipX = 64
kSFlipY = 128

kBaseSize_32x32 = 0
kBaseSize_64x32 = 1
kBaseSize_32x64 = 2
kBaseSize_64x64 = 3

;takes the screen base in Word Offset and ScreenLayout in kBaseSize_XXxXX
fBGBaseSize .function base,screenLayout
.endf ((base/1024)<<2) | screenLayout

;takes the 4 screen character base addresses in Word Offset
fBGCharAddress .function bg1,bg2,bg3,bg4
.endf (bg4/4096)<<12 | (bg3/4096)<<8 | (bg2/4096)<<4 | (bg1/4096) 

; converts 24bit RGB value into a SNES 16bit word
fRGBToSNES .function r,g,b 
.endf (b&$f8)<<7 | (g&$f8)<<2 | (r&$f8)>>3

; this wil convert a sprite X,Y index for 16x16 sprites on the sprite "map" to a tilenum + attributes word
; it handles multiple sprite "banks" as well
fSprDef .function gridX,gridY,flags
	.if gridY >= 16				; have we gone over sprite bank 1
		_y = (gridY % 8) + 8		; yes get the number upper bank relative
	.else
		_y = gridY
	.endif
.endf (gridX*2+_y*32)|flags<<8

A8 .macro
	SEP #$20
.endm

A16 .macro
	REP #$20
.endm

A16Clear .macro
	REP #$21
.endm

XY8 .macro
	SEP #$10
.endm

XY16 .macro
	REP #$10
.endm

AXY8 .macro
	SEP #$30
.endm

AXY16 .macro
	REP #$30
.endm