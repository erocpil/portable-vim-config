set nomore
function! s:Build(line) abort
    call setline(1, a:line)
    write
    let l:old = get(get(g:, 'portable_vim_build_result', {}), 'qfid', 0)
    PracticeBuild
    let l:start = reltime()
    while get(get(g:, 'portable_vim_build_result', {}), 'qfid', 0) == l:old && reltimefloat(reltime(l:start)) < 15
        sleep 20m
    endwhile
    call assert_notequal(l:old, g:portable_vim_build_result.qfid)
endfunction
try
    execute 'source ' . fnameescape(fnamemodify(expand('<sfile>:p'), ':h:h') . '/dotvimrc')
    execute 'edit ' . fnameescape(tempname() . '.c')
    setlocal filetype=c
    let s:source = win_getid()
    call s:Build('int main(void) { return unknown; }')
    call assert_notequal(0, getqflist({'winid': 0}).winid)
    call win_gotoid(s:source)
    call s:Build('int main(void) { int unused; return 0; }')
    call assert_equal(0, g:portable_vim_build_result.status)
    call assert_notequal(0, getqflist({'winid': 0}).winid, 'Warnings must keep quickfix open')
    call s:Build('int main(void) { return 0; }')
    call assert_equal(0, getqflist({'winid': 0}).winid, 'Clean build must close practice quickfix')
    call setqflist([], ' ', {'title': 'Other tool', 'items': []})
    copen
    let s:other = win_getid()
    call win_gotoid(s:source)
    call s:Build('int main(void) { return 0; }')
    call assert_equal(s:other, getqflist({'winid': 0}).winid, 'Other tool window must stay open')
catch
    call add(v:errors, v:exception . ' at ' . v:throwpoint)
endtry
call writefile(v:errors, '/tmp/portable-practice-quickfix-errors')
if !empty(v:errors)
    cquit
endif
qa!
