# C++ reference

C++20 as "C with a few templates": no standard library, no C++ headers, no
exceptions, no RTTI. The canonical source is `_ssg/base.cpp` in
`~/src/skeeto.github.com` (2026), which the user approved as looking like
his own work; read it directly when available. Older exemplars
(`~/src/scratch/misc/anagram.cpp`, `findpath.cpp`,
`~/src/scratch/w32bundle/common.cpp`) differ in details; prefer ssg.

## What C++ adds, and what it doesn't

Use:
- Templates only for foundations: `alloc<T>`, `Slice<T>`/`push`,
  `Map<V>`/`upsert`, `sort`, placement new, the `Str` literal constructor.
  Heavy templates make `-O0` builds slow; keep them few and shallow.
- Overloading for the same operation on different types (`print(Buf *, Str)`,
  `print(Buf *, i64)`); variants get a suffix instead (`printhex`,
  `printhtml`). Callers cast explicitly: `print(b, (i64)n)`.
- `operator[]` (bounds-asserting) and `operator==` (returning `bool`, so
  C++20 synthesizes `!=`). No other operators, no methods.
- Default member initializers (`= {}`), `X() = default;`, simple
  non-side-effecting constructors (`Str`, `Buf`), default arguments.
- `constexpr` only where needed (the `Str` constructors), `[[noreturn]]`,
  `static_assert`, `enum : i32 {...}` for constants, raw string literals
  `R"(...)"` for templates of text.

Avoid: `std::`, `#include <...>` in the core, `class`/`public`/`private`,
`virtual`, methods, destructors, RAII, references in APIs (pointers for
out-parameters; references only where the language forces them, as in the
array-literal constructor), `auto`, lambdas, range-for, iterators,
`enum class`, `nullptr` (write `0`), `true`/`false` (write `1`/`0` with
`b32`), exceptions, `new`/`delete` expressions other than placement new.

## Base (from ssg's base.cpp, verbatim)

```cpp
using u8   = unsigned char;
using b32  = decltype(0);
using i32  = decltype(0);
using u32  = decltype(0u);
using i64  = decltype(0ll);
using u64  = decltype(0ull);
using iz   = decltype((u8 *)0 - (u8 *)0);
using uz   = decltype(sizeof(0));
using byte = decltype('0');

#define assert(c)   while (!(c)) __builtin_unreachable()
#define countof(a)  (iz)(sizeof(a) / sizeof(*(a)))

template<typename T>
void *operator new(uz, T *p) noexcept { return p; }

struct Arena {
    byte *beg = {};
    byte *end = {};
};

// Provided by the platform layer: report out-of-memory and exit.
[[noreturn]] static void os_oom();

template<typename T>
static T *alloc(Arena *a, iz count = 1)
{
    iz size = sizeof(T);
    iz pad  = -(uz)a->beg & (alignof(T) - 1);
    if (count >= (a->end - a->beg - pad)/size) {
        os_oom();
    }
    T *r = (T *)(a->beg + pad);
    a->beg += pad + count*size;
    for (iz i = 0; i < count; i++) {
        new (r+i) T();
    }
    return r;
}

// Like alloc<u8>, but does not zero the memory.
static u8 *allocbytes(Arena *a, iz count)
{
    if (count > a->end - a->beg) {
        os_oom();
    }
    u8 *r = (u8 *)a->beg;
    a->beg += count;
    return r;
}

static void copybytes(void *dst, void *src, iz len)
{
    if (len) __builtin_memcpy(dst, src, (uz)len);
}
```

- `decltype` derives the types from the language, so no header is needed.
  `using c16 = decltype(u'0');` when UTF-16 is needed (Win32).
- The templated placement `operator new` avoids `<new>` and doesn't clash
  with it if a platform layer pulls in system headers.
- `new (r+i) T()` value-initializes: zero, plus default member initializers.
- `os_oom` is the one platform function without a context, because `alloc`
  calls it. Alternatives: an `oom` jump buffer in the arena with
  `__builtin_longjmp`, for libraries and fuzzing.

## Strings

```cpp
struct Str {
    union {
        u8         *data = 0;
        char const *cdata;
    };
    iz len = 0;

    Str() = default;

    constexpr Str(u8 *data, iz len) : data{data}, len{len} {}

    template<iz N>
    constexpr Str(char const (&s)[N]) : cdata{s}, len{N-1} {}

    u8 &operator[](iz i)
    {
        assert(i >= 0 && i < len);
        return data[i];
    }

    bool operator==(Str s)
    {
        return len==s.len && (!len || !__builtin_memcmp(data, s.data, (uz)len));
    }
};
```

- The union lets the literal constructor stay `constexpr` (no cast), so
  static tables like `static Str names[] = {"a", "b"};` are constant
  initialized on every compiler. Literals convert implicitly: `print(b, "x")`,
  `s == "---"`.
- `Str{}` (null data) means absent/failure: `if (!src.data)`, `return {};`.
  `Str{(u8 *)"", 0}` is present but empty.

Helpers (bodies in base.cpp; same style as the C reference):

```cpp
static Str span(u8 *beg, u8 *end)       { return {beg, end - beg}; }
static Str takehead(Str s, iz n);       // assert 0 <= n <= len
static Str cuthead(Str s, iz n);
static Str taketail(Str s, iz n);       // cuthead(s, s.len-n)
static Str cuttail(Str s, iz n);        // takehead(s, s.len-n)
static b32 startswith(Str s, Str prefix);
static b32 endswith(Str s, Str suffix);
static i32 compare(Str a, Str b);       // like memcmp, byte-wise
struct Cut { Str head; Str tail; b32 ok; };
static Cut cut(Str s, u8 c);
static iz  find(Str s, Str needle);     // -1 if not found
static Str trim(Str s);                 // also trimleft, trimright
static Str clone(Arena *a, Str s);      // allocbytes + copybytes
static Str concat(Arena *a, Str head, Str tail);  // in place at arena front
static u64 hash(Str s);                 // 0x100 basis, 1111111111111111111u
static i32 utf8decode(Str s, iz *i);    // advances *i
```

```cpp
static Cut cut(Str s, u8 c)
{
    Cut r = {};
    iz  i = 0;
    for (; i < s.len && s[i] != c; i++) {}
    r.ok   = i < s.len;
    r.head = takehead(s, i);
    r.tail = cuthead(s, i+r.ok);
    return r;
}
```

## Slices and maps

```cpp
template<typename T>
struct Slice {
    T *data = {};
    iz len  = {};
    iz cap  = {};

    T &operator[](iz i)
    {
        assert(i >= 0 && i < len);
        return data[i];
    }
};

template<typename T>
static Slice<T> push(Arena *a, Slice<T> s, T v)
{
    if (s.len == s.cap) {
        if (!s.data || (byte *)(s.data+s.cap) != a->beg) {
            T *data = alloc<T>(a, s.cap);
            for (iz i = 0; i < s.len; i++) {
                data[i] = s.data[i];
            }
            s.data = data;
        }
        iz extend = s.cap ? s.cap : 8;
        alloc<T>(a, extend);
        s.cap += extend;
    }
    s.data[s.len++] = v;
    return s;
}

// Hash trie keyed by strings. With a null arena, lookup only.

template<typename V>
struct Map {
    Map *child[4];
    Str  key;
    V    val;
};

template<typename V>
static V *upsert(Map<V> **m, Str key, Arena *a)
{
    for (u64 h = hash(key); *m; h <<= 2) {
        if ((*m)->key == key) {
            return &(*m)->val;
        }
        m = &(*m)->child[h>>62];
    }
    if (!a) {
        return 0;
    }
    *m = alloc<Map<V>>(a);
    (*m)->key = key;
    return &(*m)->val;
}
```

- Usage: `list = push(perm, list, item);`,
  `Post **slot = upsert(&byurl, url, perm); if (*slot) {...dup...} *slot = p;`.
- Sorting: a stable merge sort with a function-pointer comparator and a
  scratch arena, `sort(T *a, iz n, b32 (*less)(T *, T *), Arena scratch)`.

## Output: arena-growing Buf

For programs that build whole outputs in memory (generators, compilers):

```cpp
struct Buf {
    u8    *data = {};
    iz     len  = {};
    iz     cap  = {};
    Arena *a    = {};

    Buf() = default;
    Buf(Arena *a, iz cap = 1<<12) : data{allocbytes(a, cap)}, cap{cap}, a{a} {}
};

static void reserve(Buf *b, iz need)
{
    if (b->cap - b->len >= need) {
        return;
    }
    Arena *a = b->a;
    iz extend = b->cap > need ? b->cap : need;
    if ((byte *)(b->data+b->cap) == a->beg) {
        allocbytes(a, extend);
    } else {
        u8 *data = allocbytes(a, b->cap+extend);
        copybytes(data, b->data, b->len);
        b->data = data;
    }
    b->cap += extend;
}

static void print(Buf *b, Str s)
{
    reserve(b, s.len);
    copybytes(b->data+b->len, s.data, s.len);
    b->len += s.len;
}

static void putbyte(Buf *b, u8 c)
{
    reserve(b, 1);
    b->data[b->len++] = c;
}

static Str finish(Buf *b)
{
    return {b->data, b->len};
}
```

Limits without headers: `enum : i64 { I64MAX = (i64)((u64)-1 >> 1) };`
(or a small `maxof` constant per type actually used).

`print(Buf *, i64)` formats backwards from the negative side, as in the C
reference. Typical per-output scope:
`{ Arena tmp = scratch; Buf b(&tmp, 1<<16); render(&b, ...); write(finish(&b)); }`.
For streaming tools, use the flushing `Output` design from the C reference
with a sticky `err` flag instead, translated directly: same fields, `Output`
allocated with `alloc<Output>(a)`, `print(Output *, Str)` overloads.

## Build flags

```
-std=c++20 -fno-exceptions -fno-rtti -fno-threadsafe-statics
-fno-asynchronous-unwind-tables -nostdlib++ (link)
Debug: -g3 -Wall -Wextra -Wconversion -Wno-sign-conversion
       -fsanitize=undefined -fsanitize-trap
```

One-command build: `c++ -std=c++20 -o prog main_posix.cpp`. Win32:
`c++ -std=c++20 -nostartfiles -o prog.exe main_win32.cpp`. See
[platform.md](platform.md) for CMake and the platform layers.

## Speculative ideas from the posts (not adopted in code)

The 2025 posts discuss `return new(r) T[count]{}` (provenance-clean,
requires the exact `operator new[](size_t, void *)`) and arenas that run
non-trivial destructors via a LIFO `Dtor` list. No real program uses them
yet; don't introduce them unless asked.
