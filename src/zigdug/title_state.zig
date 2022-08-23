const zigdug = @import("../zigdug.zig");

const Input = zigdug.Input;
const ZigDug = zigdug.ZigDug;

pub const TitleSelection = enum(u8) {
    play,
    quit,
};

pub const TitleState = struct {
    selection: TitleSelection = .play,

    pub fn update(self: *TitleState, global: *ZigDug, input: *Input) void {
        // Check for selection change
        if (self.selection == .play and input.ui_down) {
            self.selection = .quit;
        } else if (self.selection == .quit and input.ui_up) {
            self.selection = .play;
        }

        // Check for action and possibly change state or quit
        if (self.selection == .play and input.ui_confirm) {
            global.state = .play;
        } else if (self.selection == .quit and input.ui_confirm) {
            global.is_running = false;
        }
    }
};
