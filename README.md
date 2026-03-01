# CMakePlayground

[![Discord Invite](https://img.shields.io/discord/1185622479436251227?logo=discord&logoColor=white&label=Discord&labelColor=%235865F2)](https://discord.gg/bcV3gXGtsJ)

A playground for moving [lxmonika](https://github.com/trungnt2910/lxmonika) to non-Microsoft build
tools.

This is a **temporary playground**. Changes will eventually be reflected into the main `lxmonika`
repository.

## Why?

Microsoft is annoying because:
- They are generally slower to ship new C++ features.
- They constantly deprecate platforms, such as x86 and 32-bit ARM.

Moving away from Microsoft tools prevents us from having to maintain hacks for older Windows 10
builds and older C++ versions.

## Recommended Setup

- OS: Windows 10
- Compiler: Latest build of [**@mstorsjo**'s `llvm-mingw`](https://github.com/mstorsjo/llvm-mingw)
   - The `bin` folde should be in the system `PATH`.
- Generator: `Ninja`.
- IDE: Visual Studio Code
- Linter: `clangd`
    - Intellisense has bugs when dealing with `wchar_t` and `std::wstring`.

## Supported Projects

- [ ] Core LxMonika Tools
  - [x] `monika.exe` CLI
  - [ ] `lxstub` Stub Driver
  - [ ] `lxmonika` Driver
- [ ] `mxss` Monix Example
  - [ ] `mxhost` Monix Host CLI
  - [ ] `mxss` Monix Kernel Driver
  - [ ] `monix` Monix Userland Subproject

## TODO

- Figure out how to use `MinGW`/`clang`/`CMake` with Windows Kernel Mode drivers.
- Write scripts
    - Pack build artifacts
    - Setup compiler toolchain
- CI builds

## Community

This repo is a part of [Project Reality](https://discord.gg/bcV3gXGtsJ).

Need help using this project? Join me on [Discord](https://discord.gg/bcV3gXGtsJ), and let's find a
solution together.
