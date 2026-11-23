set nomore
try
    execute 'source ' . fnameescape(fnamemodify(expand('<sfile>:p'), ':h:h') . '/dotvimrc')
    unlet! t:portable_project
    let s:root = tempname()
    call mkdir(s:root, 'p')
    execute 'lcd ' . fnameescape(s:root)
    let &g:makeprg = 'printf "probe.c:3:2: warning: inherited options\n"'
    let &g:errorformat = '%f:%l:%c: warning: %m'
    let &l:makeprg = ''
    let &l:errorformat = ''
    call assert_equal('', &l:makeprg)
    call assert_equal('', &l:errorformat)
    let v:errmsg = ''
    silent! BuildLog
    call assert_match('No build output', v:errmsg)
    let v:errmsg = ''
    silent! BuildLogLoad
    call assert_match('Specify a saved log file', v:errmsg)
    BuildAsync
    let s:id = getqflist({'id': 0}).id
    let s:start = reltime()
    while get(get(g:, 'portable_vim_build_result', {}), 'qfid', 0) != s:id && reltimefloat(reltime(s:start)) < 10
        sleep 20m
    endwhile
    call assert_equal(0, g:portable_vim_build_result.status)
    call assert_equal(&g:makeprg, g:portable_vim_build_result.command)
    let s:items = filter(getqflist({'id': s:id, 'items': 1}).items, 'v:val.valid')
    call assert_equal(1, len(s:items))
    if !empty(s:items)
        call assert_equal(3, s:items[0].lnum)
        call assert_equal('inherited options', s:items[0].text)
    endif
    BuildLog
    call assert_equal(['probe.c:3:2: warning: inherited options'], getline(1, '$'))
    call assert_equal(0, &modifiable)
    close
    execute 'BuildLogSave ' . fnameescape(s:root . '/saved.json')
    execute 'BuildLogLoad ' . fnameescape(s:root . '/saved.json')
    call assert_equal(1, len(filter(getqflist(), 'v:val.valid')))
    cclose
    call writefile(['probe.c:4:2: warning: raw inherited options'], s:root . '/raw.log')
    execute 'BuildLogLoad ' . fnameescape(s:root . '/raw.log')
    call assert_equal(4, filter(getqflist(), 'v:val.valid')[0].lnum)
    cclose
    let t:portable_project = {'root': s:root, 'tasks': {'probe': 'printf "probe.c:5:2: warning: task inherited options\n"'}}
    ProjectTask probe
    let s:id = getqflist({'id': 0}).id
    let s:start = reltime()
    while g:portable_vim_build_result.qfid != s:id && reltimefloat(reltime(s:start)) < 10
        sleep 20m
    endwhile
    call assert_equal(5, filter(getqflist(), 'v:val.valid')[0].lnum)
    unlet t:portable_project
    let &l:makeprg = 'printf "local build\n"'
    BuildAsync
    let s:id = getqflist({'id': 0}).id
    let s:start = reltime()
    while g:portable_vim_build_result.qfid != s:id && reltimefloat(reltime(s:start)) < 10
        sleep 20m
    endwhile
    call assert_equal(&l:makeprg, g:portable_vim_build_result.command)
    let s:saved = readfile(s:root . '/saved.json')
    let v:errmsg = ''
    execute 'silent! BuildLogSave ' . fnameescape(s:root . '/saved.json')
    call assert_match('overwrite', v:errmsg)
    call assert_equal(s:saved, readfile(s:root . '/saved.json'))
    call mkdir(s:root . '/directory-log', 'p')
    call writefile(['keep'], s:root . '/directory-log/sentinel')
    try
        execute 'BuildLogSave! ' . fnameescape(s:root . '/directory-log')
        call assert_report('Saving over directory should fail')
    catch /existing file preserved/
    endtry
    call assert_equal(['keep'], readfile(s:root . '/directory-log/sentinel'))
    call assert_equal([], glob(s:root . '/.vim-build-log-*', 0, 1))
    call writefile(['{broken'], s:root . '/invalid.json')
    let s:oldid = getqflist({'id': 0}).id
    let v:errmsg = ''
    try
        execute 'BuildLogLoad ' . fnameescape(s:root . '/invalid.json')
        call assert_report('Invalid JSON should be rejected')
    catch /Invalid build log JSON/
    endtry
    call assert_equal(s:oldid, getqflist({'id': 0}).id)
    let &l:makeprg = 'exec sleep 10'
    BuildAsync
    let s:id = getqflist({'id': 0}).id
    let v:errmsg = ''
    silent! BuildAsync
    call assert_match('already running', v:errmsg)
    BuildLog
    call assert_equal(0, &modifiable)
    close
    let v:errmsg = ''
    execute 'silent! BuildLogSave! ' . fnameescape(s:root . '/saved.json')
    call assert_match('Build is running', v:errmsg)
    call assert_equal(s:saved, readfile(s:root . '/saved.json'))
    BuildStop
    let s:start = reltime()
    while g:portable_vim_build_result.qfid != s:id && reltimefloat(reltime(s:start)) < 10
        sleep 20m
    endwhile
    call assert_equal(1, g:portable_vim_build_result.stopped)
    call setqflist([], 'f')
    BuildResults
    call assert_equal(resolve(s:root), resolve(getqflist({'context': 1}).context.root))
    cclose
    let t:portable_project = {'root': s:root, 'database_command': 'printf "database task\n"'}
    BuildDatabase
    let s:id = getqflist({'id': 0}).id
    let s:start = reltime()
    while g:portable_vim_build_result.qfid != s:id && reltimefloat(reltime(s:start)) < 10
        sleep 20m
    endwhile
    call assert_equal(0, g:portable_vim_build_result.status)
    call assert_equal(['database task'], g:portable_vim_build_result.lines)
    let t:portable_project = {}
    let &l:makeprg = 'true'
    ProjectBuild
    call assert_equal(0, v:shell_error)
    unlet t:portable_project
    let &g:makeprg = ''
    let &l:makeprg = ''
    let v:errmsg = ''
    silent! BuildAsync
    call assert_match('Set makeprg', v:errmsg)
    let s:oldid = getqflist({'id': 0}).id
    call assert_match('no project selected in this tab', execute('BuildDatabase'))
    let t:portable_project = {'name': 'missing-db', 'root': s:root, 'build': 'true'}
    call assert_match('project missing-db has no database_command', execute('BuildDatabase'))
    call assert_equal(s:oldid, getqflist({'id': 0}).id)
catch
    call add(v:errors, v:exception . ' at ' . v:throwpoint)
endtry
call writefile(v:errors, '/tmp/portable-build-defaults-errors')
if !empty(v:errors)
    cquit
endif
qa!
