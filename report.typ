#let autoGrid(..body, rowNum: 1) = grid(
  columns: (1fr,)*int(body.pos().len()/rowNum),
  column-gutter: 1em, row-gutter: 1em, align: left+horizon,
  ..body
)
#let style(body) = {
  set par(justify: true, leading: 9pt, spacing: 1.2em)
  set text(font: "Charis", size: 12pt)
  set document(
    author: ("Yue Jiang", "Boxuan Song"),
    title: [Digital System Project Report],
    description: [Report of the Digital System Sokoban Project.]
  )
  set page(numbering: "1")
  set heading(numbering: "1.")
  show link: underline
  show link: set text(fill: blue)
  show raw: set text(font: "Cascadia Code NF")
  show "i.e.": set text(style: "italic")
  show "etc.": set text(style: "italic")
  align(center, smallcaps(
    text(size: 1.8em)[*Digital System* \ ] +
    text(size: 1.2em)[*Sokoban Project Report* \ ]+
    [
      Boxuan Song, 999025455 \
      Yue Jiang, 999027808
    ]
  ))
  body
}

#show: style

#outline()

// 1. Names and IDs of all contributing team members + URLs and/or names of any existing resource reused in the project.

= References
+ The Boxxle game on Game Boy by Thinking Rabbit, as a reference for the game design and logic. (#link("https://wowroms.com/en/roms/nintendo-gameboy/download-boxxle-usa-europe-rev-a/9012.html")[Where I download it])

+ Resources and code from the lab.

// 2. Description of how to play the game. Keys. Features implemented. 

= Game Description

== Features

- Full Sokoban mechanics, with a reset button to restart the level.
- A splash screen on start and victory screens for each level.
- A move counter showing your current moves. (Capped to and wrapping on 255)
- An undo function for the last step. (Once only)

== How to play it

- The game starts at a splash screen showing the title. Press `START` to start.
- When a level is finished (all boxes are on the goal), press `START` to the next level. When all levels are finished, you win the game.

=== Keys when playing

+ Arrow keys `->` Control the movement of the player;
+ Start `->` Restart this level;
+ Select `->` Undo one step, nothing to do if already undone;
+ B button `->` Jump into next level (developer mode);
+ A button `->` No any effects.

= Implementation Description

In our implementation, all the tiles are located in background. We do not use objects.

== Finite state machine
Our groups uses finite state machine to control the game state. We set 5 states for the games.

=== `Splash`
A simple state that shows the title of the game. It will wait for the `START` key to be pressed, then it will change to `LevelLoad`.

=== `LevelLoad`

A state that loads the level from the ROM. It will set up the initial game state, read the level map from the ROM to the VRAM (BG tile map) and scan the map for variables `man_pos` (initial address of the player tile in the VRAM) and `box_num` (numbers of boxes to be pushed into goal). After loading, it will change to `LevelPlay`.

=== `LevelPlay`

==== Ideas
We write LevelPlay based on the idea: "We only need to preserve the location of the man." After pressing the key, we will find out whether a place is reachable or the box will be pushed.

After Readkeys, we can know in which direction where the man wants to go. Then after calculation, we can find out whether the place that the man wants to go has any objects.

+ If the place where the man wants to go is the wall, then the man will remain where he is. 

+ If the place where the man wants to go is empty or the goal, then the man will directly go to the place and that's the end.

+ If the place where the man wants to go is the box, then the man will try to push the box.
  + If the place where the box goes is the wall or the box, then the box will not be pushed. 
  + If the place where the box goes is the space, blank or goal, then the box will be pushed to that place.


==== Determine if the level is finished

We use variable `box_num` to preserver how many boxes that need to be pushed. There are `box_num` boxes still needs to be pushed into the goal.

+ Whenever the box enters the "goal", it will decrease the `box_num`;

+ Whenever the box leaves the "goal", it will increase the `box_num`.

Whenever the `box_num` reaches zero, it shows that all the boxes have been put into the right place.

=== `LevelWin`
A state that shows the victory screen, or directly change to `GameWin` if all levels are completed. If `level < LEVEL_NUM`, it will wait for the `START` key to be pressed, then it will change to `LevelLoad` to load the next level.

=== `GameWin`
A state that shows the victory screen of the game. Nothing to do but loading and showing the victory screen.

== Tiles and graphics
The tiles are stored in the background, fixed at the upper left corner with $20 times 18$ tiles. Tiles for the game objects are drawn by us using a simple tile editor, also made by us (using MS Excel). Tiles for texts are from the lab.

== Building
The project can be built using the `make` command. The build process will:

+ First, generate the final `data.asm` from `data.nolevels.asm` and `levels.txt` by a Python script, to transform the level data into a format that can be used by the assembler;

+ Then, assemble the source code, link it and fix it to create a Game Boy ROM.

However, you can also build the project only with `main.asm`, generated `data.asm` and the "standard" `hardware.inc` by `rgbasm`. The whole project source files could be found in the attachment of this PDF.

== Shortcomings
The position of tiles in the background is fixed and cannot be separated into smaller parts. If the player and boxes are required to move smoothly, then they should be written as objects.