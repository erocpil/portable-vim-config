set nomore
let s:fixture = tempname() . '.vim'
let s:lines = [
            \ 'function! s:PluginCommand(command) abort',
            \ '    let l:name = matchstr(a:command, ''^\S\+'')',
            \ '    if exists('':'' . l:name) == 2',
            \ '        execute a:command',
            \ '    else',
            \ '        echohl WarningMsg',
            \ '        echom ''Optional plugin command unavailable: '' . l:name',
            \ '        echohl None',
            \ '    endif',
            \ 'endfunction',
            \ '',
            \ 'function! WithBlankLine() abort',
            \ '    let x = 1',
            \ '',
            \ '    return x',
            \ 'endfunction',
            \ 'function! Adjacent() abort',
            \ '    return 2',
            \ 'endfunction', '',
            \ 'if has(''python3'')',
            \ '    if 1',
            \ '        let value = 1',
            \ '    endif',
            \ 'else',
            \ '    let value = 0',
            \ 'endif', '',
            \ 'for item in [1, 2]',
            \ '    let value = item',
            \ 'endfor', '',
            \ 'while 0',
            \ '    break',
            \ 'endwhile', '',
            \ 'try',
            \ '    let value = 1',
            \ 'catch',
            \ '    let value = 0',
            \ 'finally',
            \ '    let finished = 1',
            \ 'endtry']
call writefile(s:lines, s:fixture)
execute 'edit ' . fnameescape(s:fixture)
call assert_equal('syntax', &l:foldmethod)
normal! zM
for s:n in range(1, 10)
    call assert_equal(1, foldlevel(s:n))
    call assert_equal(1, foldclosed(s:n))
    call assert_equal(10, foldclosedend(s:n))
endfor
call assert_equal(0, foldlevel(11))
for s:n in range(12, 16)
    call assert_equal(12, foldclosed(s:n))
    call assert_equal(16, foldclosedend(s:n))
endfor
call assert_equal(17, foldclosed(17))
call assert_equal(19, foldclosedend(17))
for s:n in range(21, 27)
    call assert_equal(1, foldlevel(s:n))
    call assert_equal(21, foldclosed(s:n))
    call assert_equal(27, foldclosedend(s:n))
endfor
" Re-sourcing must refresh syntax loaded without function folding enabled.
for s:range in [[29, 31], [33, 35], [37, 43]]
    for s:n in range(s:range[0], s:range[1])
        call assert_equal(1, foldlevel(s:n))
        call assert_equal(s:range[0], foldclosed(s:n))
        call assert_equal(s:range[1], foldclosedend(s:n))
    endfor
endfor
let g:vimsyn_folding = ''
setlocal syntax=vim foldmethod=expr foldexpr=1
unlet g:vimsyn_folding
execute 'source ' . fnameescape($PORTABLE_VIMRC)
normal! zM
call assert_equal('syntax', &l:foldmethod)
call assert_equal(1, foldclosed(1))
call assert_equal(10, foldclosedend(1))
setlocal syntax=vim
normal! zM
call assert_equal(21, foldclosed(21), 'Syntax reload must retain control-block folds')
call assert_equal(27, foldclosedend(21))

" Verify the actual Balloon function and its following configuration separately.
execute 'edit ' . fnameescape($PORTABLE_VIMRC)
let s:function = search('^function! PortableVimBalloon(', 'w')
let s:end = search('^endfunction', 'W')
let s:if = search('^if exists(''+balloonexpr'')', 'W')
let s:endif = search('^endif', 'W')
normal! zM
call assert_true(s:function > 0 && s:if > s:end)
call assert_equal(s:function, foldclosed(s:function))
call assert_equal(s:end, foldclosedend(s:function))
call assert_equal(s:if, foldclosed(s:if))
call assert_equal(s:endif, foldclosedend(s:if))
call writefile([printf('Balloon function: %d-%d; configuration: %d-%d', s:function, s:end, s:if, s:endif)],
            \ '/tmp/portable-vim-balloon-fold-result')

new
setfiletype txt
call assert_equal('getline(v:lnum) =~ ''.'' ? 1 : 0', &l:foldexpr)
call setline(1, ['alpha', 'beta', '', 'gamma', 'delta'])
normal! zM
call assert_equal(1, foldclosed(1))
call assert_equal(2, foldclosedend(1))
call assert_equal(4, foldclosed(4))
call assert_equal(5, foldclosedend(4))
call delete(s:fixture)
call writefile(v:errors, '/tmp/portable-vim-folding-errors')
if !empty(v:errors)
    cquit
endif
qa!
