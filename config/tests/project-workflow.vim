set nomore
try
execute "source " . fnameescape(fnamemodify(expand("<sfile>:p"), ":h:h") . "/dotvimrc")
let s:root = tempname() . ' project space'
call mkdir(s:root, 'p')
call writefile(['#warning "PORTABLE_WARNING"', '#error "PORTABLE_ERROR"', 'int main(void) { return 0; }'], s:root . '/probe.c')
call writefile(['root = true', '[*.c]', 'indent_style = space', 'indent_size = 2', 'end_of_line = lf', 'trim_trailing_whitespace = false', 'insert_final_newline = false'], s:root . '/.editorconfig')
let s:baseargs = copy(get(g:, 'ycm_clangd_args', []))
let g:portable_vim_projects = {'probe': {'root': s:root,
            \ 'build': shellescape('/opt/homebrew/Cellar/llvm@22/22.1.8/bin/clang') . ' -fsyntax-only -Wall probe.c',
            \ 'database_command': shellescape(exepath('bear')) . ' -- ' . shellescape('/opt/homebrew/Cellar/llvm@22/22.1.8/bin/clang') . ' -c probe.c -o probe.o',
            \ 'compilation_database': '.', 'session': s:root . '/work session.vim'}}
Project probe
call assert_equal('probe', t:portable_project.name)
call assert_equal('--compile-commands-dir=' . t:portable_project.compilation_database, g:ycm_clangd_args[-1])
call assert_equal(g:portable_vim_projects.probe.build, &l:makeprg)
execute 'edit ' . fnameescape(s:root . '/probe.c')
call assert_equal(2, &l:shiftwidth)
call assert_equal(1, &l:expandtab)
call assert_equal(1, get(b:, 'portable_editorconfig_preserve_whitespace', 0))
call setline(3, 'int main(void) { return 0; }  ')
write
call assert_match('  $', readfile(s:root . '/probe.c')[-1])
call assert_equal(0, &l:fixendofline)
let s:disk = readfile(s:root . '/probe.c', 'b')
call setline(3, 'int main(void) { return 1; }  ')
BuildAsync
let s:buildid = getqflist({'id': 0}).id
call setqflist([], ' ', {'title': 'symbol references', 'items': [{'filename': s:root . '/probe.c', 'lnum': 3, 'text': 'reference'}]})
let s:referenceid = getqflist({'id': 0}).id
execute 'lcd ' . fnameescape(fnamemodify(s:root, ':h'))
let s:deadline = reltime()
while get(get(g:, 'portable_vim_build_result', {}), 'qfid', 0) != s:buildid && reltimefloat(reltime(s:deadline)) < 15
    sleep 20m
endwhile
call assert_equal(1, get(get(g:, 'portable_vim_build_result', {}), 'status', -999))
call assert_equal(s:referenceid, getqflist({'id': 0}).id)
call assert_equal(s:disk, readfile(s:root . '/probe.c', 'b'))
let s:items = filter(getqflist({'id': s:buildid, 'items': 1}).items, 'v:val.valid')
call assert_equal(2, len(s:items))
if len(s:items) == 2
    call assert_equal(['W', 'E'], map(copy(s:items), 'toupper(v:val.type)'))
    call assert_equal([1, 2], map(copy(s:items), 'v:val.lnum'))
    call assert_equal(resolve(s:root . '/probe.c'), resolve(fnamemodify(bufname(s:items[0].bufnr), ':p')))
endif
BuildResults
call assert_equal(s:buildid, getqflist({'id': 0}).id)
cclose
call setline(1, ['int main(void) { return 0; }'])
2,$delete _
write
BuildAsync
let s:okid = getqflist({'id': 0}).id
let s:deadline = reltime()
while get(g:portable_vim_build_result, 'qfid', 0) != s:okid && reltimefloat(reltime(s:deadline)) < 15
    sleep 20m
endwhile
call assert_equal(0, g:portable_vim_build_result.status)
call assert_equal([], filter(getqflist({'id': s:okid, 'items': 1}).items, 'v:val.valid'))
new
execute 'lcd ' . fnameescape(fnamemodify(s:root, ':h'))
ProjectBuild
call assert_equal(g:portable_vim_projects.probe.build, &l:makeprg)
call assert_equal(substitute(resolve(fnamemodify(s:root, ':p')), '/$', '', ''), resolve(getcwd()))
close
BuildDatabase
let s:dbid = getqflist({'id': 0}).id
let s:deadline = reltime()
while get(g:portable_vim_build_result, 'qfid', 0) != s:dbid && reltimefloat(reltime(s:deadline)) < 15
    sleep 20m
endwhile
call assert_equal(0, g:portable_vim_build_result.status)
call assert_true(filereadable(s:root . '/compile_commands.json'))
if filereadable(s:root . '/compile_commands.json')
    let s:db = json_decode(join(readfile(s:root . '/compile_commands.json'), "\n"))
    call assert_equal(1, len(s:db))
    if !empty(s:db)
        call assert_equal(resolve(s:root . '/probe.c'), resolve(s:db[0].directory . '/' . s:db[0].file))
        call assert_match('llvm@22', get(s:db[0], 'command', join(get(s:db[0], 'arguments', []))))
    endif
endif
let t:portable_project.build = 'exec sleep 10'
BuildAsync
let s:stopid = getqflist({'id': 0}).id
sleep 50m
BuildStop
let s:deadline = reltime()
while get(g:portable_vim_build_result, 'qfid', 0) != s:stopid && reltimefloat(reltime(s:deadline)) < 15
    sleep 20m
endwhile
call assert_equal(1, get(g:portable_vim_build_result, 'stopped', 0))
call assert_notequal(0, g:portable_vim_build_result.status)
let s:options = &sessionoptions
SaveSession
call assert_equal(s:options, &sessionoptions)
call assert_true(filereadable(s:root . '/work session.vim'))
let t:portable_project = {}
execute "LoadSession " . fnameescape(s:root . "/work session.vim")
call assert_equal('probe', t:portable_project.name)
call assert_equal('exec sleep 10', t:portable_project.build)
call setline(1, 'unsaved session guard')
let v:errmsg = ''
silent! LoadSession
call assert_match('modified buffers', v:errmsg)
edit!
call system('git -C ' . shellescape(s:root) . ' init -q')
call system('git -C ' . shellescape(s:root) . ' add probe.c')
call system('git -C ' . shellescape(s:root) . ' -c user.name=VimTest -c user.email=vim@test.invalid -c commit.gpgsign=false commit -qm initial')
call assert_equal(0, v:shell_error)
Git
call assert_equal('fugitive', &filetype)
close
execute 'edit ' . fnameescape(s:root . '/probe.c')
Gdiffsplit
call assert_true(winnr('$') >= 2)
only
execute "edit " . fnameescape(s:root . "/probe.c")
normal! gg
GitBlame
call assert_equal('fugitiveblame', &filetype)
only
catch
call add(v:errors, v:exception . ' at ' . v:throwpoint)
endtry
call writefile(v:errors, '/tmp/portable-project-errors')
let g:portable_vim_projects['default'] = {'root': s:root, 'build': 'true'}
Project default
call assert_equal(s:baseargs, g:ycm_clangd_args)
call delete(s:root, 'rf')
if !empty(v:errors)
    cquit
endif
call writefile(['PASS'], '/tmp/portable-project-pass')
qa!
