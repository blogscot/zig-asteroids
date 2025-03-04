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

    var fired = false;
    var quit = false;
    var level: u32 = 0;

    rl.initWindow(utils.SCREEN_WIDTH, utils.SCREEN_HEIGHT, "Asteroids");
    defer rl.closeWindow(); // Close window and OpenGL context

    rl.setTargetFPS(60); // Set our game to run at 60 frames-per-second
    //--------------------------------------------------------------------------------------

    // Main game loop
    while (!rl.windowShouldClose() and !quit) { // Detect window close button or ESC key

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
        if (!player.is_alive() and rl.isKeyPressed(rl.KeyboardKey.r)) {
            if (!fired) {
                fired = true;
                var thread = try std.Thread.spawn(.{}, restart_game, .{ &asteroids, &player, &lives, &fired });
                thread.detach();
            }
        }

        rl.clearBackground(rl.Color.black);

        rl.drawText("Score:   0", 540, 10, 14, rl.Color.light_gray);

        if (asteroids.cleared() and !fired) {
            fired = true;
            level += 1;
            var thread = try std.Thread.spawn(.{}, respawn, .{ &asteroids, &fired, level });
            thread.detach();
        }
        asteroids.update();
        asteroids.draw();
        asteroids.bounds();

        if (player.is_alive()) {
            for (0..player.lives) |i| {
                lives.icons[i].draw();
            }

            // draw player and bullets
            player.draw();
            player.update();
            player.bounds();

            if (player.visible) {
                // check for player collision
                if (asteroids.collision(player.location, player.hit_radius)) |_| {
                    player.death();
                }
            } else {
                if (asteroids.is_area_clear(player.hit_radius * 5)) {
                    player.respawn();
                }
            }
        } else {
            rl.drawText("Game Over!", utils.SCREEN_WIDTH / 2 - 60, utils.SCREEN_HEIGHT / 2 - 60, 20, rl.Color.light_gray);
            rl.drawText("Press R to restart", utils.SCREEN_WIDTH / 2 - 100, utils.SCREEN_HEIGHT / 2 - 20, 20, rl.Color.light_gray);
        }

        // check for bullets collision
        const translation = utils.translation(-2.0, -2.0);

        for (0..player.bullets.len) |i| {
            if (player.bullets[i].is_alive()) {
                // convert bullet screen space location to world space to compare
                // with asteroids worlds space to detect a collision
                const world = player.bullets[i].location.add(translation);
                if (asteroids.collision(world, 1)) |index| {
                    var asteroid = asteroids.get_asteroid(index);
                    asteroid.alive = false;
                    player.bullets[i].alive = false;
                    if (asteroid.size != aster.Sizes.small) {
                        asteroids.spawn(asteroid);
                    }
                }
            }
        }

        //----------------------------------------------------------------------------------
    }
}

fn restart_game(asteroids: *aster.Asteroids(), player: *playr.Player(), lives: *playr.Lives(), fired: *bool) void {
    asteroids.* = aster.Asteroids().init();
    player.* = playr.Player().init();
    lives.* = playr.Lives().init();
    fired.* = false;
}

fn respawn(asteroids: *aster.Asteroids(), fired: *bool, level: u32) void {
    rl.waitTime(2);
    asteroids.reset(level);
    fired.* = false;
}
