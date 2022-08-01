const ray = @import("raylib.zig");
const game = @import("game.zig");
const render = @import("render.zig");

const GameData = game.GameData;
const GameInput = game.GameInput;

pub fn main() void {
    const window_width = 1920;
    const window_height = 1920;
    const screen_width = 256;
    const screen_height = 256;

    ray.InitWindow(window_width, window_height, "Zig Dug");

    var game_viewport = ray.CreateViewport(screen_width, screen_height);
    ray.ScaleViewportToScreen(&game_viewport);

    const spritesheet_texture = ray.LoadTexture("data/spritesheet.png");

    var game_data = game.init();
    var game_input = game.GameInput{};

    ray.SetTargetFPS(60);

    while (!ray.WindowShouldClose() and game_data.is_running) {
        const delta_s = ray.GetFrameTime();
        processInput(&game_input);
        game.update(&game_data, &game_input, delta_s);
        render.draw(&game_data, &game_viewport, spritesheet_texture);
    }

    ray.UnloadTexture(spritesheet_texture);
    ray.UnloadViewport(&game_viewport);
    ray.CloseWindow();
}

fn processInput(game_input: *GameInput) void {
    game_input.action = ray.IsKeyPressed(ray.KeyboardKey.KEY_ENTER);
    game_input.right = ray.IsKeyDown(ray.KeyboardKey.KEY_RIGHT);
    game_input.left = ray.IsKeyDown(ray.KeyboardKey.KEY_LEFT);
    game_input.up = ray.IsKeyDown(ray.KeyboardKey.KEY_UP);
    game_input.down = ray.IsKeyDown(ray.KeyboardKey.KEY_DOWN);
}
