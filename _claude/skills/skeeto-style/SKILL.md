---
name: skeeto-style
description: Write C or C++ in Chris Wellons' (skeeto, nullprogram.com) personal style — arena allocation, counted strings, signed sizes, unity builds with platform layers, no standard library in the core, CRT-free Win32. Use this whenever starting a new C or C++ program, tool, or library for this user, whenever they say "my style", "skeeto style", "the usual style", or mention arenas, scratch/perm arenas, Str/s8 strings, hash tries, unity builds, platform layers, os_*/plt_* APIs, CRT-free or w64devkit builds, or "no std library". Also use it when extending a project that already follows this style (look for `alloc`/`new(a, n, t)`, `Str`, `iz`, `affirm`/`assert` via `__builtin_unreachable`, `main_*.c` platform files). Do not impose it on third-party codebases with their own conventions.
---

# skeeto style for C and C++

This is the house style of Chris Wellons, distilled from his blog posts and
recent programs (u-config, w64devkit tools such as rexxd and uuidgen, and the
ssg site generator). The goal is code he would read and think he wrote: not
just compiling and correct, but organized, named and formatted his way, with
the same instincts about memory, errors and portability.

The user has this style internalized, so deviations stand out immediately.
When unsure between a "conventional" choice and the style here, pick the style
here. When the surrounding code of an existing project disagrees with this
skill, follow the surrounding code (it may be older or deliberately different).

## Pick the shape first

1. **Language.** C (C23 preferred; C11/C17 if the project requires) or C++
   (C++20, used as "C with a few templates"). Read the matching reference:
   - C: [references/c.md](references/c.md)
   - C++: [references/cpp.md](references/cpp.md)
2. **Program shape.** Read [references/platform.md](references/platform.md)
   for anything beyond a toy: it covers the unity build, the platform API,
   POSIX/Win32/test/fuzz layers and build flags.
   - *Small tool:* one `.c` file. The portable app sits on top, platform
     layers at the bottom in `#if _WIN32 / #elif TEST / #else // POSIX`
     branches (as in uuidgen.c, rexxd.c).
   - *Larger program:* a core file (`prog.c`/`prog.cpp`) that `#include`s
     its modules, plus one `main_<platform>.c` per platform that includes the
     core and implements the platform API (as in u-config, ssg).
3. **Copy the foundation, don't reinvent it.** The references contain the
   canonical base definitions (types, arena, strings, slices, maps, output).
   Paste the parts the program needs, verbatim, then build on them. Only
   include what is used; a 200-line tool doesn't need a hash trie.

## Core principles (and why)

**Arenas own all memory.** Get one big block from the platform at startup
(`mmap`, `VirtualAlloc`, or a static array) and bump-allocate from it. Never
`free`, never `malloc` in the core, no destructors, no leak checkers.
Lifetimes are grouped instead of tracked, which removes whole classes of
bugs and most error paths.
- `Arena *perm` (by pointer): the callee's results live there and persist.
- `Arena scratch` (by value): temporaries; the copy is discarded on return,
  so everything allocated in it is freed on every return path automatically.
  "perm" is relative: a caller may pass its own scratch as a callee's perm.
- Per-iteration reset: `for (...) { Arena tmp = scratch; ... }`.
- Allocation zeroes memory and never returns null. Out-of-memory is handled
  non-locally (print "prog: out of memory" and exit, trap, or longjmp), so
  callers never check allocations.
- Design every struct so that **zero is a valid, empty state**: empty string,
  empty slice, empty map (null root), unset flags.

**Counted strings, never null-terminated.** A string is `{u8 *data; iz len}`
passed by value. Null-terminated strings exist only at the OS boundary, made
in a scratch arena right before the syscall. Null `data` means "absent",
distinct from an empty-but-present string.

**Signed sizes.** All sizes, lengths, counts and subscripts are `iz`
(`ptrdiff_t`). Unsigned (`uz`, `u32`, `u64`) only for hashing, bit
manipulation and external interfaces. Check ranges *before* arithmetic:
`if (count > (end-beg)/size)`, not after an overflow. Compare integers,
never out-of-bounds pointers.

**No standard library in the core.** The portable core includes nothing
beyond `<stddef.h>`/`<stdint.h>` (C) or nothing at all (C++). Use
`__builtin_memcpy`/`__builtin_memset`/`__builtin_memcmp` where needed. All
OS interaction goes through a small, documented platform API (`os_*` or
`plt_*`) that each platform layer implements. No global state: an opaque
`Os`/`Plt` context is threaded through.

**Unity builds.** One translation unit per executable. Every function is
`static` except entry points. No project headers. A program builds with one
compiler command, written in the file header comment.

**Assertions trap.** `assert`/`affirm` is `while (!(c)) __builtin_unreachable()`.
Debug builds use `-fsanitize=undefined -fsanitize-trap`, so a failed
assertion stops in the debugger exactly on the line; release builds get an
optimization hint. Assertions are for invariants only, never for runtime
errors such as a missing file. (Asserting the arena never runs out is
acceptable only when inputs are bounded so that it truly cannot.)

**Return values, not out-parameters.** Return small structs
(`{value; ok}`, `Cut {head; tail; ok}`). A function builds a zeroed result
`r`, returns it early on failure, sets `r.ok = 1` at the end.

**Bespoke, small data structures.** A 4-ary hash trie, an MSI hash table, an
intrusive linked list or a slice, written in 10-30 lines and fitted to the
problem. No generic container library, no macro-heavy generics.

**Output is appending.** Buffered output with print-like functions per type
(`print`, `printi64`, `printhex`, ...) and a sticky error flag checked once at
the end. No printf-style format strings.

**Speed matters, including debug builds.** Generation/run time first, build
time second, code size third. Keep templates and macros minimal so `-O0`
builds stay usable (a few times slower than release, not 10x) and compile
in a blink.

## Formatting

- 4-space indent. Function opening brace on its own line; all other braces
  K&R. Return type on the same line as the name.
- `static` everything except entry points. Struct types are `Capitalized`
  (`Arena`, `Str`, `Cut`, `Output`); functions and variables are short,
  lowercase, run-together words without underscores (`takehead`, `newoutput`,
  `printi64`, `parsefrontmatter`). Platform functions get an `os_`/`plt_`
  prefix. A helper behind a macro gets a trailing underscore (`push_`).
- Constants are `ALL_CAPS` enumerators in an `enum`, not `#define`.
  Function-like macros are lowercase one-liners (`new`, `countof`, `S`).
- Align columns: struct members, runs of declarations, and runs of
  assignments (`r.ok   = ...;` / `r.head = ...;`), and aligned prototype
  tables with a trailing or preceding `//` comment each.
- Tight operators inside compound conditions and subexpressions
  (`a.len==b.len && *p!=c`, `x<0 ? x : -x`, `h>>62`), normal spacing in
  simple statements and loop headers (`for (iz i = 0; i < n; i++)`).
- Empty loop bodies are `{}`: `for (; i<len && s[i]!=c; i++) {}`.
  Infinite loops are `for (;;)`. One-line guards are fine:
  `if (d) return d;`.
- `case` labels at the same indent as `switch`; short cases on one line.
- `//` comments only, short and plain. A comment above a function states its
  contract; trailing comments note units or edge cases (`// -1 if not found`).
- File header: `// name: one-line purpose`, then build commands
  (`// $ cc -o prog main_posix.c`), optional notes, and finally
  `// This is free and unencumbered software released into the public domain.`
- Sections are separated by two blank lines and a bare comment heading
  (`// Strings`, `// Platform API`).
- About 80 columns, more only for tables and literals.
- Designated initializers are fine in moderation (static tables,
  `Cut c = {.tail=s, .ok=1}`). For building up results, the usual form is
  a zeroed `r` filled by sequenced assignments.
- Literal `0` for null pointers (never `NULL`/`nullptr`), `0`/`1` for `b32`.
- No `const` (except where the language requires it, e.g. a C++ string
  literal parameter, or to place a static table in read-only memory).

## Things he rejects

Don't write these, even though they are common elsewhere:
- `malloc`/`free` pairs, `realloc` growth, null checks after allocation,
  RAII/destructors, `std::` anything, exceptions, RTTI, `virtual`, `class`
  with `private`, methods (except `operator[]`/`operator==`), `auto`,
  lambdas, references in APIs, `enum class`, iterators, range-for.
- Null-terminated string handling (`strlen`, `strcpy`, `strcat`, `sprintf`),
  `printf` for program output, `<string.h>`, `<stdio.h>` in the core.
- `size_t` lengths, mixed signed/unsigned arithmetic, raw `sizeof`
  arithmetic outside the allocator, `_Bool`, `int_fast32_t`, `_t` typedef
  names in real code.
- `const` sprinkled for "safety", `NULL`, out-parameters.
- `alloca`, VLAs, large stack arrays (more than ~1 KiB: use scratch).
- `windows.h`: declare the few Win32 functions needed by hand.
- libc `assert`, assertions for error handling.
- Big generic macro libraries, stretchy buffers, `alloc_size` attributes.
- Pointer-overflow bounds checks (`p += n; if (p > end)`), which are UB.

## Pitfalls seen in practice

- **Scratch copied from perm overlaps perm.** `Arena tmp = *perm;` shares
  memory with whatever `perm` allocates next. Finish with temporaries in
  `tmp` before allocating results into `*perm`, or allocate the result first
  and then take the scratch copy. In loops that do both, take a fresh
  `Arena t = *a;` per iteration *after* the previous result was committed.
- **In-place growth needs the arena front.** `concat`, `push` and `Buf`
  extend in place only while their data ends exactly at `a->beg`. Any
  interleaved allocation from the same arena forces a copy (correct, but
  wasteful). Build one growing object at a time, or give it its own arena.
- **`memcpy`/`memcmp` with a null pointer and zero length is UB** before
  C2y. Guard on the length (`if (len) ...`), not on the pointer, so a null
  pointer with a nonzero length still trips UBSan.
- **Null plus zero is UB in C** (fine in C++). Advancing a null `Str` by 0
  (`cuthead`, `{.tail=s}` loops over a zero string) trips UBSan in C; guard
  with `if (!s.len) return s;` in helpers that offset `data`.
- **`__builtin_setjmp` is unsupported on some targets** (clang on arm64,
  i.e. Apple Silicon). For non-local OOM exits there, use the platform's
  `setjmp`/`longjmp` (the platform layer may include `<setjmp.h>`), exit
  through the platform, or return an error from a per-input capacity check.
- **C++ ternaries don't convert literals to `Str`.** `c ? "yes" : "no"` is
  `char const *`; write `c ? Str("yes") : "no"`.
- **Trap-style tests lose buffered stdout.** Write progress to stderr or
  flush before a check can trap.
- **Platform macros collide with field names.** mingw defines `stdin`,
  `stdout`, `stderr` as macros; don't use them as identifiers. Cross-compile
  the Windows layer to catch this.
- **Zeroing is part of the contract.** Code relies on fresh allocations being
  zero (maps, slices, result structs), so a non-zeroing allocator variant
  must be used deliberately (`allocbytes` for buffers about to be filled).

## Working method

- Write the platform API first as a short, commented prototype table in the
  core; implement the core against it; then write the platform layers. Add a
  `main_test` layer with stubbed `os_*` early, and a fuzz layer for any parser.
- Build and run the debug configuration (UBSan trapping) while developing.
  Keep `-Wall -Wextra -Wconversion -Wno-sign-conversion` clean. (In C,
  `-Wconversion` implies `-Wsign-conversion`, which the canonical `alloc`
  and `memcpy` calls trip on purpose; the style uses explicit `(uz)` casts
  only where it matters.)
- Apple clang defaults to an older C: put `-std=c23` in build lines when
  using C23 features (`{}`, `[[...]]`, `enum : T`), or write C11 (`{0}`,
  `__attribute((...))`) for maximum portability. C++ build lines carry
  `-std=c++20`.
- Use real exemplars when they exist on this machine, newest first:
  `~/src/skeeto.github.com/_ssg/` (C++, approved as the canonical C++ style),
  `~/src/w64devkit/src/uuidgen.c` and `rexxd.c` (newest single-file C),
  `~/src/u-config/` (multi-platform C with test and fuzz layers). Skip
  `w64devkit/src/make2compdb.c`: a contributor wrote it, not Wellons.
- Blog posts write `ptrdiff_t`, `char *`, `int32_t` for self-contained
  exposition; real code uses the short typedefs. Generate the real-code form.
