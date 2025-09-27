# Tetra

Tetra is a classic falling-block puzzle game inspired by Tetris, created for the PICO-8 fantasy console.

## How to Play

You can play Tetra directly in your browser by visiting the official project page:

[Play Tetra](https://tmaiadev.github.io/pico8-tetra/)

Alternatively, if you own PICO-8, you can load the game cartridge `tetra.p8` and run it natively.

### Controls

The controls are simple and designed for a classic keyboard layout:

- **LEFT / RIGHT Arrows:** Move the falling tetromino left and right.
- **DOWN Arrow:** Speed up the tetromino's descent (soft drop).
- **DOWN Arrow + X:** Instantly drop the tetromino to the bottom (hard drop).
- **UP Arrow / Z:** Rotate the tetromino

## Why Does the Source Code Look Weird?

If you're looking at the source code in `tetra.p8` outside of the PICO-8 environment, it might seem a bit unconventional. There are a couple of reasons for this!

First, this was my very first project written in Lua and my first time developing for PICO-8. I built this game primarily as a fun exercise to learn the language and the platform. I'm a complete novice on this subject.

Secondly, the code is formatted to be viewed and edited within PICO-8's built-in IDE. PICO-8 is a "fantasy console" – a self-contained game development environment with intentional limitations (like a small screen resolution, limited color palette, and a tiny code editor viewport). These constraints are designed to be fun and encourage creativity. The short variable names and specific indentation style are common practices among PICO-8 developers to fit as much readable code on the small screen as possible.
