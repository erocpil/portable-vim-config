call delete('/tmp/portable-debugger-palette-errors')
set nomore
if !has('gui_running') && has('termguicolors')
    set termguicolors
endif
colorscheme ManShow
let s:program = tempname()
call writefile(['fixture'], s:program)
let g:portable_vim_debugger = executable('/usr/bin/true') ? '/usr/bin/true' : exepath('true')
execute 'DebugProgram ' . fnameescape(s:program)
let s:buffer = bufnr('%')
call assert_equal('terminal', &buftype)
call assert_equal(g:portable_vim_debugger_theme_ansi_colors,
            \ term_getansicolors(s:buffer))
call assert_equal('#805100', term_getansicolors(s:buffer)[3])
call assert_equal('#6b5a00', term_getansicolors(s:buffer)[11])
bwipeout!
colorscheme Celibate
call assert_false(exists('g:portable_vim_debugger_theme_ansi_colors'))
call assert_notmatch('E495:', execute('messages'), 'Debugger startup must not trip the GUI Buffers menu')
call delete(s:program)
if !empty(v:errors)
    call writefile(v:errors, '/tmp/portable-debugger-palette-errors')
    cquit
endif
qa!
