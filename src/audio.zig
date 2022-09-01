const std = @import("std");

const Allocator = std.mem.Allocator;
const AutoHashMap = std.AutoHashMap;

const ray = @import("raylib.zig");
const zigdug = @import("zigdug.zig");

const Sound = zigdug.Sound;
const ZigDug = zigdug.ZigDug;

pub const Audio = struct {
    sounds: AutoHashMap(zigdug.Sound, *ray.Sound),

    pub fn init(allocator: Allocator) !Audio {
        ray.InitAudioDevice();
        var sounds = AutoHashMap(zigdug.Sound, *ray.Sound).init(allocator);

        const move_sound_ptr = try allocator.create(ray.Sound);
        const boulder_sound_ptr = try allocator.create(ray.Sound);
        const gem_sound_ptr = try allocator.create(ray.Sound);

        move_sound_ptr.* = ray.LoadSound("data/sounds/move.wav");
        boulder_sound_ptr.* = ray.LoadSound("data/sounds/boulder.wav");
        gem_sound_ptr.* = ray.LoadSound("data/sounds/gem.wav");

        try sounds.put(.move, move_sound_ptr);
        try sounds.put(.boulder, boulder_sound_ptr);
        try sounds.put(.gem, gem_sound_ptr);

        return Audio{ .sounds = sounds };
    }

    pub fn destroy(_: *Audio) void {
        // TODO: this segfaults
        // for (self.sounds) |sound| {
        //     ray.UnloadSound(sound);
        // }
        ray.CloseAudioDevice();
    }

    pub fn play(self: *Audio, global: *ZigDug) void {
        if (global.state == .play) {
            const activated_sounds = global.play_state.activated_sounds;

            var sound_key_iterator = activated_sounds.keyIterator();
            while (sound_key_iterator.next()) |sound_key| {
                if (self.sounds.get(sound_key.*)) |ray_sound| {
                    ray.PlaySound(ray_sound.*);
                }
            }
        }
    }
};
