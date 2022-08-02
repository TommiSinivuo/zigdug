const ray = @import("raylib.zig");
const spritesheet = @import("spritesheet.zig");
const game = @import("game.zig");
const GameData = game.GameData;
const Point = @import("common.zig").Point;

const tile_size = 16;

pub fn draw(data: *GameData, viewport: *ray.Viewport, spritesheet_texture: ray.Texture2D) void {
    ray.BeginDrawing();
    ray.ClearBackground(ray.BLACK);
    ray.BeginViewportMode(viewport);

    switch (data.state) {
        .title => drawTitle(data, spritesheet_texture),
        .play => drawGameplay(data, spritesheet_texture),
        .credits => drawCredits(spritesheet_texture),
    }

    ray.EndViewportMode();
    ray.DrawViewport(viewport);
    ray.EndDrawing();
}

//------------------------------------------------------------------------------------
// Title screen
//------------------------------------------------------------------------------------

fn drawTitle(data: *GameData, spritesheet_texture: ray.Texture2D) void {

    // background
    ray.DrawTextureRec(
        spritesheet_texture,
        spriteRectToRectangle(spritesheet.menu_background),
        ray.Vector2{ .x = 0, .y = 0 },
        ray.WHITE,
    );

    // title/logo
    ray.DrawTextureRec(
        spritesheet_texture,
        spriteRectToRectangle(spritesheet.zigdug),
        ray.Vector2{ .x = 16, .y = 16 },
        ray.WHITE,
    );

    // menu options
    ray.DrawText("PLAY", 120, 160, 16, ray.RAYWHITE);
    ray.DrawText("QUIT", 120, 192, 16, ray.RAYWHITE);

    // menu selection
    const gem_y: f32 = if (data.title.selection == .quit) 192 else 160;
    ray.DrawTextureRec(
        spritesheet_texture,
        spriteRectToRectangle(spritesheet.gem),
        ray.Vector2{ .x = 88, .y = gem_y },
        ray.WHITE,
    );
}

//------------------------------------------------------------------------------------
// Gameplay
//------------------------------------------------------------------------------------

fn drawGameplay(data: *GameData, spritesheet_texture: ray.Texture2D) void {
    ray.ClearBackground(ray.BLACK);

    var tilemap = data.game.tilemap;
    var tilemap_iterator = tilemap.iteratorForward();

    while (tilemap_iterator.next()) |item| {
        drawTile(item.value, item.point, spritesheet_texture);
    }
}

fn drawTile(tile: game.Tile, tile_point: Point(i32), spritesheet_texture: ray.Texture2D) void {
    var draw_backdrop = false; // If tile has transparency, then we want to draw a background for it
    var sprite_rect: spritesheet.SpriteRect = undefined;

    switch (tile) {
        .none => sprite_rect = spritesheet.debug,
        .space => sprite_rect = spritesheet.space,
        .dirt => sprite_rect = spritesheet.dirt,
        .wall => sprite_rect = spritesheet.brick,
        .boulder => {
            sprite_rect = spritesheet.boulder;
            draw_backdrop = true;
        },
        .gem => {
            sprite_rect = spritesheet.gem;
            draw_backdrop = true;
        },
        .door_closed => {
            sprite_rect = spritesheet.door_closed;
            draw_backdrop = true;
        },
        .door_open => {
            sprite_rect = spritesheet.door_open;
            draw_backdrop = true;
        },
        .player => {
            sprite_rect = spritesheet.player;
            draw_backdrop = true;
        },
    }

    const screen_position = tileToScreenCoordinates(tile_point);

    if (draw_backdrop) {
        ray.DrawTextureRec(
            spritesheet_texture,
            spriteRectToRectangle(spritesheet.space),
            screen_position,
            ray.WHITE,
        );
    }

    ray.DrawTextureRec(
        spritesheet_texture,
        spriteRectToRectangle(sprite_rect),
        screen_position,
        ray.WHITE,
    );
}

fn tileToScreenCoordinates(tile_point: Point(i32)) ray.Vector2 {
    return ray.Vector2{
        .x = @intToFloat(f32, tile_point.x) * tile_size,
        .y = @intToFloat(f32, tile_point.y) * tile_size,
    };
}

//------------------------------------------------------------------------------------
// Credits
//------------------------------------------------------------------------------------

fn drawCredits(spritesheet_texture: ray.Texture2D) void {

    // background
    ray.DrawTextureRec(
        spritesheet_texture,
        spriteRectToRectangle(spritesheet.menu_background),
        ray.Vector2{ .x = 0, .y = 0 },
        ray.WHITE,
    );

    // the end
    ray.DrawTextureRec(
        spritesheet_texture,
        spriteRectToRectangle(spritesheet.the_end),
        ray.Vector2{ .x = 16, .y = 48 },
        ray.WHITE,
    );

    // credits
    ray.DrawText("A GAME BY TOMMI SINIVUO", 56, 204, 10, ray.RAYWHITE);
}

//------------------------------------------------------------------------------------
// Common utils
//------------------------------------------------------------------------------------

fn spriteRectToRectangle(sprite_rect: spritesheet.SpriteRect) ray.Rectangle {
    return ray.Rectangle{
        .x = @intToFloat(f32, sprite_rect.x),
        .y = @intToFloat(f32, sprite_rect.y),
        .width = @intToFloat(f32, sprite_rect.width),
        .height = @intToFloat(f32, sprite_rect.height),
    };
}
