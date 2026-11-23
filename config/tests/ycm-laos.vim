" Read-only semantic validation; optional build writes normal build artifacts.
set nomore
runtime plugin/youcompleteme.vim
let s:root = empty($LAOS_ROOT) ? getcwd() : $LAOS_ROOT
let s:main = s:root . '/kernel/arch/aarch64/main.c'
let s:report = ['root=' . s:root, 'clangd=' . get(g:, 'ycm_clangd_binary_path', 'bundled')]
call assert_true(filereadable(s:root . '/compile_commands.json'))
execute 'edit ' . fnameescape(s:main)
doautocmd VimEnter
let s:start = reltime()
let s:ready = 0
while reltimefloat(reltime(s:start)) < 15
    let s:ready = py3eval('ycm_state.CheckIfServerIsReady()')
    if s:ready | break | endif
    sleep 100m
endwhile
call assert_true(s:ready, 'YCM server not ready')
if s:ready
    call assert_true(py3eval('ycm_state.NativeFiletypeCompletionAvailable()'))
    py3 ycm_state.OnFileReadyToParse()
    py3 from ycm.client.command_request import GetRawCommandResponse
    sleep 500m
    call cursor(1, 1)
    let s:line = search('\<pmm_alloc\>\s*(', 'W')
    call assert_true(s:line > 0)
    call cursor(s:line, match(getline(s:line), '\<pmm_alloc\>') + 1)
    let s:start = reltime()
    let s:definition = {}
    while reltimefloat(reltime(s:start)) < 20
        let s:definition = py3eval("GetRawCommandResponse(['GoToDefinition'], True)")
        if type(s:definition) == v:t_dict && get(s:definition, 'filepath', '') =~# '/kernel/pmm.c$'
            break
        endif
        sleep 100m
    endwhile
    execute "normal " . get(g:, 'mapleader', '\') . 'yd'
    call assert_equal(resolve(s:root . '/kernel/pmm.c'), resolve(expand('%:p')), 'Cross-file pmm definition jump failed')
    call add(s:report, 'pmm definition=' . expand('%:p') . ':' . line('.'))
    execute "normal " . get(g:, 'mapleader', '\') . 'ya'
    call assert_equal(resolve(s:root . '/kernel/pmm.h'), resolve(expand('%:p')), 'pmm declaration jump failed')
    call add(s:report, 'pmm declaration=' . expand('%:p') . ':' . line('.'))
    execute "normal " . get(g:, 'mapleader', '\') . 'yr'
    call assert_true(len(getqflist()) > 1, 'Project references not found')
    call add(s:report, 'pmm references=' . len(getqflist()))
    cclose
    execute 'edit ' . fnameescape(s:main)
    call cursor(s:line, match(getline(s:line), '\<pmm_alloc\>') + 1)
    let s:type = py3eval("ycm_state.GetCommandResponse(['GetType'])")
    call assert_match('void', s:type)
    call add(s:report, 'pmm type=' . s:type)
    call cursor(s:line, match(getline(s:line), '\<pmm_alloc\>') + 6)
    py3 ycm_state.SendCompletionRequest(force_semantic=True)
    let s:start = reltime()
    while !py3eval('ycm_state.CompletionRequestReady()') && reltimefloat(reltime(s:start)) < 10
        sleep 100m
    endwhile
    let s:completion = py3eval('ycm_state.GetCompletionResponse()')
    call assert_match('pmm_alloc', string(s:completion))
    call add(s:report, 'semantic completion=pmm_alloc available')
    call cursor(1, 1)
    let s:include = search('^#include "gic.h"', 'W')
    call cursor(s:include, 12)
    execute "normal " . get(g:, 'mapleader', '\') . 'yi'
    call assert_equal(resolve(s:root . '/kernel/arch/aarch64/gic.h'), resolve(expand('%:p')), 'Architecture include jump failed')
    call add(s:report, 'include=' . expand('%:p'))
    execute 'edit ' . fnameescape(s:main)
    call cursor(1, 1)
    let s:gic = search('\<gic_init\>\s*(', 'W')
    call cursor(s:gic, match(getline(s:gic), '\<gic_init\>') + 1)
    execute "normal " . get(g:, 'mapleader', '\') . 'yd'
    call assert_equal(resolve(s:root . '/kernel/arch/aarch64/gic.c'), resolve(expand('%:p')), 'ARM64 gic definition jump failed')
    call add(s:report, 'gic definition=' . expand('%:p') . ':' . line('.'))
    execute 'edit ' . fnameescape(s:main)
    call setqflist([], 'r')
    FindSymbol pmm_alloc
    call assert_true(!empty(getqflist()) || expand('%:t') ==# 'pmm.c', 'Project symbol search failed')
    call add(s:report, 'symbol search=PASS')
    cclose
    execute 'edit ' . fnameescape(s:main)
    call setloclist(0, [])
    YcmDiags
    call add(s:report, 'main diagnostics=' . len(getloclist(0)))
    call assert_equal([], getloclist(0), 'ARM64 main diagnostics present')
    call writefile(split(execute('YcmDebugInfo'), "\n"), '/tmp/laos-ycm-debug.log')
    if get(g:, 'portable_laos_check_build', 0)
        let $PATH .= ':/opt/homebrew/Cellar/llvm@22/22.1.8/bin'
        compiler gcc
        let &l:makeprg = 'make ARCH=aarch64 ARM64_TOOLCHAIN=llvm'
        silent execute "normal " . get(g:, 'mapleader', '\') . 'mk'
        call assert_equal(0, v:shell_error, 'Vim :make ARM64 build failed')
        let s:errors = filter(copy(getqflist()), 'v:val.valid && toupper(v:val.type) ==# "E"')
        call assert_equal([], s:errors, 'Compiler errors in quickfix')
        call add(s:report, 'Vim :make=PASS; quickfix compiler errors=' . len(s:errors))
    endif
endif
for s:buffer in getbufinfo()
    call assert_equal(0, getbufvar(s:buffer.bufnr, '&modified'), 'Validation modified a buffer')
endfor
call writefile(s:report + (empty(v:errors) ? ['PASS'] : v:errors), '/tmp/laos-ycm-result.log')
if !empty(v:errors) | cquit | endif
qa!
