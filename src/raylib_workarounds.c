#include <raylib.h>

void WDrawTextureRec(Texture2D texture, Rectangle *sourceRec, Vector2 *position, Color *tint)
{
    DrawTextureRec(texture, *sourceRec, *position, *tint);
}
