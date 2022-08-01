const ray = @import("raylib.zig");

pub const GameData = struct {
    ball_position: ray.Vector2,
};

pub const GameInput = struct {
    up: bool = false,
    down: bool = false,
    left: bool = false,
    right: bool = false,
};

pub fn init() GameData {
    return GameData{
        .ball_position = ray.Vector2{
            .x = @intToFloat(f32, 256) / 2,
            .y = @intToFloat(f32, 256) / 2,
        },
    };
}

pub fn update(data: *GameData, input: *GameInput, _: f64) void {
    if (input.right) {
        data.ball_position.x += 2.0;
    }
    if (input.left) {
        data.ball_position.x -= 2.0;
    }
    if (input.up) {
        data.ball_position.y -= 2.0;
    }
    if (input.down) {
        data.ball_position.y += 2.0;
    }
}
