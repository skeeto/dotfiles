---
name: reddit-comment
description: Converts a series of Git commits into a helpful reddit comment.
---

The output will be named `reddit.md`. Never commit this file. Start by
reading the output of:

```
git format-patch -U1 --stdout $ARGUMENTS
```

For each message fill out a kind of template:

```
<brief-as-possible summary of problem fixed by the patch>

    <minimal set of commands to reproduce the problem, if possible>

Quick fix:

    <patch from message>
```

Typically these are from fuzz test results, and so the "minimal set of
commands" is a shell `printf` to produce a specific input, then the
*original* program invocation (try hard not to rely on the fuzzer program
to do this) to consume it and exhibit the bug. Prefix shell commands with
`$ ` to indicate they're shell commands. The goal is to make it as easy
and quick as possible for the reader to reproduce each issue.

In the reproduction example, prefer piping on standard input to avoid
creating files, and for this you're free to assume Linux, e.g. passing
/dev/stdin as an argument if a file name is required. For example, you
might say:

    $ printf 'bad input' | build/program -o /dev/null /dev/stdin

This might not work for some programs, in which case fall back to files.
It might not always be best reproduced using a `printf`. Think creatively
with a focus on ease. Sometimes the issue is so obvious a reproduction is
not necessary.

Regardless, also try to include the crashing/buggy output. If it's a hang,
then `(hang)` is sufficient. Include UBSan output. ASan output is lengthy,
so trim it by inserting `...` in place of addresses, typically out to the
end of that line. Remove `<ADDR> in` from the stack trace, and trim paths
to be relative to the project root. For example:

    ...ERROR: AddressSanitizer: heap-buffer-overflow on address ...
    READ of size 4294967295 at ...
        ...
        #1 LexerNextToken compiler/Frontend/Lexer/Lexer.c:693
        #2 Tokenize compiler/Frontend/Lexer/Lexer.c:909
        #3 main compiler/CLI/Koboi.c:49
        ...

I've trimmed addresses and removed stack trace lines pointing to runtime
locations. The focus is presenting only what's useful to the reader. From
that size we can guess an unsigned overflow, so even that's useful here.
To retrieve this result you may need to temporarily revert to a pre-fixed
version of the program and run the reproduction example. That's fine.

When listing patches, include the hunk headers and a/b file names, but not
the `diff` or `index` lines. Strip the function name from the hunk header.
Keep "empty" context lines and trialing space intact. The patch should be
retained well enough that it would actually apply if the 4-space prefix is
removed, e.g. when rendered. For example, this is good:

    --- a/src/asm/parse.c
    +++ b/src/asm/parse.c
    @@ -613,3 +613,3 @@
        size_t tok_len = strlen(tok);
    -	char tok_copy[tok_len];
    +	char tok_copy[tok_len + 1];
        if (!str_copy(tok_copy, tok, tok_len))

Ultimately this will be posted to reddit as a comment reviewing someone's
project. Code fences do not work on old.reddit.com, so don't use them.
Always indent code blocks by four spaces.
