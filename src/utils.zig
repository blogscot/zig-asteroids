const std = @import("std");
const rendr = @import("renderer.zig");
const rl = @import("raylib");

pub fn translation(x: f32, y: f32) rl.Vector2 {
    return rl.Vector2{ .x = rendr.SCREEN_WIDTH / x, .y = rendr.SCREEN_HEIGHT / y };
}

pub fn calc_distance(a: anytype, b: anytype) @TypeOf(a + b) {
    return @sqrt(a * a + b * b);
}
