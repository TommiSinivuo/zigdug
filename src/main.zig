const std = @import("std");
const Allocator = std.mem.Allocator;

const ray = @import("raylib.zig");
const game = @import("game.zig");
const Audio = @import("audio.zig").Audio;
const Renderer = @import("render.zig").Renderer;
const GameData = game.GameData;
const GameInput = game.GameInput;

const p_window_width = 1920;
const p_window_height = 1920;
const p_screen_width = 256;
const p_screen_height = 256;

pub fn main() !void {
    var arena_allocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const allocator = arena_allocator.allocator();

    ray.InitWindow(p_window_width, p_window_height, "Zig Dug");
    var renderer = Renderer.init(p_screen_width, p_screen_height);
    var audio = try Audio.init(allocator);

    var game_data = try game.init(allocator);
    var game_input = game.GameInput{};

    ray.SetExitKey(ray.KeyboardKey.KEY_NULL);
    ray.SetTargetFPS(60);

    while (!ray.WindowShouldClose() and game_data.is_running) {
        const delta_s = ray.GetFrameTime();
        processInput(&game_input);
        game.update(&game_data, &game_input, delta_s);
        renderer.draw(&game_data);
        audio.play(&game_data);
    }

    renderer.destroy();
    audio.destroy();
    ray.CloseWindow();
}

fn processInput(game_input: *GameInput) void {
    game_input.pressed.right = ray.IsKeyDown(ray.KeyboardKey.KEY_RIGHT);
    game_input.pressed.left = ray.IsKeyDown(ray.KeyboardKey.KEY_LEFT);
    game_input.pressed.up = ray.IsKeyDown(ray.KeyboardKey.KEY_UP);
    game_input.pressed.down = ray.IsKeyDown(ray.KeyboardKey.KEY_DOWN);

    game_input.just_pressed.action = ray.IsKeyPressed(ray.KeyboardKey.KEY_ENTER);
    game_input.just_pressed.cancel = ray.IsKeyPressed(ray.KeyboardKey.KEY_ESCAPE);
    game_input.just_pressed.up = ray.IsKeyPressed(ray.KeyboardKey.KEY_UP);
    game_input.just_pressed.down = ray.IsKeyPressed(ray.KeyboardKey.KEY_DOWN);
}
