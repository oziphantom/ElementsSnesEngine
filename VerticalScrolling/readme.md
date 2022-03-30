Vertical scrolling SNES
-----------------------

This is not a beginners' example however compared to Horizontal is a bit more straight forward. I do still have some more advanced data manipulation and SNES concepts. 

The data set uses Blocks, or "meta tiles" as the NES community calls them, but I will use the original name from here on out.

Blocks
------
Blocks are grouping smaller chars or blocks to form larger "building blocks" of the background.

The data set I have used is ripped from "Outlaw example game" from the "Shoot'em'up'Construction Kit" on the C64, it uses 5x5 blocks. This sounds like a really odd thing to do, however the C64 is 40x25 so 5x5 is 8 by 5 blocks. On a SNES not so much. To get arround the 32 wide I actually buffer 40 chars and just DMA the middle 32. 

It has 248 8x8 chars which are combined into 68 5x5 blocks on a map that is 8x512 blocks big.
This saves a lot of memory as 5x25x512 bytes = 102,400 bytes(more than a C64 can hold) vs 512x8+68x25 bytes = 5796 bytes.

Each block is arranged
~~~
ABCDE
FGHIJ
KLMNO
PQRST
UVWXY
~~~
which is stored `ABCDEFGHIJKLMNOPQRSTUVWXY ABCDEFGHIJKLMNOPQRSTUVWXY ...` until all blocks are written. 

The high level of how the map works
-----------------------------------
You read the first byte of the map data, which is 55

You then multiple by the size of each block, which is 25 words so 50 bytes, you then add the base address of the block data, this then gets you the start of the block data start.

So `ActiveBlock = BlockBase + BlockNum*50`

We then need to get this onto the screen. 

So you read the first 5 words/10 bytes and DMA that to the screen. 

Then advance the screen pointer to the next line, then DMA the next 5 words/10 bytes.

Do this until all 5 rows are done, then move over 5 chars and do the next block over in the map. 

Repeat until you have done the whole line.

This is ineffecient, doing mul 50 is inconvienient and we don't want to do 5 lines at a time, we should spread it over as many frames as we can to keep the time taken low and the frame spikes low. 

So the first trick is to store the tiles split by rows so 
~~~
Row 1 ABCDE ABCDE ABCDE ...
Row 2 FGHIJ FGHIJ FGHIJ ...
Row 3 KLMNO KLMNO KLMNO ...
Row 4 PQRST PQRST PQRST ...
Row 5 UVWXY UVWXY UVWXY ...
~~~
so we now branch on which row we want, this gives us a fixed base address we don't need to add and more, as its just in the `LDA XXXX` and we now only need to do a mul 5 so the address is `ActiveBlock_Row = BlockNum*5` much tidier. 

The next optimisation is the Map it self, we have an index into the map where we start and normally you would add 8 to get to the next row, then 1 to get each block across the screen. I.E `MapData = (MapBase + MapRow*8)[0:8]` but we can store the map data as columns, so before we had
~~~
ABCDEFGH
IJKLMNOP
QRSTUVWX
...
~~~
Now you make
~~~
Col1 AIQ...
Col2 BJR...
Col3 CKS...
Col4 DLT...
Col5 EMU...
Col6 FNV...
Col7 GOW...
Col8 HPX...
~~~
now the row is a single number that we can just index to the colums to get the block for that row.

We still have to do BlockNum*10 though. Lets look at it for second. 
- Use the SNES Mul hardware
	For a number this small, fixed value, and as often as we do, it is faster to just cacluate it, by the time you load the registers, wait and read again you've lost clocks
- Lookup table
	While we have a single byte number of tiles this blows 2 pages(512 bytes) which is not bad given how often we will do this. But again by the time you do the shift 2 then look up, you are slightly ahead. But if your blocks spawn multiple banks you then need multiple copies of the table in each bank making its 2 pages per bank.
- Just calc it
	This is what I've done in this in this example
	Always look at the most optimal way to do this as well, I see two ways
	- x8 + x2
	~~~
		lda original
		asl a
		sta Temp
		asl a
		asl a
		adc Temp
	~~~
	- x4 + 1 + x2
	~~~
		lda original
		asl a
		asl a
		adc original
		asl a
	~~~
	The second is faster as we don't need to store the temp

If you have word indexs, ie more than 256 blocks, then you can just store the raw pointer to the block in the map and avoid the x10. But it costs twice as much ROM. However this then allows you to just have blocks and not need to make "sets" which spares you from having duplicated blocks in each set. But block optimisation and techniques is another topic.

Keeping track of where we are in the map
----------------------------------------
We must keep the top edge and the bottom edge which are defined as `BlockIndex:SubRowIndex`

_SubROwIndex_ is pre-multiplied by 2 because I use it lookup into a JSR table. So in this case it has the values 0,2,4,6,8

When it hits 10, we move to the next block and reset it to 0.

I've used "holds next plot", rather than "current plot". So I plot, and then move them, but this is arbitrary. 

One slight trick I will highlight; Detecting if you go over a "next char trigger"
~~~
		lda ScreenYOffset	; cache current Screen X offset
		sta MapTempWord
		clc
		adc #3				; x += 3
		sta ScreenYOffset
		eor MapTempWord		; if the bits are the same this will go to 0, not 0 otherwise
		and #$FFF8			; I only want to know if we have crossed over 8 pixels, i.e the 
		#A8					; upper 13 bits have changed, so mask away the lower 3bits (0-7)
		beq _noHold			; same, not crossed char boundary
~~~
so if we have 
0 + 3 = 3 then

0 eor 3 = 3 

3 & FFF8 = 0 therefore the same value no change. 

if we have

7 + 3 = A

7 eor A = D

D & FFF8 = 8 there for the value has gone over 

works with any power of 2. And saves having to keep a "char and pixel counter"

VRAM position, conviently in a vertical layout VRAM is continuios done, unlike horizontal where you go 0-31, then have 1024-1055 we have
~~~
   0-31
  32-64
....
 992-1023
1024-1055
1056-1088
~~~
so for the VRAM position I use a word rather than 8bit value, and I add/subtract 32 from it each time as it moves up and down the screen. This saves doing a x32 when I want to set the VRAM dest.

License
-------
This code is free to use however you wish.

**HOWEVER** the graphics are ripped from "SUECK Outlaw" and are **for educational proposes only** and can not be used in any other projects.

Building the code
-----------------
you will need 64tass and for minimal build

`64tass.exe -a master.asm -o vertical.sfc -b -X`

however for completeness I recommend

`64tass.exe -a master.asm -o vertical.sfc -b -X --no-caret-diag --dump-labels -l vertical.tass -L vertical.list --verbose-list --line-numbers`

