const std = @import("std");

const sdl = @cImport({
    @cInclude("SDL3/SDL.h");
    @cInclude("SDL3/SDL_vulkan.h");
});

pub fn main() !void {

    var done = false;

    if (sdl.SDL_Init(sdl.SDL_INIT_VIDEO) != 0) {
        std.log.err("error on init SDL {s}", .{sdl.SDL_GetError()});
        return error.SDLInit;
    }

    if (sdl.SDL_Vulkan_LoadLibrary(null) != 0) {
        std.log.err("error on SDL_Vulkan_LoadLibrary {s}", .{sdl.SDL_GetError()});
        return error.SDLVulkanError;
    }

    std.debug.print("SDL INITIALIZED ", .{});

    const window = sdl.SDL_CreateWindow("window", 1920, 1080, sdl.SDL_WINDOW_VULKAN | sdl.SDL_WINDOW_RESIZABLE);

    while (!done) {

        var event : sdl.SDL_Event = undefined;

        while (sdl.SDL_PollEvent(&event) != sdl.SDL_FALSE) {
            if (event.type == sdl.SDL_EVENT_QUIT) {
                done = true;
            }

            if (event.type == sdl.SDL_EVENT_WINDOW_CLOSE_REQUESTED and event.window.windowID != sdl.SDL_TRUE and sdl.SDL_GetWindowID(window) != 0) {
                done = true;
            }
        }
    }

    std.debug.print("SDL finalized ", .{});

    sdl.SDL_DestroyWindow(window);
    sdl.SDL_Quit();
}
