const ray = @import("raylib.zig");
const spritesheet = @import("spritesheet.zig");
const game = @import("game.zig");
const GameData = game.GameData;
const Tile = game.Tile;
const Tilemap = @import("tilemap.zig").Tilemap;
const Point = @import("common.zig").Point;

const p_tile_size = 16;

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

    pub fn draw(self: *Renderer, data: *GameData) void {
        ray.BeginDrawing();
        ray.ClearBackground(ray.BLACK);
        ray.BeginViewportMode(&self.viewport);

        switch (data.state) {
            .title => self.drawTitle(data),
            .play => self.drawGameplay(data),
            .pause => self.drawPauseMenu(data),
            .credits => self.drawCredits(),
        }

        ray.EndViewportMode();
        ray.DrawViewport(&self.viewport);
        ray.EndDrawing();
    }

    //------------------------------------------------------------------------------------
    // Title screen
    //------------------------------------------------------------------------------------

    fn drawTitle(self: *Renderer, data: *GameData) void {

        // background
        ray.WDrawTextureRec(
            self.spritesheet_texture,
            &spriteRectToRectangle(spritesheet.menu_background),
            &ray.Vector2{ .x = 0, .y = 0 },
            &ray.WHITE,
        );

        // title/logo
        ray.WDrawTextureRec(
            self.spritesheet_texture,
            &spriteRectToRectangle(spritesheet.zigdug),
            &ray.Vector2{ .x = 16, .y = 16 },
            &ray.WHITE,
        );

        // menu options
        ray.DrawText("PLAY", 120, 160, 16, ray.RAYWHITE);
        ray.DrawText("QUIT", 120, 192, 16, ray.RAYWHITE);

        // menu selection
        const gem_y: f32 = if (data.title.selection == .quit) 192 else 160;
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

    fn drawGameplay(self: *Renderer, data: *GameData) void {
        ray.ClearBackground(ray.BLACK);

        self.drawTilemap(&data.game.background_map);
        self.drawTilemap(&data.game.tilemap);
    }

    fn drawTilemap(self: *Renderer, tilemap: *Tilemap(Tile)) void {
        var tilemap_iterator = tilemap.iteratorForward();

        while (tilemap_iterator.next()) |item| {
            self.drawTile(item.value, item.point);
        }
    }

    fn drawTile(self: *Renderer, tile: game.Tile, tile_point: Point(i32)) void {
        const optional_sprite_rect: ?spritesheet.SpriteRect = switch (tile) {
            .none => spritesheet.black,
            .back_wall => spritesheet.back_wall,
            .boulder => spritesheet.boulder,
            .dirt => spritesheet.dirt,
            .door_closed => spritesheet.door_closed,
            .door_open => spritesheet.door_open,
            .gem => spritesheet.gem,
            .ladder => spritesheet.ladder,
            .player => spritesheet.player,
            .space => null,
            .wall => spritesheet.wall,
            .debug => spritesheet.debug,
        };

        if (optional_sprite_rect) |sprite_rect| {
            const screen_position = tileToScreenCoordinates(tile_point);

            ray.WDrawTextureRec(
                self.spritesheet_texture,
                &spriteRectToRectangle(sprite_rect),
                &screen_position,
                &ray.WHITE,
            );
        }
    }

    //------------------------------------------------------------------------------------
    // Pause menu
    //------------------------------------------------------------------------------------

    fn drawPauseMenu(self: *Renderer, data: *GameData) void {

        // background
        ray.WDrawTextureRec(
            self.spritesheet_texture,
            &spriteRectToRectangle(spritesheet.menu_background),
            &ray.Vector2{ .x = 0, .y = 0 },
            &ray.WHITE,
        );

        // menu options
        ray.DrawText("RESUME LEVEL", 72, 72, 16, ray.RAYWHITE);
        ray.DrawText("RESTART LEVEL", 72, 104, 16, ray.RAYWHITE);
        ray.DrawText("TO TITLE SCREEN", 72, 136, 16, ray.RAYWHITE);
        ray.DrawText("QUIT GAME", 72, 168, 16, ray.RAYWHITE);

        // menu selection
        const gem_y: f32 = switch (data.pause_menu.selection) {
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

    fn drawCredits(self: *Renderer) void {

        // background
        ray.WDrawTextureRec(
            self.spritesheet_texture,
            &spriteRectToRectangle(spritesheet.menu_background),
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

fn tileToScreenCoordinates(tile_point: Point(i32)) ray.Vector2 {
    return ray.Vector2{
        .x = @intToFloat(f32, tile_point.x) * p_tile_size,
        .y = @intToFloat(f32, tile_point.y) * p_tile_size,
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
