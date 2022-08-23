const zigdug = @import("../zigdug.zig");

const Input = zigdug.Input;
const ZigDug = zigdug.ZigDug;

pub const CreditsState = struct {
    pub fn update(_: *CreditsState, global: *ZigDug, input: *Input) void {
        if (input.ui_confirm) {
            global.state = .title;
        }
    }
};
