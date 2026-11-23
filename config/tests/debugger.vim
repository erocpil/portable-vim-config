set nomore
let s:dir = tempname()
call mkdir(s:dir)
let s:source = s:dir . '/sample.c'
let s:program = s:dir . '/program with spaces;literal'
call writefile(['int main(void) { int value = 7; return value - 7; }'], s:source)
call system('cc -g -O0 ' . shellescape(s:source) . ' -o ' . shellescape(s:program))
call assert_equal(0, v:shell_error, 'Debug fixture compile failed')
let g:portable_vim_debugger = '/usr/bin/lldb'
execute 'DebugProgram ' . fnameescape(s:program)
let s:buffer = bufnr('%')
call assert_equal('terminal', &buftype)
call assert_equal(s:program, job_info(term_getjob(s:buffer)).cmd[-1])
call term_sendkeys(s:buffer, "breakpoint set --name main\rrun\r")
let s:start = reltime()
let s:text = ''
while reltimefloat(reltime(s:start)) < 8
    call term_wait(s:buffer, 100)
    let s:text = join(map(range(1, term_getsize(s:buffer)[0]), 'term_getline(s:buffer, v:val)'), "\n")
    if s:text =~# 'stop reason = breakpoint'
        break
    endif
endwhile
call assert_match('stop reason = breakpoint', s:text, 'LLDB did not stop at main')
call term_sendkeys(s:buffer, "quit\ry\r")
call term_wait(s:buffer, 300)
if job_status(term_getjob(s:buffer)) ==# 'run'
    call job_stop(term_getjob(s:buffer), 'kill')
endif
execute 'bwipeout! ' . s:buffer
call delete(s:dir, 'rf')
call writefile(empty(v:errors) ? ['PASS: LLDB argv path and main breakpoint'] : v:errors, '/tmp/portable-debugger-result')
if !empty(v:errors)
    call writefile(split(s:text, "\n"), '/tmp/portable-debugger-output')
    cquit
endif
qa!
