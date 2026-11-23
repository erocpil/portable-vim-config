set nomore
let s:root = fnamemodify(expand('<sfile>:p'), ':h:h')
execute 'source ' . s:root . '/dotvimrc'
let s:cursor = &guicursor
let s:map = maparg('<leader>c', 'n')
set nocursorline
colorscheme ManShow
call assert_equal(s:cursor, &guicursor)
call assert_equal(s:map, maparg('<leader>c', 'n'))
call assert_equal(0, &cursorline)
call assert_equal('light', &background)
call assert_equal(hlID('Normal'), synIDtrans(hlID('Terminal')))
call assert_equal('194', synIDattr(hlID('Normal'), 'bg', 'cterm'))
call assert_equal('', synIDattr(hlID('Comment'), 'bg', 'gui'))
call assert_equal('#d2e2c9', synIDattr(hlID('IndentGuidesOdd'), 'bg#', 'gui'))
for s:g in ['Pmenu', 'PmenuSel', 'VertSplit', 'StatusLineTerm', 'StatusLineTermNC', 'YcmErrorSection', 'YcmWarningSection']
    call assert_true(hlexists(s:g), s:g)
endfor
set termguicolors
let s:b = term_start(['/bin/sh', '-c', 'printf "theme check\n"'], {'hidden': 1})
call term_wait(s:b, 200)
call assert_equal('#daeece', term_scrape(s:b, 1)[0].bg)
vnew
wincmd p
call assert_equal(0, &cursorline)
colorscheme desert
call assert_equal('#333333', synIDattr(hlID('IndentGuidesOdd'), 'bg#', 'gui'))
colorscheme ManShow
call assert_equal('#d2e2c9', synIDattr(hlID('IndentGuidesOdd'), 'bg#', 'gui'))
call writefile(v:errors, '/tmp/refined-manshow-errors')
if !empty(v:errors)
    cquit
endif
qa!
