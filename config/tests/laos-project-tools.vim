" Read-only compilation inspection; output goes to temporary files.
set nomore
try
let s:config = fnamemodify(expand('<sfile>:p'), ':h:h')
execute 'source ' . fnameescape(s:config . '/dotvimrc')
if !empty($LAOS_ROOT)
    let g:portable_laos_root = $LAOS_ROOT
endif
execute 'source ' . fnameescape(s:config . '/examples/projects/laos.vim')
Project laos-arm64
execute 'edit ' . fnameescape(t:portable_project.root . '/kernel/arch/aarch64/main.c')
ProjectHealth
call assert_match('Current file compilation entries: 1', join(g:portable_vim_health_report, "\n"))
call assert_match('Compiler:', join(g:portable_vim_health_report, "\n"))
close
Preprocess
let s:start = reltime()
while !exists('g:portable_vim_inspection_result') && reltimefloat(reltime(s:start)) < 20
    sleep 20m
endwhile
call assert_equal(0, g:portable_vim_inspection_result.status)
call assert_match('pmm_alloc', join(getline(1, '$'), "\n"))
call assert_equal(0, &modifiable)
close
let s:old = g:portable_vim_inspection_result
Assembly
let s:start = reltime()
while g:portable_vim_inspection_result == s:old && reltimefloat(reltime(s:start)) < 20
    sleep 20m
endwhile
call assert_equal(0, g:portable_vim_inspection_result.status)
call assert_match('\<x[0-9]\+\>', join(getline(1, '$'), "\n"))
call assert_equal(0, &modifiable)
close
catch
call add(v:errors, v:exception . ' at ' . v:throwpoint)
endtry
call writefile(empty(v:errors) ? ['PASS: LaOS current database compiler, ARM64 preprocessing and assembly, readonly output'] : v:errors, '/tmp/laos-project-inspection-result')
if !empty(v:errors) | cquit | endif
qa!
