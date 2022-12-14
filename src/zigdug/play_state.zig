const std = @import("std");
const assert = std.debug.assert;

const Allocator = std.mem.Allocator;
const AutoHashMap = std.AutoHashMap;

const anim = @import("animation.zig");
const common = @import("common.zig");
const config = @import("config.zig");
const ray = @import("../raylib.zig");
const zigdug = @import("../zigdug.zig");

const Animation = anim.Animation;
const AnimationCounter = anim.AnimationCounter;
const AnimationFrame = anim.AnimationFrame;
const Direction = common.Direction;
const Input = zigdug.Input;
const Point = common.Point;
const Sound = zigdug.Sound;
const Tilemap = @import("tilemap.zig").Tilemap;
const ZigDug = zigdug.ZigDug;

pub const AnimationLayer = enum(u8) {
    background,
    foreground,
};

pub const PlayStateSubState = enum(u8) {
    load_map,
    play_map,
    finish_map,
};

pub const Tile = enum(u8) {
    none,
    back_wall,
    boulder,
    debug,
    dirt,
    door_closed,
    door_open_01,
    door_open_02,
    door_open_03,
    door_open_04,
    key,
    ladder,
    player_digging_left_01,
    player_digging_left_02,
    player_digging_right_01,
    player_digging_right_02,
    player_falling_left_01,
    player_falling_left_02,
    player_falling_right_01,
    player_falling_right_02,
    player_idle_left_01,
    player_idle_left_02,
    player_idle_left_03,
    player_idle_left_04,
    player_idle_right_01,
    player_idle_right_02,
    player_idle_right_03,
    player_idle_right_04,
    player_running_left_01,
    player_running_left_02,
    player_running_right_01,
    player_running_right_02,
    space,
    wall,
};

pub const Entity = enum(u8) {
    none,
    back_wall,
    boulder,
    dirt,
    door,
    key,
    ladder,
    player,
    space,
    wall,
    debug,
};

pub const Move = struct {
    origin: Point(i32),
    destination: Point(i32),
    lerp_amount: f32 = 0,
};

pub const PlayState = struct {
    substate: PlayStateSubState = .load_map,
    maps: [][]const u8,
    map_index: usize = 0,

    activated_sounds: AutoHashMap(Sound, bool),

    // Animations
    open_door_animation: Animation(Tile),
    player_digging_left_animation: Animation(Tile),
    player_digging_right_animation: Animation(Tile),
    player_falling_left_animation: Animation(Tile),
    player_falling_right_animation: Animation(Tile),
    player_idle_left_animation: Animation(Tile),
    player_idle_right_animation: Animation(Tile),
    player_running_left_animation: Animation(Tile),
    player_running_right_animation: Animation(Tile),

    // Components
    animation_components: Tilemap(?Animation(Tile)),
    animation_counter_components: Tilemap(?AnimationCounter),
    animation_layer_components: Tilemap(?AnimationLayer),
    background_tile_components: Tilemap(Tile),
    climbable_components: Tilemap(bool),
    climber_components: Tilemap(bool),
    climbing_components: Tilemap(bool),
    diggable_components: Tilemap(bool),
    digging_components: Tilemap(bool),
    energy_components: Tilemap(?f32),
    exit_components: Tilemap(bool),
    facing_components: Tilemap(?Direction),
    falling_components: Tilemap(bool),
    foreground_tile_components: Tilemap(Tile),
    key_components: Tilemap(bool),
    lock_components: Tilemap(bool),
    move_components: Tilemap(?Move),
    physics_components: Tilemap(bool),
    playable_components: Tilemap(bool),
    player_controlled_components: Tilemap(bool),
    processed_components: Tilemap(bool),
    pushing_components: Tilemap(bool),
    round_components: Tilemap(bool),
    running_components: Tilemap(bool),
    solid_components: Tilemap(bool),

    pub fn init(allocator: Allocator) !PlayState {
        var activated_sounds = AutoHashMap(Sound, bool).init(allocator);
        try activated_sounds.ensureTotalCapacity(config.max_sounds_per_frame);

        var open_door_animation = Animation(Tile).init(allocator);
        try open_door_animation.add_frame(.door_open_01, 1.0 / 3.0);
        try open_door_animation.add_frame(.door_open_02, 1.0 / 3.0);
        try open_door_animation.add_frame(.door_open_03, 1.0 / 3.0);
        try open_door_animation.add_frame(.door_open_04, 1.0 / 3.0);

        var player_digging_left_animation = Animation(Tile).init(allocator);
        try player_digging_left_animation.add_frame(.player_digging_left_01, 1.0 / 12.0);
        try player_digging_left_animation.add_frame(.player_digging_left_02, 1.0 / 12.0);

        var player_digging_right_animation = Animation(Tile).init(allocator);
        try player_digging_right_animation.add_frame(.player_digging_right_01, 1.0 / 12.0);
        try player_digging_right_animation.add_frame(.player_digging_right_02, 1.0 / 12.0);

        var player_falling_left_animation = Animation(Tile).init(allocator);
        try player_falling_left_animation.add_frame(.player_falling_left_01, 1.0 / 6.0);
        try player_falling_left_animation.add_frame(.player_falling_left_02, 1.0 / 6.0);

        var player_falling_right_animation = Animation(Tile).init(allocator);
        try player_falling_right_animation.add_frame(.player_falling_right_01, 1.0 / 6.0);
        try player_falling_right_animation.add_frame(.player_falling_right_02, 1.0 / 6.0);

        var player_idle_left_animation = Animation(Tile).init(allocator);
        try player_idle_left_animation.add_frame(.player_idle_left_01, 1.0 / 2.0);
        try player_idle_left_animation.add_frame(.player_idle_left_02, 1.0 / 2.0);
        try player_idle_left_animation.add_frame(.player_idle_left_03, 1.0 / 2.0);
        try player_idle_left_animation.add_frame(.player_idle_left_04, 1.0 / 2.0);

        var player_idle_right_animation = Animation(Tile).init(allocator);
        try player_idle_right_animation.add_frame(.player_idle_right_01, 1.0 / 2.0);
        try player_idle_right_animation.add_frame(.player_idle_right_02, 1.0 / 2.0);
        try player_idle_right_animation.add_frame(.player_idle_right_03, 1.0 / 2.0);
        try player_idle_right_animation.add_frame(.player_idle_right_04, 1.0 / 2.0);

        var player_running_left_animation = Animation(Tile).init(allocator);
        try player_running_left_animation.add_frame(.player_running_left_01, 1.0 / 6.0);
        try player_running_left_animation.add_frame(.player_running_left_02, 1.0 / 6.0);

        var player_running_right_animation = Animation(Tile).init(allocator);
        try player_running_right_animation.add_frame(.player_running_right_01, 1.0 / 6.0);
        try player_running_right_animation.add_frame(.player_running_right_02, 1.0 / 6.0);

        var animation_components = try initComponentTilemap(allocator, ?Animation(Tile), null);
        var animation_counter_components = try initComponentTilemap(allocator, ?AnimationCounter, null);
        var animation_layer_components = try initComponentTilemap(allocator, ?AnimationLayer, null);
        var background_tile_components = try initComponentTilemap(allocator, Tile, Tile.none);
        var climbable_components = try initComponentTilemap(allocator, bool, false);
        var climber_components = try initComponentTilemap(allocator, bool, false);
        var climbing_components = try initComponentTilemap(allocator, bool, false);
        var diggable_components = try initComponentTilemap(allocator, bool, false);
        var digging_components = try initComponentTilemap(allocator, bool, false);
        var energy_components = try initComponentTilemap(allocator, ?f32, null);
        var exit_components = try initComponentTilemap(allocator, bool, false);
        var facing_components = try initComponentTilemap(allocator, ?Direction, null);
        var falling_components = try initComponentTilemap(allocator, bool, false);
        var foreground_tile_components = try initComponentTilemap(allocator, Tile, Tile.none);
        var key_components = try initComponentTilemap(allocator, bool, false);
        var lock_components = try initComponentTilemap(allocator, bool, false);
        var move_components = try initComponentTilemap(allocator, ?Move, null);
        var physics_components = try initComponentTilemap(allocator, bool, false);
        var playable_components = try initComponentTilemap(allocator, bool, false);
        var player_controlled_components = try initComponentTilemap(allocator, bool, false);
        var processed_components = try initComponentTilemap(allocator, bool, false);
        var pushing_components = try initComponentTilemap(allocator, bool, false);
        var round_components = try initComponentTilemap(allocator, bool, false);
        var running_components = try initComponentTilemap(allocator, bool, false);
        var solid_components = try initComponentTilemap(allocator, bool, false);

        return PlayState{
            .maps = config.maps[0..],

            .activated_sounds = activated_sounds,

            .open_door_animation = open_door_animation,
            .player_digging_left_animation = player_digging_left_animation,
            .player_digging_right_animation = player_digging_right_animation,
            .player_falling_left_animation = player_falling_left_animation,
            .player_falling_right_animation = player_falling_right_animation,
            .player_idle_left_animation = player_idle_left_animation,
            .player_idle_right_animation = player_idle_right_animation,
            .player_running_left_animation = player_running_left_animation,
            .player_running_right_animation = player_running_right_animation,

            .animation_components = animation_components,
            .animation_counter_components = animation_counter_components,
            .animation_layer_components = animation_layer_components,
            .background_tile_components = background_tile_components,
            .climbable_components = climbable_components,
            .climber_components = climber_components,
            .climbing_components = climbing_components,
            .diggable_components = diggable_components,
            .digging_components = digging_components,
            .energy_components = energy_components,
            .exit_components = exit_components,
            .facing_components = facing_components,
            .falling_components = falling_components,
            .foreground_tile_components = foreground_tile_components,
            .key_components = key_components,
            .lock_components = lock_components,
            .move_components = move_components,
            .physics_components = physics_components,
            .playable_components = playable_components,
            .player_controlled_components = player_controlled_components,
            .processed_components = processed_components,
            .pushing_components = pushing_components,
            .round_components = round_components,
            .running_components = running_components,
            .solid_components = solid_components,
        };
    }

    pub fn update(self: *PlayState, global: *ZigDug, input: *Input, delta_s: f32) void {
        self.activated_sounds.clearRetainingCapacity();
        switch (self.substate) {
            .load_map => self.updateLoadMapState(),
            .play_map => self.updatePlayMapState(global, input, delta_s),
            .finish_map => self.updateFinishMapState(global),
        }
    }

    fn updateLoadMapState(self: *PlayState) void {
        self.resetState();
        self.loadMap(self.maps[self.map_index]);
    }

    fn resetState(self: *PlayState) void {
        self.substate = .play_map;

        // reset components
        self.animation_components.setAll(null);
        self.animation_counter_components.setAll(null);
        self.animation_layer_components.setAll(null);
        self.background_tile_components.setAll(.none);
        self.climbable_components.setAll(false);
        self.climber_components.setAll(false);
        self.climbing_components.setAll(false);
        self.diggable_components.setAll(false);
        self.digging_components.setAll(false);
        self.energy_components.setAll(null);
        self.exit_components.setAll(false);
        self.facing_components.setAll(null);
        self.falling_components.setAll(false);
        self.foreground_tile_components.setAll(.none);
        self.key_components.setAll(false);
        self.lock_components.setAll(false);
        self.move_components.setAll(null);
        self.physics_components.setAll(false);
        self.playable_components.setAll(false);
        self.player_controlled_components.setAll(false);
        self.processed_components.setAll(false);
        self.pushing_components.setAll(false);
        self.round_components.setAll(false);
        self.running_components.setAll(false);
        self.solid_components.setAll(false);
    }

    fn loadMap(self: *PlayState, filename: []const u8) void {
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
                0xFF000000 => {},
                0xFF532B1D => {
                    self.createEntity(.back_wall, tilemap_point);
                    self.createEntity(.space, tilemap_point);
                },
                0xFF3652AB => {
                    self.createEntity(.back_wall, tilemap_point);
                    self.createEntity(.dirt, tilemap_point);
                },
                0xFF27ECFF => self.createEntity(.wall, tilemap_point),
                0xFFC7C3C2 => {
                    self.createEntity(.back_wall, tilemap_point);
                    self.createEntity(.boulder, tilemap_point);
                },
                0xFF4D00FF => {
                    self.createEntity(.back_wall, tilemap_point);
                    self.createEntity(.key, tilemap_point);
                },
                0xFFE8F1FF => {
                    self.createEntity(.back_wall, tilemap_point);
                    self.createEntity(.player, tilemap_point);
                },
                0xFFA877FF => {
                    self.createEntity(.door, tilemap_point);
                    self.createEntity(.space, tilemap_point);
                },
                0xFF53257E => {
                    self.createEntity(.ladder, tilemap_point);
                    self.createEntity(.space, tilemap_point);
                },
                else => self.createEntity(.debug, tilemap_point),
            }
        }
    }

    fn updatePlayMapState(self: *PlayState, global: *ZigDug, input: *Input, delta_s: f32) void {
        if (self.isMapBeaten()) {
            self.map_index += 1;
            if (self.map_index >= self.maps.len) {
                global.state = .credits;
                self.map_index = 0;
            }
            self.substate = .load_map;
            return;
        }

        if (self.playable_components.findFirst(isTrue) == null) {
            self.substate = .load_map;
            return;
        }

        if (input.game_pause) {
            global.state = .pause;
            return;
        }

        self.processed_components.setAll(false);

        var energy_iterator = self.energy_components.iteratorBackward();

        while (energy_iterator.next()) |item| {
            if (!self.processed_components.get(item.point)) {
                var point = item.point;
                if (item.value) |energy| {
                    const updated_energy = energy + delta_s;
                    if (updated_energy >= config.energy_max) {
                        if (self.move_components.get(point) != null) {
                            self.move_components.set(point, null);
                        }

                        self.resetEnergyForEntity(point, input);

                        if (self.player_controlled_components.get(point)) {
                            point = self.updatePlayer(point, input);
                        }

                        if (self.physics_components.get(point)) {
                            point = self.updatePhysics(point);
                        }

                        if (self.lock_components.get(point)) {
                            point = self.updateLockedDoor(point);
                        }
                    } else {
                        self.energy_components.set(point, updated_energy);
                    }

                    // Calculate linear interpolation for rendering moving entities
                    if (self.move_components.get(point)) |move| {
                        if (self.energy_components.get(point)) |current_energy| {
                            const lerp_amount = current_energy / config.energy_max;
                            self.move_components.set(point, Move{
                                .origin = move.origin,
                                .destination = move.destination,
                                .lerp_amount = lerp_amount,
                            });
                        }
                    }
                }
                self.processed_components.set(point, true);
            }
        }

        self.animatePlayer();
        self.updateAnimations(delta_s);
    }

    fn resetEnergyForEntity(self: *PlayState, point: Point(i32), input: *Input) void {
        if (self.player_controlled_components.get(point)) {
            if (input.player_up or input.player_right or input.player_down or input.player_left) {
                self.energy_components.set(point, 0);
            }
        } else {
            self.energy_components.set(point, 0);
        }
    }

    fn isMapBeaten(self: *PlayState) bool {
        if (self.exit_components.findFirst(isTrue)) |exit_point| {
            if (self.playable_components.findFirst(isTrue)) |player_point| {
                if (player_point.x == exit_point.x and player_point.y == exit_point.y) {
                    return true;
                }
            }
        }
        return false;
    }

    fn updatePlayer(self: *PlayState, player_point: Point(i32), input: *Input) Point(i32) {
        self.climbing_components.set(player_point, false);
        self.digging_components.set(player_point, false);
        self.pushing_components.set(player_point, false);
        self.running_components.set(player_point, false);

        var new_player_point = player_point;

        var optional_direction: ?Direction = null;
        if (input.player_up) optional_direction = .up;
        if (input.player_right) optional_direction = .right;
        if (input.player_down) optional_direction = .down;
        if (input.player_left) optional_direction = .left;

        if (optional_direction) |direction| {
            new_player_point = self.tryPlayerMove(player_point, direction);

            // hand over control to physics if empty space below and no ladder
            if (!self.solid_components.get(southOf(new_player_point)) and
                !self.climbable_components.get(new_player_point))
            {
                self.player_controlled_components.set(new_player_point, false);
                self.physics_components.set(new_player_point, true);
            }
        }

        return new_player_point;
    }

    fn tryPlayerMove(self: *PlayState, origin: Point(i32), direction: Direction) Point(i32) {
        if (direction == .left or direction == .right) {
            self.facing_components.set(origin, direction);
        }

        switch (direction) {
            .up => {
                const destination = northOf(origin);
                if (self.climbable_components.get(origin) and self.climbable_components.get(destination)) {
                    self.climbing_components.set(origin, true);
                    self.moveEntity(origin, destination);
                    return destination;
                }
            },
            else => {
                const destination = switch (direction) {
                    .down => southOf(origin),
                    .left => westOf(origin),
                    .right => eastOf(origin),
                    .up => unreachable,
                };

                if (!self.solid_components.get(destination)) {
                    self.running_components.set(origin, true);
                    self.moveEntity(origin, destination);
                    return destination;
                }

                if (self.diggable_components.get(destination)) {
                    self.digging_components.set(origin, true);
                    self.moveEntity(origin, destination);
                    return destination;
                }

                if (self.key_components.get(destination)) {
                    self.running_components.set(origin, true);
                    self.moveEntity(origin, destination);
                    self.playSound(.gem);
                    return destination;
                }

                if (self.round_components.get(destination)) {
                    switch (direction) {
                        .right => {
                            if (!self.solid_components.get(eastOf(destination))) {
                                self.pushing_components.set(origin, true);
                                self.moveEntity(destination, eastOf(destination));
                                self.moveEntity(origin, destination);
                                return destination;
                            }
                        },
                        .left => {
                            if (!self.solid_components.get(westOf(destination))) {
                                self.pushing_components.set(origin, true);
                                self.moveEntity(destination, westOf(destination));
                                self.moveEntity(origin, destination);
                                return destination;
                            }
                        },
                        else => {
                            return origin;
                        },
                    }
                }
            },
        }
        return origin;
    }

    fn animatePlayer(self: *PlayState) void {
        if (self.playable_components.findFirst(isTrue)) |point| {
            const is_climbing = self.climbing_components.get(point);
            const is_digging = self.digging_components.get(point);
            const is_falling = self.falling_components.get(point);
            const is_pushing = self.pushing_components.get(point);
            const is_running = self.running_components.get(point);
            const is_idle = !(is_climbing or is_digging or is_falling or is_pushing or is_running);

            const facing = self.facing_components.get(point).?;

            var animation: ?Animation(Tile) = null;

            if (is_climbing and facing == .left) {
                animation = self.player_running_left_animation;
            } else if (is_climbing and facing == .right) {
                animation = self.player_running_right_animation;
            } else if (is_digging and facing == .left) {
                animation = self.player_digging_left_animation;
            } else if (is_digging and facing == .right) {
                animation = self.player_digging_right_animation;
            } else if (is_falling and facing == .left) {
                animation = self.player_falling_left_animation;
            } else if (is_falling and facing == .right) {
                animation = self.player_falling_right_animation;
            } else if (is_pushing and facing == .left) {
                animation = self.player_running_left_animation;
            } else if (is_pushing and facing == .right) {
                animation = self.player_running_right_animation;
            } else if (is_running and facing == .left) {
                animation = self.player_running_left_animation;
            } else if (is_running and facing == .right) {
                animation = self.player_running_right_animation;
            } else if (is_idle and facing == .left) {
                animation = self.player_idle_left_animation;
            } else if (is_idle and facing == .right) {
                animation = self.player_idle_right_animation;
            }

            if (animation != null) {
                self.startOrResumeAnimation(.foreground, point, animation.?);
            }
        }
    }

    fn updateLockedDoor(self: *PlayState, point: Point(i32)) Point(i32) {
        if (self.key_components.findFirst(isTrue) == null) {
            self.lock_components.set(point, false);
            self.exit_components.set(point, true);
            self.background_tile_components.set(point, .door_open_01);
            self.startOrResumeAnimation(.background, point, self.open_door_animation);
        }
        return point;
    }

    fn updatePhysics(self: *PlayState, origin: Point(i32)) Point(i32) {
        if (self.climbable_components.get(origin) and self.climber_components.get(origin)) {
            self.falling_components.set(origin, false);
            if (self.playable_components.get(origin)) {
                self.physics_components.set(origin, false);
                self.player_controlled_components.set(origin, true);
                self.energy_components.set(origin, config.energy_max);
            }
            return origin;
        }

        const below = southOf(origin);

        // Case: entity falls straight down
        if (!self.solid_components.get(below)) {
            if (self.falling_components.get(origin)) {
                self.moveEntity(origin, below);
                self.runPostPhysics(below);
                return below;
            } else {
                self.falling_components.set(origin, true);
                return origin;
            }
        }

        // Case: entity falls on player
        if (self.playable_components.get(below)) {
            if (self.falling_components.get(origin)) {
                self.playable_components.set(below, false);
            }
            return origin;
        }

        // Case: round entity rolls off another round entity
        if (self.round_components.get(origin) and self.round_components.get(below)) {
            const east = eastOf(origin);
            const south_east = southEastOf(origin);
            const north_east = northEastOf(origin);
            if (!self.solid_components.get(east) and
                !self.solid_components.get(south_east) and
                !self.falling_components.get(north_east))
            {
                if (self.falling_components.get(origin)) {
                    self.moveEntity(origin, east);
                    self.runPostPhysics(east);
                } else {
                    self.falling_components.set(origin, true);
                }
                return east;
            }

            const west = westOf(origin);
            const south_west = southWestOf(origin);
            const north_west = northWestOf(origin);
            if (!self.solid_components.get(west) and
                !self.solid_components.get(south_west) and
                !self.falling_components.get(north_west))
            {
                if (self.falling_components.get(origin)) {
                    self.moveEntity(origin, west);
                    self.runPostPhysics(west);
                } else {
                    self.falling_components.set(origin, true);
                }
                return west;
            }
        }

        // Case: none of the above:
        // let's stop it if it's falling and hand over control to player if entity is playable
        if (self.falling_components.get(origin)) {
            self.falling_components.set(origin, false);
            if (self.playable_components.get(origin)) {
                self.player_controlled_components.set(origin, true);
                self.physics_components.set(origin, false);
                self.energy_components.set(origin, config.energy_max);
            }
        }

        return origin;
    }

    fn runPostPhysics(self: *PlayState, point: Point(i32)) void {
        if (self.climbable_components.get(point) and self.climber_components.get(point)) {
            self.falling_components.set(point, false);
            if (self.playable_components.get(point)) {
                self.physics_components.set(point, false);
                self.player_controlled_components.set(point, true);
            }
        }
    }

    fn playSound(self: *PlayState, sound: Sound) void {
        self.activated_sounds.putAssumeCapacity(sound, true);
    }

    fn startOrResumeAnimation(self: *PlayState, layer: AnimationLayer, point: Point(i32), animation: Animation(Tile)) void {
        if (self.animation_components.get(point)) |current_animation| {
            if (current_animation.frames.items[0].data == animation.frames.items[0].data) {
                return;
            }
        }
        self.animation_components.set(point, animation);
        self.animation_counter_components.set(point, AnimationCounter{
            .frame_left_s = animation.frames.items[0].duration,
            .frame_index = 0,
        });
        self.animation_layer_components.set(point, layer);
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
                        self.setAnimationFrame(item.point, next_frame);
                    }
                } else {
                    if (animation_counter.frame_counter == 0) {
                        if (self.animation_components.get(item.point)) |animation| {
                            const frame = animation.frames.items[0];
                            self.setAnimationFrame(item.point, frame);
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

    fn setAnimationFrame(self: *PlayState, point: Point(i32), frame: AnimationFrame(Tile)) void {
        if (self.animation_layer_components.get(point)) |layer| {
            const tilemap = switch (layer) {
                .background => self.background_tile_components,
                .foreground => self.foreground_tile_components,
            };
            tilemap.set(point, frame.data);
        }
    }

    fn createEntity(self: *PlayState, entity: Entity, point: Point(i32)) void {
        switch (entity) {
            .none => {},
            .space => {
                self.foreground_tile_components.set(point, Tile.space); // TODO: unnecessary tile
            },
            .wall => {
                self.foreground_tile_components.set(point, Tile.wall);
                self.solid_components.set(point, true);
            },
            .dirt => {
                self.diggable_components.set(point, true);
                self.foreground_tile_components.set(point, Tile.dirt);
                self.solid_components.set(point, true);
            },
            .boulder => {
                self.energy_components.set(point, 0);
                self.foreground_tile_components.set(point, Tile.boulder);
                self.physics_components.set(point, true);
                self.round_components.set(point, true);
                self.solid_components.set(point, true);
            },
            .key => {
                self.energy_components.set(point, 0);
                self.foreground_tile_components.set(point, Tile.key);
                self.key_components.set(point, true);
                self.physics_components.set(point, true);
                self.round_components.set(point, true);
                self.solid_components.set(point, true);
            },
            .door => {
                self.energy_components.set(point, 0);
                self.background_tile_components.set(point, Tile.door_closed);
                self.lock_components.set(point, true);
            },
            .ladder => {
                self.background_tile_components.set(point, Tile.ladder);
                self.climbable_components.set(point, true);
            },
            .back_wall => {
                self.background_tile_components.set(point, Tile.back_wall);
            },
            .player => {
                self.climber_components.set(point, true);
                self.energy_components.set(point, config.energy_max);
                self.facing_components.set(point, Direction.right);
                self.foreground_tile_components.set(point, Tile.player_idle_right_01);
                self.physics_components.set(point, true);
                self.playable_components.set(point, true);
                self.player_controlled_components.set(point, true);
                self.solid_components.set(point, true);
                self.startOrResumeAnimation(.foreground, point, self.player_idle_right_animation);
            },
            .debug => {
                self.background_tile_components.set(point, Tile.debug);
                self.foreground_tile_components.set(point, Tile.debug);
            },
        }
    }

    fn moveEntity(self: *PlayState, start: Point(i32), destination: Point(i32)) void {
        self.animation_components.set(destination, self.animation_components.get(start));
        self.animation_components.set(start, null);
        self.animation_counter_components.set(destination, self.animation_counter_components.get(start));
        self.animation_counter_components.set(start, null);
        self.animation_layer_components.set(destination, self.animation_layer_components.get(start));
        self.animation_layer_components.set(start, null);
        self.climber_components.set(destination, self.climber_components.get(start));
        self.climber_components.set(start, false);
        self.climbing_components.set(destination, self.climbing_components.get(start));
        self.climbing_components.set(start, false);
        self.diggable_components.set(destination, self.diggable_components.get(start));
        self.diggable_components.set(start, false);
        self.digging_components.set(destination, self.digging_components.get(start));
        self.digging_components.set(start, false);
        self.energy_components.set(destination, self.energy_components.get(start));
        self.energy_components.set(start, null);
        self.facing_components.set(destination, self.facing_components.get(start));
        self.facing_components.set(start, null);
        self.falling_components.set(destination, self.falling_components.get(start));
        self.falling_components.set(start, false);
        self.foreground_tile_components.set(destination, self.foreground_tile_components.get(start));
        self.foreground_tile_components.set(start, Tile.space);
        self.key_components.set(destination, self.key_components.get(start));
        self.key_components.set(start, false);
        self.physics_components.set(destination, self.physics_components.get(start));
        self.physics_components.set(start, false);
        self.playable_components.set(destination, self.playable_components.get(start));
        self.playable_components.set(start, false);
        self.player_controlled_components.set(destination, self.player_controlled_components.get(start));
        self.player_controlled_components.set(start, false);
        self.pushing_components.set(destination, self.pushing_components.get(start));
        self.pushing_components.set(start, false);
        self.round_components.set(destination, self.round_components.get(start));
        self.round_components.set(start, false);
        self.running_components.set(destination, self.running_components.get(start));
        self.running_components.set(start, false);
        self.solid_components.set(destination, self.solid_components.get(start));
        self.solid_components.set(start, false);

        self.move_components.set(destination, Move{ .origin = start, .destination = destination });
    }

    fn updateFinishMapState(self: *PlayState, global: *ZigDug) void {
        self.substate = .load_map;
        global.state = .credits;
    }
};

fn initComponentTilemap(allocator: Allocator, comptime T: type, default_value: T) !Tilemap(T) {
    var tilemap = try Tilemap(T).init(
        allocator,
        config.map_width,
        config.map_height,
        1,
        default_value,
    );
    return tilemap;
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

fn isTrue(value: bool) bool {
    return value;
}
