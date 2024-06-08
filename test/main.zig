const std = @import("std");

const sdl = @cImport({
    @cInclude("SDL3/SDL.h");
});

pub fn main() !void {

    var done = false;

    if (sdl.SDL_Init(sdl.SDL_INIT_VIDEO) != 0) {
        return error.SDLInit;
    }

    std.debug.print("SDL INITIALIZED ", .{});

    const window = sdl.SDL_CreateWindow("window", 800, 600, 0);

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
