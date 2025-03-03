const std = @import("std");
const rl = @import("raylib");
const Vector2d = rl.Vector2;

const rendr = @import("renderer.zig");
const playr = @import("player.zig");

pub fn main() anyerror!void {
    // Initialization
    //--------------------------------------------------------------------------------------

    const rotation_angle: f32 = 4.0 * std.math.pi / 180.0;

    var player = playr.Player().init();
    var lives = playr.Lives().init();

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
        if (rl.isKeyDown(rl.KeyboardKey.right)) {
            player.rotate(rotation_angle);
        }
        if (rl.isKeyDown(rl.KeyboardKey.left)) {
            player.rotate(-rotation_angle);
        }
        if (rl.isKeyDown(rl.KeyboardKey.up)) {
            var thrust = player.get_direction();
            thrust = thrust.scale(0.06);
            player.apply_force(thrust);
        }
        if (rl.isKeyPressed(rl.KeyboardKey.space)) {
            player.shoot_bullet();
        }

        rl.clearBackground(rl.Color.black);

        for (0..player.lives) |i| {
            lives.icons[i].draw();
        }

        player.visible = true;
        player.draw();
        player.update();
        player.bounds();

        //----------------------------------------------------------------------------------
    }
}
