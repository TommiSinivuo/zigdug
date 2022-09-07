pub fn cantor(x: u32, y: u32) u32 {
    return (((x + y + 1) * (x + y)) / 2) + y;
}

pub fn lerp(v0: f32, v1: f32, t: f32) f32 {
    return v0 + (t * (v1 - v0));
}
