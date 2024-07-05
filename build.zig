const std = @import("std");
const flags = [_][]const u8{"-Wall"};

const wayland_version = .{
    .major = 1,
    .minor = 23,
    .micro = 0,
};

const libxcursor_version = .{
    .major = 1,
    .minor = 2,
    .revision = 2,
};

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const windows = target.result.os.tag == .windows;
    const apple = target.result.os.tag == .ios or target.result.os.tag == .macos;
    const other = !windows and !apple;

    const build_win32 = b.option(bool, "build-win32", "Build support for Win32") orelse windows;
    const build_cocoa = b.option(bool, "build-cocoa", "Build support for Cocoa") orelse apple;
    const build_x11 = b.option(bool, "build-x11", "Build support for X11") orelse other;
    const build_wayland = b.option(bool, "build-wayland", "Build support for Wayland") orelse other;

    const vulkan_library = b.option(
        []const u8,
        "vulkan-library",
        "Override the default name of the Vulkan library",
    );
    const egl_library = b.option(
        []const u8,
        "egl-library",
        "Override the default name of the EGL library",
    );
    const glx_library = b.option(
        []const u8,
        "glx-library",
        "Override the default name of the GLX library",
    );
    const osmesa_library = b.option(
        []const u8,
        "osmesa-library",
        "Override the default name of the OSMesa library",
    );
    const opengl_library = b.option(
        []const u8,
        "opengl-library",
        "Override the default name of the OpenGL library",
    );
    const glesv1_library = b.option(
        []const u8,
        "glesv1-library",
        "Override the default name of the GLESv1 library",
    );
    const glesv2_library = b.option(
        []const u8,
        "glesv2-library",
        "Override the default name of the GLESv2 library",
    );

    const use_hybrid_hpg = b.option(bool, "use-hybrid-hpg",
        \\determines whether to export the `NvOptimusEnablement` and 
        \\`AmdPowerXpressRequestHighPerformance` symbols, which force the use of the 
        \\high-performance GPU on Nvidia Optimus and AMD PowerXpress systems. These symbols need to 
        \\be exported by the EXE to be detected by the driver, so the override will not work if 
        \\GLFW is built as a DLL
    ) orelse false;

    const shared = b.option(bool, "shared", "Build glfw as a shared library") orelse false;

    const provide_headers = b.option(
        bool,
        "provide-headers",
        "Provides headers necessary for cross compilation",
    ) orelse false;

    const glfw_upstream = b.dependency("glfw", .{});

    const glfw_info = .{
        .name = "glfw3",
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    };
    const glfw = if (shared) b.addSharedLibrary(glfw_info) else b.addStaticLibrary(glfw_info);

    if (glfw.linkage == .dynamic) glfw.root_module.addCMacro("_GLFW_BUILD_DLL", "1");

    if (build_win32) glfw.root_module.addCMacro("_GLFW_WIN32", "1");
    if (build_cocoa) glfw.root_module.addCMacro("_GLFW_COCOA", "1");
    if (build_x11) glfw.root_module.addCMacro("_GLFW_X11", "1");
    if (build_wayland) glfw.root_module.addCMacro("_GLFW_WAYLAND", "1");

    if (vulkan_library) |value| glfw.root_module.addCMacro("_GLFW_VULKAN_LIBRARY", value);
    if (egl_library) |value| glfw.root_module.addCMacro("_GLFW_EGL_LIBRARY", value);
    if (glx_library) |value| glfw.root_module.addCMacro("_GLFW_GLX_LIBRARY", value);
    if (osmesa_library) |value| glfw.root_module.addCMacro("_GLFW_OSMESA_LIBRARY", value);
    if (opengl_library) |value| glfw.root_module.addCMacro("_GLFW_OPENGL_LIBRARY", value);
    if (glesv1_library) |value| glfw.root_module.addCMacro("_GLFW_GLESV1_LIBRARY", value);
    if (glesv2_library) |value| glfw.root_module.addCMacro("_GLFW_GLESV2_LIBRARY", value);

    if (use_hybrid_hpg) glfw.root_module.addCMacro("_GLFW_USE_HYBRID_HPG", "1");

    glfw.addCSourceFiles(.{
        .root = glfw_upstream.path("src"),
        .files = &.{
            "context.c",
            "egl_context.c",
            "init.c",
            "input.c",
            "monitor.c",
            "null_init.c",
            "null_joystick.c",
            "null_monitor.c",
            "null_window.c",
            "osmesa_context.c",
            "platform.c",
            "vulkan.c",
            "window.c",
        },
        .flags = &flags,
    });

    if (apple) {
        glfw.addCSourceFiles(.{
            .root = glfw_upstream.path("src"),
            .files = &.{
                "cocoa_time.c",
                "posix_module.c",
                "posix_thread.c",
            },
            .flags = &flags,
        });
    } else if (windows) {
        glfw.addCSourceFiles(.{
            .root = glfw_upstream.path("src"),
            .files = &.{
                "win32_module.c",
                "win32_thread.c",
                "win32_time.c",
            },
            .flags = &flags,
        });
    } else {
        glfw.addCSourceFiles(.{
            .root = glfw_upstream.path("src"),
            .files = &.{
                "posix_module.c",
                "posix_thread.c",
                "posix_time.c",
            },
            .flags = &flags,
        });
    }

    if (build_cocoa) {
        glfw.addCSourceFiles(.{
            .root = glfw_upstream.path("src"),
            .files = &.{
                "cocoa_init.m",
                "cocoa_joystick.m",
                "cocoa_monitor.m",
                "cocoa_window.m",
                "nsgl_context.m",
            },
            .flags = &flags,
        });
    }

    if (build_win32) {
        glfw.addCSourceFiles(.{
            .root = glfw_upstream.path("src"),
            .files = &.{
                "wgl_context.c",
                "win32_init.c",
                "win32_joystick.c",
                "win32_monitor.c",
                "win32_window.c",
            },
            .flags = &flags,
        });
    }

    if (build_x11) {
        glfw.addCSourceFiles(.{
            .root = glfw_upstream.path("src"),
            .files = &.{
                "glx_context.c",
                "x11_init.c",
                "x11_monitor.c",
                "x11_window.c",
            },
            .flags = &flags,
        });
    }

    if (build_wayland) {
        glfw.addCSourceFiles(.{
            .root = glfw_upstream.path("src"),
            .files = &.{
                "wl_init.c",
                "wl_monitor.c",
                "wl_window.c",
            },
            .flags = &flags,
        });
    }

    if (build_x11 or build_wayland) {
        if (target.result.os.tag == .linux) {
            glfw.addCSourceFiles(.{
                .root = glfw_upstream.path("src"),
                .files = &.{
                    "linux_joystick.c",
                },
                .flags = &flags,
            });
        }

        glfw.addCSourceFiles(.{
            .root = glfw_upstream.path("src"),
            .files = &.{
                "posix_poll.c",
                "xkb_unicode.c",
            },
            .flags = &flags,
        });
    }

    if (build_win32) {
        glfw.linkSystemLibrary("gdi32");
    }

    if (build_cocoa) {
        glfw.linkFramework("Cocoa");
        glfw.linkFramework("IOKit");
        glfw.linkFramework("CoreFoundation");
    }

    if (provide_headers) {
        if (build_wayland) {
            if (b.lazyDependency("wayland", .{})) |wayland_upstream| {
                glfw.addSystemIncludePath(wayland_upstream.path("src"));
                const wayland_version_h = b.addConfigHeader(.{
                    .style = .{
                        .cmake = wayland_upstream.path("src/wayland-version.h.in"),
                    },
                    .include_path = "wayland-version.h",
                }, .{
                    .WAYLAND_VERSION_MAJOR = wayland_version.major,
                    .WAYLAND_VERSION_MINOR = wayland_version.minor,
                    .WAYLAND_VERSION_MICRO = wayland_version.micro,
                    .WAYLAND_VERSION = std.fmt.comptimePrint("{}.{}.{}", .{
                        wayland_version.major,
                        wayland_version.minor,
                        wayland_version.micro,
                    }),
                });
                glfw.addConfigHeader(wayland_version_h);
            }

            if (b.lazyDependency("xkbcommon", .{})) |xkbcommon_upstream| {
                glfw.addSystemIncludePath(xkbcommon_upstream.path("include"));
            }
        }

        if (build_x11) {
            if (b.lazyDependency("libX11", .{})) |xlib_upstream| {
                glfw.addSystemIncludePath(xlib_upstream.path("include"));
            }

            if (b.lazyDependency("xorgproto", .{})) |xorgproto_upstream| {
                glfw.addSystemIncludePath(xorgproto_upstream.path("include"));
            }

            if (b.lazyDependency("libXcursor", .{})) |lib_x_cursor| {
                const xcursor = b.addConfigHeader(.{
                    .style = .{
                        .autoconf = lib_x_cursor.path("include/X11/Xcursor/Xcursor.h.in"),
                    },
                    .include_path = "X11/Xcursor/Xcursor.h",
                }, .{
                    .XCURSOR_LIB_MAJOR = libxcursor_version.major,
                    .XCURSOR_LIB_MINOR = libxcursor_version.minor,
                    .XCURSOR_LIB_REVISION = libxcursor_version.revision,
                });
                glfw.addConfigHeader(xcursor);
            }

            if (b.lazyDependency("libXrandr", .{})) |xrandr_upstream| {
                glfw.addSystemIncludePath(xrandr_upstream.path("include"));
            }

            if (b.lazyDependency("libXrender", .{})) |xrender_upstream| {
                glfw.addSystemIncludePath(xrender_upstream.path("include"));
            }

            if (b.lazyDependency("libXinerama", .{})) |xinerama_upstream| {
                glfw.addSystemIncludePath(xinerama_upstream.path("include"));
            }

            if (b.lazyDependency("libXi", .{})) |xi_upstream| {
                glfw.addSystemIncludePath(xi_upstream.path("include"));
            }

            if (b.lazyDependency("libXext", .{})) |xext_upstream| {
                glfw.addSystemIncludePath(xext_upstream.path("include"));
            }

            if (b.lazyDependency("libXfixes", .{})) |xfixes_upstream| {
                glfw.addSystemIncludePath(xfixes_upstream.path("include"));
            }
        }
    }

    glfw.installHeadersDirectory(glfw_upstream.path("include/GLFW"), "GLFW", .{});

    glfw.addIncludePath(b.path("generated"));

    b.installArtifact(glfw);
}
