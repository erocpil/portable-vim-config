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
    let s:root = tempname() . ' make space'
    call mkdir(s:root, 'p')
    call writefile(['#include <stdio.h>', 'int answer(void);', 'int main(void) { int n; if (scanf("%d", &n) != 1) return 2; printf("%d\n", answer()+n); return 0; }'], s:root . '/main.c')
    call writefile(['int answer(void) { return 40; }'], s:root . '/helper.c')
    call writefile(['2'], s:root . '/input.txt')
    call writefile(['.PHONY: normal checked broken empty', 'normal: program', 'program: main.c helper.c', "\t$(CC) -g -O0 -Wall -Wextra -fdiagnostics-color=never main.c helper.c -o program", 'checked:', "\t$(CC) -g -O0 -fsanitize=address,undefined main.c helper.c -o program-checked", 'broken:', "\t$(CC) -fsyntax-only bad.c", 'empty:', "\t@echo no executable produced"], s:root . '/Makefile')
    execute 'edit ' . fnameescape(s:root . '/main.c')
    setlocal filetype=c
    let s:source = bufnr('%')
    let s:cwd = getcwd()
    let s:makeprg = &makeprg
    let b:portable_practice_compiler = '/missing/compiler'
    let b:portable_practice_make = {'target': 'normal', 'output': 'program', 'args': ['CC=clang']}
    unlet! g:portable_vim_practice_result
    execute 'PracticeRun ' . fnameescape(s:root . '/input.txt')
    call s:Wait('run')
    call assert_equal(0, g:portable_vim_practice_result.status)
    call assert_equal(1, g:portable_vim_practice_result.make_mode)
    call assert_equal(s:root, g:portable_vim_build_result.root)
    let s:term = g:portable_vim_practice_result.terminal
    call term_wait(s:term, 100)
    call assert_match('42', join(getbufline(s:term, 1, '$') + map(range(1, term_getsize(s:term)[0]), 'term_getline(s:term, v:val)'), "\n"))
    execute 'buffer ' . s:source
    call assert_equal(s:cwd, getcwd())
    call assert_equal(s:makeprg, &makeprg)
    let v:errmsg = ''
    silent! PracticeRun!
    call assert_match('requires checked_target', v:errmsg)
    let b:portable_practice_make.checked_target = 'checked'
    let b:portable_practice_make.checked_output = 'program-checked'
    unlet! g:portable_vim_practice_result
    execute 'PracticeRun! ' . fnameescape(s:root . '/input.txt')
    call s:Wait('run')
    call assert_equal(0, g:portable_vim_practice_result.status)
    call assert_equal(1, g:portable_vim_practice_result.checked)
    call assert_equal(s:root . '/program-checked', g:portable_vim_practice_result.output)
    execute 'buffer ' . s:source
    call writefile(['int main(void) { return invalid_identifier; }'], s:root . '/bad.c')
    let b:portable_practice_make.target = 'broken'
    unlet! g:portable_vim_practice_result
    PracticeRun
    call s:Wait('compile')
    call assert_notequal(0, g:portable_vim_practice_result.status)
    call assert_false(has_key(g:portable_vim_practice_result, 'terminal'))
    call assert_true(len(filter(getqflist(), 'v:val.valid && fnamemodify(v:val.bufnr->bufname(), ":t") ==# "bad.c"')) > 0)
    execute 'buffer ' . s:source
    let b:portable_practice_make.target = 'empty'
    let b:portable_practice_make.output = 'not produced'
    unlet! g:portable_vim_practice_result
    PracticeRun
    call s:Wait('compile')
    sleep 100m
    call assert_equal(-1, g:portable_vim_practice_result.status)
    call assert_false(has_key(g:portable_vim_practice_result, 'terminal'))
catch
    call add(v:errors, v:exception . ' at ' . v:throwpoint)
endtry
call writefile(v:errors, '/tmp/portable-practice-make-errors')
if !empty(v:errors)
    cquit
endif
qa!
