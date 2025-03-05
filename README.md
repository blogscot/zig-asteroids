# Zig Asteroids

## Description

This is a recreation of the classic Asteroids game, written in the [Zig](https://ziglang.org/) programming language using the Raylib Zig bindings. 

In an earlier version, I ported a C implementation of the game which used SDL2, however since that time, I've found Raylib is easier to work with. In addition, a couple of files in the earlier port that dealt with vectors and rendering were removed as they were no longer needed. 

## Possible future features

 * ~add scoring~ done
 * add sound effects
 * ~add start screen~ done
 * add high score screen

## Building the game

Initially, to build the game, you need to install the [Raylib](https://github.com/Not-Nik/raylib-zig) bindings, using:

`zig fetch --save git+https://github.com/Not-Nik/raylib-zig#devel`

Then to build, type `zig build`, or to build and run, type `zig build run`.

The directory structure is as follows:

```zsh
.
├── README.md
├── build.zig
├── build.zig.zon
├── src
│   ├── asteroids.zig
│   ├── main.zig
│   ├── player.zig
│   └── utils.zig
└── zig-out
    └── bin
        └── ray-asteroids
```

## Controls
* s starts the game
* r restarts the game
* left arrow to rotate left
* right arrow to rotate right
* up arrow to apply thrust
* space to shoot
* ESC to exit

## Images
![animation](https://i.imgur.com/vgPzgha.gif)

## Tool Versions

 + Raylib version 5.5
 + Zig version 0.14.0
