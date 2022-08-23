const std = @import("std");
const assert = std.debug.assert;

const Allocator = std.mem.Allocator;

const anim = @import("animation.zig");
const common = @import("common.zig");
const config = @import("config.zig");
const ray = @import("../raylib.zig");
const zigdug = @import("../zigdug.zig");

const Animation = anim.Animation;
const AnimationCounter = anim.AnimationCounter;
const Direction = common.Direction;
const Input = zigdug.Input;
const Point = common.Point;
const Sound = zigdug.Sound;
const Tilemap = @import("tilemap.zig").Tilemap;
const ZigDug = zigdug.ZigDug;

pub const tilemap_width = 16;
pub const tilemap_height = 16;

const player_energy_full: f64 = 1.0 / 6.0;
const map_energy_full: f64 = 1.0 / 6.0;

pub const PlayStateSubState = enum(u8) {
    load_map,
    play_map,
    finish_map,
};

pub const Tile = enum(u8) {
    none,
    back_wall,
    boulder,
    dirt,
    door_closed,
    door_open_01,
    door_open_02,
    door_open_03,
    door_open_04,
    key,
    ladder,
    player_idle_right_01,
    player_idle_right_02,
    player_running_right_01,
    player_running_right_02,
    player_digging_right_01,
    player_digging_right_02,
    space,
    wall,
    debug,

    pub fn toEntity(self: Tile) Entity {
        const entity = switch (self) {
            .none => Entity.none,
            .back_wall => Entity.back_wall,
            .boulder => Entity.boulder,
            .dirt => Entity.dirt,
            .door_closed => Entity.door_closed,
            .door_open_01, .door_open_02, .door_open_03, .door_open_04 => Entity.door_open,
            .key => Entity.key,
            .ladder => Entity.ladder,
            .player_idle_right_01, .player_idle_right_02, .player_running_right_01, .player_running_right_02, .player_digging_right_01, .player_digging_right_02 => Entity.player,
            .space => Entity.space,
            .wall => Entity.wall,
            .debug => Entity.debug,
        };
        return entity;
    }
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

pub const PlayState = struct {
    substate: PlayStateSubState = .load_map,
    maps: [][]const u8,
    map_index: usize = 0,
    background_map: Tilemap(Tile),
    tilemap: Tilemap(Tile),
    falling_objects: Tilemap(bool),
    physics_objects: Tilemap(bool),
    round_objects: Tilemap(bool),
    climbable_components: Tilemap(bool),
    climber_components: Tilemap(bool),
    animation_components: Tilemap(?Animation(Tile)),
    animation_counter_components: Tilemap(?AnimationCounter),
    is_player_alive: bool = true,
    player_energy: f64 = 1.0 / 6.0,
    player_old_facing_direction: Direction = Direction.right,
    player_old_state: PlayerState = PlayerState.standing,
    player_new_facing_direction: Direction = Direction.right,
    player_new_state: PlayerState = PlayerState.standing,
    map_energy: f64 = 0,
    skip_next_tile: bool = false,
    keys: i32 = 0,
    is_level_beaten: bool = false,

    pub fn init(allocator: Allocator) !PlayState {
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
        const animation_components = try Tilemap(?Animation(Tile)).init(
            allocator,
            tilemap_width,
            tilemap_height,
            1,
            null,
        );
        const animation_counter_components = try Tilemap(?AnimationCounter).init(
            allocator,
            tilemap_width,
            tilemap_height,
            1,
            null,
        );
        return PlayState{
            .maps = config.maps[0..],
            .background_map = background_map,
            .tilemap = tilemap,
            .falling_objects = falling_objects,
            .physics_objects = physics_objects,
            .round_objects = round_objects,
            .climbable_components = climbable_components,
            .climber_components = climber_components,
            .animation_components = animation_components,
            .animation_counter_components = animation_counter_components,
        };
    }

    pub fn update(self: *PlayState, global: *ZigDug, input: *Input, delta_s: f32) void {
        switch (self.substate) {
            .load_map => self.updateLoadMapState(global),
            .play_map => self.updatePlayMapState(global, input, delta_s),
            .finish_map => self.updateFinishMapState(global),
        }
    }

    fn updateLoadMapState(self: *PlayState, global: *ZigDug) void {
        self.keys = 0;
        self.background_map.setTiles(.none);
        self.tilemap.setTiles(.none);
        self.physics_objects.setTiles(false);
        self.round_objects.setTiles(false);
        self.falling_objects.setTiles(false);
        self.climbable_components.setTiles(false);
        self.climber_components.setTiles(false);
        self.animation_components.setTiles(null);
        self.animation_counter_components.setTiles(null);
        self.is_player_alive = true;
        self.player_energy = 1.0 / 6.0;
        self.map_energy = 0;
        self.player_old_facing_direction = Direction.right;
        self.player_old_state = PlayerState.standing;
        self.player_new_facing_direction = Direction.right;
        self.player_new_state = PlayerState.standing;
        self.skip_next_tile = false;
        self.is_level_beaten = false;
        self.substate = .play_map;
        self.loadMap(global, self.maps[self.map_index]);
    }

    fn loadMap(self: *PlayState, global: *ZigDug, filename: []const u8) void {
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
                0xFF000000 => self.createEntity(global, .none, tilemap_point),
                0xFF532B1D => {
                    self.createEntity(global, .back_wall, tilemap_point);
                    self.createEntity(global, .space, tilemap_point);
                },
                0xFF3652AB => {
                    self.createEntity(global, .back_wall, tilemap_point);
                    self.createEntity(global, .dirt, tilemap_point);
                },
                0xFF27ECFF => self.createEntity(global, .wall, tilemap_point),
                0xFFC7C3C2 => {
                    self.createEntity(global, .back_wall, tilemap_point);
                    self.createEntity(global, .boulder, tilemap_point);
                },
                0xFF4D00FF => {
                    self.createEntity(global, .back_wall, tilemap_point);
                    self.createEntity(global, .key, tilemap_point);
                },
                0xFFE8F1FF => {
                    self.createEntity(global, .back_wall, tilemap_point);
                    self.createEntity(global, .player, tilemap_point);
                },
                0xFFA877FF => {
                    self.createEntity(global, .back_wall, tilemap_point);
                    self.createEntity(global, .door_closed, tilemap_point);
                },
                0xFF53257E => {
                    self.createEntity(global, .ladder, tilemap_point);
                    self.createEntity(global, .space, tilemap_point);
                },
                else => self.createEntity(global, .debug, tilemap_point),
            }
        }
    }

    fn updatePlayMapState(self: *PlayState, global: *ZigDug, input: *Input, delta_s: f32) void {
        if (self.is_level_beaten) {
            self.map_index += 1;
            if (self.map_index >= self.maps.len) {
                global.state = .credits;
                self.map_index = 0;
            }
            self.substate = .load_map;
            return;
        }

        if (!self.is_player_alive) {
            self.substate = .load_map;
            return;
        }

        if (input.game_pause) {
            global.state = .pause;
            return;
        }

        self.updatePlayer(global, input, delta_s);
        self.animatePlayer(global);
        self.updateMap(global, delta_s);
        self.updateAnimations(delta_s);
    }

    fn updatePlayer(self: *PlayState, global: *ZigDug, input: *Input, delta_s: f32) void {
        self.player_energy += delta_s;

        if (self.player_energy >= player_energy_full) {
            self.player_old_facing_direction = self.player_new_facing_direction;
            self.player_old_state = self.player_new_state;
            if (input.player_up or input.player_right or input.player_down or input.player_left) {
                var direction: Direction = undefined;
                if (input.player_up) direction = .up;
                if (input.player_right) direction = .right;
                if (input.player_down) direction = .down;
                if (input.player_left) direction = .left;

                self.tryPlayerMove(global, direction);
                self.player_energy = 0;
            } else {
                self.player_new_state = .standing;
            }
        }
    }

    fn tryPlayerMove(self: *PlayState, global: *ZigDug, direction: Direction) void {
        if (self.tilemap.findFirst(isPlayer)) |start_pos| {
            if (self.falling_objects.getTile(start_pos)) {
                if (!(self.tilemap.getTile(southOf(start_pos)) == .space) or self.climbable_components.getTile(start_pos)) {
                    self.falling_objects.setTile(start_pos, false);
                    self.player_new_state = .standing;
                } else {
                    self.player_new_state = .falling;
                    return;
                }
            }
            switch (direction) {
                .up => {
                    const above = northOf(start_pos);
                    if (self.climbable_components.getTile(start_pos) and self.climbable_components.getTile(above)) {
                        self.moveEntity(start_pos, above);
                        self.createEntity(global, .space, start_pos);
                        self.player_new_state = .climbing;
                    }
                },
                else => {
                    const new_pos = switch (direction) {
                        .down => southOf(start_pos),
                        .left => westOf(start_pos),
                        .right => eastOf(start_pos),
                        .up => unreachable,
                    };
                    const target_tile = self.tilemap.getTile(new_pos);
                    switch (target_tile.toEntity()) {
                        .space => {
                            self.moveEntity(start_pos, new_pos);
                            self.createEntity(global, .space, start_pos);
                            self.player_new_state = .running;
                        },
                        .dirt => {
                            self.moveEntity(start_pos, new_pos);
                            self.createEntity(global, .space, start_pos);
                            self.player_new_state = .digging;
                        },
                        .key => {
                            self.moveEntity(start_pos, new_pos);
                            self.createEntity(global, .space, start_pos);
                            self.player_new_state = .running;
                            self.keys -= 1;
                            global.active_sounds[@enumToInt(Sound.gem)] = true;
                        },
                        .boulder => {
                            switch (direction) {
                                .right => {
                                    if (self.tilemap.getTile(eastOf(new_pos)) == .space) {
                                        self.pushBoulder(global, start_pos, new_pos, eastOf(new_pos));
                                        self.player_new_state = .pushing;
                                    } else {
                                        self.player_new_state = .standing;
                                    }
                                },
                                .left => {
                                    if (self.tilemap.getTile(westOf(new_pos)) == .space) {
                                        self.pushBoulder(global, start_pos, new_pos, westOf(new_pos));
                                        self.player_new_state = .pushing;
                                    } else {
                                        self.player_new_state = .standing;
                                    }
                                },
                                else => {
                                    self.player_new_state = .standing;
                                },
                            }
                        },
                        .door_open => {
                            self.createEntity(global, .space, start_pos);
                            self.is_level_beaten = true;
                            self.player_new_state = .running; // TODO: we can add a winning state here
                        },
                        else => {
                            self.player_new_state = .standing;
                        },
                    }
                },
            }
            self.player_new_facing_direction = direction;
        }
    }

    fn isPlayer(tile: Tile) bool {
        return tile.toEntity() == .player;
    }

    fn pushBoulder(
        self: *PlayState,
        global: *ZigDug,
        player_origin: Point(i32),
        boulder_origin: Point(i32),
        boulder_target: Point(i32),
    ) void {
        self.moveEntity(boulder_origin, boulder_target);
        self.moveEntity(player_origin, boulder_origin);
        self.createEntity(global, .space, player_origin);
    }

    fn animatePlayer(self: *PlayState, global: *ZigDug) void {
        const old_state = self.player_old_state;
        const new_state = self.player_new_state;
        const old_facing_direction = self.player_old_facing_direction;
        const new_facing_direction = self.player_new_facing_direction;

        if (old_state == new_state and old_facing_direction == new_facing_direction) {
            return;
        }

        if (self.tilemap.findFirst(isPlayer)) |player_point| {
            var animation: ?Animation(Tile) = null;

            if (new_state == .climbing and new_facing_direction == .left) {
                animation = global.player_running_right_animation;
            } else if (new_state == .climbing and new_facing_direction == .right) {
                animation = global.player_running_right_animation;
            } else if (new_state == .digging and new_facing_direction == .left) {
                animation = global.player_digging_right_animation;
            } else if (new_state == .digging and new_facing_direction == .right) {
                animation = global.player_digging_right_animation;
            } else if (new_state == .digging and new_facing_direction == .down) {
                animation = global.player_digging_right_animation;
            } else if (new_state == .falling and new_facing_direction == .left) {
                animation = global.player_running_right_animation;
            } else if (new_state == .falling and new_facing_direction == .right) {
                animation = global.player_running_right_animation;
            } else if (new_state == .pushing and new_facing_direction == .left) {
                animation = global.player_running_right_animation;
            } else if (new_state == .pushing and new_facing_direction == .right) {
                animation = global.player_running_right_animation;
            } else if (new_state == .running and new_facing_direction == .left) {
                animation = global.player_running_right_animation;
            } else if (new_state == .running and new_facing_direction == .right) {
                animation = global.player_running_right_animation;
            } else if (new_state == .standing and new_facing_direction == .left) {
                animation = global.player_idle_right_animation;
            } else if (new_state == .standing and new_facing_direction == .right) {
                animation = global.player_idle_right_animation;
            }

            if (animation != null) {
                self.setAnimation(player_point, animation.?);
            }
        }
    }

    fn updateMap(self: *PlayState, global: *ZigDug, delta_s: f32) void {
        self.map_energy += delta_s;

        if (self.map_energy >= map_energy_full) {
            var tilemap_iterator = self.tilemap.iteratorBackward();

            while (tilemap_iterator.next()) |item| {
                if (!self.skip_next_tile) {
                    if (self.physics_objects.getTile(item.point)) {
                        self.updatePhysics(global, item.point);
                    } else if (item.value == .door_closed) {
                        self.updateDoor(global, item.point);
                    }
                } else {
                    self.skip_next_tile = false;
                }
            }
            self.map_energy = 0;
        }
    }

    fn updateDoor(self: *PlayState, global: *ZigDug, point: Point(i32)) void {
        if (self.keys == 0) {
            self.createEntity(global, .door_open, point);
        }
    }

    fn updatePhysics(self: *PlayState, global: *ZigDug, start_point: Point(i32)) void {
        var tilemap = self.tilemap;
        var climbable_components = self.climbable_components;
        var climber_components = self.climber_components;
        var round_objects = self.round_objects;
        var falling_objects = self.falling_objects;

        // Case: entity can climb
        if (climbable_components.getTile(start_point) and climber_components.getTile(start_point)) {
            return;
        }

        const below_this_tile = southOf(start_point);
        const tile_below = tilemap.getTile(below_this_tile);

        // Case: entity falls straight down
        if (tile_below == .space) {
            if (falling_objects.getTile(start_point)) {
                self.moveEntity(start_point, below_this_tile);
                self.createEntity(global, .space, start_point);
            } else {
                falling_objects.setTile(start_point, true);
            }
            return;
        }

        // Case: entity falls on player
        if (tile_below.toEntity() == .player) {
            if (falling_objects.getTile(start_point)) {
                self.is_player_alive = false;
            }
            return;
        }

        // Case: round entity rolls off another round entity
        if (round_objects.getTile(start_point) and round_objects.getTile(below_this_tile)) {
            const tile_east = tilemap.getTile(eastOf(start_point));
            const tile_south_east = tilemap.getTile(southEastOf(start_point));
            if (tile_east == .space and tile_south_east == .space) {
                if (falling_objects.getTile(start_point)) {
                    self.moveEntity(start_point, eastOf(start_point));
                    self.createEntity(global, .space, start_point);
                } else {
                    falling_objects.setTile(start_point, true);
                }
                return;
            }

            const tile_west = tilemap.getTile(westOf(start_point));
            const tile_south_west = tilemap.getTile(southWestOf(start_point));
            if (tile_west == .space and tile_south_west == .space) {
                if (falling_objects.getTile(start_point)) {
                    self.moveEntity(start_point, westOf(start_point));
                    self.createEntity(global, .space, start_point);
                    self.skip_next_tile = true;
                } else {
                    falling_objects.setTile(start_point, true);
                }
                return;
            }
        }

        // Case: none of the above, let's stop it if it's falling
        if (falling_objects.getTile(start_point)) {
            falling_objects.setTile(start_point, false);
        }
    }

    fn setAnimation(self: *PlayState, point: Point(i32), animation: Animation(Tile)) void {
        self.animation_components.setTile(point, animation);
        self.animation_counter_components.setTile(point, AnimationCounter{
            .frame_left_s = animation.frames.items[0].duration,
            .frame_index = 0,
        });
    }

    fn updateAnimations(self: *PlayState, delta_s: f32) void {
        var animation_counters_it = self.animation_counter_components.iteratorForward();

        while (animation_counters_it.next()) |item| {
            if (item.value) |animation_counter| {
                const left_s = animation_counter.frame_left_s - delta_s;
                if (left_s <= 0.0) {
                    if (self.animation_components.getTile(item.point)) |animation| {
                        var next_frame_idx = animation_counter.frame_index + 1;
                        if (next_frame_idx == animation.frames.items.len) next_frame_idx = 0;
                        const next_frame = animation.frames.items[@intCast(usize, next_frame_idx)];
                        self.animation_counter_components.setTile(item.point, AnimationCounter{
                            .frame_left_s = next_frame.duration,
                            .frame_counter = animation_counter.frame_counter + 1,
                            .frame_index = next_frame_idx,
                        });
                        self.tilemap.setTile(item.point, next_frame.data);
                    }
                } else {
                    if (animation_counter.frame_counter == 0) {
                        if (self.animation_components.getTile(item.point)) |animation| {
                            const frame = animation.frames.items[0];
                            self.tilemap.setTile(item.point, frame.data);
                        }
                    }
                    self.animation_counter_components.setTile(item.point, AnimationCounter{
                        .frame_left_s = left_s,
                        .frame_counter = animation_counter.frame_counter + 1,
                        .frame_index = animation_counter.frame_index,
                    });
                }
            }
        }
    }

    fn createEntity(self: *PlayState, global: *ZigDug, entity: Entity, point: Point(i32)) void {
        var tilemap = self.tilemap;
        var background_map = self.background_map;
        var physics_objects = self.physics_objects;
        var round_objects = self.round_objects;
        var falling_objects = self.falling_objects;
        var climbable_components = self.climbable_components;
        var climber_components = self.climber_components;

        switch (entity) {
            .none => {
                tilemap.setTile(point, .none);
                background_map.setTile(point, .none);
                physics_objects.setTile(point, false);
                round_objects.setTile(point, false);
                falling_objects.setTile(point, false);
                climbable_components.setTile(point, false);
                climber_components.setTile(point, false);
            },
            .space => {
                tilemap.setTile(point, .space);
                physics_objects.setTile(point, false);
                round_objects.setTile(point, false);
                falling_objects.setTile(point, false);
                climber_components.setTile(point, false);
            },
            .wall => {
                tilemap.setTile(point, .wall);
                physics_objects.setTile(point, false);
                round_objects.setTile(point, false);
                falling_objects.setTile(point, false);
                climber_components.setTile(point, false);
            },
            .dirt => {
                tilemap.setTile(point, .dirt);
                physics_objects.setTile(point, false);
                round_objects.setTile(point, false);
                falling_objects.setTile(point, false);
                climber_components.setTile(point, false);
            },
            .boulder => {
                tilemap.setTile(point, .boulder);
                physics_objects.setTile(point, true);
                round_objects.setTile(point, true);
                falling_objects.setTile(point, false);
                climber_components.setTile(point, false);
            },
            .key => {
                tilemap.setTile(point, .key);
                physics_objects.setTile(point, true);
                round_objects.setTile(point, true);
                falling_objects.setTile(point, false);
                climber_components.setTile(point, false);

                self.keys += 1;
            },
            .door_closed => {
                tilemap.setTile(point, .door_closed);
                physics_objects.setTile(point, false);
                round_objects.setTile(point, false);
                falling_objects.setTile(point, false);
                climber_components.setTile(point, false);
            },
            .door_open => {
                tilemap.setTile(point, .door_open_01);
                physics_objects.setTile(point, false);
                round_objects.setTile(point, false);
                falling_objects.setTile(point, false);
                climber_components.setTile(point, false);
            },
            .ladder => {
                background_map.setTile(point, .ladder);
                physics_objects.setTile(point, false);
                round_objects.setTile(point, false);
                falling_objects.setTile(point, false);
                climbable_components.setTile(point, true);
                climber_components.setTile(point, false);
            },
            .back_wall => {
                background_map.setTile(point, .back_wall);
                physics_objects.setTile(point, false);
                round_objects.setTile(point, false);
                falling_objects.setTile(point, false);
                climbable_components.setTile(point, false);
                climber_components.setTile(point, false);
            },
            .player => {
                tilemap.setTile(point, .player_idle_right_01);
                physics_objects.setTile(point, true);
                round_objects.setTile(point, false);
                falling_objects.setTile(point, false);
                climber_components.setTile(point, true);
                self.setAnimation(point, global.player_idle_right_animation);
            },
            .debug => {
                background_map.setTile(point, .debug);
                tilemap.setTile(point, .debug);
                physics_objects.setTile(point, false);
                round_objects.setTile(point, false);
                falling_objects.setTile(point, false);
                climbable_components.setTile(point, false);
                climber_components.setTile(point, false);
            },
        }
    }

    fn moveEntity(self: *PlayState, start: Point(i32), destination: Point(i32)) void {
        var tilemap = self.tilemap;
        var physics_objects = self.physics_objects;
        var round_objects = self.round_objects;
        var falling_objects = self.falling_objects;
        var climber_components = self.climber_components;
        var animation_components = self.animation_components;
        var animation_counter_components = self.animation_counter_components;

        tilemap.setTile(destination, tilemap.getTile(start));
        physics_objects.setTile(destination, physics_objects.getTile(start));
        round_objects.setTile(destination, round_objects.getTile(start));
        falling_objects.setTile(destination, falling_objects.getTile(start));
        climber_components.setTile(destination, climber_components.getTile(start));
        animation_components.setTile(destination, animation_components.getTile(start));
        animation_counter_components.setTile(destination, animation_counter_components.getTile(start));

        tilemap.setTile(start, tilemap.null_value);
        physics_objects.setTile(start, false);
        round_objects.setTile(start, false);
        falling_objects.setTile(start, false);
        climber_components.setTile(start, false);
        animation_components.setTile(start, null);
        animation_counter_components.setTile(start, null);
    }

    fn updateFinishMapState(self: *PlayState, global: *ZigDug) void {
        self.substate = .load_map;
        global.state = .credits;
    }
};

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
