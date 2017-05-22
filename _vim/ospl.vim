" Courtesy https://vi.stackexchange.com/a/2848
function! MyFormatExpr(start, end)
    silent execute a:start.','.a:end.'s/[.!?]\zs /\r/g'
endfunction
setlocal formatexpr=MyFormatExpr(v:lnum,v:lnum+v:count-1)

" Make it more comfortable to navigate
setlocal linebreak
noremap <buffer> j gj
noremap <buffer> k gk
noremap <buffer> gj j
noremap <buffer> gk k
