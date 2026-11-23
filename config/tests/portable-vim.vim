call delete('/tmp/portable-vim-base-pass')
call delete('/tmp/portable-vim-errors')
set nomore
call assert_equal('utf-8', &encoding)
call assert_equal('utf-8', &fileencoding)
call assert_equal('ucs-bom', split(&fileencodings, ',')[0])
call assert_equal(0, &autochdir)
call assert_equal(1, &swapfile)
call assert_equal(1, &hidden)
let s:config = $PORTABLE_VIMRC
execute 'source ' . fnameescape(s:config)
execute 'source ' . fnameescape(s:config)
call assert_equal(1, len(filter(split(execute('autocmd PortableVim BufReadPost'), "\n"), 'v:val =~ "RestorePosition"')))
new
setfiletype python
call assert_equal(1, &l:expandtab)
new
setfiletype make
call assert_equal(0, &l:expandtab)
new
call setline(1, ['中文 UTF-8  ', '', ''])
let s:file = tempname() . '.txt'
execute 'write ' . fnameescape(s:file)
call assert_equal(['中文 UTF-8  ', '', ''], readfile(s:file))
call assert_equal('中文 UTF-8  ', getline(1))
TrimWhitespace
call assert_equal('中文 UTF-8', getline(1))
call assert_equal(3, line('$'))
call delete(s:file)
let s:bomfile = tempname()
call writefile(["\xef\xbb\xbf中文"], s:bomfile, 'b')
execute 'edit ' . fnameescape(s:bomfile)
call assert_equal('utf-8', &fileencoding)
call assert_equal(1, &bomb)
call assert_equal('中文', getline(1))
call delete(s:bomfile)
if !empty(v:errors)
    call writefile(v:errors, '/tmp/portable-vim-errors')
    cquit
endif
call writefile(['PASS'], '/tmp/portable-vim-base-pass')
qa!
