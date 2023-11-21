# Random Things

As I have put out the other future lessons, I've have come across a few things that people also need explaining that are strictly in what learning ASM will teach you, things that I have just glossed over. This is to tell you the titbits, handy features and things that are not really explained, as they are reported to me. 

### Big Endian and the `LO HI` format:
In the beginning computers were 4bits and then they were 8bits and this was mostly fine, they were small enough in nature that what happened didn't really matter. But the bits need to be grouped in some way, which way though? Well for a binary system there are two ways.

We could write it in Human form (4 bits)  
8421  
Or add bits as we go up in a logical sense, i.e.  
1248  
the first is Big Endian, i.e., the largest "value" for the bit is at the start, while the second is Little Endian as it starts with the lowest value. 

The first makes sense to a human that uses Arabic numbers, as we have 1,10,100,1000,10000 which keeps expanding to the left as the value of each digit position increases. However, lets expand the above 4 bits to 8 bits

```
1
2631
842684321
```
and
```
       1
    1362
12486248
```
the second now has a clear advantage, as we expand to add more bits the position and data of values doesn't move. In this new 8-bit system I can still read 4 bits from memory and it would have the same value, but on the first system if I only read in 4bits, now the 4bits occupy the upper 4 bits not the lower 4bits. When expanding from the 8bit to 16bit this became a problem, and the solution chosen is to store each 8bit in increasing order. I.e. we store the bits number as 
```
          111111
76543210  54321098
```

This way we store the `lower` 8bits and then `upper` 8bits, but the bits within each _chunk_ is still big endian, so it has number going both ways which is a bit weird. 

lower -> low -> lo  
higher -> high -> hi

In the 65XX eco system lo then hi order is the standard and almost everything will be stored in `LOHI` format, although there are some rare cases that are stored `HILO` order. 

This is expanded on the SNES to 24bits oh which the order becomes
```
          111111    22221111
76543210  54321098  32109876
```
which is LO HI BANK order. 

How does this affect things? For example, if you look at assembled code you will notice that addresses are store LOHI in memory, for example 
`8D 20 D0  STA $D020`, if you are looking at hex dump or the code output you will see this order or `8f 20 d0 80  STA $80D020`. 

When you make a 16 value or a _pointer_ in memory you would also construct it in this order. I.E when you use the `(dp)` or `[dp]` if you want the dp address to point to $8123 and the dp is address $00. To do this you store $23 at $00 and then $81 at $01. Again `LO HI`. To this end, if I did 
```
LDA #$8123
STA $00
``` 
Then the CPU will store $23 at $00 and then $81 at $01, i.e. it will store the bytes in the opposite order you _write_ it in. Which is confusing but you will soon get it. This allows you when in 16bit mode you can set two 8 bit registers with a single write. Say for example you want to set Left X and the right X of a Window, you might speed it up by doing

```
LDA #$E010
STA $2126
```
which sets $2126 to $10 and $2127 to $E0

When using a hex editor, it is important to note the difference between the two endians as you will get very different numbers. I.E `%10000000` in Big Endian is 128 while in Little Endian it is 1. Be sure to make sure you Hex editor of choice is set to Big Endian, historically it also been called Motorola order for Big and Intel order for Little. 

### Terms
The SNES scene has attracted a few *cowboys* over the years, and so a few terms have been *invented* or made in isolation from the rest of programming. Some terms have different meanings in the context of SNES programming, and some terms are used in a standard sense but the standard has moved on so much in the last 35+ years that it means something else now. 

**byte** 8bits of data  
**word** 16bits of data  
**long** 24bits of data

**WRAM** Work RAM this is the internal 128K of RAM located in Banks 7E and 7F, of which the first 8K is mirrored it a lot of other banks.  
**SRAM** Save RAM this is on cart battery backed up RAM mostly used for holding Save data.  
**VRAM** Video RAM this is the 64K of RAM connected to the PPU1 and PPU2 which holds all graphics tile data, sprite data and map data.  
**CGRAM** Colour Graphics RAM, this holds the pallet data and is separate from all other RAM  
**OAM** Object Attribute Memory, this holds the sprite/object data, such as X, Y, Attributes and tile number but not any tile data.

**LOROM** This is `Mapper 20` and gives you 32K Blocks of ROM in each Bank   
**HIROM** This is `Mapper 21` and gives you 64K Blocks of ROM in each Bank

**Banks** The SNES for all intents and purposes doesn't do Banking ( there are some edge cases of cause but don't worry about those for a very long time, if ever ) it has a flat memory map, rather it's better to think of things in terms of _blocks_ of RAM, SRAM, ROM. I.e. there is a 32K block of ROM at 00:8000-00:FFFF in LOROM and then another block of ROM at 01:80000-01:FFFF, although almost all documentation will refer to these as Banks and the upper byte is called the `Bank Byte`. It is important to think about what it is a bank of. As there is the Memory Map Banks, i.e., the upper 8 bits of the address and then there is ROM Banks which occupy part of Memory Bank. SRAM has multiple Banks of a couple of K (depends on the mapper being used) which are then spread through a lot of Memory Map Banks. 

**NAMETABLE,SCREEN,MAP** the data for what tile appears where on the screen may have one of these names, _Name Table_ is the NES term and the official term, however most other machines call them Screen, Screen Map or even just Map

**TILES** the actual definition data for an 8x8 square is called a tile on the SNES, while other machines will call them chars or character definitions.

**S-SMP** This is the complete name for the SPC-700 as it also includes the S-DSP chip.

**BYTE ADDRESS** this means each address number points to a byte of memory. I.e. $00 points to 1 byte and then $01 points to the next byte. CPU memory is Byta Address.  
**WORD ADDRESS** this means each address number points to a word of memory. I.e $00 points to 2 bytes and then $01 points to the 3rd byte not the 2nd byte. Each address contains 16bits of data not 8 bits of data. VRAM is Word Address.  

### How to read documentation
Different documentations have different styles. The two main examples are the official Nintendo development books, and FullSNES by NO$CASH. For legal reason I will only quote FullSNES here. 

NO$CASH has his "own style" and he very much sat at the knee of Intel and likes to think of everything in Intel's terms. This is mostly fine however one particular instance is how one represents numbers. Intel use the h suffix to denote a hex number, i.e. `2100h` while MOS assembly format is a $ prefix for hex i.e. `$2100` so when you read a number in his documentation and it ends in a `h` that means it is a hex address.  
He also likes to write assembly examples in a somewhat Intel format using `mov` over `lda sta` but he does not use true intel numbers. If you are new to assembly and are not familiar with x86 and 65XX assembly it is best to ignore NO$CASH's assembly examples for now.

There are 3 main types of registers

1. Byte registers  
2. Word registers  
3. Bit field registers

A Byte registers is pretty straight forward, you just write a value to it, $2126 for example. 

A Word register is again pretty straight forward, you just write a 16bit value to it, or two 8bits in `LOHI` order to address and address+1, $2116 for example.

Bit Fields are little trickier, for example

> 212Ch - TM - Main Screen Designation (W)  
> 212Dh - TS - Sub Screen Designation (W)  
>   
>  7-5  Not used  
>  4    OBJ (0=Disable, 1=Enable)  
>  3    BG4 (0=Disable, 1=Enable)  
>  2    BG3 (0=Disable, 1=Enable)  
>  1    BG2 (0=Disable, 1=Enable)  
>  0    BG1 (0=Disable, 1=Enable)  
>  \-    Backdrop (Always enabled)  

Each bit does something and is not connected to the other bits, so it's a "field" which is an old-fashioned term for "an entry to be filled in", i.e., instead of looking at this as 1 register its actually 5 registers at one address. Due to Big Endian order as described above. If we wish to set the OBJ _on_ we would need to _set_ bit 4, which is in turn actually the 5th bit, and thus has the value of $10. Thus 
```
LDA #$10
STA $212C
```
Will enable Sprites and **only** sprites on the _Main Screen_. To set Sprites and BG1 then you would set bits 4 and 0 i.e. 5th and 1st which is then `$11` most assemblers will let you specify this with a bit number using the `%` operator and thus you set them like so `LDA #%00010001` again note the Big Endian order matches the written order. 

Sometimes you have groupings that form their own "number of bits" fields within the register, for example
```
  7    BG4 Tile Size (0=8x8, 1=16x16)  ;\(BgMode0..4: variable 8x8 or 16x16)
  6    BG3 Tile Size (0=8x8, 1=16x16)  ; (BgMode5: 8x8 acts as 16x8)
  5    BG2 Tile Size (0=8x8, 1=16x16)  ; (BgMode6: fixed 16x8?)
  4    BG1 Tile Size (0=8x8, 1=16x16)  ;/(BgMode7: fixed 8x8)
  3    BG3 Priority in Mode 1 (0=Normal, 1=High)
  2-0  BG Screen Mode (0..7 = see below)
```
  Here we have 5 bit fields and then a 3bit field. It may be more convenient for you to use an | (or) operator when writing these in your code. For example, say we want mode 5 and we want BG1 to be 16x16 and BG2 to 8x8 we could write `LDA #%000101001` or `LDA #%00010001 | 5` be sure to type all significant digits for your binary value, `%0001` and `%00010000` are not the same number, however `%00010000` and `%10000` are. 
  
  This can get more complex however, take for example the Attributes data for a sprite,

> Attributes:  
>  
>  Bit7    Y-Flip (0=Normal, 1=Mirror Vertically)  
>  Bit6    X-Flip (0=Normal, 1=Mirror Horizontally)  
>  Bit5-4  Priority relative to BG (0=Low..3=High)  
>  Bit3-1  Palette Number (0-7) (OBJ Palette 4-7 can use Color Math via CGADSUB)  
>  Bit0    Tile Number (upper 1bit)  

Here we have 2 bit fields, 1 2-bit field, and 1 3-bit field, and the top bit of a 9bit field. For this you would probably use shifts and the hex values for the upper values. i.e., `LDA #$C0|3<<4|2<<1|1` this sets both Y and X flip, the priority to 3 and the Palette number to 2 and the upper bit of the tile to 1. In 64tass I would make a _function_ to handle this for me, but that is getting ahead of ourselves.

#### Register value sizes and access sizes might not be the same. 
For example, the V scroll and H scroll registers are 16 bits, only each one is at an 8bit address. The documentation will tell you they are `write twice`. This means you need to write the LO then HI value of the 16bit to the same address with 2 writes to update the whole value. 

i.e. to set BG Horizontal scroll to $1234 you would do
```
LDA #$34
STA $210D
LDA #$12
STA $210D
```
doing
```
LDA #$1234
STA $210D
```
would set the lower 8 bits of X scroll to $34 and the lower 8 bits of Y scroll to $12, probably not what you want. 

