const c = @cImport({
    @cInclude("raylib.h");
    @cInclude("raylib_viewport.h");
});

pub fn main() void {
    const window_width = 1920;
    const window_height = 1080;
    const screen_width = 800;
    const screen_height = 450;

    c.InitWindow(window_width, window_height, "raylib [core] example - keyboard input");

    var game_viewport = c.CreateViewport(screen_width, screen_height);
    c.ScaleViewportToScreen(&game_viewport);

    var ball_position = c.Vector2{
        .x = @intToFloat(f32, screen_width) / 2,
        .y = @intToFloat(f32, screen_height) / 2,
    };

    c.SetTargetFPS(60);

    while (!c.WindowShouldClose()) {
        if (c.IsKeyDown(c.KEY_RIGHT)) {
            ball_position.x += 2.0;
        }
        if (c.IsKeyDown(c.KEY_LEFT)) {
            ball_position.x -= 2.0;
        }
        if (c.IsKeyDown(c.KEY_UP)) {
            ball_position.y -= 2.0;
        }
        if (c.IsKeyDown(c.KEY_DOWN)) {
            ball_position.y += 2.0;
        }

        c.BeginDrawing();
        c.ClearBackground(c.BLACK);

        c.BeginViewportMode(&game_viewport);
        c.ClearBackground(c.RAYWHITE);
        c.DrawText("move the ball with arrow keys", 10, 10, 20, c.DARKGRAY);
        c.DrawCircleV(ball_position, 50, c.MAROON);
        c.EndViewportMode();

        c.DrawViewport(&game_viewport);
        c.EndDrawing();
    }

    c.UnloadViewport(&game_viewport);
    c.CloseWindow();
}
