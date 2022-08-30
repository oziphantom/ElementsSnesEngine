;AnimCode.asm

.virtual ((`*)<<16)+gSharedRamStart
.dsection sSharedWRAM
.endv

.as
.xs
lUnpackAnimToSprites_88
   PHB
   PHK
   PLB
.databank `*
   LDA #40
   STA ZPTemp1
   PLB
   RTL


