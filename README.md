# GLFW Zig

GLFW ported to the Zig build system.

Contributions or bug reports are welcome if behavior differs from official build system.

A notable addition to the official options is `provide_headers`, which fetches all windowing headers not already provided by Zig from the official sources, enabling cross compilation. macOS frameworks are not provided. This option defaults to true.

## Version

See [build.zig.zon](build.zig.zon) for current version info.

## Known Differences

* The library is always called libglfw3, in contrast with the official build process which sometimes names it libglfw3 and sometimes names it libglfw.
* Tests, documentation, and examples are not built.
* Some mingw build workarounds are not ported.
* The official build process gives shared library artifacts an icon, that is not done here.

## Known Issues

Microsoft shuffled the button layouts for some of their controllers in a recent firmware update breaking existing mappings on Linux. This has been [patched](https://github.com/mdqinc/SDL_GameControllerDB/pull/764) in `SDL_GameControllerDB`, which GLFW should pull in on the next release.

In the mean time, you can manually apply the patch at runtime:
```zig
if (c.glfwUpdateGamepadMappings(
    \\030000005e040000120b00000f050000,Xbox Series Controller,a:b0,b:b1,back:b6,dpdown:h0.4,dpleft:h0.8,dpright:h0.2,dpup:h0.1,guide:b8,leftshoulder:b4,leftstick:b9,lefttrigger:a2,leftx:a0,lefty:a1,rightshoulder:b5,rightstick:b10,righttrigger:a5,rightx:a3,righty:a4,start:b7,x:b2,y:b3,platform:Linux,
    \\030000005e040000120b000015050000,Xbox Series Controller,a:b0,b:b1,back:b6,dpdown:h0.4,dpleft:h0.8,dpright:h0.2,dpup:h0.1,guide:b8,leftshoulder:b4,leftstick:b9,lefttrigger:a2,leftx:a0,lefty:a1,rightshoulder:b5,rightstick:b10,righttrigger:a5,rightx:a3,righty:a4,start:b7,x:b2,y:b3,platform:Linux,
) != c.GLFW_TRUE) {
    log.warn("glfwUpdateGamepadMappings failed", .{});
}
```

## How To Change the GLFW Version

The version of GLFW is set in [build.zig.zon](build.zig.zon).

The official build process for GLFW generates some files at build time. These have been cached in `generated`, when changing GLFW versions you may have to regenerate them via the official build process.
