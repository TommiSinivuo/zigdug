pub fn cantor(x: u32, y: u32) u32 {
    return (((x + y + 1) * (x + y)) / 2) + y;
}
