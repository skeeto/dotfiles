# C reference

The canonical definitions, newest form (w64devkit's uuidgen.c and rexxd.c,
2025). Copy what the program needs. Older code (u-config, 2023 posts) uses
`s8`/`s8("...")`, `size`, `assert`, `new(a, t, n)` and `{0}`; when extending
such a project, match it instead.

Contents: base block · arena · strings · parsing results · slices · hash
trie · MSI table · lists · output · sizes and casts.

## Base block

```c
#include <stddef.h>
#include <stdint.h>

typedef uint8_t     u8;
typedef int32_t     b32;
typedef int32_t     i32;
typedef uint32_t    u32;
typedef int64_t     i64;
typedef uint64_t    u64;
typedef char        byte;
typedef ptrdiff_t   iz;
typedef size_t      uz;

#define countof(a)      (iz)(sizeof(a) / sizeof(*(a)))
#define affirm(c)       while (!(c)) __builtin_unreachable()
#define new(a, n, t)    (t *)alloc(a, n, sizeof(t), _Alignof(t))
#define S(s)            (Str){(u8 *)s, sizeof(s)-1}
#define maxof(t)        ((t)-1<1 ? (((t)1<<(sizeof(t)*8-2))-1)*2+1 : (t)-1)
#define xset(d, c, n)   __builtin_memset(d, c, n)
#define xcpy(d, s, n)   __builtin_memcpy(d, s, n)
```

- Add `f32`/`f64`, `u16`, `uptr` (`uintptr_t`) and `c16` (`char16_t`, or
  `typedef unsigned short char16_t; typedef char16_t c16;` without
  `<uchar.h>`, which keeps GDB printing them as characters) only when used.
- `u8` is text/octets; `byte` (`char`) is raw memory and may alias anything.
- `b32` is the boolean; a success/presence `b32` goes last in a struct.
- C23: `{}` zero-initializers, `[[noreturn]]`, `enum : i32 {...}`,
  digit separators `0x8000'0000`, unnamed unused parameters
  (`static void plt_exit(Plt *, i32)`), C23 `unreachable()` as an alternative
  in `affirm`. Before C23 use `{0}`, `__attribute((noreturn))`, `(void)p;`.
- Write `__attribute`, not `__attribute__`.

## Arena

```c
typedef struct {
    byte *beg;
    byte *end;
} Arena;

static void *alloc(Arena *a, iz count, iz size, iz align)
{
    iz pad = -(uz)a->beg & (align - 1);
    if (count >= (a->end - a->beg - pad)/size) {
        oom();  // never returns
    }
    byte *r = a->beg + pad;
    a->beg += pad + count*size;
    return xset(r, 0, count*size);
}
```

- One division-based check covers overflow and capacity; `>=` also handles
  `count==0` with an unaligned `beg`.
- Never call `alloc` directly: `new(&perm, n, T)`. The cast type-checks and
  keeps `sizeof` out of ordinary code.
- OOM policy options, pick per program (`__builtin_setjmp` does not work
  on clang/arm64; see SKILL.md pitfalls):
  - The arena carries a context for it: `struct Arena { Ctx *ctx; byte *beg;
    byte *end; };` and `oom(a->ctx)` prints "prog: out of memory" and exits
    through the platform (rexxd, u-config).
  - Simple tools: `affirm(count < ...)` (uuidgen), only when inputs are
    bounded so that OOM cannot happen.
  - Parsers that must not exit: check per input unit (per line, per
    record) that the arena can hold the worst case, and return an
    "out of memory" error result otherwise.
  - Libraries/parsers: non-local exit with `__builtin_setjmp`/`longjmp`:
    ```c
    #define catch(e)  __builtin_setjmp((e)->jmp)
    typedef struct { void *jmp[5]; Str err; } Escape;
    [[noreturn]] static void throw(Escape *e, Str reason)
    {
        e->err = reason;
        __builtin_longjmp(e->jmp, 1);
    }
    ```
- The entry point receives raw memory and builds the arena:
  `Arena a = {mem, mem+cap};`. Bootstrap a context as the first allocation:
  `Ctx *ctx = a.ctx = new(&a, 1, Ctx);`.

## Strings

```c
typedef struct {
    u8 *data;
    iz  len;
} Str;

static Str span(u8 *beg, u8 *end)
{
    affirm(beg <= end);
    return (Str){beg, end-beg};
}

static Str import(u8 *s)  // from a null-terminated string
{
    Str r = {};
    r.data = s;
    for (; r.data[r.len]; r.len++) {}
    return r;
}

static b32 equals(Str a, Str b)
{
    return a.len==b.len && (!a.len || !__builtin_memcmp(a.data, b.data, (uz)a.len));
}

static Str cuthead(Str s, iz len)
{
    affirm(len >= 0 && len <= s.len);
    if (!len) return s;  // null+0 is UB in C
    s.data += len;
    s.len  -= len;
    return s;
}

static Str takehead(Str s, iz len)
{
    affirm(len >= 0 && len <= s.len);
    s.len = len;
    return s;
}

static Str clone(Arena *a, Str s)
{
    Str r = s;
    r.data = new(a, s.len, u8);
    if (r.len) xcpy(r.data, s.data, r.len);
    return r;
}

// Extends head in place when it sits at the front of the arena.
static Str concat(Arena *a, Str head, Str tail)
{
    if (!head.data || (byte *)(head.data+head.len) != a->beg) {
        head = clone(a, head);
    }
    head.len += clone(a, tail).len;
    return head;
}

typedef struct {
    Str head;
    Str tail;
    b32 ok;
} Cut;

static Cut cut(Str s, u8 c)
{
    u8 *beg = s.data;
    u8 *end = s.data + s.len;
    u8 *cut = beg;
    for (; cut<end && *cut!=c; cut++) {}
    Cut r  = {};
    r.ok   = cut < end;
    r.head = span(beg, cut);
    r.tail = span(cut+r.ok, end);
    return r;
}

static u64 hash64(Str s)
{
    u64 h = 0x100;
    for (iz i = 0; i < s.len; i++) {
        h ^= s.data[i];
        h *= 1111111111111111111u;
    }
    return h;
}
```

- Iterate fields: `for (Cut c = {.tail=s, .ok=1}; c.ok;) { c = cut(c.tail, ','); ... c.head ... }`.
- Add as needed, same naming: `taketail`, `cuttail`, `startswith`,
  `endswith`, `trim`/`trimleft`/`trimright`, `whitespace(u8)`, `digit(u8)`.
- `S("...")` for literals. For static tables, a bare-initializer twin:
  `#define STR(s) {(u8 *)s, sizeof(s)-1}`.
- Need a C string for a syscall? Make one in scratch:
  `concat(&scratch, path, S("\0"))`, or document that a path argument "must
  include a null terminator" and have the core append it.
- Hash seed: optionally mix in a per-table value (e.g. the table address).

## Parsing results

```c
typedef struct {
    i32 value;
    b32 ok;
} I32Parsed;

static I32Parsed parsei32(Str s)
{
    I32Parsed r = {};
    if (!s.len) {
        return r;
    }
    for (iz i = 0; i < s.len; i++) {
        i32 d = s.data[i] - '0';
        if (d<0 || d>9 || r.value > (maxof(i32) - d)/10) {
            return r;
        }
        r.value = r.value*10 + d;
    }
    r.ok = 1;
    return r;
}
```

The usual form is a zeroed `r` filled with sequenced assignments.
Designated initializers are fine in moderation, as are positional compound
literals for small pairs: `(Str){buf, len}`.

## Slices (dynamic arrays)

```c
#define push(a, s) \
  ((s)->len == (s)->cap \
    ? (s)->data = push_((a), (s)->data, &(s)->cap, \
          sizeof(*(s)->data), _Alignof(__typeof__(*(s)->data))), \
      (s)->data + (s)->len++ \
    : (s)->data + (s)->len++)

static void *push_(Arena *a, void *data, iz *pcap, iz size, iz align)
{
    iz cap = *pcap;
    if (!data || a->beg != (byte *)data + cap*size) {
        void *copy = alloc(a, cap, size, align);
        if (data) xcpy(copy, data, cap*size);
        data = copy;
    }
    iz extend = cap ? cap : 4;
    alloc(a, extend, size, 1);  // already aligned
    *pcap = cap + extend;
    return data;
}
```

- A slice is any struct with `data`, `len`, `cap` in that order:
  `typedef struct { Str *data; iz len; iz cap; } Strs;`. With C23 tag
  compatibility, `#define Slice(T) struct Slice##T { T *data; iz len; iz cap; }`.
- Zero is an empty slice. Append: `*push(&perm, &list) = value;`.
  `push(a, &list);` alone appends a zeroed element.
- Grows in place when last in the arena; old backing arrays stay valid.

## Hash trie (the default map)

```c
typedef struct Map Map;
struct Map {
    Map *child[4];
    Str  key;
    Str  value;
};

// Return a pointer to the value slot, inserting if the arena is non-null.
static Str *upsert(Map **m, Str key, Arena *perm)
{
    for (u64 h = hash64(key); *m; h <<= 2) {
        if (equals(key, (*m)->key)) {
            return &(*m)->value;
        }
        m = &(*m)->child[h>>62];
    }
    if (!perm) {
        return 0;
    }
    *m = new(perm, 1, Map);
    (*m)->key = key;
    return &(*m)->value;
}
```

- Null root is an empty map. A null arena means lookup only. A new slot is
  zeroed, so the caller can tell "just inserted" from the value.
- Keys are not copied: the caller ensures they live long enough (clone into
  perm if needed). No deletion.
- Intrusive: put `child[4]` into a domain struct instead of wrapping it. Add
  `next` for insertion order. Omit `value` for a set.

## MSI hash table (fixed-size, open addressing)

When the maximum size is known, or as an index over an existing array:

```c
enum { EXP = 10 };  // 1024 slots, keep load under ~50%

static i32 msilookup(u64 hash, i32 exp, i32 idx)
{
    u32 mask = ((u32)1 << exp) - 1;
    u32 step = (u32)(hash >> (64 - exp)) | 1;
    return (i32)(((u32)idx + step) & mask);
}

// Usage:
//     u64 h = hash64(key);
//     for (i32 i = (i32)h;;) {
//         i = msilookup(h, EXP, i);
//         if (!table[i].data) { table[i] = key; break; }  // insert
//         if (equals(table[i], key)) { break; }            // found
//     }
```

## Linked lists

Arenas make lists cheap. Build in order with a tail pointer:

```c
Node  *head = 0;
Node **tail = &head;
for (...) {
    Node *n = new(perm, 1, Node);
    n->value = ...;
    *tail = n;
    tail  = &n->next;
}
```

## Buffered output

```c
typedef struct {
    Plt *plt;
    i32  len;
    i32  fd;
    b32  err;
    u8   buf[1<<14];
} Output;

static Output *newoutput(Arena *a, Plt *plt, i32 fd)
{
    Output *b = new(a, 1, Output);
    b->plt = plt;
    b->fd  = fd;
    return b;
}

static void flush(Output *b)
{
    if (!b->err && b->len) {
        b->err = !plt_write(b->plt, b->fd, b->buf, b->len);
        b->len = 0;
    }
}

static void print(Output *b, Str s)
{
    for (iz off = 0; !b->err && off<s.len;) {
        i32 avail = countof(b->buf) - b->len;
        i32 count = s.len-off < avail ? (i32)(s.len-off) : avail;
        xcpy(b->buf+b->len, s.data+off, count);
        off    += count;
        b->len += count;
        if (b->len == countof(b->buf)) {
            flush(b);
        }
    }
}

static void printu8(Output *b, u8 c)
{
    print(b, (Str){&c, 1});
}

static void printi64(Output *b, i64 x)
{
    u8  buf[32];
    u8 *end = buf + countof(buf);
    u8 *beg = end;
    i64 t   = x<0 ? x : -x;  // negative covers the full range
    do {
        *--beg = '0' - (u8)(t%10);
    } while (t /= 10);
    if (x < 0) {
        *--beg = '-';
    }
    print(b, span(beg, end));
}
```

- The error flag is sticky: once set, output stops. Check it once at exit
  and return a non-zero status. Code above `print` never checks errors.
- Formatting is a sequence of calls, not a format string:
  `print(be, S("error: ")); print(be, path); print(be, S("\n"));`.
- Add `printu64(b, x, minwidth)`, `printhex`, `printq` (escaped) as needed.
- `fd = -1` can act as /dev/null; a memory variant grows into the arena and
  is finished into a `Str`.
- Large buffer in a struct allocated from the arena, not on the stack.

## Sizes and casts

1. Range-check before computing; check integers, not pointers:
   `if (len > end-beg) error;` rather than `if (beg+len > end)`.
2. Add only when `a <= MAX - b`; multiply only when `b <= MAX/a`; subtract
   only non-negative values; divide only by positive values.
3. Never mix signed and unsigned. Convert at boundaries with asserting
   helpers:
   ```c
   static uz touz(iz n)
   {
       affirm(n >= 0);
       return (uz)n;
   }

   static i32 trunc32(iz n)  // clamp for APIs taking i32 lengths
   {
       return n>maxof(i32) ? maxof(i32) : (i32)n;
   }
   ```
4. Counters that could overflow: `b->err |= b->fpos > maxof(i64) - len;`.
5. Use `countof` (signed) for arrays, `new` for allocation, so raw `sizeof`
   almost never appears.
