set nomore
function! s:Run(sidebar) abort
    unlet! g:portable_vim_practice_result
    PracticeRun
    call win_gotoid(a:sidebar)
    let l:start = reltime()
    while get(get(g:, 'portable_vim_practice_result', {}), 'phase', '') !=# 'run' && reltimefloat(reltime(l:start)) < 10
        sleep 20m
    endwhile
    call assert_equal('run', get(get(g:, 'portable_vim_practice_result', {}), 'phase', ''))
    call assert_equal(0, g:portable_vim_practice_result.status)
    return win_findbuf(g:portable_vim_practice_result.terminal)[0]
endfunction
try
    execute 'source ' . fnameescape(fnamemodify(expand('<sfile>:p'), ':h:h') . '/dotvimrc')
    let s:file = tempname() . '.c'
    call writefile(['#include <stdio.h>', 'int main(void) { puts("first"); return 0; }'], s:file)
    execute 'edit ' . fnameescape(s:file)
    setlocal filetype=c
    let s:source = win_getid()
    let s:sourcebuf = bufnr('%')
    topleft vnew
    " Older NERDTree releases leave buftype empty, so filetype must also be
    " considered when selecting the main code area.
    setlocal bufhidden=hide noswapfile filetype=nerdtree
    file [Tagbar Test]
    let s:sidebar = win_getid()
    call win_gotoid(s:source)
    let s:result = s:Run(s:sidebar)
    call assert_equal(['row', [['leaf', s:sidebar], ['col', [['leaf', s:source], ['leaf', s:result]]]]],
                \ winlayout(), 'Result should be below code and to the right of the full-height Tagbar')
    " :BR and :BL invoked from a sidebar must open below the code column.
    call win_gotoid(s:sidebar)
    BR
    let s:qf = getqflist({'winid': 0}).winid
    call assert_notequal(0, s:qf)
    call assert_true(get(getwininfo(s:qf), 0, {}).width
                \ > get(getwininfo(s:sidebar), 0, {}).width,
                \ 'BuildResults must not be limited to the NERDTree width')
    cclose
    call win_gotoid(s:sidebar)
    BL
    let s:log = win_getid()
    call assert_true(get(getwininfo(s:log), 0, {}).width
                \ > get(getwininfo(s:sidebar), 0, {}).width,
                \ 'BuildLog must not be limited to the NERDTree width')
    close
    call win_gotoid(s:result)
    close
    sleep 20m
    call assert_equal(s:source, win_getid(), 'Closing practice result should return to source, not Tagbar')
    call setline(2, 'int main(void) { puts("second"); return 0; }')
    write
    let s:result = s:Run(s:sidebar)
    let s:terminal = g:portable_vim_practice_result.terminal
    call term_wait(s:terminal, 100)
    call assert_match('second', join(getbufline(s:terminal, 1, '$'), "\n"), 'PracticeRun must rebuild changed source')
    " Closing a non-current result must preserve the user's current window.
    call win_gotoid(s:sidebar)
    call win_execute(s:result, 'close')
    sleep 20m
    call assert_equal(s:sidebar, win_getid(), 'Closing background result should not change focus')
    call win_gotoid(s:source)
    let s:result = s:Run(s:sidebar)
    " A replaced origin buffer should fall back to another visible source window.
    call win_gotoid(s:source)
    split
    let s:fallback = win_getid()
    call win_gotoid(s:source)
    close
    call win_gotoid(s:result)
    quit
    sleep 20m
    call assert_equal(s:fallback, win_getid(), 'Closed origin should fall back to a visible source window')
catch
    call add(v:errors, v:exception . ' at ' . v:throwpoint)
endtry
call writefile(v:errors, '/tmp/portable-practice-windows-errors')
if !empty(v:errors)
    cquit
endif
qa!
