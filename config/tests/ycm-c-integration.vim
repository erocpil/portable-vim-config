set nomore
runtime plugin/youcompleteme.vim
let s:dir = tempname()
call mkdir(s:dir)
let s:file = s:dir . '/sample.c'
let s:original = ['int add(int a,int b){return a+b;}',
            \ 'int main(void){return add(1,2)+add(3,4);}', '#include "sample.h"']
call writefile(s:original, s:file)
call writefile(['int add(int a, int b);'], s:dir . '/sample.h')
call writefile([json_encode([{'directory': s:dir, 'file': s:file,
            \ 'arguments': ['clang', '-std=c11', '-c', s:file]}])], s:dir . '/compile_commands.json')
call writefile(['BasedOnStyle: LLVM'], s:dir . '/.clang-format')
execute 'edit ' . fnameescape(s:file)
doautocmd VimEnter
let s:start = reltime()
let s:ready = 0
while reltimefloat(reltime(s:start)) < 15
    let s:ready = py3eval('ycm_state.CheckIfServerIsReady()')
    if s:ready
        break
    endif
    sleep 100m
endwhile
call assert_true(s:ready, 'YCM server not ready')
if s:ready
    call assert_true(py3eval('ycm_state.NativeFiletypeCompletionAvailable()'))
    py3 ycm_state.OnFileReadyToParse()
    sleep 500m
    call cursor(2, 23)
    YcmCompleter GoToDefinitionElseDeclaration
    call assert_equal(1, line('.'), 'C definition jump failed')
    call cursor(1, 5)
    YcmCompleter GoToReferences
    call assert_true(len(getqflist()) >= 1, 'C references unavailable')
    cclose
    execute 'buffer ' . bufnr(s:file)
    call cursor(1, 5)
    let s:type = py3eval("ycm_state.GetCommandResponse(['GetType'])")
    call assert_false(empty(s:type), 'C type unavailable')
    let s:doc = py3eval("ycm_state.GetCommandResponse(['GetDoc'])")
    call assert_match('add', s:doc, 'C symbol documentation unavailable')
    call setqflist([], 'r')
    call cursor(2, 1)
    FindSymbol add
    call assert_true(line('.') == 1 || !empty(getqflist()), 'C project symbol search unavailable')
    cclose
    execute 'buffer ' . bufnr(s:file)
    call cursor(3, 12)
    execute "normal " . get(g:, 'mapleader', '\') . 'yi'
    call assert_equal(resolve(s:dir . '/sample.h'), resolve(expand('%:p')), 'Include jump failed')
    execute "normal " . get(g:, 'mapleader', '\') . 'yh'
    call assert_equal(resolve(s:file), resolve(expand('%:p')), 'Alternate source jump failed')
    call cursor(1, match(getline(1), '\<b\>') + 1)
    RenameSymbol rhs
    execute 'buffer ' . bufnr(s:file)
    call assert_match('int rhs', getline(1), 'Parameter declaration rename failed')
    call assert_match('a+rhs', getline(1), 'Parameter use rename failed')
    FormatCode
    call assert_notequal(s:original, getline(1, '$'), 'C formatting did not change unformatted input')
    call assert_true(&modified, 'Formatting should leave changes unsaved')
    call assert_equal(s:original, readfile(s:file), 'Formatting unexpectedly saved the file')
endif
call writefile(empty(v:errors) ? ['PASS: C definition, references, type, docs, symbols, include, alternate file, rename, formatting; disk unchanged'] : v:errors,
            \ '/tmp/portable-ycm-c-integration-result')
if !empty(v:errors)
    call writefile(split(execute('messages'), "\n") + split(execute('YcmDebugInfo'), "\n"), '/tmp/portable-ycm-c-integration-debug')
endif
bwipeout!
execute 'silent! bwipeout! ' . fnameescape(s:dir . '/sample.h')
call delete(s:dir, 'rf')
if !empty(v:errors)
    cquit
endif
qa!
