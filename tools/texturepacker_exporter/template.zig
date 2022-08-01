// Created with TexturePacker (http://www.codeandweb.com/texturepacker)
//
// Sprite sheet: {{ texture.fullName }} ({{ texture.size.width }} x {{ texture.size.height }})
//
// {{ smartUpdateKey }}

pub const SpriteRect = struct {
    x: i32,
    y: i32,
    width: i32,
    height: i32,
};

{% for sprite in allSprites %}
pub const {{ sprite.trimmedName }}: SpriteRect = SpriteRect{
    .x = {{ sprite.frameRect.x }},
    .y = {{ sprite.frameRect.y }},
    .width = {{ sprite.frameRect.width }},
    .height = {{ sprite.frameRect.height }},
};
{% endfor %}
