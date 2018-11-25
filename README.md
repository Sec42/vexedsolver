# Simple solver for Vexed levels.

## Usage

    ./b-vexed-solv.pl Levels-Android/classic_levels.txt 5

Solves the 5th level of the Android classic levels.

The output is a graphical representation of the board for each step - in reverse order from the solution to the start.

## Description

Solving is done by a simple brute-force search over all moves.
For performance reasons some branches are pruned when the level is deemed unsolvable at this point.
These cases are:
- single stone of a color left
- last two stones of the same color on the "lowest" floor can't reach each other
  - at least one wall inbetween
  - non-removable stone inbetween

## Input format

The solver accepts levels in both Palm and Android format.

### Palm format

    [Level]
    board=10/10/10/5~d~a1/1h~1~~1~2/2~1~2~2/1h~d~d1a2/10
    solution=IdbEGdFe
    title=Kahlua

Each level is a ini-style block with a heading of `[Level]`
* The `board=` line defines the level
  * Each line of the level is delimited by `/`.
  * `~` is a free space.
  * Letters `a`-`z` represent a colored stone.
  * Numbers `1`-`10`are expanded to an equivalent amount of wall pieces.
* The `solution=` line defines a precomputed solution (see also https://github.com/Sec42/vexedsolver/issues/1)
  * Each two-character pair indicates which position on the board should be moved (column first, then row).
  * If the first letter is upper case, it's a move left, if the second letter is uppercase it's a move right.
  * Counting starts in the upper left corner of the level.
  * the length of the solution defines the "par" score.
* The `title=` line sets the level name

### Android format

    Albuquerque;......../.hf...e./.eab..fh/.XXX..XX/.Xc....X/..b.a.c.;19

three fields separated by `;`
* Field 1 is the level name
* Field 2 is the level
    * Each line of the level is delimited by `/`.
    * `.` is a free space.
    * Letters `a`-`z` represent a colored stone.
    * `X` is a wall.
* Field 3 is the 'par' score.


## Sources

Files in `Levels-Palm` are copied from the Original Palm version on Sourceforge:
http://vexed.cvs.sourceforge.net/vexed

Files in `Levels-Android` are copied from the free Android version `net.vgart.vexedpro`.
Unfortunately this is no longer available on the play store.
Last version can (as of this writing) be found at https://apkpure.co/vexed-pro/
