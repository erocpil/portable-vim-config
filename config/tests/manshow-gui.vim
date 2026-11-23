call delete('/tmp/portable-vim-manshow-gui-errors')
set nomore
try
    call assert_true(has('gui_running'), 'This test requires MacVim GUI mode')
    call assert_equal('ManShow', get(g:, 'colors_name', ''))
    call assert_equal('%{PortableManShowTitle()}', &titlestring)

    let s:source = tempname() . '.c'
    call writefile(['int main(void)', '{', '    return 0;', '}'], s:source)
    execute 'edit ' . fnameescape(s:source)
    set columns=160
    doautocmd <nomodeline> PortableManShowStatusline BufEnter
    call assert_match('StatuslineFileEnc', &l:statusline)
    call assert_match(fnamemodify(s:source, ':t'), PortableManShowTitle())
    let s:source_win = win_getid()

    vsplit
    vertical resize 40
    doautocmd <nomodeline> PortableManShowStatusline BufEnter
    call assert_notmatch('StatuslineFileType', &l:statusline)
    call assert_notmatch('StatuslineLineCount', &l:statusline)
    call assert_match('StatusLineNC.*%t%=', getwinvar(s:source_win, '&statusline'))
    only

    call setqflist([], 'r', {'title': 'GUI Compiler',
                \ 'lines': [s:source . ':3:5: warning: test']})
    copen
    call assert_match('\[Quickfix\].*GUI Compiler.*1/1', PortableSpecialStatusline())
    call assert_match('Quickfix.*GUI Compiler', PortableManShowTitle())
    cclose
    call assert_match(fnamemodify(s:source, ':t'), PortableManShowTitle())
    call delete(s:source)
catch
    call add(v:errors, v:exception . ' at ' . v:throwpoint)
endtry
call writefile(v:errors, '/tmp/portable-vim-manshow-gui-errors')
if !empty(v:errors)
    cquit
endif
qa!
