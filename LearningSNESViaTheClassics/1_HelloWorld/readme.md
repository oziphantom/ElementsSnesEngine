# 1. Hello World
This is the first lesson, the basic first I got everything set up and working ye olde test.

For this series I will be using 64tass as the assembler. Why?

- I find it best in class with unrivalled features
- It doesn't need any idiosyncratic handling to make up for its lack of understanding of the 65816
- It has true full 65816 support, including stack relative, auto DP optimisations, and understands when to do a 24bit address.
- Its syntax is derived from a long line of Turbo Assemblers dating back to 1984 making it practically one of the few "standard" 65XX assembler formats. However, the WDC assembler is also in the running for being "the true standard" I guess.
- It is written in ANSI C, and is so portable you can even run it on an Amiga 500, making it easy to work on anything and it is blazing fast even on a 4MB SNES ROM.
- There is a good editor with almost full auto complete support in the way of Reluanch64 which is Java based, which also almost runs on everything.

The only issue with 64tass is that it is a 65XX family assembler and not a *SNES* assembler, this means it does not handle the SNES’s weird memory mapping by default (yet, if enough people start using it, I kind of have soci/singular word he would look into adding it) so we will have to do some slightly idiosyncratic things to deal with the SNES being idiosyncratic still. 

While the above tools are very cross-platform you will basically **need** windows for SNES development, most of the tools are made by people who want a good and solid system that allows for easy and rapid GUI construction, and as such they are almost all Windows Exclusive or are a historic tool where Windows was the only practical machine, or DOS even. SNES's time in the Sun has waned somewhat, from its glory heights of the late 90s and early 2000s. So, there are a lot of historic tools that support winXP of which a WINE and or even ReactOS will probably run. You can even get DOS tools that you could use in DOSBOX if you are so inclined. The major issues you will run into is MESEN-S is Windows, Linux can support it mostly, I believe with some odd window here and there with WINE and a WinForms implementation. Macs are out of luck unless you still have an older version of MacOS that still runs 32bit software. However, all intel macs can be greatly improved by installing windows on them or dual booting for when you need to use FinalCut Pro or Xcode. VirtualBox and Q-Emu are also options, and if you have Arm mac you are going to need those either way. There is Geigers Debugger which started as Win98 I think maybe it needs WinXP in the final version but might still be fine with Win2000, and there are a pile of BSNES hacks and extensions that have a very limited QT based debugger that you might be able to get away with on MacOS. 

I will endeavour where possible to point out alternative tools that may also *"fit the bill"* but for all intents I'm going to assume Windows is available to you, in some capacity. 

## Set up
You can get 64tass from here https://sourceforge.net/projects/tass64/ it is also available in some package managers. 
The extensive documentation is here https://tass64.sourceforge.net/ keep it saved or bookmarked, although the files are also in the distribution.

For text editing I recommend https://sourceforge.net/projects/relaunch64/ set the mode to 64tass. Sadly this is a 65XX editor so it won't understand and highlight 65816 instructions, this would be a trivial fix but I'm not a Java person and have not been able to get netbeans to build a swing 7.0 project for me. If you have experience with this and can help, please let me know. 

For graphics conversion I will be using https://github.com/Optiroc/SuperFamiconv 

make sure that tass64 and superfamiconv are visible somewhere in your path or equivalent on your OS. 

## Getting started with Hello World

The first port of call with a SNES is first understanding how to make a "sfc" file for the emulator to consume. 

This will be the first conceptual hurdle you will have. How the SNES sees the data and how the file and assembler must output the data are very different. 
First go to here https://snescentral.com/pcbboards.php?chip=SHVC-4P5B-01 and look at the picture of the dev board. See those 4 large chips with SNST2 and a bunch of other letters on them and the CAPCOM stickers. Let’s imagine for a moment (as it is not actually this simple) that each one of those ROMS are 32K, now the game has 4 banks of 32K (it doesn't but just imagine) so in a LoROM 20 layout each bank occupies the upper 32K of the memory map. 
So, the first 64K of memory as the SNES's CPU see is as follows
~~~
+--------+ 
|        | 00:F000
|  1st   | 00:E000
|        | 00:D000
|  ROM   | 00:C000
|        | 00:B000
|        | 00:A000
|        | 00:9000
+--------+ 00:8000
|  SRAM  | 00:7000
+--------+ 00:6000
| PPU/APU| 00:5000
|  5A22  | 00:4000
|  REGS  | 00:3000
+--------+ 00:2000
| SHARED | 00:1000
|  RAM   | 00:0000
+--------+
~~~
then the second 64K is as follows
~~~
+--------+ 
|        | 01:F000
|  2nd   | 01:E000
|        | 01:D000
|  ROM   | 01:C000
|        | 01:B000
|        | 01:A000
|        | 01:9000
+--------+ 01:8000
|  SRAM  | 01:7000
+--------+ 01:6000
| PPU/APU| 01:5000
|  5A22  | 01:4000
|  REGS  | 01:3000
+--------+ 01:2000
| SHARED | 01:1000
|  RAM   | 01:0000
+--------+
~~~
then the third 64K is as follows
~~~
+--------+ 
|        | 02:F000
|  3rd   | 02:E000
|        | 02:D000
|  ROM   | 02:C000
|        | 02:B000
|        | 02:A000
|        | 02:9000
+--------+ 02:8000
|  SRAM  | 02:7000
+--------+ 02:6000
| PPU/APU| 02:5000
|  5A22  | 02:4000
|  REGS  | 02:3000
+--------+ 02:2000
| SHARED | 02:1000
|  RAM   | 02:0000
+--------+
~~~
then the fourth 64K is as follows
~~~
+--------+ 
|        | 03:F000
|  4th   | 03:E000
|        | 03:D000
|  ROM   | 03:C000
|        | 03:B000
|        | 03:A000
|        | 03:9000
+--------+ 03:8000
|  SRAM  | 03:7000
+--------+ 03:6000
| PPU/APU| 03:5000
|  5A22  | 03:4000
|  REGS  | 03:3000
+--------+ 03:2000
| SHARED | 03:1000
|  RAM   | 03:0000
+--------+
~~~
the number on the side are a 24bit *memory address* as seen by the SNES.

When me make a file for the SNES to play, we don't want to put empty space for the RAM, the registers and the SRAM area, that would just be a giant waste and make files much larger than they need to be, double the size in fact. In the old old days we use to actually name the files .1 .2 .3 and .4 which would then tell the emulator which "ROM" each file mimicked, but that was silly and nobody wants to have to make and move and name 4+ files so we "bolted" them together and thus the SFC file is just
~~~~
+--------+ 
|        | 01F000
|  4th   | 01E000
|        | 01D000
|  ROM   | 01C000
|        | 01B000
|        | 01A000
|        | 019000
+--------+ 018000
|        | 017000
|  3rd   | 016000
|        | 015000
|  ROM   | 014000
|        | 013000
|        | 012000
|        | 011000
+--------+ 010000
|        | 00F000
|  2nd   | 00E000
|        | 00D000
|  ROM   | 00C000
|        | 00B000
|        | 00A000
|        | 009000
+--------+ 008000
|        | 007000
|  1st   | 006000
|        | 005000
|  ROM   | 004000
|        | 003000
|        | 002000
|        | 001000
+--------+ 000000
~~~~
So now the number down the side represents the **file offset** not the *memory address*. This is crucial to understand, and failure to do so will cause great amounts of confusion. There is where the file puts data and where it _appears_ to the SNES and they are two very different numbers and when making a SNES ROM FILE we will need to deal with both. As we will need to explain to 64tass where we want things in the file and were the SNES will perceive the data. 

How do we explain this to 64tass? 

by using the `*=` to set the *file offset* and the `.logical` directive to set the *memory address* this is to make a LoROM file and I will make it 128K which is the general smallest SNES ROM size. 

>master.asm
~~~
*=$000000               ; file offset
.logical $008000        ; memory address
.include "BANK00.asm"   ; put everything in BANK00.asm file here
.here                   ; exit out of the memory address and return to file address
*=$008000               ; file offset
.logical $018000        ; memory address
; .include "BANK01.asm" ; placeholder commented out for now
.here                   ; exit out of the memory address and return to file address
*=$010000               ; file offset
.logical $028000        ; memory address
; .include "BANK02.asm" ; placeholder commented out for now
.here                   ; exit out of the memory address and return to file address
*=$018000               ; file offset
.logical $038000        ; memory address
; .include "BANK03.asm" ; placeholder commented out for now
.here                   ; exit out of the memory address and return to file address
*=$01FFFF               ; make sure all 128K is output set we set the file offset to the last byte
.byte 0                 ; place empty byte to force full output
~~~~

> `;` is 64tass for comment, same as `//` in c family or `#` in python, lua et al

This "lays out" the SFC file for us, I have commented out the include files for the upper banks, as it will be quite some time before we use more than 32K. I typically name this master.asm and it is the file we will assemble to make the SFC file. Don't do it yet however as it will fail, as we don't have a `BANK00.asm` file yet.

## The SNES side
Now we have out skeleton file and we are now able to make files in a format that the emulator understands, we can now focus on the SNES side of things. 

Of which the first port of call is the SNES INTERNAL ROM Header. This is not to be confused with the SNES ROM Header. The SNES ROM Header is a 512 byte header appended to the front of a SWC or SMC file that was used by the file copiers of yore and should **no longer be used**. No, this is the internal header used by Nintendo to verify and specify the ROMs for manufacturing and are actually totally unused by the SNES in every way, however they are important to emulators and hence we must have a valid one to ensure proper functionality of our ROM file in Emulators. That being said we won't have a 100% perfectly compliant ROM header but it should be enough. 

For the best details on this and everything else on the SNES see https://problemkaputt.de/fullsnes.htm this is a nice single page with no pictures and I encourage you to save the html file locally for fast reference and to limit the financial burden on No$ there is also a pure txt version if you prefer here http://problemkaputt.de/fullsnes.txt

The particular area of interest is the `SNES Cartridge ROM Header` section, where we have
~~~~
Cartridge Header (Area FFC0h..FFCFh)

  FFC0h  Cartridge title (21 bytes, uppercase ascii, padded with spaces)
  FFC0h  First byte of title (or 5Ch far-jump-opcode in Pirate X-in-1 Carts)
  FFD4h  Last byte of title (or 00h indicating Early Extended Header)
  FFD5h  Rom Makeup / ROM Speed and Map Mode (see below)
  FFD6h  Chipset (ROM/RAM information on cart) (see below)
  FFD7h  ROM size (1 SHL n) Kbytes (usually 8=256KByte .. 0Ch=4MByte)
          Values are rounded-up for carts with 10,12,20,24 Mbits
  FFD8h  RAM size (1 SHL n) Kbytes (usually 1=2Kbyte .. 5=32Kbyte) (0=None)
  FFD9h  Country (also implies PAL/NTSC) (see below)
  FFDAh  Developer ID code  (00h=None/Homebrew, 01h=Nintendo, etc.) (33h=New)
  FFDBh  ROM Version number (00h=First)
  FFDCh  Checksum complement (same as below, XORed with FFFFh)
  FFDEh  Checksum (all bytes in ROM added together; assume [FFDC-F]=FF,FF,0,0)

Extended Header (Area FFB0h..FFBFh) (newer carts only)
Early Extended Header (1993) (when [FFD4h]=00h; Last byte of Title=00h):

  FFB0h  Reserved   (15 zero bytes)

Later Extended Header (1994) (when [FFDAh]=33h; Old Maker Code=33h):

  FFB0h  Maker Code (2-letter ASCII, eg. "01"=Nintendo)
  FFB2h  Game Code  (4-letter ASCII) (or old 2-letter padded with 20h,20h)
  FFB6h  Reserved   (6 zero bytes)
  FFBCh  Expansion FLASH Size (1 SHL n) Kbytes (used in JRA PAT)
  FFBDh  Expansion RAM Size (1 SHL n) Kbytes (in GSUn games) (without battery?)
  FFBEh  Special Version      (usually zero) (eg. promotional version)

Both Early and Later Extended Headers:

  FFBFh  Chipset Sub-type (usually zero) (used when [FFD6h]=Fxh)
~~~~
Note these addresses are all Bank 0 and are *Memory addresses*
> Note No$ or nocash is a strict Intel man through and through, so he specifies address in the Intel “post h” format vs the Motorola preceding $ format, more typically used in the 65XX and 68XX domains. Thus, FFBDh is the same as $FFBD. I will however always use the $XXXX format.

We will not bother with the extended header for now or possibly ever, and leave it as all 0s.

To fill out this header in 64tass we simply define `.byte`, `.word` and `.text` regions with an encoding of `"none"` more on encodings later.
> The size of “named variable types” varies from CPU to CPU and even in some cases compiler to compiler or language to language. For the SNES 
> byte is 8bits
> word is 16bits
> long is 24bits 

Make a new `BANK80.asm` file and start editing it with
~~~
* = $ffb0
    .enc "none"
    .fill 16,0
    ;               111111111112
    ;      123456789012345678901
    .text "this is a dummy name "
.cerror * != $00ffd5, "name is too short", *
    .byte $20   ; Mapping
    .byte $00   ; Rom
    .byte $07   ; 128K
    .byte $00   ; 0 SRAM
    .byte $02   ; PAL
    .byte $33   ; Version 3
    .byte $00   ; rom version 0
    .word $FFFF ; complement
    .word $0000 ; CRC
~~~
> .cerror lets us put an assemble time check to make sure something is true, an "assert", in this case the error will be printed if the name is too short. A common error that can cause header detection to fail

> as I live in PAL territory I tend to make all my ROMS PAL 50hz spec, you may which to change this for your ROMs though. However, for learning I recommend PAL, while 50hz vs 60hz is a "fight" the far longer VBlank time of PAL is far more forgiving to learners and will cause you less pain. Although if you try to run it on the NTSC hardware you might end up with it failing. So, **make a mental note** and we will adjust it in the future when I believe it may become an issue.

Note the CRC and complement is FFFF and the CRC is 0000, this is not strictly "valid" and will give an invalid CRC warning in most emulators, we can ignore it though. The other fields I feel are aptly described by no$'s documentation so please see it for a breakdown of what each field means and how it is encoded. 

The next section we need to deal with is the _Vectors_ there are two sets one for the Emulation nee 6502 mode and the Native nee 65816 set. These are a series of "pointers" to Bank 00 addresses that the CPU should "jump" to when an external event occurs. Such as Reset which also doubles as the Power On Event, an Interrupt and the Non-Maskable Interrupt, which means that you can not disable it.

The layout of each "set" is identical, although not all of the fields make sense for both contexts, and in a SNES context even less make sense. 

The set order is 
~~~
COP
BRK
ABORT
NMI
RESET
IRQ
~~~
with each entry being 16bits and pointing to an address in Bank 00. 

For historic reasons the 6502 Set start at 00:FFF4 so the NMI, RESET and IRQ are in the same location as on a 6502. The 65816 set is below it in memory at 00:FFE4. These are Memory addresses. 

ABORT is useless on a SNES, and is always useless in 6502 mode, so it can be set to a dummy RTI address. 
COP is mostly useless on a SNES and always useless in 6502 mode, so it can also be set to a dummy RTI address.
The CPU will never reset or boot in 65816 mode and as such the 65816 RESET vector will never fire, making it useless as well. 

Defining these is straight forward in 64tass as we simply do

~~~~
; 65816 vectors
* = $ffe4
v16_COP    .word justRTI
v16_BRK    .word justRTI
v16_ABORT  .word justRTI
v16_NMI    .word NMI_ISR
v16_RESET  .word justRTI
v16_IRQ    .word justRTI

; 6502 vectors
* = $fff4
v02_COP    .word justRTI
v02_BRK    .word justRTI
v02_ABORT  .word justRTI
v02_NMI    .word justRTI
v02_RESET  .word RESET
v02_IRQ    .word justRTI
~~~~
were justRTI, NMI_ISR and RESET are labels we will define elsewhere in the file. 

> the header and vector definitions should be placed at the bottom of Bank00.asm **not the top** and we will add our code and data above them. This is because the assembler starts counting from the last `*` and these put it right at the end of the bank.

To recap, we now have our physical ROM file laid out, we have the header to inform the SNES emulator which type and how big it should treat our ROM and what other things we want on our "cart" and we have set up the VECTORs to tell the CPU where we want it to start, what it should do when a Non-Maskable Interrupt occurs and a safety vector to handle any other events that we shouldn't get, but better safe than sorry. 

Now we need to enter the basic code, for which we have

~~~~
RESET
   ; todo add code here

NMI_ISR
   ; nothing needed yet
justRTI
   rti
~~~~

So, we have the rom installed, we have powered on the machine and the 65816 has "reset" and thus calls the code pointed to it by the v02_RESET which points to RESET, so now we have to put our start up code. 

First port of call is we have to initialise the 65816, this includes: -

- switching from 6502 mode to 65816
- setting a valid known Stack location

The 65816 for backwards compatibility reasons will boot in 6502 mode, Accumulator and Index registers in 8 bit mode, and the Stack will be 00:01XX ie. somewhere between 256 and 511 in memory. The Direct Page will be $0000, the Databank will also be 00. To ensure we get the correct code we must first tell the assembler these settings, which is done by the following 64tass directives. 
~~~~
.as               ; Assume A8
.xs               ; Assume X8
.autsiz           ; Auto size detect
.databank $00     ; databank is 00
.dpage $0000      ; direct page is 0000
RESET
~~~~
place them before your RESET label which should be at the top of the file.

Now we can get onto some code, to switch to 65816 mode. This is done by clearing (setting to 0) the E bit in the status flags register, there is no direct command as this is all the status flags are used already and Emulation mode is a "do once" operation, so we must clear the carry flag and then exchange the C flag for the E flag
~~~~
RESET
   clc
   xce ; enter 65816 mode
~~~~
next we want to set up the Stack to be a known solid position, I recommend $1FFF for SNES, as this will give you the largest unbroken block of RAM below the 8K Shared RAM. 
> The Stack on a 65XX family grows down, thus we set the top of the stack and and we push the stack address will decrease, hence why we set it at the “top of memory”
~~~~
   rep #$30 ; AXY 16
   ldx #$1FFF
   txs      ; set the stack
~~~~
sometimes we have to handle a soft reset, i.e if you put in a L+R+Start+Select reset combo or maybe a flash cart will just jump to the vector rather than do an actual hardware reset. So, we will set the data bank to be the same as the program bank and reset the Direct Page to 0.
~~~~
   phk
   plb
   lda #0000
   tcd
~~~~
now we have the CPU fully set up and ready, now we have to bring the rest of the machine up. This is the PPU, WRAM, we won't about the SPC-700 for quite a while. 

First port of call is to ensure we are in *Forced Blanking*, this is because you can not touch the VRAM, OAM and CGRAM unless you are in a blanking period, which is typically VBlank but we can turn the screen off which is called FBlank or Forced Blanking. This gives up full access to the VRAM, OAM and CGRAM and also makes sure the user doesn't get any weird patterns on their screen while we do it. 
~~~~
   lda #$008f
   sta $2100 ; turn the screen off
~~~~
Now while we wait, we can clear WRAM, we should do this before we call any sub routines as the *stack* in in WRAM so also gets cleared. The most efficient way to do this in terms of speed is via DMA. 
~~~~
   lda #$8008     ; A -> B, FIXED SOURCE, WRITE BYTE | WRAM
   sta $4300
   lda #<>DMAZero ; 64Tass | get low word
   sta $4302
   lda #`DMAZero  ; 64Tass | get bank
   sta $4304
   stz $2181
   stz $2182      ; START AT 7E:0000
   stz $4305      ; DO 64K
   lda #$0001
   sta $420B      ; FIRE DMA
   sta $420B      ; FIRE IT AGAIN, FOR NEXT 64k
~~~~
> WRAM is 128K of Work RAM for the CPU to use and is located in banks 7E and 7F. However in LoROM the first 8K is also mirrored into the first 64banks so 00:0000-00:1FFF = 01:0000-01:1FFF = 02:0000-02:1FFF ... 3F:0000-3F:1FFF = 7E:0000-7E:1FFFF

> DMA Is Direct Memory Access. Normally you have to use the CPU to clear or move memory, this is very in efficient as the CPU has to load instructions to do the move as well as moving the data. For example the 65816 has special instructions to do this that cost 7 clocks per byte to be moved. DMA avoids this overhead by not need any instructions, so it can just move the data directly. Typical implementations of this take 2 clocks per byte, in a fetch/store cycle. This is because you can set two addresses on the same “Bus” at the same time, so you must grab, then store. The SNES has 2 busses the A and B bus, this allows it to move data in 1 clock, as it can set the source address on A and the destination address on B and then simply enable the data lines to “move the data”. This is very fast but has the cost of you can only move between the 2 buses. Thus you can not move WRAM to WRAM even though it may appear you can, you can’t. DMA is primary for moving ROM/WRAM -> VRAM/OAM/CGRAM or ROM -> WRAM. Such speed is 100% worth this limitation. 

To DMA to WRAM we have to use the WRAM PORT at 2180. A port is an access point, i.e we have a single address that we write to and the "other end" is connected to somewhere else, and that somewhere else changes. In this case the somewhere else is WRAM and the point it points to automatically increments so we set the port address which is 24bits (actually 17 but let’s not worry about it) to $7e0000 which is the start of WRAM. Then when something is written to $2180 that value will be written to $7e0000 and then the port will point to $7e0001 so the next thing written will write to $7e0001 and so on and so on. In this case the DMA is going to write a single "fixed" value of 00 to it, for 128K and thus set all of it to 00. 

To do this we set the DMA to point to address $80 as the DMA can only see the address "page" 00:21 thus 00:21XX so we only need to tell it $80 not $2180, we want to copy from A bus to B bus, which means from CPU memory to the 21XX range, we want a fixed source of 1 byte in width. I.e it writes 8bit from the src(source) to the dest(ination). Then we tell it to do 64K, which is the largest amount you can DMA in 1 "run" then we tell it do another 64K to clear all of the 128K of WRAM. 

We have to SET DMAZero somewhere, it just has to be a ZERO, luckily we have a bunch of Zero in the ROM Internal Header so we can just put DMAZero before the $00:FFB0 part of the header, we can modify the existing code as follows
```
* = $ffb0
    .enc "none"
DMAZero
    .fill 16,0
    ;               111111111112
    ;      123456789012345678901
    .text "this is a dummy name "
```

> portability note the way assembler get parts of an address varies wildly. For example given an address of $123456 the follow 64tass commands will yield
>```
> <   lower byte              $56   
> >   higher byte             $34
> <>  lower word              $3456
> >`  higher word             $1234
> ><  lower byte swapped word $5634
> `   bank byte               $12
> ```

Now we are ready to initialise the PPU. The SNES Developer Manual has a recommended settings page of which we will just follow, so these values are "as decreed by Nintendo" 
~~~~
   rep #$20    ; A16
   lda #$008F  ; FORCE BLANK, SET OBSEL TO 0
   sta $2100
   stz $2105 ;6
   stz $2107 ;8
   stz $2109 ;A
   stz $210B ;C
   stz $210D ;E
   stz $210D ;E
   stz $210F ;10
   stz $210F ;10
   stz $2111 ;12
   stz $2111 ;12
   stz $2113 ;14
   stz $2113 ;14
   stz $2119 ;1A to get Mode7
   stz $211B ;1C these are write twice
   stz $211B ;1C regs
   stz $211D ;1E
   stz $211D ;1E
   stz $211F ;20
   stz $211F ;20
   stz $2123 ;24
   stz $2125 ;26
   stz $2126 ;27 YES IT DOUBLES OH WELL
   stz $2128 ;29
   stz $212A ;2B
   stz $212C ;2D
   stz $212E ;2F
   stz $2130 ;31
   lda #$00E0
   sta $2132
~~~~
I'm using 16 bit writes to write 2 bytes at once to reduce the code size. We’ve almost set the hardware up, now we have some CPU I/O Registers which also need to set up
~~~~
   ;ONTO THE CPU I/O REGS
   lda #$FF00
   sta $4200
   stz $4202 ;3
   stz $4204 ;5
   stz $4206 ;7
   stz $4208 ;9
   stz $420A ;B
   stz $420C ;D
~~~~
Then we have to clear VRAM, CGRAM so we don't get any nasty surprises, again I will perform a fixed DMA pointing to the 0 we set up earlier. VRAM is 64K and CGRAM is 512 bytes, both have their own port.
~~~~
; CLEAR VRAM
   rep #$20        ; A16
   lda #$1809      ; A -> B, fixed source, write word | vram
   sta $4300
   lda #<>DMAZero  ; this get the low word, you will need to change if not using 64tass
   sta $4302
   lda #`DMAZero   ; this gets the bank, you will need to change if not using 64tass
   sta $4304       ; and the upper byte will be 0
   stz $4305       ; do 64k
   lda #$80        ; inc on hi write
   sta $2115
   stz $2116       ; start at $$0000
   lda #$01
   sta $420B       ; fire dma
   ; CLEAR CG-RAM
   lda #$2208      ; a -> b, fixed source, write byte | cg-ram
   sta $4300
   lda #$200       ; 512 bytes
   sta $4305
   sep #$20        ; A8
   stz $2121       ; start at 0
   lda #$01
   sta $420B       ; fire dma
~~~~

> Word formats on 65XX family use what is called LOHI format. I.E you write the lower 8bits first then the next higher 8bits, and so on. For a long its LOHIBANK. So whenever you write a 16bit value you write the lower 8bits then the upper 8bits. The assembler will take care of this for us with constants and addresses. We can use 16bits to write to the address and address + 1 i.e if we store a 16bit value to $0 it will put the lower 8 bits at $0 and the upper 8 bits at $1 thus allowing us to set 2 addresses more efficiently. In the above code I use this to write $09 to $4300 and then $18 to $4301. 

VRAM is a 16 bit port unlike WRAM so we have to set the DMA to write a 16bit "word" value. Also VRAM has multiple internal data formats so how it auto increments its port address is configurable, We are writing words so we tell it to increment when we right to the upper 8bits at $2119 and to increment by 1. Wait 1 but we are writing a word shouldn’t that be 2. Well no, here is another confusing aspect of the PPU, the address is a **word** address. I.E., each memory locations points to 16 bits not 8bits. So VRAM is 64K bytes but 32K words and that is how it is addressed. This gets very confusing, and worse still a lot of things don't specify if they are talking in byte or word address, further still the VRAM viewer in Mesen-S tells you the byte address to confuse matters further. I will endeavour to make it clear which is which in these examples, as well as highlight things that will not specify which size they are and set the record for you. 

> in these docs $ is a byte address and $$ is a word address, however in code I must, as must you, use $. So, this is in comments and discussion only!

Hurray the machine is now set up and ready for us to begin! 

## Hello world then

In order to do hello world we need a few things :-

 - a Font
 - a Pallete
 - a string encoding that matches our font

So, when I say a font, I don't mean a TTF, or similar Windows font, no we need a “bitmap font” in the SNES's graphics format, of which it has 3. 4 colour, 16 colour and 256 colour for this example we are going to use a 4 colour layer in Mode 0. 

 For reasons that will soon become apparent, I've decided to go with the C64 Font in *Screen Code* layout as per its CHARGEN rom. Luckily this is a bitmap font so is not covered by copyright, and they nicked it from Atari anyway. Open `petscii.png` and have a look at it.

 But we need to convert this into SNES format. For this I will use `superfamiconv` I am only interested in the char data and don't care for a map, but a prebuilt pallete is nice and this is a convenient way to get it, so I will use `superfamicov` to export the pallete as well. 

The invocation is `superfamiconv -p petscii.pal -t petscii.chr -M snes -B 2 -W 8 -H 8 -R -F -i petscii.png` this will make an 8 byte pal file for the "4" colours in `pal` file, the `chr` file will contain the raw character data and we want SNES with 2bits per pixel AKA 4 colour format, in 8x8 tiles, do not remap the order of the tile and no flipping thank you, I want each tile to be exactly where is should be, so the "encoding matches". 

Now we need to get these files into the ROM, which is a simple `.binary` command, and then we need to get the SNES to push it to the VRAM for us to use. First, we need to decide where in VRAM we want to put things. 

> Char vs Tile. They are the same thing, SNES docs tend to call things Tiles as do other consoles, while computers which have a Font built in tend to call them characters or chars for short. As I’ve been using the term Chars for 32years, the general ability for me to switch terms is a case of the cat escaped the bag, jumped on the back of a horse which has well and truly bolted to the sea side and got on a ship that has set sail and is beyond to point of returning to port. 

I'm going to have a 32x32 char size screen in the 1x1 layout, each "what char goes here" entry is 16bits, so 2 bytes. This is so we can have 1024 tiles + 8 palletes + h flip + v flip + Priority. Which is 32x32x2 = 2K or $800 bytes, which in VRAM address terms is 1K word or \$$400

> for the gory details see the `BG Map (32x32 entries)` under the `SNES PPU Video Memory (VRAM)` in no$ FullSNES documentation

> remember $ for byte address and $$ for word address

The screen must be allocated on a 1K word boundary, which doesn't matter for this case as I'm going to put it at \$$0000 but its handy to remember. 

The Char data has to be 4K word aligned so I can put it at \$$0000 or \$$1000 or \$$2000 you can't put it \$$400 for example. So, I will place it \$$1000.

I will place the pallete at pal entry 0.

Thus the C64 Screencode will match the SNES tile 1:1, convenient huh. 
But what is screencode and "encoding" mean. Well, we tell the SNES or any computer for that matter to show an 'A' however a computer has no idea what an 'A' is, it doesn't know what that means. It only knows numbers and in the ASCII set 'A' is defined as number 65. Thus, when the computer comes across a text file and finds number 65 it then looks into the current font and finds what the 65th one looks like and then draws it. There are lots of standards on what these should be and if you have ever opened a document in the wrong format, you will know what I mean. These days UTF8 and UTF16 are the main standards and used by almost everything. However back in the day everything had its own. DOS code page 437, Mac encoding, ASCII, ASCII-E, SHIFT-JIS and PETSCII and so on and so on. 
On the SNES we are free to make whatever encoding we want. For simplicity I'm going to use the C64 screen code encoding because that is 

a.) the order the above Font is in

b.) a build in encoding in 64tass "screen"

one less thing to worry about ;) 

but let’s get to some code! Uploading our new data files to VRAM, again I will use DMA. 

~~~~
... below the previous code
   ; DMA Petscii Font
   rep #$30                 ; AXY 16
   lda #<>PETSCII_Chars
   sta $4302
   sep #$20                 ; A8
   lda #`PETSCII_Chars
   sta $4304
   ldx #size(PETSCII_Chars)
   stx $4305
   ldx #%00000001 | $1800   ; A->B, Inc, Write WORD, $2118
   stx $4300
   ldx #$1000
   stx $2116
   lda #$80
   sta $2115                ; inc VRAM port address
   lda #1
   sta $420B
   ; DMA Pallete
   ldx #<>PETSCII_Pal
   stx $4302
   lda #`PETSCII_Pal
   sta $4304
   ldx #8
   stx $4305
   ldx #%00000010 | $2200  ; A->B, Inc, Write 2 Bytes, $2122
   stx $4300
   stz $2121               ; start of Pallete
   lda #1
   sta $420B
~~~~

> size is a 64tass command that will automatically get the size of anything defined on the same line or within a block scope of a label. Thus, it is critical to write the line as 
> ``` 
> PETSCII_Chars .binary "petscii.chr"
> ```
> and not 
> ```
> PETSCII_Chars 
>   .binary "petscii.chr"
> ```
> in the second case you will get a size of 0. It's a bit odd but you’ll also come to understand why it is this way in time.

The code is fairly straight forward, we copy the Chars, so not a fixed copy this time but data copy, to the VRAM port, 16 bits at a time, increment on the upper 8 bits being written, we write to VRAM word address /$$1000 as I said, we do however have to specify how many **bytes** make up the petscii.chr file and we fire the DMA. 

The pallete since it is 8 bytes would almost be faster to do in a loop, but I wish to demonstrate the DMA method for it. This time we are writing 2 bytes to a single address, the CGRAM port is another special custom job. You write 16bits to it, but in a pair of 8bits. So, you write the lo 8bit to 2122, then the high 8bits to 2122 and then that has set a single entry in the pallete. Then you write the next one lo, high to 2122. Needlessly complicated I'm sure, but it what we have. This time I use the Write 2 bytes form of DMA rather than the 1 word form of DMA as we use for VRAM port. OAM also uses this format, as we will see once we eventually get to using sprites. 

Of cause we also need to include the data, so before the “header” and after this code add the following lines **keeping the binary on the same line as the label is critical keep it this way or the code will fail**

~~~~
PETSCII_Chars .binary "petscii.chr"

PETSCII_Pal .binary "petscii.pal"
~~~~

almost there. 
One annoying thing about screen codes is that char 0 is @ and not ' ', ' ' is 32 so at the moment the screen would all be filled with '@' symbols, so we better clear it to ' '. Guess how we are going to do it..... you’re correct DMA time!

This will be a fixed copy again but this time with the value $0032, and we have a \$$400 screen to fill at \$$0000

After the above code and before the `PETSCII_Chars` line add
~~~
   ; fill the screen with ' '
   ldx #$1809      ; A -> B, fixed source, write word | vram
   stx $4300
   ldx #<>DMASpace ; this get the low word, you will need to change if not using 64tass
   stx $4302
   lda #`DMASpace  ; this gets the bank, you will need to change if not using 64tass
   sta $4304       ; and the upper byte will be 0
   ldx #$800       ; DMA counts bytes not words so we must give a byte size not a word size
   stx $4305       ; do 64k
   lda #$80        ; inc on hi write
   sta $2115
   stz $2116       
   stz $2117       ; start at $$0000
   lda #$01
   sta $420B       ; fire dma
~~~~

now we need to set DMASpace, the easiest and safest way to do this is with 

~~~
.enc "screen" ; tell 64Tass we want the text to be written in C64 Screen codes encoding
DMASpace .word ' '
~~~

> On 64tass you can specify characters with ' or even entire string on byte, word, long directives etc, you don’t have to use the .text directive, you can also give bytes to the text directive. In this case we are using a `.word` so it will set the upper 8bits to 0 for us, automatically. 

Place this before the PETSCII_Chars line, after the current main code.

Now to put some actual text on the screen. This we will do with a loop, directly into the port.
~~~~
   ; draw the text
   lda #1
   sta $2115
   stz $2116
   stz $2117       ; reset the port to $$0000
   ldx #0
-  lda HelloWorld,x
   sta $2118       ; write the lower 8bits of tile number
   stz $2119       ; this will set the upper 2 bits, pal and other attributes to 0
   inx
   cpx #size(HelloWorld)
   bne -
~~~~

> in 64tass and other assemblers of note - and + refer to the next symbol that is + ahead or – behind the current location, this saves us from the tedium of having to come up with a unique loop label name. see `Section 3.13.3 Anonymous symbols` in the 64tass docs for full details.

Great now VRAM is all set up, we have to tell the PPU where everything is, and then turn the screen on. 
~~~~
   ; set up screen addresses
   stz $2107 ; we want the screen at $$0000 and size 32x32
   lda #1
   sta $210B ; we want BG1 tile data to be $$1000 which is the first 4K word step
~~~~

We then have to set the screen mode, I'm using 0 which is 4 layers at 4 colours per char, that we want 8x8 chars and we have to enable BG1 but putting it on the "main screen"
~~~~
   stz $2105 ; 8x8 chars and Mode 0
   lda #1
   sta $212c ; BG1 is on the Main Screen
   lda #$ff
   sta $210e ; we also need to scroll up 1 pixel ( so do -1 )
   lda #$03
   sta $210e ; because the first line is not drawn
   lda #$0f
   sta $2100 ; don't blank, so show the screen at full brightness
-  jmp -     ; infinite loop we have nothing more to do

.enc "screen"
HelloWorld .text "hello world!"
~~~~
> as with the other size commands it’s important that the .text line is on the same line as the label `HelloWorld`

The SNES doesn't show the first line of data, this is because it fetches the data, and then outputs it while it is fetching the next line's data. This is normally a "don't notice, don't care" but for this example its "annoying" so I have to set the BG Vertical offset register to -1, the value is 10bits big so -1 is actually $03ff although $ffff in this cause would work just as well. The offset registers are odd, and they are another 16 bit register that has to be written as two 8 bits values. Thus, I write the lo then the hi to the same address. To scroll -1 so the entire char is visible. 

the final `BANK00.asm` file should look as follows
```
.as               ; Assume A8
.xs               ; Assume X8
.autsiz           ; Auto size detect
.databank $00     ; databank is 00
.dpage $0000      ; dpage is 0000
RESET
   clc
   xce ; enter 65816 mode
   rep #$30 ; AXY 16
   ldx #$1FFF
   txs      ; set the stack
   phk
   plb
   lda #0000
   tcd
   lda #$008f
   sta $2100 ; turn the screen off 
   lda #$8008     ; A -> B, FIXED SOURCE, WRITE BYTE | WRAM
   sta $4300
   lda #<>DMAZero ; 64Tass | get low word
   sta $4302
   lda #`DMAZero  ; 64Tass | get bank
   sta $4304
   stz $2181
   stz $2182      ; START AT 7E:0000
   stz $4305      ; DO 64K
   lda #$0001
   sta $420B      ; FIRE DMA
   sta $420B      ; FIRE IT AGAIN, FOR NEXT 64k
   rep #$20    ; A16
   lda #$008F  ; FORCE BLANK, SET OBSEL TO 0
   sta $2100
   stz $2105 ;6
   stz $2107 ;8
   stz $2109 ;A
   stz $210B ;C
   stz $210D ;E
   stz $210D ;E
   stz $210F ;10
   stz $210F ;10
   stz $2111 ;12
   stz $2111 ;12
   stz $2113 ;14
   stz $2113 ;14
   stz $2119 ;1A to get Mode7
   stz $211B ;1C these are write twice
   stz $211B ;1C regs
   stz $211D ;1E
   stz $211D ;1E
   stz $211F ;20
   stz $211F ;20
   stz $2123 ;24
   stz $2125 ;26
   stz $2126 ;27 YES IT DOUBLES OH WELL
   stz $2128 ;29
   stz $212A ;2B
   stz $212C ;2D
   stz $212E ;2F
   stz $2130 ;31
   lda #$00E0
   sta $2132
   ;ONTO THE CPU I/O REGS
   lda #$FF00
   sta $4200
   stz $4202 ;3
   stz $4204 ;5
   stz $4206 ;7
   stz $4208 ;9
   stz $420A ;B
   stz $420C ;D   
   ; CLEAR VRAM
   rep #$20        ; A16
   lda #$1809      ; A -> B, fixed source, write word | vram
   sta $4300
   lda #<>DMAZero  ; this get the low word, you will need to change if not using 64tass
   sta $4302
   lda #`DMAZero   ; this gets the bank, you will need to change if not using 64tass
   sta $4304       ; and the upper byte will be 0
   stz $4305       ; do 64k
   lda #$80        ; inc on hi write
   sta $2115
   stz $2116       ; start at $$0000
   lda #$01
   sta $420B       ; fire dma
   ; CLEAR CG-RAM
   lda #$2208      ; a -> b, fixed source, write byte | cg-ram
   sta $4300
   lda #$200       ; 512 bytes
   sta $4305
   sep #$20        ; A8
   stz $2121       ; start at 0
   lda #$01
   sta $420B       ; fire dma
   ; DMA Petscii Font
   rep #$30        ; AXY 16
   lda #<>PETSCII_Chars
   sta $4302
   sep #$20        ; A8
   lda #`PETSCII_Chars
   sta $4304
   ldx #size(PETSCII_Chars)
   stx $4305
   ldx #%00000001 | $1800   ; A->B, Inc, Write WORD, $2118
   stx $4300
   ldx #$1000
   stx $2116
   lda #$80
   sta $2115                ; inc VRAM port address
   lda #1
   sta $420B
   ; DMA Pallete
   ldx #<>PETSCII_Pal
   stx $4302
   lda #`PETSCII_Pal
   sta $4304
   ldx #8
   stx $4305
   ldx #%00000010 | $2200  ; A->B, Inc, Write 2 Bytes, $2122
   stx $4300
   stz $2121               ; start of Pallete
   lda #1
   sta $420B
   ; fill the screen with ' '
   ldx #$1809      ; A -> B, fixed source, write word | vram
   stx $4300
   ldx #<>DMASpace ; this get the low word, you will need to change if not using 64tass
   stx $4302
   lda #`DMASpace  ; this gets the bank, you will need to change if not using 64tass
   sta $4304       ; and the upper byte will be 0
   ldx #$800       ; DMA counts bytes not words so we must give a byte size not a word size
   stx $4305       ; do 64k
   lda #$80        ; inc on hi write
   sta $2115
   stz $2116       
   stz $2117       ; start at $$0000
   lda #$01
   sta $420B       ; fire dma
   ; draw the text
   stz $2116       
   stz $2117       ; reset the port to $$0000
   ldx #0
-  lda HelloWorld,x
   sta $2118       ; write the lower 8bits of tile number
   stz $2119       ; this will set the upper 2 bits, pal and other attributes to 0
   inx
   cpx #size(HelloWorld)
   bne -  
   ; set up screen addresses
   stz $2107 ; we want the screen at $$0000 and size 32x32
   lda #1
   sta $210B ; we want BG1 tile data to be $$1000 which is the first 4K word step
   stz $2105 ; 8x8 chars and Mode 0
   lda #1
   sta $212c ; BG1 is on the Main Screen
   lda #$ff
   sta $210e ; we also need to scroll up 1 pixel ( so do -1 )
   lda #$1f
   sta $210e ; because the first line is not drawn
   lda #$0f
   sta $2100 ; don't blank, so show the screen at full brightness
-  jmp -     ; infinite loop we have nothing more to do  

.enc "screen"
HelloWorld .text "hello world!"

NMI_ISR
   ; nothing needed yet
justRTI
   rti

.enc "screen" ; tell 64Tass we want the text to be written in C64 Screen codes encoding
DMASpace .word ' '

PETSCII_Chars .binary "petscii.chr"

PETSCII_Pal .binary "petscii.pal"

* = $ffb0
    .enc "none"
DMAZero
    .fill 16,0
    ;               111111111112
    ;      123456789012345678901
    .text "this is a dummy name "
.cerror * != $00ffd5, "name is too short", *
    .byte $20   ; Mapping
    .byte $00   ; Rom
    .byte $07   ; 128K
    .byte $00   ; 0 SRAM
    .byte $02   ; PAL
    .byte $33   ; Version 3
    .byte $00   ; rom version 0
    .word $FFFF ; complement
    .word $0000 ; CRC
    
; 65816 vectors
* = $ffe4
v16_COP    .word justRTI
v16_BRK    .word justRTI
v16_ABORT  .word justRTI
v16_NMI    .word NMI_ISR
v16_RESET  .word justRTI
v16_IRQ    .word justRTI

; 6502 vectors
* = $fff4
v02_COP    .word justRTI
v02_BRK    .word justRTI
v02_ABORT  .word justRTI
v02_NMI    .word justRTI
v02_RESET  .word RESET
v02_IRQ    .word justRTI   
```

To build the ROM you run 
`64tass -a -x -X -b master.asm -o master.sfc -l master.vice -L master.list --verbose-list`
then run the master.sfc in the emulator. I recommend my customised version of Mesen-S (https://github.com/oziphantom/Mesen-S) this will be more beneficial in future lessons, but for now any emulator should suffice. 

You should see the text HELLO WORLD! on the screen in the top left. 

