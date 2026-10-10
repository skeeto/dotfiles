# Program architecture: unity builds and platform layers

Contents: unity build · platform API · memory setup · POSIX layer ·
CRT-free Win32 layer · freestanding Linux · test layer · fuzz layer ·
builds and flags · library APIs.

## Unity build

Each executable is one translation unit. Two shapes:

**Single file** (small tools: uuidgen.c, rexxd.c). The app is on top, then
the platform layers at the bottom, chosen by preprocessor:

```c
#if TEST
// ... virtual platform + test main
#elif __AFL_COMPILER
// ... fuzz main
#elif _WIN32
// ... CRT-free mainCRTStartup
#else  // POSIX
#include <unistd.h>
// ... main
#endif
```

Build lines go in the header:

```c
// w64dk: $ cc -nostartfiles -O2 -s -o prog.exe prog.c
// unix:  $ cc               -O2 -s -o prog     prog.c
// tests: $ cc -DTEST -g3 -fsanitize=undefined -fsanitize-trap prog.c
// fuzz:  $ afl-gcc-fast -g3 -fsanitize=undefined -fsanitize-trap prog.c
```

**Core plus platform files** (u-config, ssg). `prog.c` (or `prog.cpp`)
holds the core and `#include`s its modules. Each `main_<platform>.c` is
what you hand the compiler: it includes system headers it needs, then the
core, then implements the platform API. Typical set: `main_posix`,
`main_win32` (or `main_windows`), `main_test`, `main_fuzz`, optionally
`main_wasm`, `main_linux_amd64`. Keep pure helpers of a platform (UTF-16
conversion, command-line splitting) in their own includable file so the test
layer covers them on every host.

Why: no build system needed, any `static` function is testable and
fuzzable, the compiler sees everything, and amalgamation is trivial.

## Platform API

The core declares a short, documented prototype table near the top, under
a `// Platform API` heading, against an opaque context:

```c
typedef struct Plt Plt;
static b32  plt_open(Plt *, i32 fd, u8 *, b32 trunc, Arena *);  // open(2)
static i64  plt_seek(Plt *, i32 fd, i64, i32 whence);           // lseek(2)
static i32  plt_read(Plt *, u8 *, i32);                         // read(2)
static b32  plt_write(Plt *, i32 fd, u8 *, i32);                // write(2)
static void plt_exit(Plt *, i32);                               // _exit(2)
static i32  xxd(i32, u8 **, Plt *, byte *, iz);                 // main
```

or, with a comment line above each (ssg, C++):

```cpp
struct Os;

// Read an entire file into the arena. Returns a null string on failure.
static Str     os_read(Os *, Arena *, Str path);
// Create or truncate a file with the given contents.
static b32     os_write(Os *, Arena, Str path, Str data);
// List a directory, excluding "." and "..", symlinks, and special files.
static Dirent *os_list(Os *, Arena *, Str path);
// Write to standard output (1) or standard error (2).
static b32     os_print(Os *, i32 fd, Str);
```

Rules:
- The context comes first. Each platform defines `struct Plt`/`struct Os`
  (handles, flags, test state). No globals anywhere.
- The arena parameter documents lifetime: `Arena *` means the result is
  allocated there; `Arena` by value is scratch the platform may use freely
  (for C strings, wide paths) and is discarded.
- The platform does only raw OS work: read/write/list/seek/time/exit, plus
  encoding conversion at the boundary. Parsing, logic, buffering and
  formatting belong to the core.
- The application entry is a core function taking the context, raw memory,
  and arguments, returning the exit status:
  `static i32 app(i32 argc, u8 **argv, Plt *plt, byte *mem, iz cap)` or
  `static i32 app_main(Os *, Arena, Str *args, i32 nargs)`.
- Diagnostics are buffered in the core and printed at the end; write
  errors become a non-zero exit (sticky error flags).

## Memory setup

The platform obtains one block and hands it to the core:
- POSIX: `mmap(0, cap, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_ANON, -1, 0)`,
  or a single `malloc(cap)`, or `static u8 mem[1<<21];` for small tools.
- Win32: `VirtualAlloc(0, cap, MEM_COMMIT|MEM_RESERVE, PAGE_READWRITE)`.
- Freestanding: a static array, laundered so the compiler can't reason
  about it: `byte *mem = heap; asm ("" : "+r"(mem));`.

The core splits it as needed:

```cpp
// Split memory: permanent storage and a scratch region reset per task.
iz    cap     = mem.end - mem.beg;
Arena perm    = mem;
Arena scratch = mem;
perm.end    = mem.beg + cap/4*3;
scratch.beg = perm.end;
```

Long-running loops (watch modes, servers) restart each iteration from
copies of the same arenas, so memory never grows.

## POSIX layer

```cpp
static b32 writeall(i32 fd, Str s)
{
    for (iz off = 0; off < s.len;) {
        iz n = write(fd, s.data+off, (uz)(s.len-off));
        if (n < 0) {
            if (errno == EINTR) continue;
            return 0;
        }
        off += n;
    }
    return 1;
}
```

- Make C strings for syscalls in scratch (`cstr(&scratch, path)`).
- Read whole files: `open`, `fstat` (check `S_ISREG`), allocate `st_size`,
  loop `read`.
- Read stdin/pipes until EOF into the arena's free space, in chunks capped
  well below `INT_MAX` (macOS `read` fails with `EINVAL` above it), then
  commit what was read.
- Returning the status from `main` is fine; `_exit` skips libc teardown
  when exiting from deep inside (u-config's `os_fail`). OOM: write "prog: out of
  memory\n" to fd 2, `_exit(2)`.
- Convert `argv` to `Str` once in `main`.

## CRT-free Win32 layer

No `windows.h`, no CRT. Declare what you use. Imports may be any
**system** DLL: kernel32, plus whatever Mingw-w64 links by default with
`-nostartfiles` (shell32 under `-mconsole`, gdi32 and friends under
`-mwindows`), plus `-ladvapi32`, `-lws2_32`, etc. when a feature needs them.
What to keep out: **CRT DLLs** (msvcrt.dll, ucrtbase.dll, api-ms-win-crt-*)
and **toolchain DLLs** (libgcc_s*.dll, libwinpthread-1.dll, libstdc++-6.dll).
Check with `objdump -p prog.exe | grep 'DLL Name'` (or `peports`).

```c
// C23
#define W32 [[gnu::dllimport, gnu::stdcall]]
W32 b32     CloseHandle(uz);
W32 uz      CreateFileW(c16 *, i32, i32, uz, i32, i32, uz);
W32 void    ExitProcess[[noreturn]](i32);
W32 c16    *GetCommandLineW();
W32 b32     GetConsoleMode(uz, i32 *);
W32 uz      GetStdHandle(i32);
W32 b32     ReadFile(uz, u8 *, i32, i32 *, uz);
W32 byte   *VirtualAlloc(uz, iz, i32, i32);
W32 b32     WriteConsoleW(uz, c16 *, i32, i32 *, uz);
W32 b32     WriteFile(uz, u8 *, i32, i32 *, uz);
```

```cpp
// C++
#define W32(r, p) extern "C" __declspec(dllimport) r __stdcall p noexcept
W32(b32,    CloseHandle(uz));
W32(void,   ExitProcess[[noreturn]](i32));
W32(byte *, VirtualAlloc(uz, iz, i32, i32));
```

(Pre-C23 C: `#define W32(r) __declspec(dllimport) r __stdcall`.)

- Handles are integers (`uz`); DWORD is `i32`, BOOL is `b32`; unused pointer
  parameters are `uz` so `0` can be passed.
- Constants in an enum: `enum : i32 { GENERIC_READ = (i32)0x8000'0000, ... };`
  and `enum : uz { INVALID_HANDLE_VALUE = (uz)-1 };`. Structs hand-declared
  with short names and checked: `static_assert(sizeof(FindData) == 592);`.
- Entry point, never `main`:
  ```c
  [[gnu::force_align_arg_pointer]]  // C++: extern "C" __attribute((force_align_arg_pointer))
  void mainCRTStartup(void)
  {
      iz    cap = (iz)1<<28;
      byte *mem = VirtualAlloc(0, cap, MEM_COMMIT|MEM_RESERVE, PAGE_READWRITE);
      // ... convert GetCommandLineW() to UTF-8 args, set up Plt ...
      ExitProcess(app(...));
  }
  ```
- Parse `GetCommandLineW()` yourself (after UTF-8 conversion): backslashes
  are literal except before a quote, `""` inside quotes is a literal quote,
  the program name has no escapes. Small tools may use `CommandLineToArgvW`
  plus `WideCharToMultiByte(CP_UTF8, ...)`.
- `CommandLineToArgvW` (shell32, a system DLL) is fine, as in uuidgen. The
  hand parser over WTF-8 is preferable when exotic file names must
  round-trip exactly, since it preserves unpaired surrogates.
- Internally everything is UTF-8. Convert to UTF-16 at the boundary in
  scratch. Unpaired surrogates round-trip as WTF-8. Make paths absolute and
  extended-length (`\\?\`, `\\?\UNC\`) via `GetFullPathNameW` so MAX_PATH
  never applies.
- Console output: for human-readable text (messages, paths), if
  `GetConsoleMode` succeeds, convert to UTF-16 and `WriteConsoleW` (correct
  regardless of code page); otherwise `WriteFile` the UTF-8 bytes. Tools
  whose output is data (rexxd) just `WriteFile` bytes.
  `GetStdHandle(-10 - fd)` maps fd 0/1/2. ssg's `os_print` in
  `_ssg/main_win32.cpp` and `_ssg/wide.cpp` (UTF-16 conversion, `\\?\`
  paths, command-line splitting) are the reference implementations.
- Chunk large I/O to `i32` lengths (e.g. 1<<21 per call).
- GCC still emits `memcpy`/`memset` (and at `-O0`, `memcmp`) calls. Either
  link w64devkit's `-lmemory` (exists only in w64devkit), or define them in
  the Win32 layer as ssg does (`rep movsb`/`rep stosb` asm on x86, simple
  loops for `memcmp`/`memchr`), building with `-fno-builtin` where a
  definition could turn into a self-call. Otherwise `-nostartfiles` quietly
  imports them from msvcrt.dll, a CRT DLL, which is what this style avoids.
- Avoid stack frames over a page (`___chkstk_ms`); use scratch instead.
- Keep XP compatibility in mind when cheap (e.g. retry `FindFirstFileExW`
  with basic flags on `ERROR_INVALID_PARAMETER`).
- Flags: `cc -nostartfiles -o prog.exe main_win32.c` (docs, dummy-proof;
  add `-ladvapi32` etc. as needed), or `-nostdlib -lkernel32 ...
  -Wl,--gc-sections -s` for guarantees; C++ adds `-static-libgcc` so libgcc
  helpers (e.g. 64-bit division on i686) don't pull in a toolchain DLL.

## Freestanding Linux (optional, "mostly for fun")

```c
asm (
    "        .globl _start\n"
    "_start: mov   %rsp, %rdi\n"
    "        call  entrypoint\n"
);

[[gnu::used]]
static void entrypoint(uz *stack)
{
    i32   argc = (i32)*stack;
    u8  **argv = (u8 **)(stack+1);
    // ...
    asm volatile ("syscall" :: "a"(SYS_exit), "D"(r));
    __builtin_unreachable();
}
```

Build: `cc -static -ffreestanding -nostdlib -Oz -s`.

## Test layer

A platform whose `os_*` functions are stubs or a virtual file system in
memory, so tests never touch real files and the real entry point can run
many times in one process.

ssg style (count and continue):

```cpp
struct Os {};
static Str os_read(Os *, Arena *, Str) { return {}; }
static b32 os_print(Os *, i32 fd, Str s)
{
    return fwrite(s.data, 1, (uz)s.len, fd==1 ? stdout : stderr) == (uz)s.len;
}
[[noreturn]] static void os_oom() { __builtin_trap(); }

struct Test {
    Arena perm;
    i32   run;
    i32   failed;
};

// Compare strings, printing both on mismatch.
static b32 expect(Test *t, Str name, Str got, Str want);
```

Tests are table-driven (`struct { Str in; Str want; } cases[] = {...};`),
each test copies the arena by value (`Arena a = t->perm;`), and results are
rendered to strings so every check is a string comparison. `main` prints
"N tests, M failed" and returns non-zero on failure.

rexxd/u-config style (trap immediately, for the debugger):

```c
#define expect(r, s, ...) \
    do { \
        if (!(plt->status = setjmp(*plt->oom))) { \
            char *argv[] = {"prog", __VA_ARGS__, 0}; \
            i32 argc = countof(argv) - 1; \
            plt->status = app(argc, (u8 **)argv, plt, a.beg, a.end-a.beg); \
        } \
        affirm(r == plt->status); \
        affirm(r!=STATUS_OK || equals(plt->output, S(s))); \
    } while (0)
```

`plt_exit` and OOM `longjmp` back to the test. Print progress to stderr
(unbuffered), since a trap loses buffered stdout. Fill arenas with a pattern
(`0x55`) before each run to catch reads of uninitialized memory. Print
"all tests passed" on success.

## Fuzz layer (AFL++)

```c
#include <unistd.h>  // after the core, so it isn't visible to it

__AFL_FUZZ_INIT();

int main(void)
{
    __AFL_INIT();
    iz    cap = 1<<16;  // small: pathological inputs hit OOM fast
    byte *mem = malloc(cap);
    u8   *buf = __AFL_FUZZ_TESTCASE_BUF;
    u8   *src = 0;
    while (__AFL_LOOP(10000)) {
        iz len = __AFL_FUZZ_TESTCASE_LEN;
        src = realloc(src, (uz)len);  // copy so ASan sees overreads
        memcpy(src, buf, (uz)len);
        Arena a = {mem, mem+cap};
        // ... setjmp for exit/OOM, then call the parser on (src, len) ...
    }
}
```

Build with `afl-gcc-fast -g3 -fsanitize=undefined -fsanitize-trap` (or
`address,undefined`). Persistent mode, one arena reset per input.

## Builds and flags

- Plain command first: `cc -o prog main_posix.c`. A Makefile or CMake is
  for development conveniences (tests, cross builds), never required.
- Debug (the normal development build):
  `-g3 -Wall -Wextra -Wconversion -Wno-sign-conversion
  -fsanitize=undefined -fsanitize-trap`
  (older GCC: `-fsanitize-undefined-trap-on-error`). Failed asserts trap.
- Release: `-O2` (or `-Os`/`-Oz` for small tools), `-s`. Debug builds should
  stay fast: `-O0` within about 2x of release is expected in this style.
- C++: `-std=c++20 -fno-exceptions -fno-rtti -fno-threadsafe-statics
  -fno-asynchronous-unwind-tables`, link `-nostdlib++`.

CMake, when wanted (ssg's pattern):

```cmake
cmake_minimum_required(VERSION 3.20)
project(prog LANGUAGES CXX)

# Unity build: each executable is a single translation unit, a platform
# layer that includes the portable core. No C++ runtime library,
# exceptions, or RTTI.

include(CheckCXXCompilerFlag)
include(CheckLinkerFlag)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

add_compile_options(
  -fno-exceptions -fno-rtti -fno-threadsafe-statics
  -fno-asynchronous-unwind-tables
  -Wall -Wextra -Wconversion -Wno-sign-conversion
  -Wno-unused-parameter -Wno-unused-function
)

# Debug builds trap on undefined behavior, which includes failed asserts.
check_cxx_compiler_flag(-fsanitize-trap HAS_TRAP)
if(HAS_TRAP)
  set(TRAP -fsanitize=undefined -fsanitize-trap)
else()
  set(TRAP -fsanitize=undefined -fsanitize-undefined-trap-on-error)
endif()
add_compile_options("$<$<CONFIG:Debug>:-g3;${TRAP}>")
add_link_options("$<$<CONFIG:Debug>:${TRAP}>")

check_linker_flag(CXX -nostdlib++ HAS_NOSTDLIBXX)
if(HAS_NOSTDLIBXX)
  add_link_options(-nostdlib++)
endif()

if(WIN32)
  add_executable(prog main_win32.cpp)
  target_link_options(prog PRIVATE -nostartfiles -static-libgcc)
  target_link_libraries(prog PRIVATE kernel32)
else()
  add_executable(prog main_posix.cpp)
endif()

if(NOT CMAKE_CROSSCOMPILING)
  enable_testing()
  add_executable(prog_test main_test.cpp)
  add_test(NAME unit COMMAND prog_test)
endif()
```

## Library APIs

When writing a library for others:
- Let callers supply memory. Simplest: accept an arena (`Arena *perm` for
  results, `Arena scratch` by value for temporaries), or a raw buffer.
- If an allocator interface is needed: every function takes a user context
  pointer; free receives the original size; realloc receives old and new
  sizes; sizes are signed. Model it on Lua's `lua_Alloc(ctx, ptr, old, new)`.
- No global state, no hidden allocation, no I/O; return results in structs.
- A library meant to be `#include`d into someone else's unity build should
  prefix its public names (`iniparse`, `iniget`) and guard its copy of the
  base block so a host that already has one can skip it
  (`#ifndef INI_HOSTBASE`). Internal helpers may stay short.
