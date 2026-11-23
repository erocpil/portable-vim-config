" Managed ManShow statusline; guard against duplicate user/runtime copies.
if exists('g:loaded_portable_manshow_statusline')
    finish
endif
let g:loaded_portable_manshow_statusline = 1
set laststatus=2
let s:hostname = hostname()

function! s:SafeCall(name, args, fallback) abort
    if !exists('*' . a:name)
        return a:fallback
    endif
    try
        return call(function(a:name), a:args)
    catch
        return a:fallback
    endtry
endfunction
function! s:Shorten(text, limit) abort
    let l:text = type(a:text) == v:t_string ? a:text : string(a:text)
    return a:limit < 2 || strchars(l:text) <= a:limit
                \ ? l:text : strcharpart(l:text, 0, a:limit - 1) . '…'
endfunction
function! s:StatusEscape(text) abort
    return substitute(type(a:text) == v:t_string ? a:text : string(a:text), '%', '%%', 'g')
endfunction

" Keep the animated face outside statusline evaluation.  The statusline
" expression below only reads a buffer-local value; it never touches messages.
function! PortableVimBuddyStatus() abort
    return get(b:, 'portable_vimbuddy_face', ':-)')
endfunction
function! s:ResetBuddy() abort
    let b:portable_vimbuddy_face = ':-)'
    let b:portable_vimbuddy_position = [line('.'), col('.')]
endfunction
function! s:UpdateBuddy() abort
    let l:position = [line('.'), col('.')]
    let l:previous = get(b:, 'portable_vimbuddy_position', l:position)

    " Previous experimental cursor animation, kept for reference:
    " if l:previous[0] == l:position[0] && abs(l:previous[1] - l:position[1]) == 1
    "     let l:faces = [':-)', ':-D', ';-)', ':-P']
    "     let b:portable_vimbuddy_face = l:faces[(l:position[1] - 1) % len(l:faces)]
    " else
    "     let b:portable_vimbuddy_face = ':-)'
    " endif

    " Match the former VimBuddy cursor animation: a one-column horizontal
    " move on the same line rotates / - \ | according to the new column.
    let l:delta = l:previous[1] - l:position[1]
    if l:previous[0] == l:position[0] && (l:delta == 1 || l:delta == -1)
        let l:faces = ['/', '-', '\', '|']
        let b:portable_vimbuddy_face = ':' . l:faces[l:position[1] % 4] . ')'
    else
        let b:portable_vimbuddy_face = ':-)'
    endif
    let b:portable_vimbuddy_position = l:position
endfunction
augroup PortableManShowBuddyAnimation
    autocmd!
    autocmd BufEnter,BufWinEnter * call <SID>ResetBuddy()
    autocmd CursorMoved,CursorMovedI * call <SID>UpdateBuddy()
augroup END

function! s:IsTagbarWindow() abort
    return &l:filetype ==# 'tagbar' || bufname('%') =~# '^__Tagbar__\.'
endfunction
function! s:SpecialWindowKind(winid) abort
    let l:buf = winbufnr(a:winid)
    if l:buf < 0 || getbufvar(l:buf, 'portable_practice_id', 0)
        return ''
    endif
    let l:ft = getbufvar(l:buf, '&filetype')
    let l:bt = getbufvar(l:buf, '&buftype')
    let l:name = bufname(l:buf)
    if l:ft ==# 'nerdtree'
        return 'files'
    elseif l:bt ==# 'help' || l:ft ==# 'help'
        return 'help'
    elseif l:ft ==# 'man'
        return 'man'
    elseif l:bt ==# 'quickfix'
        let l:info = get(getwininfo(a:winid), 0, {})
        return get(l:info, 'loclist', 0) ? 'location' : 'quickfix'
    elseif l:bt ==# 'terminal'
        return 'terminal'
    elseif getwinvar(win_id2win(a:winid), '&previewwindow')
        return 'preview'
    elseif l:ft ==# 'netrw'
        return 'files'
    elseif index(['fugitive', 'fugitiveblame', 'git', 'gitrebase'], l:ft) >= 0
        return 'git'
    elseif l:bt ==# 'nofile'
        return 'report'
    endif
    return ''
endfunction

function! s:ListFields(winid, kind) abort
    if a:kind ==# 'quickfix'
        let l:list = getqflist({'title': 1, 'idx': 1, 'size': 1})
    else
        let l:winnr = win_id2win(a:winid)
        let l:list = l:winnr ? getloclist(l:winnr, {'title': 1, 'idx': 1, 'size': 1}) : {}
    endif
    let l:title = substitute(get(l:list, 'title', ''), '^:', '', '')
    let l:mode = get(l:list, 'size', 0)
                \ ? printf('%d/%d', get(l:list, 'idx', 0), l:list.size) : '0/0'
    return [l:title, l:mode]
endfunction
function! s:SpecialWindowFields(winid, kind) abort
    let l:buf = winbufnr(a:winid)
    let l:name = bufname(l:buf)
    let l:title = {
                \ 'files': 'Files', 'symbols': 'Symbols',
                \ 'help': 'Help', 'man': 'Man', 'quickfix': 'Quickfix',
                \ 'location': 'Location List', 'terminal': 'Terminal',
                \ 'preview': 'Preview', 'git': 'Git',
                \ 'report': 'Report'
                \ }[a:kind]
    let l:info = ''
    let l:mode = ''
    if a:kind ==# 'help'
        let l:info = fnamemodify(l:name, ':t:r')
    elseif a:kind ==# 'man' || a:kind ==# 'preview'
        let l:info = fnamemodify(l:name, ':t')
    elseif a:kind ==# 'terminal'
        let l:mode = exists('*term_getstatus') ? substitute(term_getstatus(l:buf), ',', ' ', 'g') : ''
    elseif a:kind ==# 'quickfix' || a:kind ==# 'location'
        let [l:info, l:mode] = s:ListFields(a:winid, a:kind)
    elseif a:kind ==# 'files'
        let l:root = getbufvar(l:buf, 'netrw_curdir', '')
        let l:info = empty(l:root) ? '' : fnamemodify(l:root, ':t')
        let l:mode = '%l/%L %P'
    elseif a:kind ==# 'git'
        let l:info = s:SafeCall('FugitiveHead', [], '')
    elseif a:kind ==# 'report'
        let l:info = l:name
    endif
    let l:winnr = win_id2win(a:winid)
    let l:limit = max([8, (l:winnr ? winwidth(l:winnr) : 30) - 22])
    return [l:title, s:Shorten(l:info, l:limit), l:mode]
endfunction

function! PortableManShowTitle() abort
    let l:kind = s:SpecialWindowKind(win_getid())
    if !empty(l:kind)
        let [l:title, l:info, l:mode] = s:SpecialWindowFields(win_getid(), l:kind)
        return l:title . (empty(l:info) ? '' : ' — ' . l:info)
    endif
    let l:fileinfo = s:SafeCall('FileInfo', [], '')
    let l:path = expand('%:p')
    let l:name = empty(l:path) ? '[No Name]' : fnamemodify(l:path, ':t')
    let l:directory = empty(l:path) ? '' : fnamemodify(l:path, ':h')
    return l:name . (empty(l:directory) ? '' : ' ' . l:directory)
                \ . (empty(l:fileinfo) ? '' : ' ' . l:fileinfo)
                \ . printf(' %d/%d-%d%%', line('.'), line('$'), line('.') * 100 / max([1, line('$')]))
endfunction
function! PortableManShowTagName() abort
    return s:SafeCall('GetTagName', [line('.')], '')
endfunction
function! PortableManShowCapsLock() abort
    return s:SafeCall('CapsLockSTATUSLINE', [], '')
endfunction
function! PortableManShowHostName() abort
    return s:hostname
endfunction
function! s:SetTitle() abort
    if has('gui_running')
        " Keep the leading filename: titlelen's default truncates the left side.
        set title titlelen=0
        let &titlestring = '%{PortableManShowTitle()}'
    endif
endfunction

function! PortableSpecialStatusline() abort
    let l:winid = get(g:, 'statusline_winid', win_getid())
    let l:kind = s:SpecialWindowKind(l:winid)
    if empty(l:kind)
        return ''
    endif
    let [l:title, l:info, l:mode] = s:SpecialWindowFields(l:winid, l:kind)
    let l:info = s:StatusEscape(l:info)
    let l:active = l:winid == win_getid()
    if !l:active
        return '%#StatusLineNC#[' . l:title . ']'
                    \ . (empty(l:info) ? '' : ' ' . l:info) . '%='
                    \ . (empty(l:mode) ? '' : ' ' . l:mode . ' ')
    endif
    let l:line = '%#SpecialStatusTitle#[' . l:title . '] '
    let l:line .= '%#SpecialStatusInfo#' . l:info
    let l:line .= '%#SpecialStatusFill#%='
    if !empty(l:mode)
        let l:line .= '%#SpecialStatusMode# ' . l:mode . ' '
    endif
    return l:line
endfunction
function! s:SetSpecialStatusline() abort
    if empty(s:SpecialWindowKind(win_getid()))
        return 0
    endif
    let w:portable_manshow_statusline = 0
    let &l:statusline = '%!PortableSpecialStatusline()'
    return 1
endfunction

function! s:PositionFields(level) abort
    let l:line = '%#StatuslineLine#%l%#StatuslineLineColumnSep#:%#StatuslineColumn#%c%V'
    if a:level > 0
        let l:line .= '%#StatuslineColumnCountSep#/%#StatuslineLineCount#%L '
        let l:line .= '%#StatuslinePercent#%P'
    endif
    return l:line
endfunction
function! s:BuildActiveStatusline(gui) abort
    let l:width = winwidth(0)
    let l:level = l:width < 55 ? 0 : l:width < 88 ? 1 : 2
    let l:line = a:gui ? '%#StatuslineBufNr#%-1.2n' : ''
    let l:line .= '%#StatuslineFlag#%h%m%r%w %#StatuslineFileName#%<%t'
    if l:level == 2
        let l:line .= ' %#StatuslineFileEnc#%{&fileencoding} %#StatuslineFileFormat#%{&fileformat}'
        let l:line .= ' %#StatuslineFileType#%{strlen(&ft) ? "." . &ft : "**"}'
        let l:line .= ' %#GetTagName#%{PortableManShowTagName()}%0*'
    elseif l:level == 1
        let l:line .= ' %#StatuslineFileType#%{strlen(&ft) ? "." . &ft : ""}%0*'
    endif
    let l:line .= '%#StatuslineFill#%='
    if l:level == 2 && a:gui
        let l:line .= '%#StatuslineChar#%-2B '
    endif
    let l:line .= s:PositionFields(l:level)
    if l:level == 2
        if a:gui
            let l:line .= ' %#StatuslineCapsBuddy#%{PortableManShowCapsLock()}'
        endif
        let l:line .= ' %#StatuslineBuddy#%{PortableVimBuddyStatus()}'
    endif
    let l:line .= ' %#StatuslineHostName#%{PortableManShowHostName()}'
    let l:line .= a:gui ? '%0*' : ' local%0*'
    return l:line
endfunction
function! s:SetActiveStatusline(gui) abort
    if get(b:, 'portable_practice_id', 0) || s:IsTagbarWindow()
        return
    endif
    if s:SetSpecialStatusline()
        return
    endif
    let w:portable_manshow_statusline = 1
    let &l:statusline = s:BuildActiveStatusline(a:gui)
    call s:SetTitle()
endfunction
function! s:SetInactiveStatusline() abort
    if get(b:, 'portable_practice_id', 0) || s:IsTagbarWindow()
        return
    endif
    if s:SetSpecialStatusline()
        return
    endif
    let w:portable_manshow_statusline = 1
    let &l:statusline = '%#StatusLineNC#%h%m%r%w %<%t%=%l:%c '
endfunction
function! s:ResizeStatusline() abort
    if !get(w:, 'portable_manshow_statusline', 0) || get(b:, 'portable_practice_id', 0)
                \ || &buftype !=# ''
        return
    endif
    call s:SetActiveStatusline(has('gui_running'))
endfunction

augroup PortableManShowStatusline
    autocmd!
    autocmd BufEnter,BufWinEnter,WinEnter,BufFilePost,BufWritePost,FileType * call <SID>SetActiveStatusline(has('gui_running'))
    autocmd BufLeave,WinLeave * call <SID>SetInactiveStatusline()
augroup END
if exists('##WinResized')
    augroup PortableManShowStatuslineResize
        autocmd!
        autocmd WinResized * call <SID>ResizeStatusline()
    augroup END
endif
call s:SetTitle()

" vim: ts=4:ft=vim:foldmethod=expr:tw=75:foldcolumn=2
