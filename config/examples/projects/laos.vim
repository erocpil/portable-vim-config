" Load explicitly: :source /path/to/config/examples/projects/laos.vim
" These are local workstation settings, not changes to the kernel repository.
let s:root = get(g:, 'portable_laos_root', fnamemodify(expand('<sfile>:p'), ':h:h:h') . '/../LaOS-private')
let s:llvm = get(g:, 'portable_llvm_bin', has('macunix') ? '/opt/homebrew/Cellar/llvm@22/22.1.8/bin' : fnamemodify(exepath('clang'), ':h'))
let s:lld = get(g:, 'portable_lld_bin', has('macunix') ? '/opt/homebrew/opt/lld@22/bin' : fnamemodify(exepath('ld.lld'), ':h'))
let s:exe_suffix = (has('win32') || has('win64')) ? '.exe' : ''
if !isdirectory(s:llvm) || !executable(s:llvm . '/clang' . s:exe_suffix) || !executable(s:llvm . '/clangd' . s:exe_suffix)
    echoerr 'Set g:portable_llvm_bin to your LLVM bin directory'
    finish
endif
let s:path_sep = has('win32') || has('win64') ? ';' : ':'
let s:path = s:llvm . s:path_sep . s:lld . s:path_sep . $PATH
let s:prefix = has('win32') || has('win64') ? 'set "PATH=' . s:path . '" && ' : 'env PATH=' . shellescape(s:path) . ' '
let s:arm64_build = 'make ARCH=aarch64 ARM64_TOOLCHAIN=llvm'
" Match run_x86_64.sh: target clang explicitly, and use the same LLD/NM.
" Quote CC as one make variable because its value includes the target option.
let s:x86_64_make = 'make ARCH=x86_64'
            \ . ' ' . shellescape('CC=' . s:llvm . '/clang' . s:exe_suffix . ' --target=x86_64-unknown-none-elf')
            \ . ' LD=' . shellescape(s:lld . '/ld.lld' . s:exe_suffix)
            \ . ' NM=' . shellescape(s:llvm . '/llvm-nm' . s:exe_suffix)
let s:x86_64_build = s:x86_64_make . ' iso'
let g:portable_vim_projects = get(g:, 'portable_vim_projects', {})
let g:portable_vim_projects['laos-arm64'] = {
            \ 'root': s:root,
            \ 'build': s:prefix . s:arm64_build,
            \ 'clangd': s:llvm . '/clangd' . s:exe_suffix,
            \ 'compilation_database': '.',
            \ 'database_command': s:prefix . 'bear -- ' . s:arm64_build . ' -B',
            \ 'tasks': {'kernel': s:prefix . s:arm64_build . ' kernel',
            \           'module': s:prefix . s:arm64_build . ' module',
            \           'image': s:prefix . s:arm64_build . ' iso',
            \           'check-config': s:prefix . s:arm64_build . ' test-task-conf-v1'},
            \ 'log_file': fnamemodify(expand('<sfile>:p'), ':h:h:h') . '/laos-arm64.build.json',
            \ 'session': fnamemodify(expand('<sfile>:p'), ':h:h:h') . '/laos-arm64.session.vim'}
let g:portable_vim_projects['laos-x86_64'] = {
            \ 'root': s:root,
            \ 'build': s:prefix . s:x86_64_build,
            \ 'clangd': s:llvm . '/clangd' . s:exe_suffix,
            \ 'compilation_database': '.',
            \ 'database_command': s:prefix . 'bear -- ' . s:x86_64_make . ' -B iso',
            \ 'tasks': {'kernel': s:prefix . s:x86_64_make . ' kernel',
            \           'module': s:prefix . s:x86_64_make . ' module',
            \           'image': s:prefix . s:x86_64_make . ' iso',
            \           'check-config': s:prefix . s:x86_64_make . ' test-task-conf-v1'},
            \ 'log_file': fnamemodify(expand('<sfile>:p'), ':h:h:h') . '/laos-x86_64.build.json',
            \ 'session': fnamemodify(expand('<sfile>:p'), ':h:h:h') . '/laos-x86_64.session.vim'}
