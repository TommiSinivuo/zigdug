const ray = @import("raylib.zig");
const spritesheet = @import("spritesheet.zig");
const game = @import("game.zig");
const GameData = game.GameData;

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

fn drawGameplay(data: *GameData, spritesheet_texture: ray.Texture2D) void {
    ray.ClearBackground(ray.BLACK);
    var y: usize = 0;
    while (y < game.tilemap_height) : (y += 1) {
        var x: usize = 0;
        while (x < game.tilemap_width) : (x += 1) {
            drawTile(data.game.tilemap[y][x], x, y, spritesheet_texture);
        }
    }
}

fn drawTile(tile: game.Tile, tile_x: usize, tile_y: usize, spritesheet_texture: ray.Texture2D) void {
    const sprite_rect = switch (tile) {
        .none => spritesheet.debug,
        .space => spritesheet.space,
        .dirt => spritesheet.dirt,
        .wall => spritesheet.brick,
        .boulder => spritesheet.boulder,
        .gem => spritesheet.gem,
        .door_closed => spritesheet.door_closed,
        .door_open => spritesheet.door_open,
        .player => spritesheet.player,
    };
    ray.DrawTextureRec(
        spritesheet_texture,
        spriteRectToRectangle(sprite_rect),
        tileToScreenCoordinates(tile_x, tile_y),
        ray.WHITE,
    );
}

fn tileToScreenCoordinates(tile_x: usize, tile_y: usize) ray.Vector2 {
    return ray.Vector2{
        .x = @intToFloat(f32, tile_x) * tile_size,
        .y = @intToFloat(f32, tile_y) * tile_size,
    };
}

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

fn spriteRectToRectangle(sprite_rect: spritesheet.SpriteRect) ray.Rectangle {
    return ray.Rectangle{
        .x = @intToFloat(f32, sprite_rect.x),
        .y = @intToFloat(f32, sprite_rect.y),
        .width = @intToFloat(f32, sprite_rect.width),
        .height = @intToFloat(f32, sprite_rect.height),
    };
}
