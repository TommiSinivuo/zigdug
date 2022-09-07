// Created with TexturePacker (http://www.codeandweb.com/texturepacker)
//
// Sprite sheet: spritesheet.png (512 x 256)
//
// $TexturePacker:SmartUpdate:fe227d919c67f8af91e1ad73370025e0:76d162d90eeb0b1b9fb362ed654c7fbc:1b6881295bff6f61dedfffcb681fdac5$

pub const SpriteRect = struct {
    x: i32,
    y: i32,
    width: i32,
    height: i32,
};


pub const back_wall: SpriteRect = SpriteRect{
    .x = 480,
    .y = 0,
    .width = 16,
    .height = 16,
};

pub const black: SpriteRect = SpriteRect{
    .x = 496,
    .y = 0,
    .width = 16,
    .height = 16,
};

pub const boulder: SpriteRect = SpriteRect{
    .x = 480,
    .y = 16,
    .width = 16,
    .height = 16,
};

pub const debug: SpriteRect = SpriteRect{
    .x = 496,
    .y = 16,
    .width = 16,
    .height = 16,
};

pub const dirt: SpriteRect = SpriteRect{
    .x = 480,
    .y = 32,
    .width = 16,
    .height = 16,
};

pub const dirt_edge_east: SpriteRect = SpriteRect{
    .x = 496,
    .y = 32,
    .width = 16,
    .height = 16,
};

pub const dirt_edge_horizontal: SpriteRect = SpriteRect{
    .x = 480,
    .y = 48,
    .width = 16,
    .height = 16,
};

pub const dirt_edge_north: SpriteRect = SpriteRect{
    .x = 496,
    .y = 48,
    .width = 16,
    .height = 16,
};

pub const dirt_edge_north_east: SpriteRect = SpriteRect{
    .x = 480,
    .y = 64,
    .width = 16,
    .height = 16,
};

pub const dirt_edge_north_west: SpriteRect = SpriteRect{
    .x = 496,
    .y = 64,
    .width = 16,
    .height = 16,
};

pub const dirt_edge_south: SpriteRect = SpriteRect{
    .x = 480,
    .y = 80,
    .width = 16,
    .height = 16,
};

pub const dirt_edge_south_east: SpriteRect = SpriteRect{
    .x = 496,
    .y = 80,
    .width = 16,
    .height = 16,
};

pub const dirt_edge_south_west: SpriteRect = SpriteRect{
    .x = 480,
    .y = 96,
    .width = 16,
    .height = 16,
};

pub const dirt_edge_vertical: SpriteRect = SpriteRect{
    .x = 496,
    .y = 96,
    .width = 16,
    .height = 16,
};

pub const dirt_edge_west: SpriteRect = SpriteRect{
    .x = 480,
    .y = 112,
    .width = 16,
    .height = 16,
};

pub const dirt_lonely: SpriteRect = SpriteRect{
    .x = 496,
    .y = 112,
    .width = 16,
    .height = 16,
};

pub const dirt_spike_east: SpriteRect = SpriteRect{
    .x = 480,
    .y = 128,
    .width = 16,
    .height = 16,
};

pub const dirt_spike_north: SpriteRect = SpriteRect{
    .x = 496,
    .y = 128,
    .width = 16,
    .height = 16,
};

pub const dirt_spike_south: SpriteRect = SpriteRect{
    .x = 480,
    .y = 144,
    .width = 16,
    .height = 16,
};

pub const dirt_spike_west: SpriteRect = SpriteRect{
    .x = 496,
    .y = 144,
    .width = 16,
    .height = 16,
};

pub const door_closed: SpriteRect = SpriteRect{
    .x = 480,
    .y = 160,
    .width = 16,
    .height = 16,
};

pub const door_open: SpriteRect = SpriteRect{
    .x = 496,
    .y = 160,
    .width = 16,
    .height = 16,
};

pub const door_open_01: SpriteRect = SpriteRect{
    .x = 480,
    .y = 176,
    .width = 16,
    .height = 16,
};

pub const door_open_02: SpriteRect = SpriteRect{
    .x = 496,
    .y = 176,
    .width = 16,
    .height = 16,
};

pub const door_open_03: SpriteRect = SpriteRect{
    .x = 480,
    .y = 192,
    .width = 16,
    .height = 16,
};

pub const door_open_04: SpriteRect = SpriteRect{
    .x = 496,
    .y = 192,
    .width = 16,
    .height = 16,
};

pub const gem: SpriteRect = SpriteRect{
    .x = 480,
    .y = 208,
    .width = 16,
    .height = 16,
};

pub const key: SpriteRect = SpriteRect{
    .x = 496,
    .y = 208,
    .width = 16,
    .height = 16,
};

pub const ladder: SpriteRect = SpriteRect{
    .x = 256,
    .y = 224,
    .width = 16,
    .height = 16,
};

pub const player: SpriteRect = SpriteRect{
    .x = 256,
    .y = 240,
    .width = 16,
    .height = 16,
};

pub const player_digging_left_01: SpriteRect = SpriteRect{
    .x = 272,
    .y = 224,
    .width = 16,
    .height = 16,
};

pub const player_digging_left_02: SpriteRect = SpriteRect{
    .x = 272,
    .y = 240,
    .width = 16,
    .height = 16,
};

pub const player_digging_right_01: SpriteRect = SpriteRect{
    .x = 288,
    .y = 224,
    .width = 16,
    .height = 16,
};

pub const player_digging_right_02: SpriteRect = SpriteRect{
    .x = 288,
    .y = 240,
    .width = 16,
    .height = 16,
};

pub const player_falling_left_01: SpriteRect = SpriteRect{
    .x = 304,
    .y = 224,
    .width = 16,
    .height = 16,
};

pub const player_falling_left_02: SpriteRect = SpriteRect{
    .x = 304,
    .y = 240,
    .width = 16,
    .height = 16,
};

pub const player_falling_right_01: SpriteRect = SpriteRect{
    .x = 320,
    .y = 224,
    .width = 16,
    .height = 16,
};

pub const player_falling_right_02: SpriteRect = SpriteRect{
    .x = 320,
    .y = 240,
    .width = 16,
    .height = 16,
};

pub const player_idle_left_01: SpriteRect = SpriteRect{
    .x = 336,
    .y = 224,
    .width = 16,
    .height = 16,
};

pub const player_idle_left_02: SpriteRect = SpriteRect{
    .x = 336,
    .y = 240,
    .width = 16,
    .height = 16,
};

pub const player_idle_left_03: SpriteRect = SpriteRect{
    .x = 352,
    .y = 224,
    .width = 16,
    .height = 16,
};

pub const player_idle_left_04: SpriteRect = SpriteRect{
    .x = 352,
    .y = 240,
    .width = 16,
    .height = 16,
};

pub const player_idle_right: SpriteRect = SpriteRect{
    .x = 368,
    .y = 224,
    .width = 16,
    .height = 16,
};

pub const player_idle_right_01: SpriteRect = SpriteRect{
    .x = 368,
    .y = 240,
    .width = 16,
    .height = 16,
};

pub const player_idle_right_02: SpriteRect = SpriteRect{
    .x = 384,
    .y = 224,
    .width = 16,
    .height = 16,
};

pub const player_idle_right_03: SpriteRect = SpriteRect{
    .x = 384,
    .y = 240,
    .width = 16,
    .height = 16,
};

pub const player_idle_right_04: SpriteRect = SpriteRect{
    .x = 400,
    .y = 224,
    .width = 16,
    .height = 16,
};

pub const player_running_left_01: SpriteRect = SpriteRect{
    .x = 400,
    .y = 240,
    .width = 16,
    .height = 16,
};

pub const player_running_left_02: SpriteRect = SpriteRect{
    .x = 416,
    .y = 224,
    .width = 16,
    .height = 16,
};

pub const player_running_right_01: SpriteRect = SpriteRect{
    .x = 416,
    .y = 240,
    .width = 16,
    .height = 16,
};

pub const player_running_right_02: SpriteRect = SpriteRect{
    .x = 432,
    .y = 224,
    .width = 16,
    .height = 16,
};

pub const the_end: SpriteRect = SpriteRect{
    .x = 256,
    .y = 0,
    .width = 224,
    .height = 112,
};

pub const ui_background: SpriteRect = SpriteRect{
    .x = 0,
    .y = 0,
    .width = 256,
    .height = 256,
};

pub const wall: SpriteRect = SpriteRect{
    .x = 432,
    .y = 240,
    .width = 16,
    .height = 16,
};

pub const zigdug_logo: SpriteRect = SpriteRect{
    .x = 256,
    .y = 112,
    .width = 224,
    .height = 112,
};

