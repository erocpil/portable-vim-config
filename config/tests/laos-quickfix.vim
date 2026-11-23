" Build only an isolated LaOS copy containing deliberate diagnostic probes.
set nomore
let s:root = readfile('/tmp/laos-quickfix-root')[0]
let s:probe = s:root . '/kernel/arch/aarch64/quickfix_probe.c'
if s:root !~# '/laos-clang22-quickfix-[^/]\+$'
    echoerr 'Quickfix validation requires an isolated temporary LaOS copy'
    cquit
endif
call assert_true(filereadable(s:probe))
let $PATH = '/opt/homebrew/Cellar/llvm@22/22.1.8/bin:' . $PATH
call assert_equal('/opt/homebrew/Cellar/llvm@22/22.1.8/bin/clang', exepath('clang'))
let s:config = empty($PORTABLE_VIMRC) ? fnamemodify(expand('<sfile>:p'), ':h:h') . '/dotvimrc' : $PORTABLE_VIMRC
execute 'source ' . fnameescape(s:config)
let v:errmsg = ''
execute 'lcd ' . fnameescape(s:root)
compiler gcc
let &l:makeprg = 'make ARCH=aarch64 ARM64_TOOLCHAIN=llvm'
" Preserve output and make's status even when tee is used by :make.
let &shell = '/bin/zsh'
let &shellcmdflag = '-o pipefail -c'
let &shellpipe = '2>&1 | tee %s /tmp/laos-clang22-quickfix-active.log'
let &makeef = '/tmp/laos-clang22-quickfix-compiler.log'
" Expected build failure: suppress Ex's error state, then assert shell status
" and the exact compiler diagnostics instead.
silent! make!
let s:failed_status = v:shell_error
call assert_notequal(0, s:failed_status, 'Deliberate #error did not fail the build')
let s:failed = getqflist({'id': 1, 'items': 1, 'title': 1})
call writefile([json_encode(s:failed)], '/tmp/laos-clang22-quickfix-items.json')
call writefile(readfile('/tmp/laos-clang22-quickfix-active.log'), '/tmp/laos-clang22-quickfix-failed-build.log')
let s:warnings = filter(copy(s:failed.items), 'v:val.valid && toupper(v:val.type) ==# "W" && v:val.text =~# "LAOS_QF_WARNING_PROBE"')
let s:errors = filter(copy(s:failed.items), 'v:val.valid && toupper(v:val.type) ==# "E" && v:val.text =~# "LAOS_QF_ERROR_PROBE"')
call assert_equal(1, len(s:warnings), 'Warning was not parsed')
call assert_equal(1, len(s:errors), 'Error was not parsed')
if len(s:warnings) == 1 && len(s:errors) == 1
    call assert_equal(1, s:warnings[0].lnum)
    call assert_equal(2, s:errors[0].lnum)
    call assert_equal(2, s:warnings[0].col)
    call assert_equal(2, s:errors[0].col)
    call assert_equal(resolve(s:probe), resolve(fnamemodify(bufname(s:errors[0].bufnr), ':p')))
    " :cfirst addresses entry 1 even if it is an unparsed make output line.
    " Select the warning's actual list index before testing next/previous.
    execute (index(s:failed.items, s:warnings[0]) + 1) . 'cc'
    call assert_equal(resolve(s:probe), resolve(expand('%:p')))
    call assert_equal(1, line('.'))
    call assert_equal(2, col('.'))
    execute "normal " . get(g:, 'mapleader', '\') . 'qn'
    call assert_equal(2, line('.'))
    call assert_equal(2, col('.'))
    execute "normal " . get(g:, 'mapleader', '\') . 'qp'
    call assert_equal(1, line('.'))
    execute "normal " . get(g:, 'mapleader', '\') . 'qo'
    call assert_equal('quickfix', &buftype)
    execute "normal " . get(g:, 'mapleader', '\') . 'qc'
    Cfilter /LAOS_QF_WARNING_PROBE/
    call assert_equal(1, len(filter(copy(getqflist()), 'v:val.valid')))
    execute "normal " . get(g:, 'mapleader', '\') . 'qb'
    call assert_equal(s:failed.id, getqflist({'id': 1}).id)
    Cfilter! /LAOS_QF_WARNING_PROBE/
    call assert_equal(1, len(filter(copy(getqflist()), 'v:val.valid && toupper(v:val.type) ==# "E"')))
    execute "normal " . get(g:, 'mapleader', '\') . 'qb'
    call assert_equal(s:failed.id, getqflist({'id': 1}).id)
endif
" Repair only the isolated copy and prove a successful build creates a new list.
call writefile(['int laos_quickfix_probe(void) { return 0; }'], s:probe)
execute 'edit ' . fnameescape(s:probe)
compiler gcc
let &l:makeprg = 'make ARCH=aarch64 ARM64_TOOLCHAIN=llvm'
silent make!
let s:success_status = v:shell_error
let s:success_id = getqflist({'id': 1}).id
call writefile(readfile('/tmp/laos-clang22-quickfix-active.log'), '/tmp/laos-clang22-quickfix-repaired-build.log')
call assert_equal(0, s:success_status, 'Build after repair failed')
call assert_equal([], filter(copy(getqflist()), 'v:val.valid && index(["E", "W"], toupper(v:val.type)) >= 0'))
execute "normal " . get(g:, 'mapleader', '\') . 'qb'
call assert_equal(s:failed.id, getqflist({'id': 1}).id)
execute "normal " . get(g:, 'mapleader', '\') . 'qf'
call assert_equal(s:success_id, getqflist({'id': 1}).id)
let s:report = ['compiler=' . exepath('clang'), 'failed make status=' . s:failed_status,
            \ 'parsed warnings=' . len(s:warnings), 'parsed errors=' . len(s:errors),
            \ 'repaired make status=' . s:success_status]
call assert_equal('', v:errmsg, 'Unexpected Vim error during quickfix validation')
call writefile(s:report + (empty(v:errors) ? ['PASS: quickfix positions, navigation, filter and history'] : v:errors),
            \ '/tmp/laos-clang22-quickfix-result.log')
if !empty(v:errors)
    cquit
endif
" Explicit status after a deliberately failing shell command.
cquit 0
