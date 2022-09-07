const std = @import("std");
const assert = std.debug.assert;
const log = std.log;
const mem = std.mem;

const Allocator = mem.Allocator;

pub const config = @import("zigdug/config.zig");
pub const math = @import("zigdug/math.zig");

const common = @import("zigdug/common.zig");
const play_state = @import("zigdug/play_state.zig");
const ray = @import("raylib.zig");

pub const CreditsState = @import("zigdug/credits_state.zig").CreditsState;
pub const Direction = common.Direction;
pub const Move = play_state.Move;
pub const PauseState = @import("zigdug/pause_state.zig").PauseState;
pub const PlayState = play_state.PlayState;
pub const Point = common.Point;
pub const Tile = play_state.Tile;
pub const Tilemap = @import("zigdug/tilemap.zig").Tilemap;
pub const TitleState = @import("zigdug/title_state.zig").TitleState;

pub const ZigDug = struct {
    is_running: bool = true,
    state: GameState,

    // States
    title_state: TitleState,
    play_state: PlayState,
    pause_state: PauseState,
    credits_state: CreditsState,

    pub fn init(allocator: Allocator) !ZigDug {
        return ZigDug{
            .state = .title,
            .title_state = TitleState{},
            .play_state = try PlayState.init(allocator),
            .pause_state = PauseState{},
            .credits_state = CreditsState{},
        };
    }

    pub fn update(self: *ZigDug, input: *Input, delta_s: f32) void {
        switch (self.state) {
            .title => self.title_state.update(self, input),
            .play => self.play_state.update(self, input, delta_s),
            .pause => self.pause_state.update(self, input),
            .credits => self.credits_state.update(self, input),
        }
    }
};

pub const GameState = enum(u8) {
    // Main states
    title,
    play,
    pause,
    credits,
};

pub const Input = struct {
    game_pause: bool = false,

    ui_up: bool = false,
    ui_right: bool = false,
    ui_down: bool = false,
    ui_left: bool = false,
    ui_confirm: bool = false,
    ui_cancel: bool = false,

    player_up: bool = false,
    player_right: bool = false,
    player_down: bool = false,
    player_left: bool = false,
};

pub const Sound = enum(u8) {
    boulder,
    gem,
    move,
};
