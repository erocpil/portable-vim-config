set nomore
try
    call assert_true(exists('*PortableTagbarStatusline'))
    call assert_equal('PortableTagbarStatusline', g:tagbar_status_func)

    let s:active = PortableTagbarStatusline(1, 'Name', 'long%source-file.c', ['i', 'v'])
    call assert_match('^%#TagbarStatusTitle#\[Tagbar\] ', s:active)
    call assert_match('%#TagbarStatusFill#%=%#TagbarStatusMode# Name \[iv\] $', s:active)
    call assert_equal(-1, stridx(s:active, 'source-file.c'))
    call assert_equal(1, count(s:active, '%='))
    let s:inactive = PortableTagbarStatusline(0, 'Order', 'source.c', [])
    call assert_equal('%#StatusLineNC#[Order] ', s:inactive)
    call assert_equal('%#StatusLineNC#[Name] [iv] ',
                \ PortableTagbarStatusline(0, 'Name', 'source.c', ['i', 'v']))

    for s:theme in ['ManShow', 'Celibate']
        execute 'colorscheme ' . s:theme
        for s:group in ['TagbarStatusTitle', 'TagbarStatusFill', 'TagbarStatusMode']
            call assert_true(hlexists(s:group), s:theme . ' missing Tagbar group: ' . s:group)
        endfor
    endfor

    if exists(':TagbarOpen') == 2
        let s:source = tempname() . '.c'
        call writefile(['static int value;', 'int main(void) { return value; }'], s:source)
        execute 'edit ' . fnameescape(s:source)
        TagbarOpen
        let s:tagbar = bufwinid('__Tagbar__.*')
        call assert_true(s:tagbar > 0, 'Tagbar window did not open')
        if s:tagbar > 0
            for s:width in [30, 35, 45]
                call win_execute(s:tagbar, 'vertical resize ' . s:width)
                call assert_equal(s:width, winwidth(s:tagbar))
                let s:line = getwinvar(s:tagbar, '&statusline')
                call assert_match('^%#StatusLineNC#\[Name\]', s:line)
            endfor
            call assert_match('^%#StatusLineNC#\[Name\]', getwinvar(s:tagbar, '&statusline'))
            call win_gotoid(s:tagbar)
            call assert_match('TagbarStatusTitle', &l:statusline)
            call assert_match('%=', &l:statusline)
            call assert_match(' Name', &l:statusline)
            wincmd p
            call assert_match('^%#StatusLineNC#\[Name\]', getwinvar(s:tagbar, '&statusline'))
        endif
        silent! TagbarClose
        call delete(s:source)
    endif

    " Closing the source in one tab must not leave an orphan Tagbar tab when
    " another document tab is still open.
    if exists(':TagbarOpen') == 2 && exists('*timer_start')
        tabonly
        let s:first = tempname() . '.c'
        let s:second = tempname() . '.c'
        call writefile(['int first(void) { return 1; }'], s:first)
        call writefile(['int second(void) { return 2; }'], s:second)
        execute 'edit ' . fnameescape(s:first)
        TagbarOpen
        execute 'tabedit ' . fnameescape(s:second)
        tabprevious
        let s:sourcewin = bufwinid(s:first)
        call assert_true(s:sourcewin > 0)
        call win_gotoid(s:sourcewin)
        quit
        sleep 20m
        call assert_equal(1, tabpagenr('$'), 'Orphan Tagbar tab must close after source :q')
        call assert_equal(fnamemodify(s:second, ':p'), expand('%:p'))
        call delete(s:first)
        call delete(s:second)
    endif
catch
    call add(v:errors, v:exception . ' at ' . v:throwpoint)
endtry
call writefile(v:errors, '/tmp/portable-vim-tagbar-statusline-errors')
if !empty(v:errors)
    cquit
endif
qa!
