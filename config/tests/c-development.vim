" Check the range delivered to the plugin, rather than formatting internals.
set nomore
new
call setline(1, ['one', 'two', 'three', 'four'])
command! -range=% -nargs=+ YcmCompleter let g:portable_ycm_request = [<line1>, <line2>, <q-args>]
FormatCode
call assert_equal([1, 4, 'Format'], g:portable_ycm_request)
2,3FormatCode
call assert_equal([2, 3, 'Format'], g:portable_ycm_request)
FindSymbol packet
call assert_equal('GoToSymbol packet', g:portable_ycm_request[2])
RenameSymbol renamed_value
call assert_equal('RefactorRename renamed_value', g:portable_ycm_request[2])
let s:messages = execute('RenameSymbol bad|name')
call assert_match('requires a C identifier', s:messages)
call assert_equal('RefactorRename renamed_value', g:portable_ycm_request[2])
call setqflist([{'bufnr': bufnr('%'), 'lnum': 1, 'text': 'first'},
            \ {'bufnr': bufnr('%'), 'lnum': 3, 'text': 'second'}])
cfirst
execute "normal " . get(g:, 'mapleader', '\') . 'qn'
call assert_equal(3, line('.'))
execute "normal " . get(g:, 'mapleader', '\') . 'qp'
call assert_equal(1, line('.'))
call setqflist([{'bufnr': bufnr('%'), 'lnum': 2, 'text': 'new list'}])
execute "normal " . get(g:, 'mapleader', '\') . 'qb'
call assert_equal('first', getqflist()[0].text)
execute "normal " . get(g:, 'mapleader', '\') . 'qf'
call assert_equal('new list', getqflist()[0].text)
if exists(':Cfilter') == 2
    call setqflist([{'bufnr': bufnr('%'), 'lnum': 1, 'text': 'error: broken'},
                \ {'bufnr': bufnr('%'), 'lnum': 2, 'text': 'warning: unused'}])
    Cfilter /error:/
    call assert_equal(1, len(getqflist()))
    call assert_equal('error: broken', getqflist()[0].text)
    colder
    call assert_equal(2, len(getqflist()))
    Cfilter! /warning:/
    call assert_equal('error: broken', getqflist()[0].text)
endif
call setloclist(0, [{'bufnr': bufnr('%'), 'lnum': 1, 'text': 'old diagnostics'}])
call setloclist(0, [{'bufnr': bufnr('%'), 'lnum': 2, 'text': 'new diagnostics'}])
execute "normal " . get(g:, 'mapleader', '\') . 'lb'
call assert_equal('old diagnostics', getloclist(0)[0].text)
execute "normal " . get(g:, 'mapleader', '\') . 'lf'
call assert_equal('new diagnostics', getloclist(0)[0].text)
delcommand YcmCompleter
let s:messages = execute('FormatCode')
call assert_match('Optional plugin command unavailable: YcmCompleter', s:messages)
if !empty(v:errors)
    call writefile(v:errors, '/tmp/portable-c-development-errors')
    cquit
endif
qa!
