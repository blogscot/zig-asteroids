const rl = @import("raylib");
const Vector2d = rl.Vector2;

const rendr = @import("renderer.zig");
const playr = @import("player.zig");

pub fn main() anyerror!void {
    // Initialization
    //--------------------------------------------------------------------------------------

    var player = playr.Player().init();
    var quit = false;

    rl.initWindow(rendr.SCREEN_WIDTH, rendr.SCREEN_HEIGHT, "Asteroids");
    defer rl.closeWindow(); // Close window and OpenGL context

    rl.setTargetFPS(60); // Set our game to run at 60 frames-per-second
    //--------------------------------------------------------------------------------------

    // Main game loop
    while (!rl.windowShouldClose() and !quit) { // Detect window close button or ESC key
        // Update
        //----------------------------------------------------------------------------------
        // TODO: Update your variables here
        //----------------------------------------------------------------------------------

        // Draw
        //----------------------------------------------------------------------------------
        rl.beginDrawing();
        defer rl.endDrawing();

        if (rl.isKeyDown(rl.KeyboardKey.q)) {
            quit = true;
        }

        rl.clearBackground(rl.Color.black);

        player.visible = true;
        player.draw();

        //----------------------------------------------------------------------------------
    }
}
