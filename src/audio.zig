const Allocator = @import("std").mem.Allocator;

const ray = @import("raylib.zig");
const zigdug = @import("zigdug.zig");

const Sound = zigdug.Sound;
const ZigDug = zigdug.ZigDug;

pub const Audio = struct {
    sounds: []ray.Sound,

    pub fn init(allocator: Allocator) !Audio {
        ray.InitAudioDevice();
        var sounds = try allocator.alloc(ray.Sound, 3);
        sounds[@enumToInt(Sound.move)] = ray.LoadSound("data/sounds/move.wav");
        sounds[@enumToInt(Sound.boulder)] = ray.LoadSound("data/sounds/boulder.wav");
        sounds[@enumToInt(Sound.gem)] = ray.LoadSound("data/sounds/gem.wav");
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
        for (global.active_sounds[0..3]) |is_active, i| {
            if (is_active) ray.PlaySound(self.sounds[i]);
        }
    }
};
