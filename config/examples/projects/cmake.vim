" Adjust the root, then source this file; select using :Project c-app.
let g:portable_vim_projects = get(g:, 'portable_vim_projects', {})
let g:portable_vim_projects['c-app'] = {
            \ 'root': expand('~/src/c-app'),
            \ 'build': 'cmake --build build',
            \ 'database_command': 'cmake -S . -B build -DCMAKE_EXPORT_COMPILE_COMMANDS=ON',
            \ 'tasks': {'test': 'ctest --test-dir build --output-on-failure'},
            \ 'log_file': expand('~/c-app.build.json'),
            \ 'session': expand('~/c-app.session.vim')}
" Existing build directories retain their generator. A fresh build directory
" needs Makefiles or Ninja to export compile_commands.json.
