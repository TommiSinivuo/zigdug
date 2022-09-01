const std = @import("std");

const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

pub const AnimationCounter = struct {
    frame_left_s: f32,
    frame_counter: u32 = 0,
    frame_index: u8,
};

pub fn Animation(comptime T: type) type {
    return struct {
        frames: ArrayList(AnimationFrame(T)),

        pub fn init(allocator: Allocator) Animation(T) {
            var frames = ArrayList(AnimationFrame(T)).init(allocator);
            return Animation(T){
                .frames = frames,
            };
        }

        pub fn add_frame(self: *Animation(T), data: T, duration: f32) !void {
            var frame = AnimationFrame(T){
                .duration = duration,
                .data = data,
            };
            try self.frames.append(frame);
        }
    };
}

pub fn AnimationFrame(comptime T: type) type {
    return struct {
        duration: f32,
        data: T,
    };
}
