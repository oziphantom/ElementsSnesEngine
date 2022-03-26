Horizontal scrolling SNES
-------------------------

This is not a beginners’ example; this has some more advanced SNES concepts and data manipulation. 

The data set uses Blocks, or "meta tiles" as the NES community calls them, but I will use the original name from here on out.

Blocks
------
Blocks are grouping smaller chars or blocks to form larger "building blocks" of the background.
The data set I have used is ripped from "Mayhem in Monsterland" on the C64, it uses 4x4 blocks.
It has 245 8x8 chars which are combined into 136 4x4 blocks on a map that is 243x6 blocks big.
This saves a lot of memory as 544x20 bytes = 10880 bytes vs 1458+2176 bytes = 3634 bytes.

Each block is arranged
~~~
ABCD
EFGH
IJKL
MNOP
~~~

which is stored `ABCDEFGHIJKLMNOP ABCDEFGHIJKLMNOP ...` until all blocks are written

The high level of how the map works
-----------------------------------
You read the first byte of the map data, which is 70

You then multiply 70 by the size of each block, which is 16 words so 32 bytes, this gets you the block data start.

From there you read 8 bytes and transfer to the screen.

Then move done a line on the screen
Read 8 more
Repeat until all 4 lines are done.

Then you read the map[x+243] and repeat, and do this again for each 6 blocks that make up the height. (The C64 is 200 lines not 224)

And that is pretty simple, but very inefficient, if we were drawing a fixed screen, sure, but we are not, we are scrolling left and right we will want to update just a column often.

So the first trick is to store them `AEIMBFJNCGKODHLP`

Now the order is in col 1, col 2, col 3 and col 4 so we can just copy or DMA the 8 consecutive bytes direct. 

But setting up DMAs for 8 bytes runs is expensive, we would be better off putting all of a column for the screen into a single buffer and then doing a +32 VRAM DMA at once.

When we are doing a column, we want the same column of every block we are drawing, as they are aligned, we don't stagger the blocks.

To avoid a bunch of maths on each block we can store the columns of the blocks together, so
~~~
AEIM AEIM AEIM AEIM AEIM ...

BFJN BFJN BFJN BFJN BFJN ...

CGKO CGKO CGKO CGKO CGKO ...

DHLP DHLP DHLP DHLP DHLP ...
~~~
so before we had `blockdata[tile*32+column*4][0:3]`
no we have
~~~
col1 : blockdata.col1[tile*8][0:3]
col2 : blockdata.col2[tile*8][0:3]
col3 : blockdata.col3[tile*8][0:3]
col4 : blockdata.col4[tile*8][0:3]
~~~

and we have 6 blocks high, so we can just unroll the loop for speed. There are two options :
 - you can put the stack at the end of the buffer then push the data on. Which is 4 clocks but only 1 byte. 
 - Or you could move the DP and write sta XX unrolled which is also 4 clocks but 2 bytes.

I've gone with stack in this version.

The stack has another requirement; it flips the byte order so the stack will push hi lo. This means that the data needs to be _Intel_ byte order not _Motorola_ byte order. Which is handy for tool making, gives us _Intel->Motorola_ "for free"

So each ‘blk’ file is now
`hi lo hi lo hi lo hi lo` for each column of each block. If you where using the DP method, you could flip it or leave it lo hi as you prefer.

Now that I have my buffer of column data backwards I have to get it to VRAM, which is done by a reverse src +32 VRAM dest DMA. I could write the data backwards and do a forward DMA, but then the map data would need to be _Motorola_ order again.

This is great but what happens when you have more than one MAP?

Well if you have enough banks, you can put tiles + map into the same spot in each bank as needed and just switch the databank register.

OR if you have a lot you will want to compress this data anyway so you just unpack to the same spot in RAM. But RAM is slow right? well you want to do sequential reads of which the WRAM port is perfect for and full speed. You could even put the DP to the WRAM port register for extra speed loops of
~~~
lda $80 ; set the DP to $2100 so you don't pay a clock penalty for not having page alignment
pha
lda $80
pha
lda $80
pha
~~~ 


Keeping track of where we are in the map
----------------------------------------
We must keep the left edge and the right edge where we are defined as `BlockIndex:SubCharIndex`

_SubCharIndex_ is pre-multiplied by 2 because I use it lookup into a JSR table. So in this case it has the values 0,2,4,6

When it hits 8, we move to the next block and reset it to 0. 

I've used "holds next plot", rather than "current plot". So I plot, and then move them, but this is arbitrary. 

One slight trick I will highlight; Detecting if you go over a "next char trigger"

		lda ScreenXOffset	; cache current Screen X offset
		sta MapTempWord
		clc
		adc #3				; x += 3
		sta ScreenXOffset
		eor MapTempWord		; if the bits are the same this will go to 0, not 0 otherwise
		and #$FFF8			; I only want to know if we have crossed over 8 pixels, i.e the 
		#A8					; upper 13 bits have changed, so mask away the lower 3bits (0-7)
		beq _noHold			; same, not crossed char boundary

so if we have 
0 + 3 = 3 then

0 eor 3 = 3 

3 & FFF8 = 0 therefor the same value no change. 

if we have

7 + 3 = A

7 eor A = D

D & FFF8 = 8 there for the value has gone over 

works with any power of 2. And saves having to keep a "char and pixel counter"

License
-------
This code is free to use however you wish.

**HOWEVER** the graphics are ripped from "Mayhem in Monsterland" and are **for educational proposes only** and can not be used in any other projects.

Building the code
-----------------
you will need 64tass and for minimal build

`64tass.exe -a master.asm -o horizontal.sfc -b -X`

however for completeness I recommend

`64tass.exe -a master.asm -o horizontal.sfc -b -X --no-caret-diag --dump-labels -l horizontal.tass -L horizontal.list --verbose-list --line-numbers`
