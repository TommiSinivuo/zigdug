const std = @import("std");
const mem = std.mem;
const Allocator = mem.Allocator;

const ray = @import("raylib.zig");
const log = std.log;
const assert = std.debug.assert;

const Tilemap = @import("tilemap.zig").Tilemap;
const common = @import("common.zig");
const Direction = common.Direction;
const Point = common.Point;

const config = @import("config.zig");

//------------------------------------------------------------------------------------
// Top level state machine
//------------------------------------------------------------------------------------

pub const GameState = enum(u8) {
    // Main states
    title,
    play,
    pause,
    credits,
};

pub const GameData = struct {
    is_running: bool = true,
    state: GameState,
    active_sounds: [n_sounds]bool = [_]bool{false} ** n_sounds,
    title: TitleData = TitleData{},
    game: GameplayData = GameplayData{},
    pause_menu: PauseMenuData = PauseMenuData{},
};

pub const GameInput = struct {
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

pub fn init(allocator: Allocator) !GameData {
    var gameplay_data = try GameplayData.init(allocator);
    return GameData{
        .state = .title,
        .game = gameplay_data,
    };
}

pub fn update(data: *GameData, input: *GameInput, delta_s: f64) void {
    mem.set(bool, data.active_sounds[0..n_sounds], false);
    switch (data.state) {
        .title => updateTitleState(data, input),
        .play => updateGameplayState(data, input, delta_s),
        .pause => updatePauseMenuState(data, input),
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
    if (data.title.selection == .play and input.ui_down) {
        data.title.selection = .quit;
    } else if (data.title.selection == .quit and input.ui_up) {
        data.title.selection = .play;
    }

    // Check for action and possibly change state or quit
    if (data.title.selection == .play and input.ui_confirm) {
        data.state = .play;
    } else if (data.title.selection == .quit and input.ui_confirm) {
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
    back_wall,
    boulder,
    dirt,
    door_closed,
    door_open,
    gem,
    ladder,
    player,
    space,
    wall,
    debug,
};

pub const GameplayData = struct {
    state: GamePlaySubState = .load_map,
    maps: [][]const u8,
    map_index: usize = 0,
    background_map: Tilemap(Tile),
    tilemap: Tilemap(Tile),
    falling_objects: Tilemap(bool),
    physics_objects: Tilemap(bool),
    round_objects: Tilemap(bool),
    climbable_components: Tilemap(bool),
    climber_components: Tilemap(bool),
    is_player_alive: bool = true,
    player_energy: f64 = 1.0 / 6.0,
    map_energy: f64 = 0,
    skip_next_tile: bool = false,
    gems: i32 = 0,
    is_level_beaten: bool = false,

    pub fn init(allocator: Allocator) !GameplayData {
        const background_map = try Tilemap(Tile).init(
            allocator,
            tilemap_width,
            tilemap_height,
            1,
            Tile.none,
        );
        const tilemap = try Tilemap(Tile).init(
            allocator,
            tilemap_width,
            tilemap_height,
            1,
            Tile.none,
        );
        const falling_objects = try Tilemap(bool).init(
            allocator,
            tilemap_width,
            tilemap_height,
            1,
            false,
        );
        const physics_objects = try Tilemap(bool).init(
            allocator,
            tilemap_width,
            tilemap_height,
            1,
            false,
        );
        const round_objects = try Tilemap(bool).init(
            allocator,
            tilemap_width,
            tilemap_height,
            1,
            false,
        );
        const climbable_components = try Tilemap(bool).init(
            allocator,
            tilemap_width,
            tilemap_height,
            1,
            false,
        );
        const climber_components = try Tilemap(bool).init(
            allocator,
            tilemap_width,
            tilemap_height,
            1,
            false,
        );
        return GameplayData{
            .maps = config.maps[0..],
            .background_map = background_map,
            .tilemap = tilemap,
            .falling_objects = falling_objects,
            .physics_objects = physics_objects,
            .round_objects = round_objects,
            .climbable_components = climbable_components,
            .climber_components = climber_components,
        };
    }
};

const player_energy_full: f64 = 1.0 / 6.0;
const map_energy_full: f64 = 1.0 / 6.0;

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
    data.game.gems = 0;
    data.game.background_map.setTiles(.none);
    data.game.tilemap.setTiles(.none);
    data.game.physics_objects.setTiles(false);
    data.game.round_objects.setTiles(false);
    data.game.falling_objects.setTiles(false);
    data.game.climbable_components.setTiles(false);
    data.game.climber_components.setTiles(false);
    data.game.is_player_alive = true;
    data.game.player_energy = 1.0 / 6.0;
    data.game.map_energy = 0;
    data.game.skip_next_tile = false;
    data.game.is_level_beaten = false;
    data.game.state = .play_map;
    loadMap(data.game.maps[data.game.map_index], data);
}

fn loadMap(filename: []const u8, data: *GameData) void {
    var map_image = ray.LoadImage(@ptrCast([*c]const u8, filename));
    defer ray.UnloadImage(map_image);

    // Make sure the image data consists of 32-bit pixels.
    // For example, if pixels are 24 bits, then they don't contain padding in the raw image data.
    // This is a problem, because u24 type has an alignment of 4 (contains padding), so when using
    // the pixel data as a slice containing u24s, the pixel values will "slide" off and become
    // incorrect.
    ray.ImageFormat(&map_image, ray.PixelFormat.PIXELFORMAT_UNCOMPRESSED_R8G8B8A8);

    const width = map_image.width;
    const height = map_image.height;
    assert(width == tilemap_width);
    assert(height == tilemap_height);

    const n_pixels = @intCast(usize, (width * height));
    const pixels_ptr = @ptrCast([*]u32, @alignCast(@alignOf(u32), map_image.data.?));
    const pixels = pixels_ptr[0..n_pixels];

    for (pixels) |pixel_value, i| {
        const tilemap_point = Point(i32){
            .x = @intCast(i32, @mod(i, @intCast(usize, width))),
            .y = @intCast(i32, @divFloor(i, @intCast(usize, height))),
        };
        switch (pixel_value) {
            0xFF000000 => createVoidEntity(tilemap_point, data),
            0xFF532B1D => {
                createBackWallEntity(tilemap_point, data);
                createSpaceEntity(tilemap_point, data);
            },
            0xFF3652AB => {
                createBackWallEntity(tilemap_point, data);
                createDirtEntity(tilemap_point, data);
            },
            0xFF27ECFF => createWallEntity(tilemap_point, data),
            0xFFC7C3C2 => {
                createBackWallEntity(tilemap_point, data);
                createBoulderEntity(tilemap_point, data);
            },
            0xFF4D00FF => {
                createBackWallEntity(tilemap_point, data);
                createGemEntity(tilemap_point, data);
            },
            0xFFE8F1FF => {
                createBackWallEntity(tilemap_point, data);
                createPlayerEntity(tilemap_point, data);
            },
            0xFFA877FF => {
                createBackWallEntity(tilemap_point, data);
                createClosedDoorEntity(tilemap_point, data);
            },
            0xFF53257E => {
                createLadderEntity(tilemap_point, data);
                createSpaceEntity(tilemap_point, data);
            },
            else => createDebugEntity(tilemap_point, data),
        }
    }
}

//------------------------------------------------------------------------------------
// Play map sub state (this is where the beaf of the game is)
//------------------------------------------------------------------------------------

fn updatePlayMapState(data: *GameData, input: *GameInput, delta_s: f64) void {
    if (data.game.is_level_beaten) {
        data.game.map_index += 1;
        if (data.game.map_index >= data.game.maps.len) {
            data.state = .credits;
            data.game.map_index = 0;
        }
        data.game.state = .load_map;
        return;
    }

    if (!data.game.is_player_alive) {
        data.game.state = .load_map;
        return;
    }

    if (input.game_pause) {
        data.state = .pause;
        return;
    }

    updatePlayer(data, input, delta_s);
    updateMap(data, delta_s);
}

fn updatePlayer(data: *GameData, input: *GameInput, delta_s: f64) void {
    data.game.player_energy += delta_s;

    if (data.game.player_energy >= player_energy_full) {
        if (input.player_up or input.player_right or input.player_down or input.player_left) {
            var direction: Direction = undefined;
            if (input.player_up) direction = .up;
            if (input.player_right) direction = .right;
            if (input.player_down) direction = .down;
            if (input.player_left) direction = .left;

            tryPlayerMove(direction, data);
            data.game.player_energy = 0;
        }
    }
}

fn tryPlayerMove(direction: Direction, data: *GameData) void {
    var tilemap = data.game.tilemap;
    var falling_objects = data.game.falling_objects;
    var climbable_components = data.game.climbable_components;

    if (tilemap.findFirst(isPlayer)) |start_pos| {
        if (falling_objects.getTile(start_pos)) {
            if (!(tilemap.getTile(southOf(start_pos)) == .space) or climbable_components.getTile(start_pos)) {
                falling_objects.setTile(start_pos, false);
            } else {
                return;
            }
        }
        switch (direction) {
            .up => {
                const above = northOf(start_pos);
                if (climbable_components.getTile(start_pos) and climbable_components.getTile(above)) {
                    moveEntity(start_pos, above, data);
                    createSpaceEntity(start_pos, data);
                } else if (tilemap.getTile(above) == .dirt) {
                    createSpaceEntity(above, data);
                }
            },
            else => {
                const new_pos = switch (direction) {
                    .down => southOf(start_pos),
                    .left => westOf(start_pos),
                    .right => eastOf(start_pos),
                    .up => unreachable,
                };
                const target_tile = tilemap.getTile(new_pos);
                switch (target_tile) {
                    .space, .dirt, .gem => {
                        moveEntity(start_pos, new_pos, data);
                        createSpaceEntity(start_pos, data);
                        if (target_tile == .gem) {
                            data.game.gems -= 1;
                            data.active_sounds[@enumToInt(Sound.gem)] = true;
                        }
                    },
                    .boulder => {
                        switch (direction) {
                            .right => if (tilemap.getTile(eastOf(new_pos)) == .space) {
                                pushBoulder(start_pos, new_pos, eastOf(new_pos), data);
                            },
                            .left => if (tilemap.getTile(westOf(new_pos)) == .space) {
                                pushBoulder(start_pos, new_pos, westOf(new_pos), data);
                            },
                            else => {},
                        }
                    },
                    .door_open => {
                        createSpaceEntity(start_pos, data);
                        data.game.is_level_beaten = true;
                    },
                    else => {},
                }
            },
        }
    }
}

fn isPlayer(tile: Tile) bool {
    return tile == .player;
}

fn pushBoulder(
    player_origin: Point(i32),
    boulder_origin: Point(i32),
    boulder_target: Point(i32),
    data: *GameData,
) void {
    moveEntity(boulder_origin, boulder_target, data);
    moveEntity(player_origin, boulder_origin, data);
    createSpaceEntity(player_origin, data);
}

fn updateMap(data: *GameData, delta_s: f64) void {
    data.game.map_energy += delta_s;

    if (data.game.map_energy >= map_energy_full) {
        var tilemap = data.game.tilemap;
        var tilemap_iterator = tilemap.iteratorBackward();

        while (tilemap_iterator.next()) |item| {
            if (!data.game.skip_next_tile) {
                if (data.game.physics_objects.getTile(item.point)) {
                    updatePhysics(item.point, data);
                } else if (item.value == .door_closed) {
                    updateDoor(item.point, data);
                }
            } else {
                data.game.skip_next_tile = false;
            }
        }
        data.game.map_energy = 0;
    }
}

fn updateDoor(point: Point(i32), data: *GameData) void {
    if (data.game.gems == 0) {
        createOpenDoorEntity(point, data);
    }
}

fn updatePhysics(start_point: Point(i32), data: *GameData) void {
    var tilemap = data.game.tilemap;
    var climbable_components = data.game.climbable_components;
    var climber_components = data.game.climber_components;
    var round_objects = data.game.round_objects;
    var falling_objects = data.game.falling_objects;

    // Case: entity can climb
    if (climbable_components.getTile(start_point) and climber_components.getTile(start_point)) {
        return;
    }

    const below_this_tile = southOf(start_point);
    const tile_below = tilemap.getTile(below_this_tile);

    // Case: entity falls straight down
    if (tile_below == .space) {
        if (falling_objects.getTile(start_point)) {
            moveEntity(start_point, below_this_tile, data);
            createSpaceEntity(start_point, data);
        } else {
            falling_objects.setTile(start_point, true);
        }
        return;
    }

    // Case: entity falls on player
    if (tile_below == .player) {
        if (falling_objects.getTile(start_point)) {
            data.game.is_player_alive = false;
        }
        return;
    }

    // Case: round entity rolls off another round entity
    if (round_objects.getTile(start_point) and round_objects.getTile(below_this_tile)) {
        const tile_east = tilemap.getTile(eastOf(start_point));
        const tile_south_east = tilemap.getTile(southEastOf(start_point));
        if (tile_east == .space and tile_south_east == .space) {
            if (falling_objects.getTile(start_point)) {
                moveEntity(start_point, eastOf(start_point), data);
                createSpaceEntity(start_point, data);
            } else {
                falling_objects.setTile(start_point, true);
            }
            return;
        }

        const tile_west = tilemap.getTile(westOf(start_point));
        const tile_south_west = tilemap.getTile(southWestOf(start_point));
        if (tile_west == .space and tile_south_west == .space) {
            if (falling_objects.getTile(start_point)) {
                moveEntity(start_point, westOf(start_point), data);
                createSpaceEntity(start_point, data);
                data.game.skip_next_tile = true;
            } else {
                falling_objects.setTile(start_point, true);
            }
            return;
        }
    }

    // Case: none of the above, let's stop it if it's falling
    if (data.game.falling_objects.getTile(start_point)) {
        data.game.falling_objects.setTile(start_point, false);
    }
}

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

fn createVoidEntity(point: Point(i32), data: *GameData) void {
    var tilemap = data.game.tilemap;
    var background_map = data.game.background_map;
    var physics_objects = data.game.physics_objects;
    var round_objects = data.game.round_objects;
    var falling_objects = data.game.falling_objects;
    var climbable_components = data.game.climbable_components;
    var climber_components = data.game.climber_components;

    tilemap.setTile(point, .none);
    background_map.setTile(point, .none);
    physics_objects.setTile(point, false);
    round_objects.setTile(point, false);
    falling_objects.setTile(point, false);
    climbable_components.setTile(point, false);
    climber_components.setTile(point, false);
}

fn createSpaceEntity(point: Point(i32), data: *GameData) void {
    var tilemap = data.game.tilemap;
    var physics_objects = data.game.physics_objects;
    var round_objects = data.game.round_objects;
    var falling_objects = data.game.falling_objects;
    var climber_components = data.game.climber_components;

    tilemap.setTile(point, .space);
    physics_objects.setTile(point, false);
    round_objects.setTile(point, false);
    falling_objects.setTile(point, false);
    climber_components.setTile(point, false);
}

fn createWallEntity(point: Point(i32), data: *GameData) void {
    var tilemap = data.game.tilemap;
    var physics_objects = data.game.physics_objects;
    var round_objects = data.game.round_objects;
    var falling_objects = data.game.falling_objects;
    var climber_components = data.game.climber_components;

    tilemap.setTile(point, .wall);
    physics_objects.setTile(point, false);
    round_objects.setTile(point, false);
    falling_objects.setTile(point, false);
    climber_components.setTile(point, false);
}

fn createDirtEntity(point: Point(i32), data: *GameData) void {
    var tilemap = data.game.tilemap;
    var physics_objects = data.game.physics_objects;
    var round_objects = data.game.round_objects;
    var falling_objects = data.game.falling_objects;
    var climber_components = data.game.climber_components;

    tilemap.setTile(point, .dirt);
    physics_objects.setTile(point, false);
    round_objects.setTile(point, false);
    falling_objects.setTile(point, false);
    climber_components.setTile(point, false);
}

fn createBoulderEntity(point: Point(i32), data: *GameData) void {
    var tilemap = data.game.tilemap;
    var physics_objects = data.game.physics_objects;
    var round_objects = data.game.round_objects;
    var falling_objects = data.game.falling_objects;
    var climber_components = data.game.climber_components;

    tilemap.setTile(point, .boulder);
    physics_objects.setTile(point, true);
    round_objects.setTile(point, true);
    falling_objects.setTile(point, false);
    climber_components.setTile(point, false);
}

fn createGemEntity(point: Point(i32), data: *GameData) void {
    var tilemap = data.game.tilemap;
    var physics_objects = data.game.physics_objects;
    var round_objects = data.game.round_objects;
    var falling_objects = data.game.falling_objects;
    var climber_components = data.game.climber_components;

    tilemap.setTile(point, .gem);
    physics_objects.setTile(point, true);
    round_objects.setTile(point, true);
    falling_objects.setTile(point, false);
    climber_components.setTile(point, false);

    data.game.gems += 1;
}

fn createClosedDoorEntity(point: Point(i32), data: *GameData) void {
    var tilemap = data.game.tilemap;
    var physics_objects = data.game.physics_objects;
    var round_objects = data.game.round_objects;
    var falling_objects = data.game.falling_objects;
    var climber_components = data.game.climber_components;

    tilemap.setTile(point, .door_closed);
    physics_objects.setTile(point, false);
    round_objects.setTile(point, false);
    falling_objects.setTile(point, false);
    climber_components.setTile(point, false);
}

fn createOpenDoorEntity(point: Point(i32), data: *GameData) void {
    var tilemap = data.game.tilemap;
    var physics_objects = data.game.physics_objects;
    var round_objects = data.game.round_objects;
    var falling_objects = data.game.falling_objects;
    var climber_components = data.game.climber_components;

    tilemap.setTile(point, .door_open);
    physics_objects.setTile(point, false);
    round_objects.setTile(point, false);
    falling_objects.setTile(point, false);
    climber_components.setTile(point, false);
}

fn createLadderEntity(point: Point(i32), data: *GameData) void {
    var background_map = data.game.background_map;
    var physics_objects = data.game.physics_objects;
    var round_objects = data.game.round_objects;
    var falling_objects = data.game.falling_objects;
    var climbable_components = data.game.climbable_components;
    var climber_components = data.game.climber_components;

    background_map.setTile(point, .ladder);
    physics_objects.setTile(point, false);
    round_objects.setTile(point, false);
    falling_objects.setTile(point, false);
    climbable_components.setTile(point, true);
    climber_components.setTile(point, false);
}

fn createBackWallEntity(point: Point(i32), data: *GameData) void {
    var background_map = data.game.background_map;
    var physics_objects = data.game.physics_objects;
    var round_objects = data.game.round_objects;
    var falling_objects = data.game.falling_objects;
    var climbable_components = data.game.climbable_components;
    var climber_components = data.game.climber_components;

    background_map.setTile(point, .back_wall);
    physics_objects.setTile(point, false);
    round_objects.setTile(point, false);
    falling_objects.setTile(point, false);
    climbable_components.setTile(point, false);
    climber_components.setTile(point, false);
}

fn createPlayerEntity(point: Point(i32), data: *GameData) void {
    var tilemap = data.game.tilemap;
    var physics_objects = data.game.physics_objects;
    var round_objects = data.game.round_objects;
    var falling_objects = data.game.falling_objects;
    var climber_components = data.game.climber_components;

    tilemap.setTile(point, .player);
    physics_objects.setTile(point, true);
    round_objects.setTile(point, false);
    falling_objects.setTile(point, false);
    climber_components.setTile(point, true);
}

fn createDebugEntity(point: Point(i32), data: *GameData) void {
    var tilemap = data.game.tilemap;
    var background_map = data.game.background_map;
    var physics_objects = data.game.physics_objects;
    var round_objects = data.game.round_objects;
    var falling_objects = data.game.falling_objects;
    var climbable_components = data.game.climbable_components;
    var climber_components = data.game.climber_components;

    background_map.setTile(point, .debug);
    tilemap.setTile(point, .debug);
    physics_objects.setTile(point, false);
    round_objects.setTile(point, false);
    falling_objects.setTile(point, false);
    climbable_components.setTile(point, false);
    climber_components.setTile(point, false);
}

fn moveEntity(start: Point(i32), destination: Point(i32), data: *GameData) void {
    var tilemap = data.game.tilemap;
    var physics_objects = data.game.physics_objects;
    var round_objects = data.game.round_objects;
    var falling_objects = data.game.falling_objects;
    var climber_components = data.game.climber_components;

    tilemap.setTile(destination, tilemap.getTile(start));
    physics_objects.setTile(destination, physics_objects.getTile(start));
    round_objects.setTile(destination, round_objects.getTile(start));
    falling_objects.setTile(destination, falling_objects.getTile(start));
    climber_components.setTile(destination, climber_components.getTile(start));

    tilemap.setTile(start, tilemap.null_value);
    physics_objects.setTile(start, false);
    round_objects.setTile(start, false);
    falling_objects.setTile(start, false);
    climber_components.setTile(start, false);
}

//------------------------------------------------------------------------------------
// Finish map sub state
//------------------------------------------------------------------------------------

fn updateFinishMapState(data: *GameData) void {
    data.game.state = .load_map;
    data.state = .credits;
}

//------------------------------------------------------------------------------------
// Pause menu state
//------------------------------------------------------------------------------------

pub const PauseMenuSelection = enum(u8) {
    resume_level,
    restart_level,
    return_to_title,
    quit_game,
};

pub const PauseMenuData = struct {
    selection: PauseMenuSelection = .resume_level,
};

fn updatePauseMenuState(data: *GameData, input: *GameInput) void {
    switch (data.pause_menu.selection) {
        .resume_level => {
            if (input.ui_down) {
                data.pause_menu.selection = .restart_level;
            }
        },
        .restart_level => {
            if (input.ui_down) {
                data.pause_menu.selection = .return_to_title;
            } else if (input.ui_up) {
                data.pause_menu.selection = .resume_level;
            }
        },
        .return_to_title => {
            if (input.ui_down) {
                data.pause_menu.selection = .quit_game;
            } else if (input.ui_up) {
                data.pause_menu.selection = .restart_level;
            }
        },
        .quit_game => {
            if (input.ui_up) {
                data.pause_menu.selection = .return_to_title;
            }
        },
    }

    if (input.ui_confirm) {
        switch (data.pause_menu.selection) {
            .resume_level => data.state = .play,
            .restart_level => {
                data.game.state = .load_map;
                data.state = .play;
            },
            .return_to_title => {
                data.game.map_index = 0;
                data.game.state = .load_map;
                data.state = .title;
            },
            .quit_game => data.is_running = false,
        }
        data.pause_menu.selection = .resume_level;
    } else if (input.ui_cancel) {
        data.state = .play;
        data.pause_menu.selection = .resume_level;
    }
}

//------------------------------------------------------------------------------------
// End credits state
//------------------------------------------------------------------------------------

fn updateCreditsState(data: *GameData, input: *GameInput) void {
    if (input.ui_confirm) {
        data.state = .title;
    }
}
