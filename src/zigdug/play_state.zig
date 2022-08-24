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

pub const PlayerData = struct {
    is_alive: bool = true,
    energy: f64 = 1.0 / 6.0,
    old_facing_direction: Direction = Direction.right,
    old_state: PlayerState = PlayerState.standing,
    new_facing_direction: Direction = Direction.right,
    new_state: PlayerState = PlayerState.standing,
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

    map_energy: f64 = 0,
    skip_next_tile: bool = false,
    keys: i32 = 0,
    is_level_beaten: bool = false,

    player: PlayerData = PlayerData{},

    // Components
    animation_components: Tilemap(?Animation(Tile)),
    animation_counter_components: Tilemap(?AnimationCounter),
    background_tile_components: Tilemap(Tile),
    climbable_components: Tilemap(bool),
    climber_components: Tilemap(bool),
    entity_type_components: Tilemap(Entity),
    falling_components: Tilemap(bool),
    foreground_tile_components: Tilemap(Tile),
    physics_components: Tilemap(bool),
    round_components: Tilemap(bool),

    pub fn init(allocator: Allocator) !PlayState {
        const entity_type_components = try Tilemap(Entity).init(
            allocator,
            config.map_width,
            config.map_height,
            1,
            Entity.none,
        );
        const background_tile_components = try Tilemap(Tile).init(
            allocator,
            config.map_width,
            config.map_height,
            1,
            Tile.none,
        );
        const foreground_tile_components = try Tilemap(Tile).init(
            allocator,
            config.map_width,
            config.map_height,
            1,
            Tile.none,
        );
        const falling_components = try Tilemap(bool).init(
            allocator,
            config.map_width,
            config.map_height,
            1,
            false,
        );
        const physics_components = try Tilemap(bool).init(
            allocator,
            config.map_width,
            config.map_height,
            1,
            false,
        );
        const round_components = try Tilemap(bool).init(
            allocator,
            config.map_width,
            config.map_height,
            1,
            false,
        );
        const climbable_components = try Tilemap(bool).init(
            allocator,
            config.map_width,
            config.map_height,
            1,
            false,
        );
        const climber_components = try Tilemap(bool).init(
            allocator,
            config.map_width,
            config.map_height,
            1,
            false,
        );
        const animation_components = try Tilemap(?Animation(Tile)).init(
            allocator,
            config.map_width,
            config.map_height,
            1,
            null,
        );
        const animation_counter_components = try Tilemap(?AnimationCounter).init(
            allocator,
            config.map_width,
            config.map_height,
            1,
            null,
        );
        return PlayState{
            .maps = config.maps[0..],
            .animation_components = animation_components,
            .animation_counter_components = animation_counter_components,
            .background_tile_components = background_tile_components,
            .climbable_components = climbable_components,
            .climber_components = climber_components,
            .entity_type_components = entity_type_components,
            .falling_components = falling_components,
            .foreground_tile_components = foreground_tile_components,
            .physics_components = physics_components,
            .round_components = round_components,
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
        self.substate = .play_map;
        self.skip_next_tile = false;
        self.is_level_beaten = false;
        self.map_energy = 0;
        self.keys = 0;
        self.entity_type_components.setAll(.none);
        self.background_tile_components.setAll(.none);
        self.foreground_tile_components.setAll(.none);
        self.physics_components.setAll(false);
        self.round_components.setAll(false);
        self.falling_components.setAll(false);
        self.climbable_components.setAll(false);
        self.climber_components.setAll(false);
        self.animation_components.setAll(null);
        self.animation_counter_components.setAll(null);
        self.player.is_alive = true;
        self.player.energy = 1.0 / 6.0;
        self.player.old_facing_direction = Direction.right;
        self.player.old_state = PlayerState.standing;
        self.player.new_facing_direction = Direction.right;
        self.player.new_state = PlayerState.standing;
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
        assert(width == config.map_width);
        assert(height == config.map_height);

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

        if (!self.player.is_alive) {
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
        self.player.energy += delta_s;

        if (self.player.energy >= config.player_energy_max) {
            self.player.old_facing_direction = self.player.new_facing_direction;
            self.player.old_state = self.player.new_state;
            if (input.player_up or input.player_right or input.player_down or input.player_left) {
                var direction: Direction = undefined;
                if (input.player_up) direction = .up;
                if (input.player_right) direction = .right;
                if (input.player_down) direction = .down;
                if (input.player_left) direction = .left;

                self.tryPlayerMove(global, direction);
                self.player.energy = 0;
            } else {
                self.player.new_state = .standing;
            }
        }
    }

    fn tryPlayerMove(self: *PlayState, global: *ZigDug, direction: Direction) void {
        if (self.entity_type_components.findFirst(isPlayer)) |start_pos| {
            if (self.falling_components.get(start_pos)) {
                if (!(self.entity_type_components.get(southOf(start_pos)) == .space) or self.climbable_components.get(start_pos)) {
                    self.falling_components.set(start_pos, false);
                    self.player.new_state = .standing;
                } else {
                    self.player.new_state = .falling;
                    return;
                }
            }
            switch (direction) {
                .up => {
                    const above = northOf(start_pos);
                    if (self.climbable_components.get(start_pos) and self.climbable_components.get(above)) {
                        self.moveEntity(start_pos, above);
                        self.createEntity(global, .space, start_pos);
                        self.player.new_state = .climbing;
                    }
                },
                else => {
                    const new_pos = switch (direction) {
                        .down => southOf(start_pos),
                        .left => westOf(start_pos),
                        .right => eastOf(start_pos),
                        .up => unreachable,
                    };
                    const target_entity = self.entity_type_components.get(new_pos);
                    switch (target_entity) {
                        .space => {
                            self.moveEntity(start_pos, new_pos);
                            self.createEntity(global, .space, start_pos);
                            self.player.new_state = .running;
                        },
                        .dirt => {
                            self.moveEntity(start_pos, new_pos);
                            self.createEntity(global, .space, start_pos);
                            self.player.new_state = .digging;
                        },
                        .key => {
                            self.moveEntity(start_pos, new_pos);
                            self.createEntity(global, .space, start_pos);
                            self.player.new_state = .running;
                            self.keys -= 1;
                            global.active_sounds[@enumToInt(Sound.gem)] = true;
                        },
                        .boulder => {
                            switch (direction) {
                                .right => {
                                    if (self.entity_type_components.get(eastOf(new_pos)) == .space) {
                                        self.pushBoulder(global, start_pos, new_pos, eastOf(new_pos));
                                        self.player.new_state = .pushing;
                                    } else {
                                        self.player.new_state = .standing;
                                    }
                                },
                                .left => {
                                    if (self.entity_type_components.get(westOf(new_pos)) == .space) {
                                        self.pushBoulder(global, start_pos, new_pos, westOf(new_pos));
                                        self.player.new_state = .pushing;
                                    } else {
                                        self.player.new_state = .standing;
                                    }
                                },
                                else => {
                                    self.player.new_state = .standing;
                                },
                            }
                        },
                        .door_open => {
                            self.createEntity(global, .space, start_pos);
                            self.is_level_beaten = true;
                            self.player.new_state = .running; // TODO: we can add a winning state here
                        },
                        else => {
                            self.player.new_state = .standing;
                        },
                    }
                },
            }
            self.player.new_facing_direction = direction;
        }
    }

    fn isPlayer(entity_type: Entity) bool {
        return entity_type == .player;
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
        const old_state = self.player.old_state;
        const new_state = self.player.new_state;
        const old_facing_direction = self.player.old_facing_direction;
        const new_facing_direction = self.player.new_facing_direction;

        if (old_state == new_state and old_facing_direction == new_facing_direction) {
            return;
        }

        if (self.entity_type_components.findFirst(isPlayer)) |player_point| {
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

        if (self.map_energy >= config.map_energy_max) {
            var entity_type_iterator = self.entity_type_components.iteratorBackward();

            while (entity_type_iterator.next()) |item| {
                if (!self.skip_next_tile) {
                    if (self.physics_components.get(item.point)) {
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
        var entity_type_components = self.entity_type_components;
        var climbable_components = self.climbable_components;
        var climber_components = self.climber_components;
        var round_components = self.round_components;
        var falling_components = self.falling_components;

        // Case: entity can climb
        if (climbable_components.get(start_point) and climber_components.get(start_point)) {
            return;
        }

        const below_this_tile = southOf(start_point);
        const entity_below = entity_type_components.get(below_this_tile);

        // Case: entity falls straight down
        if (entity_below == .space) {
            if (falling_components.get(start_point)) {
                self.moveEntity(start_point, below_this_tile);
                self.createEntity(global, .space, start_point);
            } else {
                falling_components.set(start_point, true);
            }
            return;
        }

        // Case: entity falls on player
        if (entity_below == .player) {
            if (falling_components.get(start_point)) {
                self.player.is_alive = false;
            }
            return;
        }

        // Case: round entity rolls off another round entity
        if (round_components.get(start_point) and round_components.get(below_this_tile)) {
            const entity_east = entity_type_components.get(eastOf(start_point));
            const entity_south_east = entity_type_components.get(southEastOf(start_point));
            if (entity_east == .space and entity_south_east == .space) {
                if (falling_components.get(start_point)) {
                    self.moveEntity(start_point, eastOf(start_point));
                    self.createEntity(global, .space, start_point);
                } else {
                    falling_components.set(start_point, true);
                }
                return;
            }

            const entity_west = entity_type_components.get(westOf(start_point));
            const entity_south_west = entity_type_components.get(southWestOf(start_point));
            if (entity_west == .space and entity_south_west == .space) {
                if (falling_components.get(start_point)) {
                    self.moveEntity(start_point, westOf(start_point));
                    self.createEntity(global, .space, start_point);
                    self.skip_next_tile = true;
                } else {
                    falling_components.set(start_point, true);
                }
                return;
            }
        }

        // Case: none of the above, let's stop it if it's falling
        if (falling_components.get(start_point)) {
            falling_components.set(start_point, false);
        }
    }

    fn setAnimation(self: *PlayState, point: Point(i32), animation: Animation(Tile)) void {
        self.animation_components.set(point, animation);
        self.animation_counter_components.set(point, AnimationCounter{
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
                    if (self.animation_components.get(item.point)) |animation| {
                        var next_frame_idx = animation_counter.frame_index + 1;
                        if (next_frame_idx == animation.frames.items.len) next_frame_idx = 0;
                        const next_frame = animation.frames.items[@intCast(usize, next_frame_idx)];
                        self.animation_counter_components.set(item.point, AnimationCounter{
                            .frame_left_s = next_frame.duration,
                            .frame_counter = animation_counter.frame_counter + 1,
                            .frame_index = next_frame_idx,
                        });
                        self.foreground_tile_components.set(item.point, next_frame.data);
                    }
                } else {
                    if (animation_counter.frame_counter == 0) {
                        if (self.animation_components.get(item.point)) |animation| {
                            const frame = animation.frames.items[0];
                            self.foreground_tile_components.set(item.point, frame.data);
                        }
                    }
                    self.animation_counter_components.set(item.point, AnimationCounter{
                        .frame_left_s = left_s,
                        .frame_counter = animation_counter.frame_counter + 1,
                        .frame_index = animation_counter.frame_index,
                    });
                }
            }
        }
    }

    fn createEntity(self: *PlayState, global: *ZigDug, entity: Entity, point: Point(i32)) void {
        var entity_type_components = self.entity_type_components;
        var foreground_tile_components = self.foreground_tile_components;
        var background_tile_components = self.background_tile_components;
        var physics_components = self.physics_components;
        var round_components = self.round_components;
        var falling_components = self.falling_components;
        var climbable_components = self.climbable_components;
        var climber_components = self.climber_components;

        switch (entity) {
            .none => {
                entity_type_components.set(point, Entity.none);
                foreground_tile_components.set(point, Tile.none);
                background_tile_components.set(point, Tile.none);
                physics_components.set(point, false);
                round_components.set(point, false);
                falling_components.set(point, false);
                climbable_components.set(point, false);
                climber_components.set(point, false);
            },
            .space => {
                entity_type_components.set(point, Entity.space);
                foreground_tile_components.set(point, Tile.space);
                physics_components.set(point, false);
                round_components.set(point, false);
                falling_components.set(point, false);
                climber_components.set(point, false);
            },
            .wall => {
                entity_type_components.set(point, Entity.wall);
                foreground_tile_components.set(point, Tile.wall);
                physics_components.set(point, false);
                round_components.set(point, false);
                falling_components.set(point, false);
                climber_components.set(point, false);
            },
            .dirt => {
                entity_type_components.set(point, Entity.dirt);
                foreground_tile_components.set(point, Tile.dirt);
                physics_components.set(point, false);
                round_components.set(point, false);
                falling_components.set(point, false);
                climber_components.set(point, false);
            },
            .boulder => {
                entity_type_components.set(point, Entity.boulder);
                foreground_tile_components.set(point, Tile.boulder);
                physics_components.set(point, true);
                round_components.set(point, true);
                falling_components.set(point, false);
                climber_components.set(point, false);
            },
            .key => {
                entity_type_components.set(point, Entity.key);
                foreground_tile_components.set(point, Tile.key);
                physics_components.set(point, true);
                round_components.set(point, true);
                falling_components.set(point, false);
                climber_components.set(point, false);

                self.keys += 1;
            },
            .door_closed => {
                entity_type_components.set(point, Entity.door_closed);
                foreground_tile_components.set(point, Tile.door_closed);
                physics_components.set(point, false);
                round_components.set(point, false);
                falling_components.set(point, false);
                climber_components.set(point, false);
            },
            .door_open => {
                entity_type_components.set(point, Entity.door_open);
                foreground_tile_components.set(point, Tile.door_open_01);
                physics_components.set(point, false);
                round_components.set(point, false);
                falling_components.set(point, false);
                climber_components.set(point, false);
            },
            .ladder => {
                entity_type_components.set(point, Entity.ladder);
                background_tile_components.set(point, Tile.ladder);
                physics_components.set(point, false);
                round_components.set(point, false);
                falling_components.set(point, false);
                climbable_components.set(point, true);
                climber_components.set(point, false);
            },
            .back_wall => {
                entity_type_components.set(point, Entity.back_wall);
                background_tile_components.set(point, Tile.back_wall);
                physics_components.set(point, false);
                round_components.set(point, false);
                falling_components.set(point, false);
                climbable_components.set(point, false);
                climber_components.set(point, false);
            },
            .player => {
                entity_type_components.set(point, Entity.player);
                foreground_tile_components.set(point, Tile.player_idle_right_01);
                physics_components.set(point, true);
                round_components.set(point, false);
                falling_components.set(point, false);
                climber_components.set(point, true);
                self.setAnimation(point, global.player_idle_right_animation);
            },
            .debug => {
                entity_type_components.set(point, Entity.debug);
                background_tile_components.set(point, Tile.debug);
                foreground_tile_components.set(point, Tile.debug);
                physics_components.set(point, false);
                round_components.set(point, false);
                falling_components.set(point, false);
                climbable_components.set(point, false);
                climber_components.set(point, false);
            },
        }
    }

    fn moveEntity(self: *PlayState, start: Point(i32), destination: Point(i32)) void {
        self.animation_components.set(destination, self.animation_components.get(start));
        self.animation_components.set(start, null);
        self.animation_counter_components.set(destination, self.animation_counter_components.get(start));
        self.animation_counter_components.set(start, null);
        self.climber_components.set(destination, self.climber_components.get(start));
        self.climber_components.set(start, false);
        self.entity_type_components.set(destination, self.entity_type_components.get(start));
        self.entity_type_components.set(start, Entity.none);
        self.falling_components.set(destination, self.falling_components.get(start));
        self.falling_components.set(start, false);
        self.foreground_tile_components.set(destination, self.foreground_tile_components.get(start));
        self.foreground_tile_components.set(start, self.foreground_tile_components.null_value);
        self.physics_components.set(destination, self.physics_components.get(start));
        self.physics_components.set(start, false);
        self.round_components.set(destination, self.round_components.get(start));
        self.round_components.set(start, false);
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
