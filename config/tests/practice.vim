set nomore
function! s:Wait(phase) abort
    let l:start = reltime()
    while get(get(g:, 'portable_vim_practice_result', {}), 'phase', '') !=# a:phase && reltimefloat(reltime(l:start)) < 15
        sleep 20m
    endwhile
    call assert_equal(a:phase, get(get(g:, 'portable_vim_practice_result', {}), 'phase', ''))
endfunction
function! s:Output(buf) abort
    call term_wait(a:buf, 100)
    redraw
    return join(getbufline(a:buf, 1, '$') + map(range(1, term_getsize(a:buf)[0]), 'term_getline(a:buf, v:val)'), "\n")
endfunction
try
    execute 'source ' . fnameescape(fnamemodify(expand('<sfile>:p'), ':h:h') . '/dotvimrc')
    let s:root = tempname() . ' practice space'
    call mkdir(s:root, 'p')
    let g:portable_practice_cc = '/opt/homebrew/Cellar/llvm@22/22.1.8/bin/clang'
    let g:portable_practice_cxx = '/opt/homebrew/Cellar/llvm@22/22.1.8/bin/clang++'
    call writefile(['#include <stdio.h>', 'int main(void) { int a, b; if (scanf("%d%d", &a, &b) != 2) return 2; printf("%d\n", a+b); return 0; }'], s:root . '/sum file.c')
    call writefile(['19 23'], s:root . '/input file.txt')
    execute 'edit ' . fnameescape(s:root . '/sum file.c')
    setlocal filetype=c
    let &l:makeprg = 'original build'
    let &l:errorformat = '%f:%l:%m'
    let t:portable_project = {'name': 'unchanged', 'root': s:root, 'build': 'never execute'}
    let s:profile = deepcopy(t:portable_project)
    let v:errmsg = ''
    silent! PracticeRun /nonexistent/portable-input.txt
    call assert_match('Practice input does not exist', v:errmsg)
    execute 'PracticeRun ' . fnameescape(s:root . '/input file.txt')
    call s:Wait('run')
    call assert_equal(0, g:portable_vim_practice_result.status)
    let s:term = g:portable_vim_practice_result.terminal
    call term_wait(s:term, 100)
    call assert_match('42', s:Output(s:term))
    call assert_equal(s:profile, t:portable_project)
    execute 'buffer ' . bufnr(s:root . '/sum file.c')
    call assert_equal('original build', &l:makeprg)
    call assert_equal('%f:%l:%m', &l:errorformat)
    unlet g:portable_vim_practice_result
    PracticeRun
    let s:start = reltime()
    while !has_key(get(g:, 'portable_vim_practice_result', {}), 'terminal') && reltimefloat(reltime(s:start)) < 15
        sleep 20m
    endwhile
    call term_sendkeys(g:portable_vim_practice_result.terminal, "7 8\r")
    call s:Wait('run')
    call assert_equal(0, g:portable_vim_practice_result.status)
    execute 'buffer ' . bufnr(s:root . '/sum file.c')
    call setline(2, 'int main(void) { return invalid_identifier; }')
    let v:errmsg = ''
    silent! PracticeBuild
    call assert_match('Save the source', v:errmsg)
    write
    unlet g:portable_vim_practice_result
    PracticeRun
    call s:Wait('compile')
    call assert_notequal(0, g:portable_vim_practice_result.status)
    call assert_false(has_key(g:portable_vim_practice_result, 'terminal'))
    call assert_true(len(filter(getqflist(), 'v:val.valid && v:val.lnum == 2')) > 0)
    call writefile(['#include <limits.h>', 'int main(void) { volatile int x = INT_MAX; return x + 1; }'], s:root . '/overflow.c')
    execute 'edit ' . fnameescape(s:root . '/overflow.c')
    setlocal filetype=c
    unlet g:portable_vim_practice_result
    PracticeRun!
    call s:Wait('run')
    call assert_notequal(0, g:portable_vim_practice_result.status)
    call assert_equal(1, g:portable_vim_practice_result.checked)
    let s:term = g:portable_vim_practice_result.terminal
    call term_wait(s:term, 100)
    call assert_match('runtime error: signed integer overflow', s:Output(s:term))
    call writefile(['#include <stdlib.h>', 'int main(void) { int *p = malloc(sizeof(int)); volatile int index = 2; p[index] = 42; free(p); return 0; }'], s:root . '/bounds.c')
    execute 'edit ' . fnameescape(s:root . '/bounds.c')
    setlocal filetype=c
    unlet g:portable_vim_practice_result
    PracticeRun!
    call s:Wait('run')
    call assert_notequal(0, g:portable_vim_practice_result.status)
    let s:term = g:portable_vim_practice_result.terminal
    call term_wait(s:term, 100)
    call assert_match('AddressSanitizer: heap-buffer-overflow', s:Output(s:term))
    call writefile(['#include <iostream>', 'int main() { std::cout << "cpp17" << std::endl; }'], s:root . '/hello.cpp')
    execute 'edit ' . fnameescape(s:root . '/hello.cpp')
    setlocal filetype=cpp
    unlet g:portable_vim_practice_result
    PracticeRun
    call s:Wait('run')
    call assert_equal(0, g:portable_vim_practice_result.status)
    let s:term = g:portable_vim_practice_result.terminal
    call term_wait(s:term, 100)
    call assert_match('cpp17', s:Output(s:term))
    execute 'buffer ' . bufnr(s:root . '/hello.cpp')
    let b:portable_practice_standard = 'c++20'
    let b:portable_practice_flags = ['-Wconversion']
    unlet g:portable_vim_practice_result
    PracticeBuild!
    call s:Wait('compile')
    call assert_equal(0, g:portable_vim_practice_result.status)
    call assert_match('-std=c++20', g:portable_vim_build_result.command)
    call assert_match('-Wconversion', g:portable_vim_build_result.command)
    execute 'buffer ' . bufnr(s:root . '/sum file.c')
    call setline(2, 'int main(void) { for (;;) {} }')
    write
    unlet g:portable_vim_practice_result
    PracticeRun
    let s:start = reltime()
    while !has_key(get(g:, 'portable_vim_practice_result', {}), 'terminal') && reltimefloat(reltime(s:start)) < 15
        sleep 20m
    endwhile
    call assert_match('Running #', PortablePracticeStatus())
    call assert_match('\[Normal\].*Running', PortablePracticeStatusline())
    let s:running = g:portable_vim_practice_result.terminal
    close
    execute 'buffer ' . bufnr(s:root . '/sum file.c')
    call assert_equal(' [Practice: running]', PortablePracticeStatus())
    PracticeLast
    call assert_equal(s:running, bufnr('%'))
    PracticeStop
    call s:Wait('run')
    PracticeLast
    call assert_match('Failed #', PortablePracticeStatus())
    call assert_notequal(0, g:portable_vim_practice_result.status)
catch
    call add(v:errors, v:exception . ' at ' . v:throwpoint)
endtry
call writefile(v:errors, '/tmp/portable-practice-errors')
if !empty(v:errors)
    cquit
endif
qa!
