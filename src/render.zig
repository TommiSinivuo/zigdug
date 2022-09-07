const config = @import("config.zig");
const ray = @import("raylib.zig");
const spritesheet = @import("spritesheet.zig");
const zigdug = @import("zigdug.zig");
const math = zigdug.math;

const Move = zigdug.Move;
const PauseState = zigdug.PauseState;
const PlayState = zigdug.PlayState;
const Point = zigdug.Point;
const Tile = zigdug.Tile;
const Tilemap = zigdug.Tilemap;
const TitleState = zigdug.TitleState;
const ZigDug = zigdug.ZigDug;

pub const Renderer = struct {
    viewport: ray.Viewport,
    spritesheet_texture: ray.Texture2D,

    pub fn init(
        game_screen_width: i32,
        game_screen_height: i32,
    ) Renderer {
        var viewport = ray.CreateViewport(game_screen_width, game_screen_height);
        ray.ScaleViewportToScreen(&viewport);

        const spritesheet_texture = ray.LoadTexture("data/spritesheet.png");

        return Renderer{
            .viewport = viewport,
            .spritesheet_texture = spritesheet_texture,
        };
    }

    pub fn destroy(self: *Renderer) void {
        ray.UnloadTexture(self.spritesheet_texture);
        ray.UnloadViewport(&self.viewport);
    }

    pub fn draw(self: *Renderer, global: *ZigDug) void {
        ray.BeginDrawing();
        ray.ClearBackground(ray.BLACK);
        ray.BeginViewportMode(&self.viewport);

        switch (global.state) {
            .title => self.drawTitleState(&global.title_state),
            .play => self.drawPlayState(&global.play_state),
            .pause => self.drawPauseState(&global.pause_state),
            .credits => self.drawCreditsState(),
        }

        ray.EndViewportMode();
        ray.DrawViewport(&self.viewport);
        ray.EndDrawing();
    }

    //------------------------------------------------------------------------------------
    // Title screen
    //------------------------------------------------------------------------------------

    fn drawTitleState(self: *Renderer, title_state: *TitleState) void {

        // background
        ray.WDrawTextureRec(
            self.spritesheet_texture,
            &spriteRectToRectangle(spritesheet.ui_background),
            &ray.Vector2{ .x = 0, .y = 0 },
            &ray.WHITE,
        );

        // title/logo
        ray.WDrawTextureRec(
            self.spritesheet_texture,
            &spriteRectToRectangle(spritesheet.zigdug_logo),
            &ray.Vector2{ .x = 16, .y = 16 },
            &ray.WHITE,
        );

        // menu options
        ray.DrawText("PLAY", 120, 160, 16, ray.RAYWHITE);
        ray.DrawText("QUIT", 120, 192, 16, ray.RAYWHITE);

        // menu selection
        const gem_y: f32 = if (title_state.selection == .quit) 192 else 160;
        ray.WDrawTextureRec(
            self.spritesheet_texture,
            &spriteRectToRectangle(spritesheet.gem),
            &ray.Vector2{ .x = 88, .y = gem_y },
            &ray.WHITE,
        );
    }

    //------------------------------------------------------------------------------------
    // Gameplay
    //------------------------------------------------------------------------------------

    fn drawPlayState(self: *Renderer, play_state: *PlayState) void {
        ray.ClearBackground(ray.BLACK);

        self.drawBackground(play_state);
        self.drawForeground(play_state);
    }

    fn drawBackground(self: *Renderer, play_state: *PlayState) void {
        var tilemap_iterator = play_state.background_tile_components.iteratorForward();

        while (tilemap_iterator.next()) |item| {
            const screen_point = tileToScreenPoint(item.point);
            self.drawTileOnScreen(item.value, screen_point);
        }
    }

    fn drawForeground(self: *Renderer, play_state: *PlayState) void {
        var tilemap_iterator = play_state.foreground_tile_components.iteratorForward();

        while (tilemap_iterator.next()) |item| {
            var screen_point: ray.Vector2 = undefined;
            if (play_state.move_components.get(item.point)) |move| {
                screen_point = movingTileToScreenPoint(move);
            } else {
                screen_point = tileToScreenPoint(item.point);
            }
            self.drawTileOnScreen(item.value, screen_point);
        }
    }

    fn drawTileOnScreen(self: *Renderer, tile: Tile, screen_point: ray.Vector2) void {
        const optional_sprite_rect: ?spritesheet.SpriteRect = switch (tile) {
            .none => spritesheet.black,
            .back_wall => spritesheet.back_wall,
            .boulder => spritesheet.boulder,
            .dirt => spritesheet.dirt,
            .door_closed => spritesheet.door_closed,
            .door_open_01 => spritesheet.door_open_01,
            .door_open_02 => spritesheet.door_open_02,
            .door_open_03 => spritesheet.door_open_03,
            .door_open_04 => spritesheet.door_open_04,
            .key => spritesheet.key,
            .ladder => spritesheet.ladder,
            .player_digging_left_01 => spritesheet.player_digging_left_01,
            .player_digging_left_02 => spritesheet.player_digging_left_02,
            .player_digging_right_01 => spritesheet.player_digging_right_01,
            .player_digging_right_02 => spritesheet.player_digging_right_02,
            .player_falling_left_01 => spritesheet.player_falling_left_01,
            .player_falling_left_02 => spritesheet.player_falling_left_02,
            .player_falling_right_01 => spritesheet.player_falling_right_01,
            .player_falling_right_02 => spritesheet.player_falling_right_02,
            .player_idle_left_01 => spritesheet.player_idle_left_01,
            .player_idle_left_02 => spritesheet.player_idle_left_02,
            .player_idle_left_03 => spritesheet.player_idle_left_03,
            .player_idle_left_04 => spritesheet.player_idle_left_04,
            .player_idle_right_01 => spritesheet.player_idle_right_01,
            .player_idle_right_02 => spritesheet.player_idle_right_02,
            .player_idle_right_03 => spritesheet.player_idle_right_03,
            .player_idle_right_04 => spritesheet.player_idle_right_04,
            .player_running_left_01 => spritesheet.player_running_left_01,
            .player_running_left_02 => spritesheet.player_running_left_02,
            .player_running_right_01 => spritesheet.player_running_right_01,
            .player_running_right_02 => spritesheet.player_running_right_02,
            .space => null,
            .wall => spritesheet.wall,
            .debug => spritesheet.debug,
        };

        if (optional_sprite_rect) |sprite_rect| {
            ray.WDrawTextureRec(
                self.spritesheet_texture,
                &spriteRectToRectangle(sprite_rect),
                &screen_point,
                &ray.WHITE,
            );
        }
    }

    //------------------------------------------------------------------------------------
    // Pause menu
    //------------------------------------------------------------------------------------

    fn drawPauseState(self: *Renderer, pause_state: *PauseState) void {

        // background
        ray.WDrawTextureRec(
            self.spritesheet_texture,
            &spriteRectToRectangle(spritesheet.ui_background),
            &ray.Vector2{ .x = 0, .y = 0 },
            &ray.WHITE,
        );

        // menu options
        ray.DrawText("RESUME LEVEL", 72, 72, 16, ray.RAYWHITE);
        ray.DrawText("RESTART LEVEL", 72, 104, 16, ray.RAYWHITE);
        ray.DrawText("TO TITLE SCREEN", 72, 136, 16, ray.RAYWHITE);
        ray.DrawText("QUIT GAME", 72, 168, 16, ray.RAYWHITE);

        // menu selection
        const gem_y: f32 = switch (pause_state.selection) {
            .resume_level => 72,
            .restart_level => 104,
            .return_to_title => 136,
            .quit_game => 168,
        };
        ray.WDrawTextureRec(
            self.spritesheet_texture,
            &spriteRectToRectangle(spritesheet.gem),
            &ray.Vector2{ .x = 40, .y = gem_y },
            &ray.WHITE,
        );
    }

    //------------------------------------------------------------------------------------
    // Credits
    //------------------------------------------------------------------------------------

    fn drawCreditsState(self: *Renderer) void {

        // background
        ray.WDrawTextureRec(
            self.spritesheet_texture,
            &spriteRectToRectangle(spritesheet.ui_background),
            &ray.Vector2{ .x = 0, .y = 0 },
            &ray.WHITE,
        );

        // the end
        ray.WDrawTextureRec(
            self.spritesheet_texture,
            &spriteRectToRectangle(spritesheet.the_end),
            &ray.Vector2{ .x = 16, .y = 48 },
            &ray.WHITE,
        );

        // credits
        ray.DrawText("A GAME BY TOMMI SINIVUO", 56, 204, 10, ray.RAYWHITE);
    }
};

//------------------------------------------------------------------------------------
// Common utils
//------------------------------------------------------------------------------------

fn tileToScreenPoint(tile_point: Point(i32)) ray.Vector2 {
    return ray.Vector2{
        .x = @intToFloat(f32, tile_point.x) * config.render_tile_size,
        .y = @intToFloat(f32, tile_point.y) * config.render_tile_size,
    };
}

fn movingTileToScreenPoint(move: Move) ray.Vector2 {
    const origin = ray.Vector2{
        .x = @intToFloat(f32, move.origin.x) * config.render_tile_size,
        .y = @intToFloat(f32, move.origin.y) * config.render_tile_size,
    };
    const destination = ray.Vector2{
        .x = @intToFloat(f32, move.destination.x) * config.render_tile_size,
        .y = @intToFloat(f32, move.destination.y) * config.render_tile_size,
    };
    return ray.Vector2{
        .x = math.lerp(origin.x, destination.x, move.lerp_amount),
        .y = math.lerp(origin.y, destination.y, move.lerp_amount),
    };
}

fn spriteRectToRectangle(sprite_rect: spritesheet.SpriteRect) ray.Rectangle {
    return ray.Rectangle{
        .x = @intToFloat(f32, sprite_rect.x),
        .y = @intToFloat(f32, sprite_rect.y),
        .width = @intToFloat(f32, sprite_rect.width),
        .height = @intToFloat(f32, sprite_rect.height),
    };
}
