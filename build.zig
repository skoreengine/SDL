const std = @import("std");

const FileArray = std.ArrayList([]const u8);

fn addSourceFiles(b: *std.Build, sources: *FileArray, sub_path: []const u8) !void {
    var dir = try std.fs.cwd().openDir(sub_path, .{ .iterate = true });
    var iter = dir.iterate();
    while (try iter.next()) |file| {
        if (file.kind != .file) {
            continue;
        }

        const ext = std.fs.path.extension(file.name);
        if (std.mem.eql(u8, ext, ".c")) {
            const paths = [_][]const u8{ sub_path, file.name };
            const full_path = b.pathJoin(&paths);
            try sources.append(full_path);
        }
    }
}

pub fn build(b: *std.Build) !void {
    var sources = FileArray.init(b.allocator);
    defer sources.deinit();

    try addSourceFiles(b, &sources, "src");
    try addSourceFiles(b, &sources, "src/atomic");
    try addSourceFiles(b, &sources, "src/audio");
    try addSourceFiles(b, &sources, "src/camera");
    try addSourceFiles(b, &sources, "src/core");
    try addSourceFiles(b, &sources, "src/cpuinfo");
    try addSourceFiles(b, &sources, "src/dynapi");
    try addSourceFiles(b, &sources, "src/events");
    try addSourceFiles(b, &sources, "src/file");
    try addSourceFiles(b, &sources, "src/filesystem");
    try addSourceFiles(b, &sources, "src/joystick");
    try addSourceFiles(b, &sources, "src/haptic");
    try addSourceFiles(b, &sources, "src/hidapi");
    try addSourceFiles(b, &sources, "src/libm");
    try addSourceFiles(b, &sources, "src/locale");
    try addSourceFiles(b, &sources, "src/main");
    try addSourceFiles(b, &sources, "src/misc");
    try addSourceFiles(b, &sources, "src/power");
    try addSourceFiles(b, &sources, "src/render");
    try addSourceFiles(b, &sources, "src/render");
    try addSourceFiles(b, &sources, "src/sensor");
    try addSourceFiles(b, &sources, "src/stdlib");
    try addSourceFiles(b, &sources, "src/storage");
    try addSourceFiles(b, &sources, "src/thread");
    try addSourceFiles(b, &sources, "src/time");
    try addSourceFiles(b, &sources, "src/timer");
    try addSourceFiles(b, &sources, "src/video");

    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const t = target.result;

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

        try addSourceFiles(b, &sources, "src/core/windows");
        try addSourceFiles(b, &sources, "src/misc/windows");
        try addSourceFiles(b, &sources, "src/audio/directsound");
        try addSourceFiles(b, &sources, "src/audio/wasapi");
        try addSourceFiles(b, &sources, "src/video/windows/");
        try addSourceFiles(b, &sources, "src/locale/windows");
        try addSourceFiles(b, &sources, "src/filesystem/windows");
        try addSourceFiles(b, &sources, "src/timer/windows");
        try addSourceFiles(b, &sources, "src/time/windows");
        try addSourceFiles(b, &sources, "src/storage/steam");
        try addSourceFiles(b, &sources, "src/storage/generic");
        try addSourceFiles(b, &sources, "src/joystick/windows");
        try addSourceFiles(b, &sources, "src/loadso/windows");

        lib.linkSystemLibrary("setupapi");
        lib.linkSystemLibrary("winmm");
        lib.linkSystemLibrary("gdi32");
        lib.linkSystemLibrary("imm32");
        lib.linkSystemLibrary("version");
        lib.linkSystemLibrary("oleaut32");
        lib.linkSystemLibrary("ole32");
    }


    lib.addCSourceFiles(.{ .files = sources.items });
    lib.installHeadersDirectory(b.path("include"), "SDL3", .{});
    b.installArtifact(lib);
}
