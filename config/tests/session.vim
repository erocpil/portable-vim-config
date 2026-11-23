set nomore
let s:config = fnamemodify(expand('<sfile>:p'), ':h:h') . '/dotvimrc'
try
execute 'source ' . fnameescape(fnamemodify(expand('<sfile>:p'), ':h:h') . '/dotvimrc')
let s:root = tempname() . ' session space'
call mkdir(s:root . '/one', 'p')
call mkdir(s:root . '/two', 'p')
call writefile(['int first;', 'int second;', 'int third;'], s:root . '/one/a.c')
call writefile(['int other;', 'int last;'], s:root . '/two/b.c')
let s:path = s:root . '/work session.vim'
let g:portable_vim_projects = {
            \ 'one': {'root': s:root . '/one', 'build': 'printf one', 'session': s:path, 'compilation_database': '.', 'clangd_args': ['--background-index']},
            \ 'two': {'root': s:root . '/two', 'build': 'printf two', 'session': s:path, 'compilation_database': '.', 'clangd_args': ['--header-insertion=never']}}
Project one
execute 'edit ' . fnameescape(s:root . '/one/a.c')
setlocal foldmethod=manual
1,2fold
call cursor(3, 1)
tabnew
Project two
execute 'edit ' . fnameescape(s:root . '/two/b.c')
call cursor(2, 1)
let s:oldoptions = &sessionoptions
SaveSession
call assert_equal(s:oldoptions, &sessionoptions)
call assert_equal(s:path, v:this_session)
let s:contents = readfile(s:path)
let v:errmsg = ''
silent! SaveSession
call assert_match('overwrite', v:errmsg)
call assert_equal(s:contents, readfile(s:path))
SaveSession!
call assert_equal([], glob(s:root . '/.vim-session-*.vim', 0, 1))
call mkdir(s:root . '/protected.vim')
call writefile(['keep'], s:root . '/protected.vim/sentinel')
let s:oldsession = v:this_session
let v:errmsg = ''
try
    execute 'SaveSession! ' . fnameescape(s:root . '/protected.vim')
    call assert_report('Expected failed session replacement')
catch
    call assert_match('existing session preserved', v:exception)
endtry
call assert_equal(['keep'], readfile(s:root . '/protected.vim/sentinel'))
call assert_equal(s:oldsession, v:this_session)
call assert_equal(s:oldoptions, &sessionoptions)
call assert_equal([], glob(s:root . '/.vim-session-*.vim', 0, 1))
let g:ycm_clangd_args = ['--intentionally-replaced']
let &l:makeprg = 'wrong command'
execute 'LoadSession ' . fnameescape(s:path)
call assert_equal(2, tabpagenr('$'))
call assert_equal('two', t:portable_project.name)
call assert_equal('printf two', &l:makeprg)
call assert_equal('--header-insertion=never', g:ycm_clangd_args[0])
call assert_match('/two/', g:ycm_clangd_args[-1])
call assert_equal(2, line('.'))
tabprevious
call assert_equal('one', t:portable_project.name)
call assert_equal(3, line('.'))
call assert_equal(1, foldclosed(1))
tabnext
call setline(1, 'unsaved session change')
let v:errmsg = ''
silent! LoadSession
call assert_match('modified buffers', v:errmsg)
call assert_equal('unsaved session change', getline(1))
edit!
let s:child = s:root . '/load.vim'
call writefile(['set nomore',
            \ 'execute ''LoadSession '' . fnameescape(' . string(s:path) . ')',
            \ 'call assert_equal(2, tabpagenr("$"))',
            \ 'call assert_equal("two", t:portable_project.name)',
            \ 'call assert_equal("printf two", &l:makeprg)',
            \ 'call assert_equal("--header-insertion=never", g:ycm_clangd_args[0])',
            \ 'call writefile(v:errors, "/tmp/portable-session-child-errors")',
            \ 'if !empty(v:errors) | cquit | endif', 'qa!'], s:child)
call system(shellescape(v:progpath) . ' -v -Nu ' . shellescape(s:config) . ' -i NONE -n -es -S ' . shellescape(s:child))
call assert_equal(0, v:shell_error)
catch
call add(v:errors, v:exception . ' at ' . v:throwpoint)
endtry
call writefile(v:errors, '/tmp/portable-session-errors')
call delete(s:root, 'rf')
if !empty(v:errors) | cquit | endif
qa!
