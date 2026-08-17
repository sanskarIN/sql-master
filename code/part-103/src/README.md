# SQL Full Mastery - Part 103 Companion Code

Author: Ram Sandesh  
Part: 103 - C/C++ Database APIs and Embedded SQLite

## Requirements

- CMake 3.20 or newer
- A C17 and C++20 compiler
- SQLite development package

### Ubuntu/Debian

```bash
sudo apt update
sudo apt install build-essential cmake libsqlite3-dev
```

### macOS with Homebrew

```bash
brew install cmake sqlite
```

### Windows with vcpkg

```powershell
vcpkg install sqlite3:x64-windows
cmake -S . -B build -DCMAKE_TOOLCHAIN_FILE=C:/path/to/vcpkg/scripts/buildsystems/vcpkg.cmake
cmake --build build --config Release
```

## Build

```bash
cmake -S . -B build
cmake --build build
```

Run `sqlite_c_example` and `sqlite_cpp_raii` from the build directory. Each program creates its own local SQLite database file.

Official store: https://ramsandesh.gumroad.com
