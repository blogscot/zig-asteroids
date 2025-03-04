const std = @import("std");
const utils = @import("utils.zig");
const rl = @import("raylib");
const Vector2d = rl.Vector2;

const NUM_ASTEROIDS: u32 = 45;
const INIT_ASTEROIDS: u32 = 3;

const VERTS: u32 = 11;
pub const Sizes = enum(u32) {
    small = 20,
    medium = 10,
    large = 5,

    pub fn smaller(size: Sizes) Sizes {
        switch (size) {
            Sizes.large => return Sizes.medium,
            Sizes.medium => return Sizes.small,
            Sizes.small => return Sizes.small,
        }
    }
};

pub fn Asteroids() type {
    return struct {
        rock: [NUM_ASTEROIDS]Asteroid(),

        const Self = @This();

        pub fn init() Asteroids() {
            var rock: [NUM_ASTEROIDS]Asteroid() = undefined;
            for (0..NUM_ASTEROIDS) |i| {
                rock[i] = Asteroid().init();

                if (i < INIT_ASTEROIDS) {
                    rock[i].alive = true;
                }
            }
            return .{ .rock = rock };
        }

        pub fn draw(self: *Self) void {
            for (0..NUM_ASTEROIDS) |i| {
                if (self.rock[i].alive) {
                    self.rock[i].draw();
                }
            }
        }

        pub fn update(self: *Self) void {
            for (0..NUM_ASTEROIDS) |i| {
                if (self.rock[i].alive) {
                    self.rock[i].update();
                }
            }
        }

        pub fn get_asteroid(self: *Self, i: usize) *Asteroid() {
            return &self.rock[i];
        }

        pub fn cleared(self: *Self) bool {
            for (0..NUM_ASTEROIDS) |i| {
                if (self.rock[i].alive) {
                    return false;
                }
            }
            return true;
        }

        pub fn reset(self: *Self, level: u32) void {
            for (0..NUM_ASTEROIDS) |i| {
                self.rock[i] = Asteroid().init();

                // let's make it slightly harder
                if (i < INIT_ASTEROIDS + level) {
                    self.rock[i].alive = true;
                }
            }
        }

        pub fn bounds(self: *Self) void {
            for (0..NUM_ASTEROIDS) |i| {
                if (self.rock[i].alive) {
                    self.rock[i].bounds();
                }
            }
        }

        pub fn spawn(self: *Self, parent: *Asteroid()) void {
            const new_size = parent.size.smaller();
            const new_obj_vert = parent.shrink();
            var count: u32 = 0;
            // find the first 3 unallocated asteroids and spawn
            // new smaller asteroids in its place
            for (0..NUM_ASTEROIDS) |i| {
                const rock = &self.rock[i];
                if (!rock.alive) {
                    rock.alive = true;
                    rock.location = parent.location;
                    rock.hit_radius = parent.hit_radius / 2;
                    rock.size = new_size;
                    rock.obj_vert = new_obj_vert;
                    count += 1;
                    if (count == 3) break;
                }
            }
        }

        pub fn collision(self: *Self, location: Vector2d, radius: f32) ?usize {
            for (0..NUM_ASTEROIDS) |i| {
                if (self.rock[i].alive) {
                    if (self.rock[i].collision(location, radius)) {
                        return i;
                    }
                }
            }
            return null;
        }

        pub fn is_area_clear(self: *Self, radius: f32) bool {
            for (0..NUM_ASTEROIDS) |i| {
                const rock = &self.rock[i];
                if (rock.alive) {
                    // calculate the distance between the asteroid and the centre
                    // where the player will respawn.
                    const distance = utils.calc_distance(rock.location.x, rock.location.y);
                    if (distance < radius) {
                        return false;
                    }
                }
            }
            return true;
        }
    };
}

fn Asteroid() type {
    return struct {
        alive: bool,
        size: Sizes,
        hit_radius: f32,
        rotation: f32,
        location: Vector2d,
        velocity: Vector2d,
        obj_vert: [VERTS]Vector2d,
        world_vert: [VERTS]Vector2d,

        const Self = @This();

        fn init() Asteroid() {
            var prng = std.Random.DefaultPrng.init(blk: {
                var seed: u64 = undefined;
                std.posix.getrandom(std.mem.asBytes(&seed)) catch unreachable;
                break :blk seed;
            });
            const rand = prng.random();

            var obj_vert = [VERTS]Vector2d{
                Vector2d{ .x = 0.0, .y = 0.4 },
                Vector2d{ .x = 0.2, .y = 0.3 },
                Vector2d{ .x = 0.2, .y = 0.1 },
                Vector2d{ .x = 0.4, .y = 0.0 },
                Vector2d{ .x = 0.3, .y = -0.2 },
                Vector2d{ .x = 0.1, .y = -0.2 },
                Vector2d{ .x = 0.0, .y = -0.3 },
                Vector2d{ .x = -0.2, .y = -0.2 },
                Vector2d{ .x = -0.4, .y = 0.0 },
                Vector2d{ .x = -0.3, .y = 0.3 },
                Vector2d{ .x = 0.0, .y = 0.4 },
            };
            var world_vert = [_]Vector2d{.{ .x = 0.0, .y = 0.0 }} ** VERTS;

            // convert player vertices from object space to world space
            const translation = utils.translation(2.0, 2.0);
            for (0..VERTS) |i| {
                obj_vert[i] = obj_vert[i].scale(88);
                world_vert[i] = world_vert[i].add(obj_vert[i]);
                world_vert[i] = world_vert[i].add(translation);
            }

            const sign_x: u32 = rand.intRangeAtMost(u32, 0, 100);
            const sign_y = rand.intRangeAtMost(u32, 0, 100);

            // start asteroid at random location
            var lx: i32 = rand.intRangeAtMost(i32, 0, utils.SCREEN_WIDTH / 2);
            var ly: i32 = rand.intRangeAtMost(i32, 0, utils.SCREEN_HEIGHT / 2);

            // give asteroid a random velocity
            var vx = rand.float(f32) / 2.0;
            var vy = rand.float(f32) / 2.0;

            const degrees = (@mod(rand.float(f32), 300.0) + 500) / 1000;

            if (sign_x >= 50) {
                vx = -vx;
                lx = -lx;
            }
            if (sign_y >= 50) {
                vy = -vy;
                ly = -ly;
            }

            return .{
                .alive = false,
                .size = Sizes.large,
                .hit_radius = 35.0,
                .rotation = degrees * std.math.pi / 180.0,
                .location = Vector2d{ .x = @as(f32, @floatFromInt(lx)), .y = @as(f32, @floatFromInt(ly)) },
                .velocity = Vector2d{ .x = vx, .y = vy },
                .obj_vert = obj_vert,
                .world_vert = world_vert,
            };
        }

        fn update(self: *Self) void {
            const translation = utils.translation(2.0, 2.0);
            // updates the asteroids location based off its velicity vector
            self.location = self.location.add(self.velocity);

            for (0..VERTS) |i| {
                self.world_vert[i] = self.obj_vert[i].add(self.location);
                self.world_vert[i] = self.world_vert[i].add(translation);
                self.obj_vert[i] = self.obj_vert[i].rotate(self.rotation);
            }
        }
        fn draw(self: *Self) void {
            rl.drawLineStrip(&self.world_vert, rl.Color.white);
        }
        /// Resets the asteroid position if it goes out of bounds.
        fn bounds(self: *Self) void {
            const widthLimit = @as(f32, @floatFromInt(utils.SCREEN_WIDTH / 2));
            const heightLimit = @as(f32, @floatFromInt(utils.SCREEN_HEIGHT / 2));

            if (self.location.x < -widthLimit) {
                self.location.x = widthLimit;
            }
            if (self.location.x > widthLimit) {
                self.location.x = -widthLimit;
            }
            if (self.location.y < -heightLimit) {
                self.location.y = heightLimit;
            }
            if (self.location.y > heightLimit) {
                self.location.y = -heightLimit;
            }
        }

        fn shrink(self: *Self) [VERTS]Vector2d {
            var new_vert: [VERTS]Vector2d = undefined;
            for (0..VERTS) |i| {
                const x = self.obj_vert[i].x * 0.5;
                const y = self.obj_vert[i].y * 0.5;
                new_vert[i] = Vector2d{ .x = x, .y = y };
            }
            return new_vert;
        }

        fn collision(self: *Self, location: Vector2d, radius: f32) bool {
            const a = self.location.x - location.x;
            const b = self.location.y - location.y;
            const distance = utils.calc_distance(a, b);
            return distance < self.hit_radius + radius;
        }
    };
}
