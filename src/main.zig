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

    const config_flags = @enumToInt(ray.ConfigFlags.FLAG_VSYNC_HINT); // |
    //    @enumToInt(ray.ConfigFlags.FLAG_FULLSCREEN_MODE);
    ray.SetConfigFlags(config_flags);
    ray.InitWindow(p_window_width, p_window_height, "Zig Dug");
    ray.HideCursor();

    var renderer = Renderer.init(p_screen_width, p_screen_height);
    var audio = try Audio.init(allocator);

    var game_data = try game.init(allocator);
    var game_input = game.GameInput{};

    ray.SetExitKey(ray.KeyboardKey.KEY_NULL);
    ray.SetTargetFPS(30);

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
    // Keyboard
    const kb_game_pause = ray.IsKeyPressed(ray.KeyboardKey.KEY_ESCAPE);
    const kb_player_up = ray.IsKeyDown(ray.KeyboardKey.KEY_UP);
    const kb_player_right = ray.IsKeyDown(ray.KeyboardKey.KEY_RIGHT);
    const kb_player_down = ray.IsKeyDown(ray.KeyboardKey.KEY_DOWN);
    const kb_player_left = ray.IsKeyDown(ray.KeyboardKey.KEY_LEFT);
    const kb_ui_confirm = ray.IsKeyPressed(ray.KeyboardKey.KEY_ENTER);
    const kb_ui_cancel = ray.IsKeyPressed(ray.KeyboardKey.KEY_ESCAPE);
    const kb_ui_up = ray.IsKeyPressed(ray.KeyboardKey.KEY_UP);
    const kb_ui_right = ray.IsKeyPressed(ray.KeyboardKey.KEY_RIGHT);
    const kb_ui_down = ray.IsKeyPressed(ray.KeyboardKey.KEY_DOWN);
    const kb_ui_left = ray.IsKeyPressed(ray.KeyboardKey.KEY_LEFT);

    // Gamepad
    var gp_game_pause = false;
    var gp_player_up = false;
    var gp_player_right = false;
    var gp_player_down = false;
    var gp_player_left = false;
    var gp_ui_confirm = false;
    var gp_ui_cancel = false;
    var gp_ui_up = false;
    var gp_ui_right = false;
    var gp_ui_down = false;
    var gp_ui_left = false;

    if (ray.IsGamepadAvailable(0)) {
        gp_game_pause = ray.IsGamepadButtonPressed(0, ray.GamepadButton.GAMEPAD_BUTTON_MIDDLE_RIGHT);
        gp_player_up = ray.IsGamepadButtonDown(0, ray.GamepadButton.GAMEPAD_BUTTON_LEFT_FACE_UP);
        gp_player_right = ray.IsGamepadButtonDown(0, ray.GamepadButton.GAMEPAD_BUTTON_LEFT_FACE_RIGHT);
        gp_player_down = ray.IsGamepadButtonDown(0, ray.GamepadButton.GAMEPAD_BUTTON_LEFT_FACE_DOWN);
        gp_player_left = ray.IsGamepadButtonDown(0, ray.GamepadButton.GAMEPAD_BUTTON_LEFT_FACE_LEFT);
        gp_ui_confirm = ray.IsGamepadButtonPressed(0, ray.GamepadButton.GAMEPAD_BUTTON_RIGHT_FACE_RIGHT);
        gp_ui_cancel = ray.IsGamepadButtonPressed(0, ray.GamepadButton.GAMEPAD_BUTTON_RIGHT_FACE_DOWN);
        gp_ui_up = ray.IsGamepadButtonPressed(0, ray.GamepadButton.GAMEPAD_BUTTON_LEFT_FACE_UP);
        gp_ui_right = ray.IsGamepadButtonPressed(0, ray.GamepadButton.GAMEPAD_BUTTON_LEFT_FACE_RIGHT);
        gp_ui_down = ray.IsGamepadButtonPressed(0, ray.GamepadButton.GAMEPAD_BUTTON_LEFT_FACE_DOWN);
        gp_ui_left = ray.IsGamepadButtonPressed(0, ray.GamepadButton.GAMEPAD_BUTTON_LEFT_FACE_LEFT);
    }

    // Aggregate into game input
    game_input.game_pause = kb_game_pause or gp_game_pause;
    game_input.player_up = kb_player_up or gp_player_up;
    game_input.player_right = kb_player_right or gp_player_right;
    game_input.player_down = kb_player_down or gp_player_down;
    game_input.player_left = kb_player_left or gp_player_left;
    game_input.ui_confirm = kb_ui_confirm or gp_ui_confirm;
    game_input.ui_cancel = kb_ui_cancel or gp_ui_cancel;
    game_input.ui_up = kb_ui_up or gp_ui_up;
    game_input.ui_right = kb_ui_right or gp_ui_right;
    game_input.ui_down = kb_ui_down or gp_ui_down;
    game_input.ui_left = kb_ui_left or gp_ui_left;
}
