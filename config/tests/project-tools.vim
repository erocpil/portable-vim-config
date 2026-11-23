set nomore
let s:config = fnamemodify(expand('<sfile>:p'), ':h:h') . '/dotvimrc'
try
execute 'source ' . fnameescape(fnamemodify(expand('<sfile>:p'), ':h:h') . '/dotvimrc')
let s:root = tempname() . ' project tools'
call mkdir(s:root . '/include space', 'p')
call mkdir(s:root . '/build', 'p')
call writefile(['#define VALUE 37'], s:root . '/include space/values.h')
call writefile(['#include "values.h"', 'int answer(void) { return VALUE + EXTRA; }', '// TODO inspect macros', '// FIXME improve answer', '// shell $(touch NEVER_CREATE)'], s:root . '/main file.c')
call writefile(['TODO in notes'], s:root . '/notes.txt')
call writefile(['#error TASK_ERROR'], s:root . '/bad.c')
call writefile(['original object'], s:root . '/build/original.o')
call writefile(['original dependencies'], s:root . '/build/original.d')
let s:clang = '/opt/homebrew/Cellar/llvm@22/22.1.8/bin/clang'
let s:args = [s:clang, '--target=aarch64-none-elf', '-O2', '-nostdinc', '-I', 'include space', '-DEXTRA=5', '-MMD', '-MP', '-MF', 'build/original.d', '-MT', 'build/original.o', '-c', 'main file.c', '-o', 'build/original.o']
let s:variant = [s:clang, '--target=aarch64-none-elf', '-O2', '-nostdinc', '-I', 'include space', '-DEXTRA=6', '-c', 'main file.c', '-o', 'build/original.o']
call writefile([json_encode([{'directory': s:root, 'file': 'main file.c', 'arguments': s:args},
            \ {'directory': s:root, 'file': 'main file.c', 'command': join(map(copy(s:variant), 'shellescape(v:val)'), ' ')}])], s:root . '/compile_commands.json')
let g:portable_vim_projects = {'tools': {'root': s:root, 'build': 'true', 'compilation_database': '.',
            \ 'tasks': {'check': shellescape(s:clang) . ' -fsyntax-only bad.c', 'custom': {'command': 'sleep 0.1; printf "bad.c:1:2: custom diagnostic\\n"', 'errorformat': '%f:%l:%c:%m'}},
            \ 'log_file': s:root . '/saved log.json'}}
Project tools
execute 'edit ' . fnameescape(s:root . '/main file.c')
ProjectSearch answer
let s:searchid = getqflist({'id': 0}).id
call setqflist([], ' ', {'title': 'keep this list', 'items': []})
let s:keepid = getqflist({'id': 0}).id
execute 'lcd ' . fnameescape(fnamemodify(s:root, ':h'))
let s:start = reltime()
while get(get(g:, 'portable_vim_search_result', {}), 'qfid', 0) != s:searchid && reltimefloat(reltime(s:start)) < 10
    sleep 20m
endwhile
call assert_equal(0, g:portable_vim_search_result.status)
call assert_equal(s:keepid, getqflist({'id': 0}).id)
call assert_equal(2, len(filter(getqflist({'id': s:searchid, 'items': 1}).items, 'v:val.valid')))
SearchResults
call assert_equal(s:searchid, getqflist({'id': 0}).id)
cclose
ProjectTodo!
let s:searchid = getqflist({'id': 0}).id
let s:start = reltime()
while g:portable_vim_search_result.qfid != s:searchid && reltimefloat(reltime(s:start)) < 10
    sleep 20m
endwhile
call assert_equal(2, len(filter(copy(getqflist()), 'v:val.valid')))
call cursor(2, 6)
ProjectWord!
let s:searchid = getqflist({'id': 0}).id
let s:start = reltime()
while g:portable_vim_search_result.qfid != s:searchid && reltimefloat(reltime(s:start)) < 10
    sleep 20m
endwhile
call assert_equal(2, len(filter(copy(getqflist()), 'v:val.valid')))
ProjectSearch UNIQUE_MISSING_TOKEN
let s:searchid = getqflist({'id': 0}).id
let s:start = reltime()
while g:portable_vim_search_result.qfid != s:searchid && reltimefloat(reltime(s:start)) < 10
    sleep 20m
endwhile
call assert_equal(1, g:portable_vim_search_result.status)
call assert_equal([], filter(copy(getqflist()), 'v:val.valid'))
ProjectSearch $(touch NEVER_CREATE)
let s:searchid = getqflist({'id': 0}).id
let s:start = reltime()
while g:portable_vim_search_result.qfid != s:searchid && reltimefloat(reltime(s:start)) < 10
    sleep 20m
endwhile
call assert_false(filereadable(s:root . '/NEVER_CREATE'))
ProjectSearch [
let s:searchid = getqflist({'id': 0}).id
let s:start = reltime()
while g:portable_vim_search_result.qfid != s:searchid && reltimefloat(reltime(s:start)) < 10
    sleep 20m
endwhile
call assert_equal(2, g:portable_vim_search_result.status)
ProjectTask check
let s:buildid = getqflist({'id': 0}).id
let s:start = reltime()
while get(get(g:, 'portable_vim_build_result', {}), 'qfid', 0) != s:buildid && reltimefloat(reltime(s:start)) < 10
    sleep 20m
endwhile
call assert_equal(1, g:portable_vim_build_result.status)
call assert_match('TASK_ERROR', join(g:portable_vim_build_result.lines, "\n"))
BuildLogSave
let s:expected = g:portable_vim_build_result
let v:errmsg = ''
silent! BuildLogSave
call assert_match('overwrite', v:errmsg)
BuildLogSave!
unlet g:portable_vim_build_result
BuildLogLoad
call assert_equal(1, len(filter(copy(getqflist()), 'v:val.valid')))
call assert_equal(s:expected.command, getqflist({'context': 1}).context.command)
cclose
let s:child = s:root . '/reload.vim'
call writefile(['set nomore',
            \ 'execute ''BuildLogLoad '' . fnameescape(' . string(s:root . '/saved log.json') . ')',
            \ 'call assert_equal(1, len(filter(getqflist(), ''v:val.valid'')))',
            \ 'call assert_equal(1, getqflist({''context'': 1}).context.status)',
            \ 'call writefile(v:errors, ''/tmp/portable-log-reload-errors'')',
            \ 'if !empty(v:errors) | cquit | endif', 'qa!'], s:child)
call system(shellescape(v:progpath) . ' -v -Nu ' . shellescape(s:config) . ' -i NONE -n -es -S ' . shellescape(s:child))
call assert_equal(0, v:shell_error, 'Separate mvim log import failed')
call writefile(['bad.c:1:2: error: raw log test'], s:root . '/raw.log')
execute 'BuildLogLoad ' . fnameescape(s:root . '/raw.log')
call assert_equal(1, len(filter(copy(getqflist()), 'v:val.valid')))
cclose
ProjectTask custom
let s:buildid = getqflist({'id': 0}).id
call setqflist([], 'f')
let s:start = reltime()
while get(get(g:, 'portable_vim_build_result', {}), 'qfid', 0) != s:buildid && reltimefloat(reltime(s:start)) < 10
    sleep 20m
endwhile
BuildResults
call assert_equal(1, len(filter(copy(getqflist()), 'v:val.valid')))
cclose
call assert_match('custom diagnostic', getqflist()[-1].text)
execute 'buffer ' . bufnr(s:root . '/main file.c')
ProjectHealth
call assert_match('Current file compilation entries: 2', join(g:portable_vim_health_report, "\n"))
call assert_match('clang version 22', join(g:portable_vim_health_report, "\n"))
call assert_equal(0, &modifiable)
close
let s:disk = readfile(s:root . '/main file.c')
call setline(2, 'int answer(void) { return 999; }')
let s:oldresult = get(g:, 'portable_vim_inspection_result', {})
Preprocess
let s:start = reltime()
while get(g:, 'portable_vim_inspection_result', {}) == s:oldresult && reltimefloat(reltime(s:start)) < 10
    sleep 20m
endwhile
call assert_equal(0, g:portable_vim_inspection_result.status)
call assert_match('return 37 + 5', join(getline(1, '$'), "\n"))
call assert_equal(0, &modifiable)
call assert_equal(1, &readonly)
call assert_equal(0, filereadable(g:portable_vim_inspection_result.argv[-1]))
close
call assert_true(&modified)
call assert_equal(s:disk, readfile(s:root . '/main file.c'))
let s:oldresult = g:portable_vim_inspection_result
Assembly
let s:start = reltime()
while g:portable_vim_inspection_result == s:oldresult && reltimefloat(reltime(s:start)) < 10
    sleep 20m
endwhile
call assert_equal(0, g:portable_vim_inspection_result.status)
call assert_match('w0', join(getline(1, '$'), "\n"))
call assert_match('#42', join(getline(1, '$'), "\n"))
call assert_equal(0, &modifiable)
close
let s:oldresult = g:portable_vim_inspection_result
Preprocess 2
let s:start = reltime()
while g:portable_vim_inspection_result == s:oldresult && reltimefloat(reltime(s:start)) < 10
    sleep 20m
endwhile
call assert_equal(0, g:portable_vim_inspection_result.status)
call assert_match('return 37 + 6', join(getline(1, '$'), "\n"))
close
call assert_equal(['original object'], readfile(s:root . '/build/original.o'))
call assert_equal(['original dependencies'], readfile(s:root . '/build/original.d'))
call assert_false(filereadable(s:root . '/NEVER_CREATE'))
let s:db = json_decode(join(readfile(s:root . '/compile_commands.json'), "\n"))
call add(s:db, {'directory': s:root, 'file': 'bad.c', 'arguments': [s:clang, '--target=aarch64-none-elf', '-c', 'bad.c', '-o', 'build/original.o']})
call writefile([json_encode(s:db)], s:root . '/compile_commands.json')
execute 'edit ' . fnameescape(s:root . '/bad.c')
let s:oldresult = g:portable_vim_inspection_result
Preprocess
let s:start = reltime()
while g:portable_vim_inspection_result == s:oldresult && reltimefloat(reltime(s:start)) < 10
    sleep 20m
endwhile
call assert_equal(1, g:portable_vim_inspection_result.status)
call assert_equal(1, len(filter(copy(getqflist()), 'v:val.valid')))
call assert_equal(['original object'], readfile(s:root . '/build/original.o'))
call assert_equal(0, filereadable(g:portable_vim_inspection_result.argv[-1]))
call setqflist([], 'f')
SearchResults
call assert_true(!empty(getqflist()))
cclose
catch
call add(v:errors, v:exception . ' at ' . v:throwpoint)
endtry
call writefile(v:errors, '/tmp/portable-project-tools-errors')
call delete(s:root, 'rf')
if !empty(v:errors)
    cquit
endif
call writefile(['PASS'], '/tmp/portable-project-tools-pass')
qa!
