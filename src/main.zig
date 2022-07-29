const c = @cImport(@cInclude("raylib.h"));

pub fn main() void {
    const screen_width = 800;
    const screen_height = 450;

    c.InitWindow(screen_width, screen_height, "raylib [core] example - keyboard input");

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
        c.ClearBackground(c.RAYWHITE);
        c.DrawText("move the ball with arrow keys", 10, 10, 20, c.DARKGRAY);
        c.DrawCircleV(ball_position, 50, c.MAROON);
        c.EndDrawing();
    }

    c.CloseWindow();
}
