const play_state = @import("play_state.zig");
const zigdug = @import("../zigdug.zig");

const Input = zigdug.Input;
const PlayStateSubState = play_state.PlayStateSubState;
const ZigDug = zigdug.ZigDug;

pub const PauseSelection = enum(u8) {
    resume_level,
    restart_level,
    return_to_title,
    quit_game,
};

pub const PauseState = struct {
    selection: PauseSelection = .resume_level,

    pub fn update(self: *PauseState, global: *ZigDug, input: *Input) void {
        switch (self.selection) {
            .resume_level => {
                if (input.ui_down) {
                    self.selection = .restart_level;
                }
            },
            .restart_level => {
                if (input.ui_down) {
                    self.selection = .return_to_title;
                } else if (input.ui_up) {
                    self.selection = .resume_level;
                }
            },
            .return_to_title => {
                if (input.ui_down) {
                    self.selection = .quit_game;
                } else if (input.ui_up) {
                    self.selection = .restart_level;
                }
            },
            .quit_game => {
                if (input.ui_up) {
                    self.selection = .return_to_title;
                }
            },
        }

        if (input.ui_confirm) {
            switch (self.selection) {
                .resume_level => global.state = .play,
                .restart_level => {
                    global.play_state.substate = PlayStateSubState.load_map;
                    global.state = .play;
                },
                .return_to_title => {
                    global.play_state.map_index = 0;
                    global.play_state.substate = PlayStateSubState.load_map;
                    global.state = .title;
                },
                .quit_game => global.is_running = false,
            }
            self.selection = .resume_level;
        } else if (input.ui_cancel) {
            global.state = .play;
            self.selection = .resume_level;
        }
    }
};
