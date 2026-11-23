set nomore
try
let s:config = empty($PORTABLE_VIMRC) ? fnamemodify(expand('<sfile>:p'), ':h:h') . '/dotvimrc' : $PORTABLE_VIMRC
let s:copy = tempname() . '.vim'
call writefile(readfile(s:config), s:copy)
execute 'edit ' . fnameescape(s:copy)
setlocal filetype=vim expandtab shiftwidth=4 tabstop=4
normal! gg=G
call writefile(getline(1, '$'), s:copy)
execute 'source ' . fnameescape(s:copy)
let s:command = 'clang "-DVALUE=with space" source.c'
call assert_equal(['clang', '-DVALUE=with space', 'source.c'], py3eval('_portable_compilation_split(' . json_encode(s:command) . ')'))
call assert_equal(0, len(filter(copy(getmatches()), 'v:val.group ==# "OverLength"')))
new
setlocal filetype=c
call assert_equal(1, len(filter(copy(getmatches()), 'v:val.group ==# "OverLength"')))
call assert_equal('\%101v.*', filter(copy(getmatches()), 'v:val.group ==# "OverLength"')[0].pattern)
setlocal filetype=cpp
call assert_equal(1, len(filter(copy(getmatches()), 'v:val.group ==# "OverLength"')))
setlocal filetype=python
call assert_equal(0, len(filter(copy(getmatches()), 'v:val.group ==# "OverLength"')))
setlocal filetype=c
execute 'file ' . fnameescape(tempname() . '.c')
let s:cbuf = bufnr('%')
enew
setlocal filetype=text
call assert_equal(0, len(filter(copy(getmatches()), 'v:val.group ==# "OverLength"')))
execute 'buffer ' . s:cbuf
call assert_equal(1, len(filter(copy(getmatches()), 'v:val.group ==# "OverLength"')))
execute 'buffer ' . bufnr(s:copy)
call assert_equal(0, len(filter(copy(getmatches()), 'v:val.group ==# "OverLength"')))
catch
call add(v:errors, v:exception . ' at ' . v:throwpoint)
endtry
call writefile(v:errors, '/tmp/portable-reindent-errors')
call delete(s:copy)
if !empty(v:errors)
    cquit
endif
qa!
