const std = @import("std");
const rl = @import("raylib");
const Vector2d = rl.Vector2;

const utils = @import("utils.zig");
const playr = @import("player.zig");
const aster = @import("asteroids.zig");

const GameState = struct {
    player: *playr.Player(),
    asteroids: *aster.Asteroids(),
    lives: *playr.Lives(),
    score: *u32,
    level: *u32,
};

pub fn main() anyerror!void {
    // Initialization
    //----------------------------------------------------------------

    const rotation_angle: f32 = 4.0 * std.math.pi / 180.0;

    // Game state
    var player = playr.Player().init();
    var asteroids = aster.Asteroids().init();
    var lives = playr.Lives().init();
    var score: u32 = 0;
    var level: u32 = 0;

    var show_start_msg: bool = true;
    player.lives = 0;

    var game_state = GameState{
        .player = &player,
        .asteroids = &asteroids,
        .lives = &lives,
        .score = &score,
        .level = &level,
    };

    var fired = false;
    var quit = false;
    const buffer_size = 20;
    var buffer: [buffer_size]u8 = undefined;
    const translation = utils.translation(-2.0, -2.0);

    rl.initWindow(utils.SCREEN_WIDTH, utils.SCREEN_HEIGHT, "Asteroids");
    defer rl.closeWindow(); // Close window and OpenGL context

    const font1 = try rl.loadFont("resources/fonts/mecha.png");
    defer rl.unloadFont(font1);
    const font2 = try rl.loadFont("resources/fonts/setback.png");
    defer rl.unloadFont(font2);

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
                var thread = try std.Thread.spawn(.{}, restart_game, .{ &game_state, &fired });
                thread.detach();
            }
        }
        if (show_start_msg and rl.isKeyPressed(rl.KeyboardKey.s)) {
            show_start_msg = false;
            player.lives = playr.NUM_LIVES;
        }

        rl.clearBackground(rl.Color.black);

        const scoreText = std.fmt.bufPrintZ(&buffer, "{d:0>5}", .{score}) catch unreachable;
        rl.drawTextEx(font1, scoreText, .{ .x = 595.0, .y = 10.0 }, 16, 2, rl.Color.light_gray);

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
            const width = utils.SCREEN_WIDTH / 2;
            const height = utils.SCREEN_HEIGHT / 2;
            if (show_start_msg) {
                rl.drawTextEx(font2, "Press S to start", .{ .x = width - 110, .y = height - 40 }, 24, 2, rl.Color.light_gray);
            } else {
                rl.drawTextEx(font2, "Game Over!", .{ .x = width - 65, .y = height - 60 }, 24, 2, rl.Color.light_gray);
                rl.drawTextEx(font2, "Press R to restart", .{ .x = width - 105, .y = height - 20 }, 20, 2, rl.Color.light_gray);
            }
        }

        // check for bullets collision
        for (0..player.bullets.len) |i| {
            if (player.bullets[i].is_alive()) {
                // convert bullet screen space location to world space to compare
                // with asteroids worlds space to detect a collision
                const world = player.bullets[i].location.add(translation);
                if (asteroids.collision(world, 1)) |index| {
                    var asteroid = asteroids.get_asteroid(index);
                    score += @intFromEnum(asteroid.size);
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

fn restart_game(state: *GameState, fired: *bool) void {
    state.player.* = playr.Player().init();
    state.asteroids.* = aster.Asteroids().init();
    state.lives.* = playr.Lives().init();
    state.score.* = 0;
    state.level.* = 0;
    fired.* = false;
}

fn respawn(asteroids: *aster.Asteroids(), fired: *bool, level: u32) void {
    rl.waitTime(2);
    asteroids.reset(level);
    fired.* = false;
}
