#ifndef RAYLIB_VIEWPORT_H
#define RAYLIB_VIEWPORT_H

#include <math.h>

#include "raylib.h"

typedef struct Viewport
{
    RenderTexture2D target;
    Rectangle src_rect;
    Rectangle dest_rect;
    Vector2 origin;
    float rotation;
} Viewport;

Viewport CreateViewport(int width, int height); // Create a Viewport with a logical size
void BeginViewportMode(Viewport *vp);           // Begin viewport mode (texture mode) for rendering
void EndViewportMode();                         // End viewport mode
void DrawViewport(Viewport *vp);                // Draw the viewport onto the screen
void ScaleViewportToScreen(Viewport *vp);       // Scale viewport to fit screen and apply letterboxing
void UnloadViewport(Viewport *vp);              // Unload viewport

Viewport CreateViewport(int width, int height)
{
    RenderTexture2D render_texture = LoadRenderTexture(width, height);
    SetTextureFilter(render_texture.texture, TEXTURE_FILTER_POINT);

    Viewport vp = (Viewport){
        .target = render_texture,
        .src_rect = (Rectangle){
            .x = 0.0f,
            .y = 0.0f,
            .width = (float)width,
            .height = (float)-height,
        },
        .dest_rect = (Rectangle){
            .x = 0.0f,
            .y = 0.0f,
            .width = (float)width,
            .height = (float)height,
        },
        .origin = (Vector2){0, 0},
        .rotation = 0.0f,
    };

    return vp;
}

void BeginViewportMode(Viewport *vp)
{
    BeginTextureMode(vp->target);
}

void EndViewportMode()
{
    EndTextureMode();
}

void DrawViewport(Viewport *vp)
{
    DrawTexturePro(vp->target.texture,
                   vp->src_rect,
                   vp->dest_rect,
                   vp->origin,
                   vp->rotation,
                   WHITE);
}

void ScaleViewportToScreen(Viewport *vp)
{
    float screen_width = (float)GetScreenWidth();
    float screen_height = (float)GetScreenHeight();
    float scale_h = screen_width / vp->src_rect.width;
    float scale_v = screen_height / -vp->src_rect.height;
    float scale = fminf(scale_h, scale_v);

    vp->dest_rect = (Rectangle){
        .x = 0.0f,
        .y = 0.0f,
        .width = vp->src_rect.width * scale,
        .height = -vp->src_rect.height * scale,
    };
    vp->origin.x = -(screen_width - vp->dest_rect.width) * 0.5f;
    vp->origin.y = -(screen_height - vp->dest_rect.height) * 0.5f;
}

void UnloadViewport(Viewport *vp)
{
    UnloadRenderTexture(vp->target);
}

#endif
