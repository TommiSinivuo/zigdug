const ray = @import("raylib.zig");
const game = @import("game.zig");

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

    ray.SetTargetFPS(60);

    var game_data = game.init();
    var game_input = game.GameInput{};

    while (!ray.WindowShouldClose()) {
        const delta_s = ray.GetFrameTime();
        processInput(&game_input);
        game.update(&game_data, &game_input, delta_s);
        render(&game_data, &game_viewport);
    }

    ray.UnloadViewport(&game_viewport);
    ray.CloseWindow();
}

fn processInput(game_input: *GameInput) void {
    game_input.right = ray.IsKeyDown(ray.KeyboardKey.KEY_RIGHT);
    game_input.left = ray.IsKeyDown(ray.KeyboardKey.KEY_LEFT);
    game_input.up = ray.IsKeyDown(ray.KeyboardKey.KEY_UP);
    game_input.down = ray.IsKeyDown(ray.KeyboardKey.KEY_DOWN);
}

fn render(data: *GameData, viewport: *ray.Viewport) void {
    ray.BeginDrawing();
    ray.ClearBackground(ray.BLACK);

    ray.BeginViewportMode(viewport);
    ray.ClearBackground(ray.RAYWHITE);
    ray.DrawText("move the ball with arrow keys", 10, 10, 20, ray.DARKGRAY);
    ray.DrawCircleV(data.ball_position, 50, ray.MAROON);
    ray.EndViewportMode();

    ray.DrawViewport(viewport);
    ray.EndDrawing();
}
