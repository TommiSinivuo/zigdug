const builtin = @import("builtin");

const config = @import("config.zig");
const ray = @import("raylib.zig");
const std = @import("std");
const zigdug = @import("zigdug.zig");

const Allocator = std.mem.Allocator;
const Audio = @import("audio.zig").Audio;
const Renderer = @import("render.zig").Renderer;
const Input = zigdug.Input;
const ZigDug = zigdug.ZigDug;

const debug_mode = (builtin.mode == std.builtin.Mode.Debug);

pub fn main() !void {
    var arena_allocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const allocator = arena_allocator.allocator();

    initWindow();

    const screen_width = config.render_tile_size * zigdug.config.map_width;
    const screen_height = config.render_tile_size * zigdug.config.map_height;
    var renderer = Renderer.init(screen_width, screen_height);
    var audio = try Audio.init(allocator);
    var game = try ZigDug.init(allocator);
    var game_input = Input{};

    ray.SetExitKey(ray.KeyboardKey.KEY_NULL);
    ray.SetTargetFPS(60);

    while (!ray.WindowShouldClose() and game.is_running) {
        const delta_s = ray.GetFrameTime();

        if (ray.IsWindowResized()) {
            renderer.scaleToScreen();
        }

        processInput(&game_input);
        game.update(&game_input, delta_s);
        renderer.draw(&game);
        audio.play(&game);
    }

    renderer.destroy();
    audio.destroy();
    ray.CloseWindow();
}

fn initWindow() void {
    if (debug_mode) {
        const config_flags = @enumToInt(ray.ConfigFlags.FLAG_VSYNC_HINT) |
            @enumToInt(ray.ConfigFlags.FLAG_WINDOW_RESIZABLE);
        ray.SetConfigFlags(config_flags);
        ray.InitWindow(config.default_window_width, config.default_window_height, "Zig Dug (debug)");
        ray.SetWindowSize(config.default_window_width, config.default_window_height);
    } else {
        switch (builtin.os.tag) {
            .macos => {
                const config_flags = @enumToInt(ray.ConfigFlags.FLAG_VSYNC_HINT) |
                    @enumToInt(ray.ConfigFlags.FLAG_WINDOW_RESIZABLE);
                ray.SetConfigFlags(config_flags);
                ray.InitWindow(config.default_window_width, config.default_window_height, "Zig Dug");
                ray.SetWindowSize(config.default_window_width, config.default_window_height);
                ray.MaximizeWindow();
            },
            else => {
                const config_flags = @enumToInt(ray.ConfigFlags.FLAG_VSYNC_HINT) |
                    @enumToInt(ray.ConfigFlags.FLAG_FULLSCREEN_MODE);
                ray.SetConfigFlags(config_flags);
                ray.InitWindow(0, 0, "Zig Dug");
            },
        }
    }
}

fn processInput(game_input: *Input) void {
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
