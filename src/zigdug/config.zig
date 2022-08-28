pub const map_width = 16;
pub const map_height = 16;

pub var maps = [_][]const u8{
    "data/maps/01.png",
    "data/maps/02.png",
    "data/maps/03.png",
    "data/maps/04.png",
    "data/maps/concentrate.png",
    "data/maps/gate.png",
    "data/maps/biggate.png",
};

// How often will entities update (less is faster)
pub const energy_max: f32 = 1.0 / 6.0; // 6 FPS
pub const map_energy_max: f32 = 1.0 / 6.0; // 6 FPS
