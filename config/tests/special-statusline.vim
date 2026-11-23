set nomore
try
    call assert_true(exists('*PortableSpecialStatusline'))

    help help
    call assert_equal('%!PortableSpecialStatusline()', &l:statusline)
    call assert_match('%#SpecialStatusTitle#\[Help\]', PortableSpecialStatusline())
    helpclose

    call setqflist([], 'r', {'title': 'Compiler', 'lines': ['sample.c:1:1: error: test']})
    copen
    call assert_equal('%!PortableSpecialStatusline()', &l:statusline)
    call assert_match('%#SpecialStatusTitle#\[Quickfix\]', PortableSpecialStatusline())
    call assert_match('Compiler.*1/1', PortableSpecialStatusline())
    cclose

    call setloclist(0, [], 'r', {'title': 'Symbols', 'lines': ['sample.c:1:1: symbol']})
    lopen
    call assert_equal('%!PortableSpecialStatusline()', &l:statusline)
    call assert_match('%#SpecialStatusTitle#\[Location List\]', PortableSpecialStatusline())
    call assert_match('Symbols.*1/1', PortableSpecialStatusline())
    lclose

    new
    file [Portable Report]
    setlocal buftype=nofile bufhidden=wipe
    doautocmd <nomodeline> PortableManShowStatusline BufEnter
    call assert_equal('%!PortableSpecialStatusline()', &l:statusline)
    call assert_match('%#SpecialStatusTitle#\[Report\]', PortableSpecialStatusline())
    bwipe!

    if exists(':NERDTree') == 2
        NERDTree
        call assert_equal('nerdtree', &l:filetype)
        call assert_equal('%!PortableSpecialStatusline()', &l:statusline)
        call assert_match('%#SpecialStatusTitle#\[Files\]', PortableSpecialStatusline())
        NERDTreeClose
    endif

    if exists('*term_start')
        new
        call term_start(['/usr/bin/printf', 'ok'], {'curwin': 1, 'term_finish': 'open'})
        doautocmd <nomodeline> PortableManShowStatusline BufEnter
        call assert_equal('terminal', &l:buftype)
        call assert_equal('%!PortableSpecialStatusline()', &l:statusline)
        call assert_match('%#SpecialStatusTitle#\[Terminal\]', PortableSpecialStatusline())
        bwipe!
    endif
catch
    call add(v:errors, v:exception . ' at ' . v:throwpoint)
endtry
call writefile(v:errors, '/tmp/portable-vim-special-statusline-errors')
if !empty(v:errors)
    cquit
endif
qa!
