pub const Direction = enum(u8) {
    up,
    right,
    down,
    left,
};

pub fn Point(comptime T: type) type {
    return struct {
        x: T,
        y: T,
    };
}

pub const Rect = struct {
    x: i32,
    y: i32,
    w: i32,
    h: i32,
};
