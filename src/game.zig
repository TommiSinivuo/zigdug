const std = @import("std");
const Allocator = std.mem.Allocator;

const ray = @import("raylib.zig");
const log = std.log;
const assert = std.debug.assert;

const Tilemap = @import("tilemap.zig").Tilemap;
const common = @import("common.zig");
const Direction = common.Direction;
const Point = common.Point;

//------------------------------------------------------------------------------------
// Top level state machine
//------------------------------------------------------------------------------------

pub const GameState = enum(u8) {
    // Main states
    title,
    play,
    credits,
};

pub const GameData = struct {
    is_running: bool = true,
    state: GameState,
    title: TitleData = TitleData{},
    game: GameplayData = GameplayData{},
};

pub const GameInput = struct {
    action: bool = false,
    up: bool = false,
    down: bool = false,
    left: bool = false,
    right: bool = false,
};

pub fn init(allocator: Allocator) !GameData {
    var gameplay_data = try GameplayData.init(allocator);
    return GameData{
        .state = .title,
        .game = gameplay_data,
    };
}

pub fn update(data: *GameData, input: *GameInput, delta_s: f64) void {
    switch (data.state) {
        .title => updateTitleState(data, input),
        .play => updateGameplayState(data, input, delta_s),
        .credits => updateCreditsState(data, input),
    }
}

//------------------------------------------------------------------------------------
// Title screen state
//------------------------------------------------------------------------------------

pub const TitleSelection = enum(u8) {
    play,
    quit,
};

pub const TitleData = struct {
    selection: TitleSelection = .play,
};

fn updateTitleState(data: *GameData, input: *GameInput) void {
    // Check for selection change
    if (data.title.selection == .play and input.down) {
        data.title.selection = .quit;
    } else if (data.title.selection == .quit and input.up) {
        data.title.selection = .play;
    }

    // Check for action and possibly change state or quit
    if (data.title.selection == .play and input.action) {
        data.state = .play;
    } else if (data.title.selection == .quit and input.action) {
        data.is_running = false;
    }
}

//------------------------------------------------------------------------------------
// Gameplay state
//------------------------------------------------------------------------------------

pub const tilemap_width = 16;
pub const tilemap_height = 16;

pub const Tile = enum(u8) {
    none,
    space,
    dirt,
    wall,
    boulder_stationary,
    boulder_falling,
    gem_stationary,
    gem_falling,
    door_closed,
    door_open,
    player,
};

pub const GameplayData = struct {
    state: GamePlaySubState = .load_map,
    tilemap: Tilemap(Tile),
    player_position: Point(i32) = Point(i32){ .x = 0, .y = 0 },
    player_energy: f64 = 1.0 / 6.0,

    pub fn init(allocator: Allocator) !GameplayData {
        const tilemap = try Tilemap(Tile).init(
            allocator,
            tilemap_width,
            tilemap_height,
            1,
            Tile.none,
        );
        return GameplayData{
            .tilemap = tilemap,
        };
    }
};

const player_energy_full: f64 = 1.0 / 6.0;

fn updateGameplayState(data: *GameData, input: *GameInput, delta_s: f64) void {
    switch (data.game.state) {
        .load_map => updateLoadMapState(data),
        .play_map => updatePlayMapState(data, input, delta_s),
        .finish_map => updateFinishMapState(data),
    }
}

//------------------------------------------------------------------------------------
// Sub states for gameplay state
//------------------------------------------------------------------------------------

pub const GamePlaySubState = enum(u8) {
    load_map,
    play_map,
    finish_map,
};

//------------------------------------------------------------------------------------
// Load map sub state
//------------------------------------------------------------------------------------

fn updateLoadMapState(data: *GameData) void {
    loadMap("data/maps/001.png", data);
    data.game.state = .play_map;
}

fn loadMap(filename: []const u8, data: *GameData) void {
    var map_image = ray.LoadImage(@ptrCast([*c]const u8, filename));
    ray.ImageFormat(&map_image, ray.PixelFormat.PIXELFORMAT_UNCOMPRESSED_R8G8B8A8);

    const width = map_image.width;
    const height = map_image.height;
    assert(width == tilemap_width);
    assert(height == tilemap_height);

    const n_pixels = @intCast(usize, (width * height));
    const pixels_ptr = @ptrCast([*]u32, @alignCast(@alignOf(u32), map_image.data.?));
    const pixels = pixels_ptr[0..n_pixels];

    var tilemap = data.game.tilemap;

    for (pixels) |pixel_value, i| {
        const tile_value = switch (pixel_value) {
            0xFF000000 => Tile.none,
            0xFF532B1D => Tile.space,
            0xFF3652AB => Tile.dirt,
            0xFF27ECFF => Tile.wall,
            0xFFC7C3C2 => Tile.boulder_stationary,
            0xFF4D00FF => Tile.gem_stationary,
            0xFFE8F1FF => Tile.player,
            0xFFA877FF => Tile.door_closed,
            else => Tile.none,
        };

        tilemap.memory.tiles[i] = tile_value;
        if (tile_value == .player) {
            data.game.player_position = Point(i32){
                .x = @intCast(i32, @mod(i, @intCast(usize, width))),
                .y = @intCast(i32, @divFloor(i, @intCast(usize, width))),
            };
        }
    }

    ray.UnloadImage(map_image);
}

//------------------------------------------------------------------------------------
// Play map sub state (this is where the beaf of the game is)
//------------------------------------------------------------------------------------

fn updatePlayMapState(data: *GameData, input: *GameInput, delta_s: f64) void {
    updatePlayer(data, input, delta_s);
    updateMap(data, delta_s);
}

fn updatePlayer(data: *GameData, input: *GameInput, delta_s: f64) void {
    data.game.player_energy += delta_s;

    if (data.game.player_energy > player_energy_full) {
        if (input.up or input.right or input.down or input.left) {
            var direction: Direction = undefined;
            if (input.up) direction = .up;
            if (input.right) direction = .right;
            if (input.down) direction = .down;
            if (input.left) direction = .left;

            movePlayer(direction, data);
            data.game.player_energy = 0;
        }
    }
}

fn movePlayer(direction: Direction, data: *GameData) void {
    const start_pos = data.game.player_position;
    const new_pos = switch (direction) {
        .down => southOf(start_pos),
        .left => westOf(start_pos),
        .right => eastOf(start_pos),
        .up => northOf(start_pos),
    };
    const target_tile = data.game.tilemap.getTile(new_pos);
    switch (target_tile) {
        .space, .dirt, .gem_stationary, .gem_falling => {
            data.game.player_position = new_pos;
            data.game.tilemap.setTile(new_pos, .player);
            data.game.tilemap.setTile(start_pos, .space);
        },
        else => {},
    }
}

fn updateMap(_: *GameData, _: f64) void {}

fn northOf(pos: Point(i32)) Point(i32) {
    return Point(i32){
        .x = pos.x,
        .y = pos.y - 1,
    };
}

fn eastOf(pos: Point(i32)) Point(i32) {
    return Point(i32){
        .x = pos.x + 1,
        .y = pos.y,
    };
}

fn southOf(pos: Point(i32)) Point(i32) {
    return Point(i32){
        .x = pos.x,
        .y = pos.y + 1,
    };
}

fn westOf(pos: Point(i32)) Point(i32) {
    return Point(i32){
        .x = pos.x - 1,
        .y = pos.y,
    };
}

fn northEastOf(pos: Point(i32)) Point(i32) {
    return northOf(eastOf(pos));
}

fn southEastOf(pos: Point(i32)) Point(i32) {
    return southOf(eastOf(pos));
}

fn southWestOf(pos: Point(i32)) Point(i32) {
    return southOf(westOf(pos));
}

fn northWestOf(pos: Point(i32)) Point(i32) {
    return northOf(westOf(pos));
}

//------------------------------------------------------------------------------------
// Finish map sub state
//------------------------------------------------------------------------------------

fn updateFinishMapState(data: *GameData) void {
    data.game.state = .load_map;
    data.state = .credits;
}

//------------------------------------------------------------------------------------
// End credits state
//------------------------------------------------------------------------------------

fn updateCreditsState(data: *GameData, input: *GameInput) void {
    if (input.action) {
        data.state = .title;
    }
}
