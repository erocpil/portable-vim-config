set nomore
function! s:Run() abort
    unlet! g:portable_vim_practice_result
    PracticeRun
    call assert_equal(' [Practice: compiling]', PortablePracticeStatus())
    let l:start = reltime()
    while get(get(g:, 'portable_vim_practice_result', {}), 'phase', '') !=# 'run' && reltimefloat(reltime(l:start)) < 15
        sleep 20m
    endwhile
    call assert_equal('run', get(get(g:, 'portable_vim_practice_result', {}), 'phase', ''))
    call assert_equal(0, g:portable_vim_practice_result.status)
    call term_wait(g:portable_vim_practice_result.terminal, 100)
    return copy(g:portable_vim_practice_result)
endfunction
try
    execute 'source ' . fnameescape(fnamemodify(expand('<sfile>:p'), ':h:h') . '/dotvimrc')
    let s:file = tempname() . '.c'
    call writefile(['#include <stdio.h>', 'int main(void) { puts("first"); return 0; }'], s:file)
    execute 'edit ' . fnameescape(s:file)
    setlocal filetype=c
    let s:source = win_getid()
    set termguicolors
    highlight Normal guifg=#eeeeee guibg=#123456
    let s:first = s:Run()
    call assert_equal('#123456', term_scrape(s:first.terminal, 1)[0].bg)
    highlight Normal guifg=#eeeeee guibg=#234567
    let s:pane = win_getid()
    call assert_match('Done #1 · exit 0', PortablePracticeStatus())
    call assert_equal('%!PortablePracticeStatusline()', &l:statusline)
    call assert_match('Practice #1.*\[Normal\].*Done · exit 0', PortablePracticeStatusline())
    call win_gotoid(s:source)
    let g:statusline_winid = s:pane
    call assert_match('Practice #1.*Done · exit 0', PortablePracticeStatusline(), 'Inactive terminal must use its own buffer')
    unlet g:statusline_winid
    call setline(2, 'int main(void) { puts("second"); return 0; }')
    write
    let s:second = s:Run()
    call assert_equal('#234567', term_scrape(s:second.terminal, 1)[0].bg, 'New runs must use the current theme')
    call assert_equal(s:pane, win_getid(), 'Run must reuse result window')
    call assert_equal(2, winnr('$'))
    call assert_notequal(s:first.terminal, s:second.terminal)
    call assert_equal(2, len(g:portable_vim_practice_history))
    call assert_match('first', join(getbufline(s:first.terminal, 1, '$'), "\n"))
    call assert_match('second', join(getbufline(s:second.terminal, 1, '$'), "\n"))
    let s:build = deepcopy(g:portable_vim_build_result)
    call win_gotoid(s:source)
    execute 'PracticeHistory ' . s:first.id
    call assert_equal(s:pane, win_getid())
    call assert_equal(s:first.terminal, bufnr('%'))
    call assert_match('Practice #1.*Done · exit 0', PortablePracticeStatusline())
    call assert_equal(s:build, g:portable_vim_build_result, 'History must not compile or execute')
    call assert_equal(2, winnr('$'))
    close
    sleep 20m
    call assert_equal(s:source, win_getid())
    PracticeLast
    call assert_equal(s:second.terminal, bufnr('%'))
    call assert_equal(2, winnr('$'), 'Closed result must reopen below source')
    call win_gotoid(s:source)
    call setline(2, 'int main(void) { return missing_identifier; }')
    write
    PracticeRun
    let s:start = reltime()
    while get(g:portable_vim_build_result, 'qfid', 0) == s:build.qfid && reltimefloat(reltime(s:start)) < 15
        sleep 20m
    endwhile
    call assert_notequal(0, g:portable_vim_build_result.status)
    call assert_equal(2, len(g:portable_vim_practice_history), 'Failed compilation must preserve history')
    cclose
    call win_gotoid(s:source)
    call setline(2, 'int main(void) { puts("third"); return 0; }')
    write
    let g:portable_practice_history_limit = 2
    let s:third = s:Run()
    call assert_equal([s:second.id, s:third.id], map(copy(g:portable_vim_practice_history), 'v:val.id'))
    call assert_equal(0, bufexists(s:first.terminal), 'Eviction should remove hidden completed output')
    call assert_equal(2, winnr('$'))
    let s:history = deepcopy(g:portable_vim_practice_history)
    call win_gotoid(s:source)
    execute 'source ' . fnameescape(fnamemodify(expand('<sfile>:p'), ':h:h') . '/dotvimrc')
    call assert_equal(s:history, g:portable_vim_practice_history, 'Reload must preserve history')
catch
    call add(v:errors, v:exception . ' at ' . v:throwpoint)
endtry
call writefile(v:errors, '/tmp/portable-practice-history-errors')
if !empty(v:errors)
    cquit
endif
qa!
