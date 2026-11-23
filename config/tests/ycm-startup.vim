runtime plugin/youcompleteme.vim
call assert_equal(1, has('python3'))
new /tmp/portable-ycm-check.cpp
setfiletype cpp
doautocmd VimEnter
call assert_equal(2, exists(':YcmCompleter'))
let s:start = reltime()
let s:ready = 0
while reltimefloat(reltime(s:start)) < 15
    let s:ready = py3eval('ycm_state.CheckIfServerIsReady()')
    if s:ready
        break
    endif
    sleep 100m
endwhile
call assert_true(s:ready, 'YCM server failed to become ready')
if s:ready
    call assert_true(py3eval('ycm_state.NativeFiletypeCompletionAvailable()'), 'C++ semantic completer unavailable')
    setlocal filetype=c
    call assert_true(py3eval('ycm_state.NativeFiletypeCompletionAvailable()'), 'C semantic completer unavailable')
endif
call writefile(['python3=' . has('python3'), 'YcmCompleter=' . exists(':YcmCompleter'), 'server_ready=' . s:ready] + v:errors, '/tmp/mvim-ycm-result')
if !empty(v:errors)
    cquit
endif
qa!
