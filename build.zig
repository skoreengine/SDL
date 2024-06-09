const std = @import("std");

const FileArray = std.ArrayList([]const u8);

const generic_src_directorioes = [_][]const u8{
    "dummy",
};

const windows_src_directories = [_][]const u8{
    "windows",
    "wasapi",
    "mediafoundation",
    "directsound",
    "direct3d",
    "direct3d11",
    "direct3d12",
    "vulkan",
    "opengl",
    "opengles2",
    "software",
};

const linux_src_directorioes = [_][]const u8{
    "unix",
    "steam",
    "software",
    "pthread",
    "x11",
    "vulkan",
    "opengl",
    "opengles2",
    "dlopen",
};

fn isFolderAllowed(t: std.Target, name: []const u8) bool {
    for (generic_src_directorioes) |value| {
        if (std.mem.eql(u8, name, value)) {
            return true;
        }
    }

    if (t.os.tag == .windows) {
        for (windows_src_directories) |value| {
            if (std.mem.eql(u8, name, value)) {
                return true;
            }
        }
    } else if (t.os.tag == .linux) {
        for (linux_src_directorioes) |value| {
            if (std.mem.eql(u8, name, value)) {
                return true;
            }
        }
    }

    return false;
}

fn addSourceFiles(t: std.Target, b: *std.Build, sources: *FileArray, sub_path: []const u8) !void {
    var dir = try std.fs.cwd().openDir(b.path(sub_path).getPath(b), .{ .iterate = true });
    var iter = dir.iterate();
    while (try iter.next()) |file| {
        if (file.kind == .directory) {
            if (isFolderAllowed(t, file.name)) {
                const paths = [_][]const u8{ sub_path, file.name };
                const full_path = b.pathJoin(&paths);
                try addSourceFiles(t, b, sources, full_path);
            }
        } else if (file.kind == .file) {
            const ext = std.fs.path.extension(file.name);
            if (std.mem.eql(u8, ext, ".c")) {
                const paths = [_][]const u8{ sub_path, file.name };
                const full_path = b.pathJoin(&paths);
                try sources.append(full_path);
            }
        }
    }
}

pub fn build(b: *std.Build) !void {
    var sources = FileArray.init(b.allocator);
    defer sources.deinit();

    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const t = target.result;

    try addSourceFiles(t, b, &sources, "src");
    try addSourceFiles(t, b, &sources, "src/atomic");
    try addSourceFiles(t, b, &sources, "src/audio");
    try addSourceFiles(t, b, &sources, "src/camera");
    try addSourceFiles(t, b, &sources, "src/core");
    try addSourceFiles(t, b, &sources, "src/cpuinfo");
    try addSourceFiles(t, b, &sources, "src/dynapi");
    try addSourceFiles(t, b, &sources, "src/events");
    try addSourceFiles(t, b, &sources, "src/file");
    try addSourceFiles(t, b, &sources, "src/filesystem");
    try addSourceFiles(t, b, &sources, "src/joystick");
    try addSourceFiles(t, b, &sources, "src/haptic");
    try addSourceFiles(t, b, &sources, "src/hidapi");
    try addSourceFiles(t, b, &sources, "src/libm");
    try addSourceFiles(t, b, &sources, "src/locale");
    try addSourceFiles(t, b, &sources, "src/main");
    try addSourceFiles(t, b, &sources, "src/misc");
    try addSourceFiles(t, b, &sources, "src/power");
    try addSourceFiles(t, b, &sources, "src/render");
    try addSourceFiles(t, b, &sources, "src/render");
    try addSourceFiles(t, b, &sources, "src/sensor");
    try addSourceFiles(t, b, &sources, "src/stdlib");
    try addSourceFiles(t, b, &sources, "src/storage");
    try addSourceFiles(t, b, &sources, "src/storage/steam");
    try addSourceFiles(t, b, &sources, "src/thread");
    try addSourceFiles(t, b, &sources, "src/time");
    try addSourceFiles(t, b, &sources, "src/timer");
    try addSourceFiles(t, b, &sources, "src/loadso");
    try addSourceFiles(t, b, &sources, "src/video");
    try addSourceFiles(t, b, &sources, "src/video/yuv2rgb");

    try addSourceFiles(t, b, &sources, "src/audio/disk");
    try addSourceFiles(t, b, &sources, "src/video/offscreen");

    try addSourceFiles(t, b, &sources, "src/joystick/virtual");
    try addSourceFiles(t, b, &sources, "src/joystick/hidapi");

    try addSourceFiles(t, b, &sources, "src/storage/generic");

    const lib = b.addStaticLibrary(.{
        .name = "SDL3",
        .target = target,
        .optimize = optimize,
    });

    lib.addIncludePath(b.path("include"));
    lib.addIncludePath(b.path("src"));

    lib.defineCMacro("SDL_USE_BUILTIN_OPENGL_DEFINITIONS", "1");

    lib.linkLibC();

    if (t.os.tag.isDarwin()) {
        lib.linkFramework("OpenGL");
        lib.linkFramework("Metal");
        lib.linkFramework("CoreVideo");
        lib.linkFramework("Cocoa");
        lib.linkFramework("IOKit");
        lib.linkFramework("ForceFeedback");
        lib.linkFramework("Carbon");
        lib.linkFramework("CoreAudio");
        lib.linkFramework("AudioToolbox");
        lib.linkFramework("AVFoundation");
        lib.linkFramework("Foundation");
    } else if (t.os.tag == .windows) {
        try sources.append("src/thread/generic/SDL_syscond.c");
        try sources.append("src/thread/generic/SDL_sysrwlock.c");

        lib.linkSystemLibrary("setupapi");
        lib.linkSystemLibrary("winmm");
        lib.linkSystemLibrary("gdi32");
        lib.linkSystemLibrary("imm32");
        lib.linkSystemLibrary("version");
        lib.linkSystemLibrary("oleaut32");
        lib.linkSystemLibrary("ole32");
    } else if (t.os.tag == .linux) {

        lib.defineCMacro("SDL_TIMER_UNIX" , "1");

        lib.linkSystemLibrary("Xi");
        lib.linkSystemLibrary("Xmu");
        lib.linkSystemLibrary("Xext");

        lib.defineCMacro("HAVE_X11", "TRUE");
        lib.defineCMacro("HAVE_SDL_VIDEO", "TRUE");
        lib.defineCMacro("SDL_VIDEO_DRIVER_X11" , "1");
        lib.defineCMacro("HAVE_XCURSOR_H", "1");
        lib.defineCMacro("HAVE_XINPUT2_H", "1");
        lib.defineCMacro("HAVE_XRANDR_H", "1");
        lib.defineCMacro("HAVE_XFIXES_H_", "1");
        lib.defineCMacro("HAVE_XRENDER_H", "1");
        lib.defineCMacro("HAVE_XSS_H", "1");
        lib.defineCMacro("HAVE_XSHAPE_H", "1");
        lib.defineCMacro("HAVE_XDBE_H", "1");
        lib.defineCMacro("HAVE_XEXT_H", "1");
        lib.defineCMacro("SDL_VIDEO_DRIVER_X11_SUPPORTS_GENERIC_EVENTS", "1");
        lib.defineCMacro("SDL_VIDEO_DRIVER_X11_XSHAPE", "1");
        lib.defineCMacro("HAVE_X11_XSHAPE", "TRUE");

        lib.defineCMacro("SDL_VIDEO_VULKAN", "1");
        lib.defineCMacro("HAVE_VULKAN", "TRUE");

        lib.defineCMacro("SDL_LOADSO_DLOPEN", "1");
        lib.defineCMacro("HAVE_SDL_LOADSO", "TRUE");

        try sources.append("src/core/linux/SDL_evdev_capabilities.c");
        try sources.append("src/core/linux/SDL_threadprio.c");
        try sources.append("src/core/linux/SDL_sandbox.c");
    }

    lib.addCSourceFiles(.{ .files = sources.items });
    lib.installHeadersDirectory(b.path("include/SDL3"), "SDL3", .{});

    b.installArtifact(lib);

    const test_app = b.addExecutable(.{
        .name = "test_app",
        .root_source_file = b.path("test/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    b.installArtifact(test_app);

    test_app.linkLibrary(lib);
    test_app.addIncludePath(b.path("include"));

    const run_cmd = b.addRunArtifact(test_app);

    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
