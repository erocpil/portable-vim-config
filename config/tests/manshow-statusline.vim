set nomore
try
    let s:root = fnamemodify(expand('<sfile>:p'), ':h:h')
    augroup Statusline
        autocmd!
        autocmd User ManShowCollisionSentinel let g:manshow_collision_sentinel = 1
    augroup END
    " Exercise the GUI callbacks in MacVim's headless runner as well.
    set columns=120
    let s:plugin = readfile(s:root . '/plugin/ManShow.vim')
    call map(s:plugin, 'substitute(v:val, "if has(''gui_running'')", "if 1", "")')
    call map(s:plugin, 'substitute(v:val, "if !has(''gui_running'')", "if 0", "")')
    call map(s:plugin, 'substitute(v:val, "let l:width = winwidth(0)", "let l:width = get(g:, ''manshow_test_width'', winwidth(0))", "")')
    let s:temp = tempname() . '.vim'
    call writefile(s:plugin, s:temp)
    unlet! g:loaded_portable_manshow_statusline
    let g:manshow_test_width = 120
    execute 'source ' . fnameescape(s:temp)
    enew
    doautocmd <nomodeline> PortableManShowStatusline BufEnter
    call assert_match('StatuslineFileEnc', &l:statusline)
    call assert_match('%#StatuslineFill#%=', &l:statusline)
    call setline(1, 'first save')
    execute 'write ' . fnameescape(tempname() . '.txt')
    call assert_match('StatuslineFileEnc', &l:statusline, 'First save must keep the full statusline')
    execute 'saveas ' . fnameescape(tempname() . '.txt')
    call assert_match('StatuslineFileEnc', &l:statusline, 'Saveas must refresh the full statusline')
    doautocmd <nomodeline> PortableManShowStatusline BufLeave
    call assert_match('StatusLineNC.*%t%=', &l:statusline)
    call assert_equal(-1, stridx(&l:statusline, '\%='), 'Inactive layout must not display a backslash')
    doautocmd <nomodeline> PortableManShowStatusline BufEnter
    let s:events = execute('autocmd PortableManShowStatusline')
    execute 'source ' . fnameescape(s:temp)
    call assert_equal(s:events, execute('autocmd PortableManShowStatusline'), 'Repeated plugin load must be harmless')
    doautocmd <nomodeline> Statusline User ManShowCollisionSentinel
    call assert_equal(1, get(g:, 'manshow_collision_sentinel', 0),
                \ 'ManShow must not clear another plugin''s Statusline group')

    let b:portable_practice_id = 7
    let &l:statusline = 'PRACTICE-OWNED'
    doautocmd <nomodeline> PortableManShowStatusline WinEnter
    call assert_equal('PRACTICE-OWNED', &l:statusline)
    doautocmd <nomodeline> PortableManShowStatusline WinLeave
    call assert_equal('PRACTICE-OWNED', &l:statusline)
    unlet b:portable_practice_id

    " The full config may already have loaded an installed copy.  Resolve the
    " script id belonging to the temporary copy rather than the first match.
    let s:scripts = filter(split(execute('scriptnames'), '\n'),
                \ 'stridx(v:val, s:temp) >= 0')
    let s:sid = matchstr(get(s:scripts, -1, ''), '^\s*\zs\d\+')
    let s:builder = '<SNR>' . s:sid . '_BuildActiveStatusline'
    let g:manshow_test_width = 50
    let s:compact = call(function(s:builder), [1])
    call assert_notmatch('StatuslineFileType', s:compact)
    call assert_notmatch('StatuslineLineCount', s:compact)
    let g:manshow_test_width = 70
    let s:medium = call(function(s:builder), [1])
    call assert_match('StatuslineFileType', s:medium)
    call assert_match('StatuslineLineCount', s:medium)
    call assert_notmatch('StatuslineFileEnc', s:medium)
    let g:manshow_test_width = 120
    let s:wide = call(function(s:builder), [1])
    call assert_match('StatuslineFileEnc', s:wide)
    call assert_match('PortableManShowTagName', s:wide)

    function! GetTagName(...) abort
        throw 'intentional tag failure'
    endfunction
    function! CapsLockSTATUSLINE(...) abort
        throw 'intentional caps failure'
    endfunction
    function! FileInfo(...) abort
        throw 'intentional title failure'
    endfunction
    call assert_equal('', PortableManShowTagName())
    call assert_equal('', PortableManShowCapsLock())
    call assert_match('2\.txt', PortableManShowTitle())
    delfunction GetTagName
    delfunction CapsLockSTATUSLINE
    delfunction FileInfo

    " Tagbar's own WinEnter/WinLeave hook must remain the final owner in GUI.
    enew
    file __Tagbar__.99
    setlocal filetype=tagbar buftype=nofile
    let &l:statusline = 'TAGBAR-OWNED'
    doautocmd <nomodeline> PortableManShowStatusline BufEnter
    call assert_equal('TAGBAR-OWNED', &l:statusline,
                \ 'GUI BufEnter must not replace the focused Tagbar statusline')
    doautocmd <nomodeline> PortableManShowStatusline BufLeave
    call assert_equal('TAGBAR-OWNED', &l:statusline,
                \ 'GUI BufLeave must not replace the inactive Tagbar statusline')
    call delete(s:temp)
catch
    call add(v:errors, v:exception . ' at ' . v:throwpoint)
endtry
call writefile(v:errors, '/tmp/manshow-statusline-errors')
if !empty(v:errors)
    cquit
endif
qa!
