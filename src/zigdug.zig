const std = @import("std");
const assert = std.debug.assert;
const log = std.log;
const mem = std.mem;

const Allocator = mem.Allocator;

const animation = @import("zigdug/animation.zig");
const common = @import("zigdug/common.zig");
const config = @import("zigdug/config.zig");
const play_state = @import("zigdug/play_state.zig");
const ray = @import("raylib.zig");

pub const CreditsState = @import("zigdug/credits_state.zig").CreditsState;
pub const Direction = common.Direction;
pub const PauseState = @import("zigdug/pause_state.zig").PauseState;
pub const PlayState = play_state.PlayState;
pub const Point = common.Point;
pub const Tile = play_state.Tile;
pub const Tilemap = @import("zigdug/tilemap.zig").Tilemap;
pub const TitleState = @import("zigdug/title_state.zig").TitleState;

const Animation = animation.Animation;

pub const ZigDug = struct {
    is_running: bool = true,
    state: GameState,

    active_sounds: [n_sounds]bool = [_]bool{false} ** n_sounds,

    // States
    title_state: TitleState,
    play_state: PlayState,
    pause_state: PauseState,
    credits_state: CreditsState,

    // Animations
    player_idle_right_animation: Animation(Tile),
    player_running_right_animation: Animation(Tile),
    player_digging_right_animation: Animation(Tile),
    open_door_animation: Animation(Tile),

    pub fn init(allocator: Allocator) !ZigDug {
        var player_idle_right_animation = Animation(Tile).init(allocator);
        try player_idle_right_animation.add_frame(.player_idle_right_01, 1.0 / 2.0);
        try player_idle_right_animation.add_frame(.player_idle_right_02, 1.0 / 2.0);

        var player_running_right_animation = Animation(Tile).init(allocator);
        try player_running_right_animation.add_frame(.player_running_right_01, 1.0 / 6.0);
        try player_running_right_animation.add_frame(.player_running_right_02, 1.0 / 6.0);

        var player_digging_right_animation = Animation(Tile).init(allocator);
        try player_digging_right_animation.add_frame(.player_digging_right_01, 1.0 / 12.0);
        try player_digging_right_animation.add_frame(.player_digging_right_02, 1.0 / 12.0);

        var open_door_animation = Animation(Tile).init(allocator);
        try open_door_animation.add_frame(.door_open_01, 1.0 / 3.0);
        try open_door_animation.add_frame(.door_open_02, 1.0 / 3.0);
        try open_door_animation.add_frame(.door_open_03, 1.0 / 3.0);
        try open_door_animation.add_frame(.door_open_04, 1.0 / 3.0);

        return ZigDug{
            .state = .title,
            .player_idle_right_animation = player_idle_right_animation,
            .player_running_right_animation = player_running_right_animation,
            .player_digging_right_animation = player_digging_right_animation,
            .open_door_animation = open_door_animation,
            .title_state = TitleState{},
            .play_state = try PlayState.init(allocator),
            .pause_state = PauseState{},
            .credits_state = CreditsState{},
        };
    }

    pub fn update(self: *ZigDug, input: *Input, delta_s: f32) void {
        mem.set(bool, self.active_sounds[0..n_sounds], false);
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

const n_sounds = 3;

pub const Sound = enum(u8) {
    boulder,
    gem,
    move,
};

pub const Entity = enum(u8) {
    none,
    back_wall,
    boulder,
    dirt,
    door_closed,
    door_open,
    key,
    ladder,
    player,
    space,
    wall,
    debug,
};

pub const PlayerState = enum(u8) {
    climbing,
    digging,
    falling,
    pushing,
    running,
    standing,
};
