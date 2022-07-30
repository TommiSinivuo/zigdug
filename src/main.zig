const ray = @import("raylib.zig");

pub fn main() void {
    const window_width = 1920;
    const window_height = 1080;
    const screen_width = 800;
    const screen_height = 450;

    ray.InitWindow(window_width, window_height, "raylib [core] example - keyboard input");

    var game_viewport = ray.CreateViewport(screen_width, screen_height);
    ray.ScaleViewportToScreen(&game_viewport);

    var ball_position = ray.Vector2{
        .x = @intToFloat(f32, screen_width) / 2,
        .y = @intToFloat(f32, screen_height) / 2,
    };

    ray.SetTargetFPS(60);

    while (!ray.WindowShouldClose()) {
        if (ray.IsKeyDown(ray.KeyboardKey.KEY_RIGHT)) {
            ball_position.x += 2.0;
        }
        if (ray.IsKeyDown(ray.KeyboardKey.KEY_LEFT)) {
            ball_position.x -= 2.0;
        }
        if (ray.IsKeyDown(ray.KeyboardKey.KEY_UP)) {
            ball_position.y -= 2.0;
        }
        if (ray.IsKeyDown(ray.KeyboardKey.KEY_DOWN)) {
            ball_position.y += 2.0;
        }

        ray.BeginDrawing();
        ray.ClearBackground(ray.BLACK);

        ray.BeginViewportMode(&game_viewport);
        ray.ClearBackground(ray.RAYWHITE);
        ray.DrawText("move the ball with arrow keys", 10, 10, 20, ray.DARKGRAY);
        ray.DrawCircleV(ball_position, 50, ray.MAROON);
        ray.EndViewportMode();

        ray.DrawViewport(&game_viewport);
        ray.EndDrawing();
    }

    ray.UnloadViewport(&game_viewport);
    ray.CloseWindow();
}
