const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    const exe = b.addExecutable("zigdug", "src/main.zig");
    exe.setTarget(target);
    exe.setBuildMode(mode);
    exe.linkLibC();

    // raylib
    // TODO: extract raylib stuff to separate function
    const raylib_flags = &[_][]const u8{
        "-std=gnu99",
        "-DPLATFORM_DESKTOP",
        "-DGL_SILENCE_DEPRECATION=199309L",
        "-fno-sanitize=undefined", // https://github.com/raysan5/raylib/issues/1891
    };

    exe.addIncludePath("raylib/src");
    exe.addIncludePath("./raylib/src/external/glfw/include");

    exe.addCSourceFile("./raylib/src/rcore.c", raylib_flags);
    exe.addCSourceFile("./raylib/src/rmodels.c", raylib_flags);
    exe.addCSourceFile("./raylib/src/raudio.c", raylib_flags);
    exe.addCSourceFile("./raylib/src/rshapes.c", raylib_flags);
    exe.addCSourceFile("./raylib/src/rtext.c", raylib_flags);
    exe.addCSourceFile("./raylib/src/rtextures.c", raylib_flags);
    exe.addCSourceFile("./raylib/src/utils.c", raylib_flags);

    switch (exe.target.toTarget().os.tag) {
        .windows => {
            exe.addCSourceFile("./raylib/src/rglfw.c", raylib_flags);
            exe.linkSystemLibrary("winmm");
            exe.linkSystemLibrary("gdi32");
            exe.linkSystemLibrary("opengl32");
            // TODO: make this depend on target C ABI
            exe.linkSystemLibrary("User32"); // for MSVC
            exe.linkSystemLibrary("Shell32"); // for MSVC
            //exe.addIncludeDir("./raylib/src/external/glfw/deps/mingw"); // for MINGW
        },
        // TODO: Linux not verified as working
        .linux => {
            exe.addCSourceFile("./raylib/src/rglfw.c", raylib_flags);
            exe.linkSystemLibrary("GL");
            exe.linkSystemLibrary("rt");
            exe.linkSystemLibrary("dl");
            exe.linkSystemLibrary("m");
            exe.linkSystemLibrary("X11");
        },
        // TODO: BSD's not verfied as working
        .freebsd, .openbsd, .netbsd, .dragonfly => {
            exe.addCSourceFile("./raylib/src/rglfw.c", raylib_flags);
            exe.linkSystemLibrary("GL");
            exe.linkSystemLibrary("rt");
            exe.linkSystemLibrary("dl");
            exe.linkSystemLibrary("m");
            exe.linkSystemLibrary("X11");
            exe.linkSystemLibrary("Xrandr");
            exe.linkSystemLibrary("Xinerama");
            exe.linkSystemLibrary("Xi");
            exe.linkSystemLibrary("Xxf86vm");
            exe.linkSystemLibrary("Xcursor");
        },
        .macos => {
            // On macos rglfw.c include Objective-C files.
            const raylib_flags_extra_macos = &[_][]const u8{
                "-ObjC",
            };
            exe.addCSourceFile(
                "./raylib/src/rglfw.c",
                raylib_flags ++ raylib_flags_extra_macos,
            );
            exe.linkFramework("Foundation");
            exe.linkFramework("Cocoa");
            exe.linkFramework("OpenGL");
            exe.linkFramework("CoreAudio");
            exe.linkFramework("CoreVideo");
            exe.linkFramework("IOKit");
        },
        else => {
            @panic("Unsupported OS");
        },
    }

    // My custom raylib addons
    exe.addCSourceFile("./src/raylib_viewport.c", raylib_flags);

    exe.install();

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const exe_tests = b.addTest("src/main.zig");
    exe_tests.setTarget(target);
    exe_tests.setBuildMode(mode);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&exe_tests.step);
}
