// Some Basic Colors
pub const LIGHTGRAY = Color{ .r = 200, .g = 200, .b = 200, .a = 255 };
pub const GRAY = Color{ .r = 130, .g = 130, .b = 130, .a = 255 };
pub const DARKGRAY = Color{ .r = 80, .g = 80, .b = 80, .a = 255 };
pub const YELLOW = Color{ .r = 253, .g = 249, .b = 0, .a = 255 };
pub const GOLD = Color{ .r = 255, .g = 203, .b = 0, .a = 255 };
pub const ORANGE = Color{ .r = 255, .g = 161, .b = 0, .a = 255 };
pub const PINK = Color{ .r = 255, .g = 109, .b = 194, .a = 255 };
pub const RED = Color{ .r = 230, .g = 41, .b = 55, .a = 255 };
pub const MAROON = Color{ .r = 190, .g = 33, .b = 55, .a = 255 };
pub const GREEN = Color{ .r = 0, .g = 228, .b = 48, .a = 255 };
pub const LIME = Color{ .r = 0, .g = 158, .b = 47, .a = 255 };
pub const DARKGREEN = Color{ .r = 0, .g = 117, .b = 44, .a = 255 };
pub const SKYBLUE = Color{ .r = 102, .g = 191, .b = 255, .a = 255 };
pub const BLUE = Color{ .r = 0, .g = 121, .b = 241, .a = 255 };
pub const DARKBLUE = Color{ .r = 0, .g = 82, .b = 172, .a = 255 };
pub const PURPLE = Color{ .r = 200, .g = 122, .b = 255, .a = 255 };
pub const VIOLET = Color{ .r = 135, .g = 60, .b = 190, .a = 255 };
pub const DARKPURPLE = Color{ .r = 112, .g = 31, .b = 126, .a = 255 };
pub const BEIGE = Color{ .r = 211, .g = 176, .b = 131, .a = 255 };
pub const BROWN = Color{ .r = 127, .g = 106, .b = 79, .a = 255 };
pub const DARKBROWN = Color{ .r = 76, .g = 63, .b = 47, .a = 255 };

pub const WHITE = Color{ .r = 255, .g = 255, .b = 255, .a = 255 };
pub const BLACK = Color{ .r = 0, .g = 0, .b = 0, .a = 255 };
pub const BLANK = Color{ .r = 0, .g = 0, .b = 0, .a = 0 };
pub const MAGENTA = Color{ .r = 255, .g = 0, .b = 255, .a = 255 };
pub const RAYWHITE = Color{ .r = 245, .g = 245, .b = 245, .a = 255 };

pub const Rectangle = extern struct {
    x: f32,
    y: f32,
    width: f32,
    height: f32,
};

// Color type, RGBA (32bit)
pub const Color = extern struct {
    r: u8,
    g: u8,
    b: u8,
    a: u8,
};

pub const Vector2 = extern struct {
    x: f32,
    y: f32,
};

pub const Texture = extern struct {
    id: c_uint,
    width: c_int,
    height: c_int,
    mipmaps: c_int,
    format: c_int,
};
pub const Texture2D = Texture;

pub const RenderTexture = extern struct {
    id: c_uint,
    texture: Texture,
    depth: Texture,
};
pub const RenderTexture2D = RenderTexture;

// Keyboard keys
pub const KeyboardKey = enum(c_int) {
    KEY_NULL = 0,

    // Alphanumeric keys
    KEY_APOSTROPHE = 39,
    KEY_COMMA = 44,
    KEY_MINUS = 45,
    KEY_PERIOD = 46,
    KEY_SLASH = 47,
    KEY_ZERO = 48,
    KEY_ONE = 49,
    KEY_TWO = 50,
    KEY_THREE = 51,
    KEY_FOUR = 52,
    KEY_FIVE = 53,
    KEY_SIX = 54,
    KEY_SEVEN = 55,
    KEY_EIGHT = 56,
    KEY_NINE = 57,
    KEY_SEMICOLON = 59,
    KEY_EQUAL = 61,
    KEY_A = 65,
    KEY_B = 66,
    KEY_C = 67,
    KEY_D = 68,
    KEY_E = 69,
    KEY_F = 70,
    KEY_G = 71,
    KEY_H = 72,
    KEY_I = 73,
    KEY_J = 74,
    KEY_K = 75,
    KEY_L = 76,
    KEY_M = 77,
    KEY_N = 78,
    KEY_O = 79,
    KEY_P = 80,
    KEY_Q = 81,
    KEY_R = 82,
    KEY_S = 83,
    KEY_T = 84,
    KEY_U = 85,
    KEY_V = 86,
    KEY_W = 87,
    KEY_X = 88,
    KEY_Y = 89,
    KEY_Z = 90,

    // Function keys
    KEY_SPACE = 32,
    KEY_ESCAPE = 256,
    KEY_ENTER = 257,
    KEY_TAB = 258,
    KEY_BACKSPACE = 259,
    KEY_INSERT = 260,
    KEY_DELETE = 261,
    KEY_RIGHT = 262,
    KEY_LEFT = 263,
    KEY_DOWN = 264,
    KEY_UP = 265,
    KEY_PAGE_UP = 266,
    KEY_PAGE_DOWN = 267,
    KEY_HOME = 268,
    KEY_END = 269,
    KEY_CAPS_LOCK = 280,
    KEY_SCROLL_LOCK = 281,
    KEY_NUM_LOCK = 282,
    KEY_PRINT_SCREEN = 283,
    KEY_PAUSE = 284,
    KEY_F1 = 290,
    KEY_F2 = 291,
    KEY_F3 = 292,
    KEY_F4 = 293,
    KEY_F5 = 294,
    KEY_F6 = 295,
    KEY_F7 = 296,
    KEY_F8 = 297,
    KEY_F9 = 298,
    KEY_F10 = 299,
    KEY_F11 = 300,
    KEY_F12 = 301,
    KEY_LEFT_SHIFT = 340,
    KEY_LEFT_CONTROL = 341,
    KEY_LEFT_ALT = 342,
    KEY_LEFT_SUPER = 343,
    KEY_RIGHT_SHIFT = 344,
    KEY_RIGHT_CONTROL = 345,
    KEY_RIGHT_ALT = 346,
    KEY_RIGHT_SUPER = 347,
    KEY_KB_MENU = 348,
    KEY_LEFT_BRACKET = 91,
    KEY_BACKSLASH = 92,
    KEY_RIGHT_BRACKET = 93,
    KEY_GRAVE = 96,

    // Keypad keys
    KEY_KP_0 = 320,
    KEY_KP_1 = 321,
    KEY_KP_2 = 322,
    KEY_KP_3 = 323,
    KEY_KP_4 = 324,
    KEY_KP_5 = 325,
    KEY_KP_6 = 326,
    KEY_KP_7 = 327,
    KEY_KP_8 = 328,
    KEY_KP_9 = 329,
    KEY_KP_DECIMAL = 330,
    KEY_KP_DIVIDE = 331,
    KEY_KP_MULTIPLY = 332,
    KEY_KP_SUBTRACT = 333,
    KEY_KP_ADD = 334,
    KEY_KP_ENTER = 335,
    KEY_KP_EQUAL = 336,
};

// Mouse buttons
pub const MouseButton = enum(c_int) {
    MOUSE_LEFT_BUTTON = 0,
    MOUSE_RIGHT_BUTTON = 1,
    MOUSE_MIDDLE_BUTTON = 2,
};

//------------------------------------------------------------------------------------
// Window and Graphics Device Functions (Module: core)
//------------------------------------------------------------------------------------

// Window-related functions
pub extern fn InitWindow(width: c_int, height: c_int, title: [*c]const u8) void;
pub extern fn WindowShouldClose() bool;
pub extern fn CloseWindow() void;

// Drawing-related functions
pub extern fn ClearBackground(color: Color) void;
pub extern fn BeginDrawing() void;
pub extern fn EndDrawing() void;

// Timing-related functions
pub extern fn SetTargetFPS(fps: c_int) void;
pub extern fn GetTime() f64;

//------------------------------------------------------------------------------------
// Input Handling Functions (Module: core)
//------------------------------------------------------------------------------------

// Input-related functions: keyboard
pub extern fn IsKeyPressed(key: KeyboardKey) bool;
pub extern fn IsKeyDown(key: KeyboardKey) bool;
pub extern fn IsKeyReleased(key: KeyboardKey) bool;
pub extern fn IsKeyUp(key: KeyboardKey) bool;

// Input-related functions: mouse
pub extern fn IsMouseButtonPressed(button: MouseButton) bool;
pub extern fn GetMouseX() i32;
pub extern fn GetMouseY() i32;

//------------------------------------------------------------------------------------
// Basic Shapes Drawing Functions (Module: shapes)
//------------------------------------------------------------------------------------

// Basic shapes drawing functions
pub extern fn DrawCircleV(center: Vector2, radius: f32, color: Color) void;
pub extern fn DrawRectangle(posX: c_int, posY: c_int, width: c_int, height: c_int, color: Color) void;

//------------------------------------------------------------------------------------
// Font Loading and Text Drawing Functions (Module: text)
//------------------------------------------------------------------------------------

// Text drawing functions
pub extern fn DrawFPS(posX: c_int, posY: c_int) void;
pub extern fn DrawText(text: [*c]const u8, posX: c_int, posY: c_int, fontSize: c_int, color: Color) void;

// Text strings management functions (no utf8 strings, only byte chars)
// NOTE: Some strings allocate memory internally for returned strings, just be careful!
pub extern fn TextFormat(text: [*c]const u8, ...) [*c]const u8;

//------------------------------------------------------------------------------------
// My custom addons
//------------------------------------------------------------------------------------

pub const Viewport = extern struct {
    target: RenderTexture2D,
    src_rect: Rectangle,
    dest_rect: Rectangle,
    origin: Vector2,
    rotation: f32,
};

pub extern fn CreateViewport(width: c_int, height: c_int) Viewport;
pub extern fn BeginViewportMode(vp: *Viewport) void;
pub extern fn EndViewportMode() void;
pub extern fn DrawViewport(vp: *Viewport) void;
pub extern fn ScaleViewportToScreen(vp: *Viewport) void;
pub extern fn UnloadViewport(vp: *Viewport) void;