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
    try addSourceFiles(b, &sources, "src/video/yuv2rgb");

    try addSourceFiles(b, &sources, "src/audio/disk");
    try addSourceFiles(b, &sources, "src/video/offscreen");

    try addSourceFiles(b, &sources, "src/joystick/virtual");
    try addSourceFiles(b, &sources, "src/joystick/hidapi");

    try addSourceFiles(b, &sources, "src/audio/dummy");
    try addSourceFiles(b, &sources, "src/video/dummy");
    try addSourceFiles(b, &sources, "src/joystick/dummy");
    try addSourceFiles(b, &sources, "src/haptic/dummy");
    try addSourceFiles(b, &sources, "src/sensor/dummy");
    try addSourceFiles(b, &sources, "src/loadso/dummy");
    try addSourceFiles(b, &sources, "src/filesystem/dummy");
    try addSourceFiles(b, &sources, "src/camera/dummy");

    try addSourceFiles(b, &sources, "src/storage/generic");

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
        try addSourceFiles(b, &sources, "src/video/windows");
        try addSourceFiles(b, &sources, "src/locale/windows");
        try addSourceFiles(b, &sources, "src/filesystem/windows");
        try addSourceFiles(b, &sources, "src/haptic/windows");
        try addSourceFiles(b, &sources, "src/timer/windows");
        try addSourceFiles(b, &sources, "src/time/windows");
        try addSourceFiles(b, &sources, "src/storage/steam");
        try addSourceFiles(b, &sources, "src/storage/generic");
        try addSourceFiles(b, &sources, "src/joystick/windows");
        try addSourceFiles(b, &sources, "src/loadso/windows");
        try addSourceFiles(b, &sources, "src/sensor/windows/");
        try addSourceFiles(b, &sources, "src/camera/mediafoundation");

        try sources.append("src/thread/generic/SDL_syscond.c");
        try sources.append("src/thread/generic/SDL_sysrwlock.c");
        try sources.append("src/thread/windows/SDL_syscond_cv.c");
        try sources.append("src/thread/windows/SDL_sysmutex.c");
        try sources.append("src/thread/windows/SDL_sysrwlock_srw.c");
        try sources.append("src/thread/windows/SDL_syssem.c");
        try sources.append("src/thread/windows/SDL_systhread.c");
        try sources.append("src/thread/windows/SDL_systls.c");

        try addSourceFiles(b, &sources, "src/render/direct3d");
        try addSourceFiles(b, &sources, "src/render/direct3d11");
        try addSourceFiles(b, &sources, "src/render/direct3d12");
        try addSourceFiles(b, &sources, "src/render/vulkan");
        try addSourceFiles(b, &sources, "src/render/opengl");
        try addSourceFiles(b, &sources, "src/render/opengles2");
        try addSourceFiles(b, &sources, "src/render/software");

        lib.linkSystemLibrary("setupapi");
        lib.linkSystemLibrary("winmm");
        lib.linkSystemLibrary("gdi32");
        lib.linkSystemLibrary("imm32");
        lib.linkSystemLibrary("version");
        lib.linkSystemLibrary("oleaut32");
        lib.linkSystemLibrary("ole32");
    }

    lib.addCSourceFiles(.{ .files = sources.items });
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
