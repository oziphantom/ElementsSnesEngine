64tass -a -X -b -o test.sfc -L test.list master.asm
       -a ASCII input
          -X 24bit address space
             -b binary file no header
                -o output file
                            -L listing file

64tass Turbo Assembler Macro V1.55.2200?
64TASS comes with ABSOLUTELY NO WARRANTY; This is free software, and you
are welcome to redistribute it under certain conditions; See LICENSE!

Assembling file:   master.asm
Assembling file:   Bank80.asm
Assembling file:   AnimCode.asm
Assembling file:   AnimDataLo.asm
Reading file:      SpriteData.bin
Error messages:    None
Warning messages:  None
Passes:            4
Memory range:      $0000-$0131   $0132
Memory range:      $7fb0-$7fdf   $0030
Memory range:      $7fe4-$7fef   $000c
Memory range:      $7ff4-$8008   $0015
Memory range:     $10000-$17fff  $8000
Section:           $0000-$0131   $0132   sBank80
Memory range:      $0000-$0131   $0132
Section:           $7fb0-$7fdf   $0030   sHeader
Memory range:      $7fb0-$7fdf   $0030
Section:           $7fe4-$7fef   $000c   s65816Vectors
Memory range:      $7fe4-$7fef   $000c
Section:           $7ff4-$7fff   $000c   s6502Vectors
Memory range:      $7ff4-$7fff   $000c
Section:           $8000-$8009   $000a   sBank81
Memory range:      $8000-$8008   $0009
Section:          $10000-$17fff  $8000   sBank82
Memory range:     $10000-$17fff  $8000
Section:           $0000-$0006   $0007   sDP
Section:           $0007         $0000   sSharedWRAM
Section:         $7e2000         $0000   sLoWRAM
Section:         $7f0000         $0000   sHiWRAM
Section:         $800007-$80004a $0044   sBank80.sSharedWRAM
Section:           $0007         $0000   sBank81.sSharedWRAM

    STZ NMIReadyNF
    CLI
    ; do bunch of other things here
    ; set up VRAM
    ; copy data
    ; enable NMI VBlank etc
    LDX #$00
    JSR lUnpackAnimToSprites_88

MainLoop
    SEP   #$20                ; A8
MainLoopWait

64tass Turbo Assembler Macro V1.55.2200?
64TASS comes with ABSOLUTELY NO WARRANTY; This is free software, and you
are welcome to redistribute it under certain conditions; See LICENSE!

Assembling file:   master.asm
Assembling file:   Bank80.asm
Assembling file:   AnimCode.asm
Assembling file:   AnimDataLo.asm
Reading file:      SpriteData.bin
Bank80.asm:148:9: error: not defined ident 'lUnpackAnimToSprites_88'
     JSR lUnpackAnimToSprites_88
         ^
master.asm:110:1: note: searched in this scope and in all it's parents
 Bank80 .binclude "Bank80.asm"
 ^
Error messages:    1
Warning messages:  None
Passes:            3

    LDX #$00
    JSR AnimCode.lUnpackAnimToSprites_88
    
64tass Turbo Assembler Macro V1.55.2200?
64TASS comes with ABSOLUTELY NO WARRANTY; This is free software, and you
are welcome to redistribute it under certain conditions; See LICENSE!

Assembling file:   master.asm
Assembling file:   Bank80.asm
Assembling file:   AnimCode.asm
Assembling file:   AnimDataLo.asm
Reading file:      SpriteData.bin
Bank80.asm:148:9: error: address in different program bank code '$818000'
     JSR AnimCode.lUnpackAnimToSprites_88
         ^
Error messages:    1
Warning messages:  None
Passes:            3

