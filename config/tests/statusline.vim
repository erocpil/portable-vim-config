call delete('/tmp/portable-vim-statusline-pass')
set nomore
let s:man = globpath(&runtimepath, 'plugin/ManShow.vim', 0, 1)
if !empty(s:man)
    runtime plugin/ManShow.vim
    new
    let s:local = &l:statusline
    call assert_equal('', &g:statusline)
    call assert_equal(1, count(s:local, '%='))
    call assert_equal(1, count(s:local, '%#StatuslineFileName#'))
    call assert_match('%#StatuslineLine#%l%#StatuslineLineColumnSep#:%#StatuslineColumn#%c%V%#StatuslineColumnCountSep#/%#StatuslineLineCount#%L', s:local)
    call assert_equal(0, count(s:local, '%<%f'))
    execute 'source ' . fnameescape($PORTABLE_VIMRC)
    call assert_equal(s:local, strpart(&l:statusline, 0, strlen(s:local)))
    for s:theme in ['ManShow', 'Celibate']
        execute 'colorscheme ' . s:theme
        for s:group in ['StatuslineFill', 'StatuslineLine', 'StatuslineLineColumnSep', 'StatuslineColumn', 'StatuslineColumnCountSep', 'StatuslineLineCount', 'TagbarStatusTitle', 'TagbarStatusFill', 'TagbarStatusMode', 'SpecialStatusTitle', 'SpecialStatusInfo', 'SpecialStatusFill', 'SpecialStatusMode']
            call assert_true(hlexists(s:group), s:theme . ' missing statusline highlight group: ' . s:group)
        endfor
    endfor
    new
    call assert_equal(s:local, strpart(&l:statusline, 0, strlen(s:local)))
    " Exercise the GUI layout builder without opening a GUI window.
    let s:full = matchstr(execute('function /SetActiveStatusline'), '<SNR>\d\+_SetActiveStatusline')
    call assert_false(empty(s:full))
    call call(function(s:full), [1])
    call assert_equal(1, count(&l:statusline, '%='))
    call assert_equal(1, count(&l:statusline, '%#StatuslineFileName#'))
    call assert_match('%#StatuslineLine#%l%#StatuslineLineColumnSep#:%#StatuslineColumn#%c%V%#StatuslineColumnCountSep#/%#StatuslineLineCount#%L', &l:statusline)
    call assert_equal(0, count(&l:statusline, '%<%f'))
else
    call assert_equal(1, count(&g:statusline, '%='))
    call assert_match('^%<%f', &g:statusline)
endif
if !empty(v:errors)
    call writefile(v:errors, '/tmp/portable-vim-statusline-errors')
    cquit
endif
call writefile(['PASS'], '/tmp/portable-vim-statusline-pass')
qa!
