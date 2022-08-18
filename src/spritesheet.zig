// Created with TexturePacker (http://www.codeandweb.com/texturepacker)
//
// Sprite sheet: spritesheet.png (256 x 496)
//
// $TexturePacker:SmartUpdate:d8da982f1ca8d6c49f0fee5d07eb6b63:3b869b7d23a47824cd27add7158b57da:1b6881295bff6f61dedfffcb681fdac5$

pub const SpriteRect = struct {
    x: i32,
    y: i32,
    width: i32,
    height: i32,
};


pub const back_wall: SpriteRect = SpriteRect{
    .x = 224,
    .y = 256,
    .width = 16,
    .height = 16,
};

pub const black: SpriteRect = SpriteRect{
    .x = 224,
    .y = 272,
    .width = 16,
    .height = 16,
};

pub const boulder: SpriteRect = SpriteRect{
    .x = 224,
    .y = 288,
    .width = 16,
    .height = 16,
};

pub const debug: SpriteRect = SpriteRect{
    .x = 224,
    .y = 304,
    .width = 16,
    .height = 16,
};

pub const dirt: SpriteRect = SpriteRect{
    .x = 224,
    .y = 320,
    .width = 16,
    .height = 16,
};

pub const dirt_edge_east: SpriteRect = SpriteRect{
    .x = 224,
    .y = 336,
    .width = 16,
    .height = 16,
};

pub const dirt_edge_horizontal: SpriteRect = SpriteRect{
    .x = 224,
    .y = 352,
    .width = 16,
    .height = 16,
};

pub const dirt_edge_north: SpriteRect = SpriteRect{
    .x = 224,
    .y = 368,
    .width = 16,
    .height = 16,
};

pub const dirt_edge_north_east: SpriteRect = SpriteRect{
    .x = 224,
    .y = 384,
    .width = 16,
    .height = 16,
};

pub const dirt_edge_north_west: SpriteRect = SpriteRect{
    .x = 224,
    .y = 400,
    .width = 16,
    .height = 16,
};

pub const dirt_edge_south: SpriteRect = SpriteRect{
    .x = 224,
    .y = 416,
    .width = 16,
    .height = 16,
};

pub const dirt_edge_south_east: SpriteRect = SpriteRect{
    .x = 224,
    .y = 432,
    .width = 16,
    .height = 16,
};

pub const dirt_edge_south_west: SpriteRect = SpriteRect{
    .x = 224,
    .y = 448,
    .width = 16,
    .height = 16,
};

pub const dirt_edge_vertical: SpriteRect = SpriteRect{
    .x = 224,
    .y = 464,
    .width = 16,
    .height = 16,
};

pub const dirt_edge_west: SpriteRect = SpriteRect{
    .x = 240,
    .y = 256,
    .width = 16,
    .height = 16,
};

pub const dirt_lonely: SpriteRect = SpriteRect{
    .x = 240,
    .y = 272,
    .width = 16,
    .height = 16,
};

pub const dirt_spike_east: SpriteRect = SpriteRect{
    .x = 240,
    .y = 288,
    .width = 16,
    .height = 16,
};

pub const dirt_spike_north: SpriteRect = SpriteRect{
    .x = 240,
    .y = 304,
    .width = 16,
    .height = 16,
};

pub const dirt_spike_south: SpriteRect = SpriteRect{
    .x = 240,
    .y = 320,
    .width = 16,
    .height = 16,
};

pub const dirt_spike_west: SpriteRect = SpriteRect{
    .x = 240,
    .y = 336,
    .width = 16,
    .height = 16,
};

pub const door_closed: SpriteRect = SpriteRect{
    .x = 240,
    .y = 352,
    .width = 16,
    .height = 16,
};

pub const door_open: SpriteRect = SpriteRect{
    .x = 240,
    .y = 368,
    .width = 16,
    .height = 16,
};

pub const door_open_01: SpriteRect = SpriteRect{
    .x = 240,
    .y = 384,
    .width = 16,
    .height = 16,
};

pub const door_open_02: SpriteRect = SpriteRect{
    .x = 240,
    .y = 400,
    .width = 16,
    .height = 16,
};

pub const door_open_03: SpriteRect = SpriteRect{
    .x = 240,
    .y = 416,
    .width = 16,
    .height = 16,
};

pub const door_open_04: SpriteRect = SpriteRect{
    .x = 240,
    .y = 432,
    .width = 16,
    .height = 16,
};

pub const gem: SpriteRect = SpriteRect{
    .x = 240,
    .y = 448,
    .width = 16,
    .height = 16,
};

pub const key: SpriteRect = SpriteRect{
    .x = 240,
    .y = 464,
    .width = 16,
    .height = 16,
};

pub const ladder: SpriteRect = SpriteRect{
    .x = 0,
    .y = 480,
    .width = 16,
    .height = 16,
};

pub const player: SpriteRect = SpriteRect{
    .x = 16,
    .y = 480,
    .width = 16,
    .height = 16,
};

pub const player_digging_right_01: SpriteRect = SpriteRect{
    .x = 32,
    .y = 480,
    .width = 16,
    .height = 16,
};

pub const player_digging_right_02: SpriteRect = SpriteRect{
    .x = 48,
    .y = 480,
    .width = 16,
    .height = 16,
};

pub const player_idle_right: SpriteRect = SpriteRect{
    .x = 64,
    .y = 480,
    .width = 16,
    .height = 16,
};

pub const player_idle_right_01: SpriteRect = SpriteRect{
    .x = 80,
    .y = 480,
    .width = 16,
    .height = 16,
};

pub const player_idle_right_02: SpriteRect = SpriteRect{
    .x = 96,
    .y = 480,
    .width = 16,
    .height = 16,
};

pub const player_running_right_01: SpriteRect = SpriteRect{
    .x = 112,
    .y = 480,
    .width = 16,
    .height = 16,
};

pub const player_running_right_02: SpriteRect = SpriteRect{
    .x = 128,
    .y = 480,
    .width = 16,
    .height = 16,
};

pub const the_end: SpriteRect = SpriteRect{
    .x = 0,
    .y = 256,
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
    .x = 144,
    .y = 480,
    .width = 16,
    .height = 16,
};

pub const zigdug_logo: SpriteRect = SpriteRect{
    .x = 0,
    .y = 368,
    .width = 224,
    .height = 112,
};

