const std = @import("std");
const rl = @import("raylib");
const Vector2d = rl.Vector2;

const utils = @import("utils.zig");
const playr = @import("player.zig");
const aster = @import("asteroids.zig");

pub fn main() anyerror!void {
    // Initialization
    //--------------------------------------------------------------------------------------

    const rotation_angle: f32 = 4.0 * std.math.pi / 180.0;

    var player = playr.Player().init();
    var asteroids = aster.Asteroids().init();
    var lives = playr.Lives().init();

    var quit = false;

    rl.initWindow(utils.SCREEN_WIDTH, utils.SCREEN_HEIGHT, "Asteroids");
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

        rl.drawText("Score:   0", 540, 10, 14, rl.Color.light_gray);

        for (0..player.lives) |i| {
            lives.icons[i].draw();
        }

        asteroids.update();
        asteroids.draw();
        asteroids.bounds();

        player.visible = true;
        player.draw();
        player.update();
        player.bounds();

        //----------------------------------------------------------------------------------
    }
}
