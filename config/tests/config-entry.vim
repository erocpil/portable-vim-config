set nomore
call assert_equal(expand('<sfile>:p:h:h') . '/dotvimrc',
            \ fnamemodify(g:portable_vim_config_file, ':p'))
call assert_equal(2, exists(':EditVimConfig'))
call assert_equal(2, exists(':ReloadVimConfig'))
call assert_match(':EditVimConfig<CR>', maparg('<leader>ev', 'n'))
let s:before = execute('autocmd PortableVimRetained BufWritePost')
execute 'source ' . fnameescape(g:portable_vim_config_file)
let s:after = execute('autocmd PortableVimRetained BufWritePost')
call assert_equal(s:before, s:after)
if !empty(v:errors)
    call writefile(v:errors, '/tmp/portable-config-entry-errors')
    cquit
endif
call writefile(['PASS'], '/tmp/portable-config-entry-result')
qa!
