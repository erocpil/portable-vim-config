set nomore
function! s:Wait(phase) abort
    let l:start = reltime()
    while get(get(g:, 'portable_vim_practice_result', {}), 'phase', '') !=# a:phase && reltimefloat(reltime(l:start)) < 15
        sleep 20m
    endwhile
    call assert_equal(a:phase, get(get(g:, 'portable_vim_practice_result', {}), 'phase', ''))
endfunction
try
    execute 'source ' . fnameescape(fnamemodify(expand('<sfile>:p'), ':h:h') . '/dotvimrc')
    for s:cmd in ['PR', 'PB', 'PL', 'PH', 'PS']
        call assert_equal(2, exists(':' . s:cmd))
    endfor
    let s:root = tempname() . ' output space'
    call mkdir(s:root, 'p')
    call writefile(['#include <stdio.h>', 'int main(void) { puts("fixed-output-ok"); return 0; }'], s:root . '/main.c')
    execute 'edit ' . fnameescape(s:root . '/main.c')
    setlocal filetype=c
    let s:source = bufnr('%')
    let s:cwd = getcwd()
    let b:portable_practice_output = 'new directory/my program'
    unlet! g:portable_vim_practice_result
    PracticeRun
    call s:Wait('run')
    call assert_equal(0, g:portable_vim_practice_result.status)
    call assert_equal(s:root . '/new directory/my program', g:portable_vim_practice_result.output)
    call assert_true(executable(g:portable_vim_practice_result.output))
    let s:term = g:portable_vim_practice_result.terminal
    call term_wait(s:term, 100)
    call assert_match('fixed-output-ok', join(getbufline(s:term, 1, '$') + map(range(1, term_getsize(s:term)[0]), 'term_getline(s:term, v:val)'), "\n"))
    execute 'buffer ' . s:source
    call assert_equal(s:cwd, getcwd())
    let b:portable_practice_checked_output = s:root . '/absolute checked/program'
    unlet! g:portable_vim_practice_result
    PracticeRun!
    call s:Wait('run')
    call assert_equal(0, g:portable_vim_practice_result.status)
    call assert_equal(s:root . '/absolute checked/program', g:portable_vim_practice_result.output)
    execute 'buffer ' . s:source
    let b:portable_practice_output = 'main.c'
    let v:errmsg = ''
    silent! PracticeBuild
    call assert_match('distinct from the source', v:errmsg)
    call assert_match('stdio.h', readfile(s:root . '/main.c')[0])
    let b:portable_practice_output = 123
    let v:errmsg = ''
    silent! PracticeBuild
    call assert_match('must be a string', v:errmsg)
    " Per-command directories use Vim cwd, overriding both persistent paths.
    let b:portable_practice_output = 'persistent'
    let b:portable_practice_checked_output = 'persistent-checked'
    let s:work = s:root . '/different cwd'
    call mkdir(s:work, 'p')
    execute 'lcd ' . fnameescape(s:work)
    let s:work = getcwd()
    unlet! g:portable_vim_practice_result
    PR -o .
    call s:Wait('run')
    call assert_equal(0, g:portable_vim_practice_result.status)
    call assert_equal(s:work . '/main', g:portable_vim_practice_result.output)
    execute 'buffer ' . s:source
    call assert_equal('persistent', b:portable_practice_output)
    call writefile(['unused input'], s:work . '/input file.txt')
    unlet! g:portable_vim_practice_result
    execute 'PR! -o ' . fnameescape('new build') . ' ' . fnameescape('input file.txt')
    call s:Wait('run')
    call assert_equal(0, g:portable_vim_practice_result.status)
    call assert_equal(s:work . '/new build/main', g:portable_vim_practice_result.output)
    execute 'buffer ' . s:source
    call assert_equal('persistent-checked', b:portable_practice_checked_output)
    call assert_equal(s:work, getcwd())
    let v:errmsg = ''
    silent! PracticeRun -o
    call assert_match('Usage:', v:errmsg)
    let b:portable_practice_make = {'output': 'program'}
    let v:errmsg = ''
    silent! PracticeRun -o .
    call assert_match('single-file mode', v:errmsg)
    unlet b:portable_practice_make
    unlet! g:portable_vim_practice_result
    PB -o compile-only
    call s:Wait('compile')
    call assert_equal(0, g:portable_vim_practice_result.status)
    call assert_true(executable(s:work . '/compile-only/main'))
    execute 'lcd ' . fnameescape(s:cwd)
    unlet b:portable_practice_output b:portable_practice_checked_output
    unlet! g:portable_vim_practice_result
    PracticeBuild
    call s:Wait('compile')
    call assert_equal(0, g:portable_vim_practice_result.status)
    call assert_true(executable(g:portable_vim_practice_result.output))
    call assert_notequal(s:root, fnamemodify(g:portable_vim_practice_result.output, ':h'))
catch
    call add(v:errors, v:exception . ' at ' . v:throwpoint)
endtry
call writefile(v:errors, '/tmp/portable-practice-output-errors')
if !empty(v:errors)
    cquit
endif
qa!
