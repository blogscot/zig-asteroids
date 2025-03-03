const utils = @import("utils.zig");

const rl = @import("raylib");
const Vector2d = rl.Vector2;

const P_VERTS: u32 = 3;
const NUM_LIVES: u32 = 3;
const NUM_BULLETS: u32 = 3;

const Bullet = struct {
    location: Vector2d,
    velocity: Vector2d,
    alive: bool,

    pub fn is_alive(self: *Bullet) bool {
        return self.alive;
    }
};

pub fn Lives() type {
    return struct {
        icons: [NUM_LIVES]Player(),

        const Self = @This();

        pub fn init() Lives() {
            var icons: [NUM_LIVES]Player() = undefined;
            var top_left: Vector2d = Vector2d{ .x = 20.0, .y = 20.0 };

            for (0..NUM_LIVES) |i| {
                icons[i] = Player().init();
                icons[i].lives = 1;
                icons[i].visible = true;
                icons[i].location = top_left;
                for (0..P_VERTS) |j| {
                    icons[i].obj_vert[j] = icons[i].obj_vert[j].scale(0.5);
                    icons[i].world_vert[j] = icons[i].obj_vert[j].add(icons[i].location);
                }
                top_left.x += 20.0;
            }
            return .{ .icons = icons };
        }

        pub fn draw(self: *Self) void {
            rl.drawTriangleLines((Vector2d){ .x = self.world_vert[0].x, .y = self.world_vert[0].y }, (rl.Vector2){ .x = self.world_vert[1].x, .y = self.world_vert[1].y }, (rl.Vector2){ .x = self.world_vert[2].x, .y = self.world_vert[2].y }, rl.Color.white);
        }
    };
}

pub fn Player() type {
    return struct {
        hit_radius: f32,
        visible: bool,
        lives: u32,
        location: Vector2d,
        velocity: Vector2d,
        obj_vert: [P_VERTS]Vector2d,
        world_vert: [P_VERTS]Vector2d,
        bullets: [NUM_BULLETS]Bullet,

        const Self = @This();

        pub fn init() Player() {
            var obj_vert = [P_VERTS]Vector2d{
                Vector2d{ .x = 0.0, .y = 1.5 },
                Vector2d{ .x = -1.0, .y = -1.0 },
                Vector2d{ .x = 1.0, .y = -1.0 },
            };

            var world_vert = [_]Vector2d{.{ .x = 0.0, .y = 0.0 }} ** P_VERTS;

            // convert player vertices from object space to world space
            const translation = utils.translation(2.0, 2.0);
            for (0..P_VERTS) |i| {
                obj_vert[i] = obj_vert[i].scale(-12);
                world_vert[i] = world_vert[i].add(obj_vert[i]);
                world_vert[i] = world_vert[i].add(translation);
            }

            const bullets = [_]Bullet{.{
                .location = Vector2d{ .x = 0.0, .y = 0.0 },
                .velocity = Vector2d{ .x = 0.0, .y = 0.0 },
                .alive = false,
            }} ** NUM_BULLETS;

            return .{
                .hit_radius = 15.0,
                .visible = false,
                .lives = NUM_LIVES,
                .location = Vector2d{ .x = 0.0, .y = 0.0 },
                .velocity = Vector2d{ .x = 0.0, .y = 0.0 },
                .obj_vert = obj_vert,
                .world_vert = world_vert,
                .bullets = bullets,
            };
        }

        pub fn death(self: *Self) void {
            self.visible = false;
            self.lives -= 1;
        }

        pub fn respawn(self: *Self) void {
            self.location = Vector2d{ .x = 0.0, .y = 0.0 };
            self.velocity = Vector2d{ .x = 0.0, .y = 0.0 };
            self.visible = true;
        }

        pub fn is_alive(self: *Self) bool {
            return self.lives > 0;
        }

        pub fn apply_force(self: *Self, force: Vector2d) void {
            self.velocity = self.velocity.add(force);
        }

        pub fn get_direction(self: *Self) Vector2d {
            var direction = self.obj_vert[0];
            return direction.normalize();
        }

        pub fn draw(self: *Self) void {
            if (self.visible) {
                rl.drawTriangleLines((Vector2d){ .x = self.world_vert[0].x, .y = self.world_vert[0].y }, (rl.Vector2){ .x = self.world_vert[1].x, .y = self.world_vert[1].y }, (rl.Vector2){ .x = self.world_vert[2].x, .y = self.world_vert[2].y }, rl.Color.white);
            }

            // draw bullets
            for (0..NUM_BULLETS) |i| {
                if (self.bullets[i].alive) {
                    const x = @as(i32, @intFromFloat(self.bullets[i].location.x));
                    const y = @as(i32, @intFromFloat(self.bullets[i].location.y));
                    rl.drawPixel(x, y, rl.Color.white);
                }
            }
        }

        pub fn shoot_bullet(self: *Self) void {
            for (0..NUM_BULLETS) |i| {
                if (!self.bullets[i].alive) {
                    self.bullets[i].alive = true;
                    self.bullets[i].location = self.world_vert[0];
                    self.bullets[i].velocity = self.get_direction();
                    self.bullets[i].velocity = self.bullets[i].velocity.scale(4.1);
                    break; // only one bullet at a time
                }
            }
        }

        pub fn rotate(self: *Self, degrees: f32) void {
            for (0..P_VERTS) |i| {
                self.obj_vert[i] = Vector2d.rotate(self.obj_vert[i], degrees);
            }
        }

        fn limit_velocity(self: *Self, limit: f32) void {
            const x = self.velocity.x;
            const y = self.velocity.y;
            const magnitude = @sqrt(x * x + y * y);
            if (magnitude > limit) {
                self.velocity = self.velocity.normalize();
                self.velocity = self.velocity.scale(limit);
            }
        }

        pub fn update(self: *Self) void {
            self.limit_velocity(1.4);
            self.location = self.location.add(self.velocity);

            const translation = utils.translation(2.0, 2.0);
            for (0..P_VERTS) |i| {
                self.world_vert[i] = self.obj_vert[i].add(self.location);
                self.world_vert[i] = self.world_vert[i].add(translation);
            }

            // update bullets
            for (0..NUM_BULLETS) |i| {
                if (self.bullets[i].alive) {
                    self.bullets[i].location = self.bullets[i].location.add(self.bullets[i].velocity);
                    // bounds checking
                    const x = self.bullets[i].location.x;
                    const y = self.bullets[i].location.y;
                    if (x < 0 or x > utils.SCREEN_WIDTH or y < 0 or y > utils.SCREEN_HEIGHT) {
                        self.bullets[i].alive = false;
                    }
                }
            }
        }

        /// Resets the player position if it goes out of bounds.
        pub fn bounds(self: *Self) void {
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
    };
}
