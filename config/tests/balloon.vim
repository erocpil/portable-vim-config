new
call setline(1, map(range(1, 40), '"line " . v:val'))
setlocal foldmethod=manual
1,15fold
call assert_match('v:beval_winnr+1', &balloonexpr)
let s:expr = &balloonexpr
for [s:key, s:value] in items({'bufnr': bufnr('%'), 'winnr': winnr() - 1, 'lnum': 1, 'col': 1, 'text': ''})
    let s:expr = substitute(s:expr, 'v:beval_' . s:key, string(s:value), 'g')
endfor
call assert_equal(join(getline(1, 15), "\n"), eval(s:expr))
call assert_equal(join(getline(1, 15), "\n"), PortableVimBalloon(bufnr('%'), winnr(), 1, 1, ''))
normal! zR
call assert_equal('', PortableVimBalloon(bufnr('%'), winnr(), 1, 1, ''))
normal! zE
1,40fold
let s:text = PortableVimBalloon(bufnr('%'), winnr(), 1, 1, '')
call assert_match('line 1\nline 2', s:text)
call assert_match('-- Snipped 10 lines --', s:text)
call assert_match('line 39\nline 40$', s:text)
if !empty(v:errors)
    call writefile(v:errors, '/tmp/portable-balloon-errors')
    cquit
endif
qa!
