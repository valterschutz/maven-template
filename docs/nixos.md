# Running on NixOS

The generated `flake.nix` provides Maven and the JDK selected by `java_version`
for `x86_64-linux`. That JDK must be available in nixpkgs as `jdk<version>`.

It also sets `LD_LIBRARY_PATH` for X11, OpenGL, and the system graphics drivers.
GLFW dynamically loads these libraries; without their paths, raylib can report
`X11: Failed to load Xlib` and then crash.

## With direnv

Enable flakes in Nix and install direnv with nix-direnv integration (`use flake`).
The included `.envrc` loads the development shell automatically on NixOS when
`nix` is available. On other operating systems it does nothing.

## Without direnv

```sh
nix develop
```
