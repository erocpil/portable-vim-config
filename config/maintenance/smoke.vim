" Called by portable-setup.py in a separate Vim process.
set nomore
let s:dir = tempname()
let s:checks = split($VIM_SETUP_CHECKS, ',')
let s:passed = ['startup']
try
    call assert_equal(2, exists(':EditVimConfig'))
    call assert_equal(2, exists(':BuildAsync'))
    call assert_equal(2, exists(':PracticeRun'))
    if exists(':EditVimConfig') == 2
        EditVimConfig
        let s:expected = resolve(fnamemodify($VIM_SETUP_CONFIG, ':p'))
        let s:opened = resolve(expand('%:p'))
        if has('win32') || has('win64')
            call assert_equal(tolower(tr(s:expected, '\', '/')), tolower(tr(s:opened, '\', '/')))
        else
            call assert_equal(s:expected, s:opened)
        endif
        call assert_equal('vim', &filetype)
    endif

    if !empty(s:checks)
        call mkdir(s:dir)
        let s:file = s:dir . '/smoke.c'
        call writefile(['int add(int a, int b) { return a + b; }',
                    \ 'int main(void) { return add(19, 23) != 42; }'], s:file)
        execute 'edit ' . fnameescape(s:file)
    endif
    if index(s:checks, 'practice') >= 0
        PracticeRun
        let s:start = reltime()
        while get(get(g:, 'portable_vim_practice_result', {}), 'phase', '') !=# 'run'
                    \ && reltimefloat(reltime(s:start)) < 15
            sleep 50m
        endwhile
        let s:result = get(g:, 'portable_vim_practice_result', {})
        call assert_equal('run', get(s:result, 'phase', ''), string(s:result))
        call assert_equal(0, get(s:result, 'status', -1), string(s:result))
        call add(s:passed, 'PracticeRun')
        execute 'buffer ' . bufnr(s:file)
    endif
    if index(s:checks, 'ycm') >= 0
        call writefile([json_encode([{'directory': s:dir, 'file': s:file,
                    \ 'arguments': ['clang', '-std=c17', '-c', s:file]}])],
                    \ s:dir . '/compile_commands.json')
        runtime plugin/youcompleteme.vim
        doautocmd VimEnter
        call assert_equal(2, exists(':YcmCompleter'), 'YCM is not loaded')
        if exists(':YcmCompleter') == 2
            let s:expected_ycm = resolve(fnamemodify($VIM_SETUP_YCM, ':p'))
            let s:loaded_ycm = resolve(fnamemodify(py3eval('__import__("ycm").__file__'), ':p'))
            if has('win32') || has('win64')
                call assert_equal(tolower(tr(s:expected_ycm, '\', '/')), tolower(tr(s:loaded_ycm, '\', '/')))
            else
                call assert_equal(s:expected_ycm, s:loaded_ycm, 'Unexpected YCM checkout')
            endif
            let s:start = reltime()
            while !py3eval('ycm_state.CheckIfServerIsReady()') && reltimefloat(reltime(s:start)) < 20
                sleep 100m
            endwhile
            call assert_true(py3eval('ycm_state.CheckIfServerIsReady()'), 'ycmd did not start')
            py3 ycm_state.OnFileReadyToParse()
            sleep 500m
            call cursor(2, match(getline(2), '\<add\>') + 1)
            YcmCompleter GoToDefinitionElseDeclaration
            call assert_equal(1, line('.'), 'clangd did not jump to add()')
        endif
        call add(s:passed, 'YCM definition')
    endif
catch
    call add(v:errors, v:exception . ' at ' . v:throwpoint)
endtry
call writefile(empty(v:errors) ? ['PASS: ' . join(s:passed, ', ')] : v:errors, $VIM_SETUP_RESULT)
if isdirectory(s:dir)
    call delete(s:dir, 'rf')
endif
if !empty(v:errors)
    cquit
endif
qa!
