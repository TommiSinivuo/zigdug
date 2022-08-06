const Allocator = @import("std").mem.Allocator;

const game = @import("game.zig");
const GameData = game.GameData;
const ray = @import("raylib.zig");

pub const Audio = struct {
    sounds: []ray.Sound,

    pub fn init(allocator: Allocator) !Audio {
        ray.InitAudioDevice();
        var sounds = try allocator.alloc(ray.Sound, 3);
        sounds[@enumToInt(game.Sound.move)] = ray.LoadSound("data/sounds/move.wav");
        sounds[@enumToInt(game.Sound.boulder)] = ray.LoadSound("data/sounds/boulder.wav");
        sounds[@enumToInt(game.Sound.gem)] = ray.LoadSound("data/sounds/gem.wav");
        return Audio{ .sounds = sounds };
    }

    pub fn destroy(_: *Audio) void {
        // TODO: this segfaults
        // for (self.sounds) |sound| {
        //     ray.UnloadSound(sound);
        // }
        ray.CloseAudioDevice();
    }

    pub fn play(self: *Audio, data: *GameData) void {
        for (data.active_sounds[0..3]) |is_active, i| {
            if (is_active) ray.PlaySound(self.sounds[i]);
        }
    }
};
