const std = @import("std");
const rl = @import("raylib");

pub const SCREEN_WIDTH = 640;
pub const SCREEN_HEIGHT = 480;

pub fn translation(x: f32, y: f32) rl.Vector2 {
    return rl.Vector2{ .x = SCREEN_WIDTH / x, .y = SCREEN_HEIGHT / y };
}

pub fn calc_distance(a: anytype, b: anytype) @TypeOf(a + b) {
    return @sqrt(a * a + b * b);
}
