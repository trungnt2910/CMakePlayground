# CMakePlayground

[![Discord Invite](https://img.shields.io/discord/1185622479436251227?logo=discord&logoColor=white&label=Discord&labelColor=%235865F2)](https://discord.gg/bcV3gXGtsJ)

### **This repository is no longer maintained. Changes have been integrated into [lxmonika][3].**

[3]: https://github.com/trungnt2910/lxmonika

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
   - Currently a [fork](https://github.com/trungnt2910/llvm-mingw) with
     [ARM SEH support](https://github.com/llvm/llvm-project/pull/184953) is required.
   - The toolchain is automatically fetched by the build script.
- Generator: `Ninja`.
- IDE: Visual Studio Code
- Linter: `clangd`
    - Intellisense has bugs when dealing with `wchar_t` and `std::wstring`.
- WDK & Win10 SDK.
   - 22621 for building 32-bit targets (x86, ARM).
   - The latest (currently tested on 26100) for building 64-bit targets (x64, ARM64).

## Supported Projects

- [ ] Core LxMonika Tools
  - [x] `monika.exe` CLI
  - [x] `lxstub` Stub Driver
  - [x] `lxmonika` Driver
  - [ ] 32-bit ARM support
        (blocked by [LLVM SEH support](https://github.com/llvm/llvm-project/pull/184953))
- [x] `mxss` Monix Example
  - [x] `mxhost` Monix Host CLI
  - [x] `mxss` Monix Kernel Driver
  - [x] `monix` Monix Userland Subproject
- [x] CI

## TODO

- Merge this repo into `lxmonika`.

## Community

This repo is a part of [Project Reality](https://discord.gg/bcV3gXGtsJ).

Need help using this project? Join me on [Discord](https://discord.gg/bcV3gXGtsJ), and let's find a
solution together.
