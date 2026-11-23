call delete('/tmp/portable-vim-retained-pass')
call delete('/tmp/portable-vim-retained-errors')
scriptencoding utf-8
set nomore
let s:themes = g:portable_vim_themes
let g:portable_vim_themes = ['nonexistent-portable-theme', 'desert', 'ron']
colorscheme desert
RotateColorTheme
call assert_equal('ron', g:colors_name)
RotateColorTheme
call assert_equal('desert', g:colors_name)
let g:portable_vim_themes = s:themes
new
setlocal filetype=c
call setline(1, ['    value();', 'next();', 'fold last'])
setlocal foldmethod=manual
1,3fold
let s:balloon = PortableVimBalloon(bufnr('%'), winnr(), 1, 2, 'value')
call assert_match('value();', s:balloon)
call assert_match('fold last', s:balloon)
call assert_equal('', PortableVimBalloon(999999, winnr(), 1, 1, ''))
normal! zR
let s:buffer = bufnr('%')
execute matchstr(maparg('\sa', 'n'), '^:\zs.\{-}\ze<CR>')
call assert_equal(1, len(sign_getplaced(s:buffer, {'group': 'PortableVim'})[0].signs))
call sign_define('PortableTestOther', {'text': 'xx'})
call sign_place(5, 'OtherPlugin', 'PortableTestOther', s:buffer, {'lnum': 1})
execute matchstr(maparg('\sS', 'n'), '^:\zs.\{-}\ze<CR>')
call assert_equal([], sign_getplaced(s:buffer, {'group': 'PortableVim'})[0].signs)
call assert_equal(1, len(sign_getplaced(s:buffer, {'group': 'OtherPlugin'})[0].signs))
call sign_unplace('OtherPlugin')
new
let s:file = tempname() . '.c'
setfiletype c
call setline(1, ['int main(void) {}  ', '', ''])
execute 'write ' . fnameescape(s:file)
call assert_equal(['int main(void) {}'], readfile(s:file))
call delete(s:file)
new
setfiletype markdown
call setline(1, ['hard break  ', '', ''])
let s:file = tempname() . '.md'
execute 'write ' . fnameescape(s:file)
call assert_equal(['hard break  ', '', ''], readfile(s:file))
call delete(s:file)
" xxd round trips: embedded NUL, non-UTF8, newline and no final newline.
if executable('xxd')
    for s:bytes in [["a\nb", "\xff", ''], ["a\nb\xff"], []]
        let s:file = tempname() . ' spaced.bin'
        call writefile(s:bytes, s:file, 'b')
        let s:expected = readfile(s:file, 'b')
        execute 'edit ' . fnameescape(s:file)
        call assert_equal('xxd', &filetype)
        let s:hex = getline(1, '$')
        let s:undo = undotree().seq_last
        write
        call assert_equal(s:undo, undotree().seq_last)
        call assert_equal(fnamemodify(s:file, ':p'), expand('%:p'))
        call assert_equal(s:expected, readfile(s:file, 'b'))
        call assert_equal(s:hex, getline(1, '$'))
        call assert_equal(0, &modified)
        bdelete!
        call delete(s:file)
    endfor
endif

if executable('gcc') || executable('clang')
    let s:file = tempname() . ' spaced ;source.c'
    new
    execute 'file ' . fnameescape(s:file)
    setfiletype c
    call setline(1, ['#include <stdio.h>', 'int main(void) { puts("portable ok"); return 0; }'])
    let s:source_buffer = bufnr('%')
    call PortableVimCompileRun(0)
    call assert_equal('Compile/run exit status: 0', getline(1))
    call assert_match('portable ok', join(getline(1, '$'), "\n"))
    bdelete!
    execute 'buffer ' . s:source_buffer
    call setline(1, 'invalid C syntax @@@')
    call PortableVimCompileRun(0)
    call assert_match('Compile/run exit status: [1-9]', getline(1))
    bdelete!
    call delete(s:file)
endif


if executable('xxd')
    let s:file = tempname() . '.bin'
    call writefile(['original bytes'], s:file, 'b')
    let s:expected = readfile(s:file, 'b')
    execute 'edit ' . fnameescape(s:file)
    call setline(1, 'not valid hex')
    let s:caught = 0
    try
        write
    catch /Malformed xxd/
        let s:caught = 1
    endtry
    call assert_equal(1, s:caught)
    call assert_equal(s:expected, readfile(s:file, 'b'))
    call assert_equal(1, &modified)
    bdelete!
    call delete(s:file)
endif
if executable('ctags') && executable('cscope') && has('cscope')
    let s:cwd = getcwd()
    let s:project = tempname() . '-project'
    call mkdir(s:project)
    call writefile(['int portable_symbol(void) { return 0; }'], s:project . '/sample.c')
    execute 'cd ' . fnameescape(s:project)
    BuildTags
    call assert_true(filereadable('tags'))
    call assert_match('portable_symbol', join(readfile('tags'), "\n"))
    new sample.c
    let s:hover = PortableVimBalloon(bufnr('%'), winnr(), 1, 5, 'portable_symbol')
    call assert_match('Tag:.*portable_symbol', s:hover)
    BuildCscope
    call assert_true(filereadable('cscope.out'))
    call assert_true(cscope_connection(2, fnamemodify('cscope.out', ':p')))
    silent! cs kill -1
    execute 'cd ' . fnameescape(s:cwd)
    call delete(s:project . '/sample.c')
    call delete(s:project . '/tags')
    call delete(s:project . '/cscope.out')
    call delete(s:project, 'd')
endif


let s:file = tempname() . '.nfo'
call writefile(["\x82"], s:file, 'b')
execute 'edit ' . fnameescape(s:file)
call assert_equal('cp437', &fileencoding)
call assert_equal('é', getline(1))
call setline(1, 'modified text')
let s:caught = 0
try
    ReloadEncoding utf-8
catch /Save or discard/
    let s:caught = 1
endtry
call assert_equal(1, s:caught)
call assert_equal('modified text', getline(1))
bdelete!
call delete(s:file)

" Unicode / percent tab names must not corrupt the statusline format.
new
execute 'file ' . fnameescape('测试文件百分号%abcdefgh')
call assert_match('测试文件百分..', ShortTabLine())
if !empty(v:errors)
    call writefile(v:errors, '/tmp/portable-vim-retained-errors')
    cquit
endif
call writefile(['PASS'], '/tmp/portable-vim-retained-pass')
qa!
