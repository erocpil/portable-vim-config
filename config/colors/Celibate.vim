" Celibate: restrained dark palette based on the original personal colorscheme.
" GUI and 256-color terminals share a softened dark blue-grey background.
set background=dark
highlight clear
if exists('syntax_on')
    syntax reset
endif
let g:colors_name = 'Celibate'

" Core colors
highlight Normal guifg=#d8dee9 guibg=#202631 ctermfg=252 ctermbg=235 gui=NONE cterm=NONE
highlight Comment guifg=#80a0ff ctermfg=111 gui=italic cterm=italic
highlight Constant guifg=#f2a6a0 ctermfg=217
highlight String guifg=#a8c97f ctermfg=150
highlight Character guifg=#a8c97f ctermfg=150
highlight Number guifg=#e7b86a ctermfg=215
highlight Boolean guifg=#e7b86a ctermfg=215
highlight Identifier guifg=#9acb83 ctermfg=150
highlight Function guifg=#c6a0e0 ctermfg=183
highlight Statement guifg=#ffad42 ctermfg=215 gui=bold cterm=bold
highlight Conditional guifg=#ffad42 ctermfg=215 gui=bold cterm=bold
highlight Repeat guifg=#ffad42 ctermfg=215 gui=bold cterm=bold
highlight Operator guifg=#d4a0c8 ctermfg=182
highlight Type guifg=#8fc7b5 ctermfg=116
highlight StorageClass guifg=#ffad42 ctermfg=215
highlight Structure guifg=#8fc7b5 ctermfg=116
highlight Typedef guifg=#8fc7b5 ctermfg=116
highlight PreProc guifg=#8fcf73 ctermfg=149
highlight Include guifg=#8fcf73 ctermfg=149
highlight Define guifg=#8fcf73 ctermfg=149
highlight Macro guifg=#8fcf73 ctermfg=149
highlight Special guifg=#e8c477 ctermfg=222
highlight SpecialChar guifg=#e8c477 ctermfg=222
highlight Tag guifg=#9ecbd3 ctermfg=152
highlight Title guifg=#c6a0e0 ctermfg=183 gui=bold cterm=bold
highlight Directory guifg=#8fb9e8 ctermfg=110 gui=bold cterm=bold
highlight Todo guifg=#151923 guibg=#e7b86a ctermfg=234 ctermbg=215 gui=bold cterm=bold
highlight Error guifg=#ffb4ab guibg=#512d35 ctermfg=224 ctermbg=239 gui=bold cterm=bold
highlight ErrorMsg guifg=#ffb4ab guibg=#512d35 ctermfg=224 ctermbg=239 gui=bold cterm=bold
highlight WarningMsg guifg=#f0c674 ctermfg=222 gui=bold cterm=bold
highlight Question guifg=#8fc7b5 ctermfg=116 gui=bold cterm=bold
highlight Ignore guifg=#778091 ctermfg=244

" Active stock C/C++ syntax groups use these links (custom cMathOperator
" groups from the old personal config were not defined by the runtime syntax).
highlight Label guifg=#e8c477 ctermfg=222
highlight Delimiter guifg=#b6c2d3 ctermfg=250 cterm=NONE
highlight Float guifg=#e7b86a ctermfg=215
highlight Exception guifg=#ffad42 ctermfg=215 gui=bold cterm=bold
highlight link cError Error
highlight link cLabel Label
highlight link cUserLabel Label
highlight link cOperator Operator
highlight link cStructure Structure
highlight link cTypedef Structure
highlight link cStorageClass StorageClass
highlight link cType Type
highlight link cInclude Include
highlight link cDefine Macro
highlight link cPreCondit PreProc
highlight link cppOperator Operator
highlight link cppStatement Statement
highlight link cppType Type
highlight link cppStorageClass StorageClass
highlight link cppStructure Structure
highlight link cppExceptions Exception

" Editor UI: no cursor, mapping, or cursorline option changes in a colorscheme.
highlight CursorLine guifg=NONE guibg=#263043 ctermfg=NONE ctermbg=236 gui=NONE cterm=NONE
highlight CursorColumn guifg=NONE guibg=#263043 ctermfg=NONE ctermbg=236 gui=NONE cterm=NONE
highlight CursorLineNr guifg=#e7b86a guibg=#263043 ctermfg=215 ctermbg=236 gui=bold cterm=bold
highlight LineNr guifg=#778091 guibg=#202631 ctermfg=244 ctermbg=235
highlight SignColumn guifg=#9ecbd3 guibg=#202631 ctermfg=152 ctermbg=235
highlight Folded guifg=#aab4c5 guibg=#252b38 ctermfg=249 ctermbg=235
highlight FoldColumn guifg=#8fb9e8 guibg=#252b38 ctermfg=110 ctermbg=235
highlight NonText guifg=#697386 guibg=#202631 ctermfg=241 ctermbg=235
highlight SpecialKey guifg=#697386 ctermfg=241
highlight Visual guifg=#f0f3f8 guibg=#39465b ctermfg=255 ctermbg=239
highlight Search guifg=#151923 guibg=#e7c66a ctermfg=234 ctermbg=179 gui=bold cterm=bold
highlight IncSearch guifg=#151923 guibg=#f2a65a ctermfg=234 ctermbg=215 gui=bold cterm=bold
highlight MatchParen guifg=#ffffff guibg=#526782 ctermfg=15 ctermbg=60 gui=bold cterm=bold
highlight VertSplit guifg=#465064 guibg=#202631 ctermfg=240 ctermbg=235 gui=NONE cterm=NONE
highlight WinSeparator guifg=#465064 guibg=#202631 ctermfg=240 ctermbg=235 gui=NONE cterm=NONE
highlight Pmenu guifg=#d8dee9 guibg=#252b38 ctermfg=252 ctermbg=235
highlight PmenuSel guifg=#ffffff guibg=#46546b ctermfg=15 ctermbg=60 gui=bold cterm=bold
highlight PmenuSbar guibg=#394252 ctermbg=239
highlight PmenuThumb guibg=#8fb9e8 ctermbg=110
highlight WildMenu guifg=#ffffff guibg=#46546b ctermfg=15 ctermbg=60 gui=bold cterm=bold
highlight StatusLine guifg=#d8dee9 guibg=#222a35 ctermfg=231 ctermbg=235 gui=NONE cterm=NONE
highlight StatusLineNC guifg=#aab4c5 guibg=#222834 ctermfg=249 ctermbg=235 gui=NONE cterm=NONE
highlight StatusLineTerm guifg=#d8dee9 guibg=#222a35 ctermfg=231 ctermbg=235 gui=NONE cterm=NONE
highlight StatusLineTermNC guifg=#aab4c5 guibg=#222834 ctermfg=249 ctermbg=235 gui=NONE cterm=NONE
highlight TabLine guifg=#aab4c5 guibg=#222834 ctermfg=249 ctermbg=235
highlight TabLineSel guifg=#ffffff guibg=#46546b ctermfg=15 ctermbg=60 gui=bold cterm=bold
highlight TabLineFill guifg=#697386 guibg=#202631 ctermfg=241 ctermbg=235
highlight QuickFixLine guifg=#ffffff guibg=#39465b ctermfg=15 ctermbg=239 gui=bold cterm=bold
highlight qfFileName guifg=#9ecbd3 ctermfg=152 gui=italic cterm=italic
highlight DiffAdd guifg=#c3e88d guibg=#25372e ctermfg=151 ctermbg=235
highlight DiffChange guifg=#e7c66a guibg=#383323 ctermfg=179 ctermbg=236
highlight DiffDelete guifg=#ffb4ab guibg=#402a32 ctermfg=224 ctermbg=238 gui=bold cterm=bold
highlight DiffText guifg=#ffffff guibg=#663d46 ctermfg=15 ctermbg=240 gui=bold cterm=bold
highlight SpellBad guifg=#ffb4ab guisp=#ff6b6b gui=undercurl,bold cterm=underline ctermfg=224
highlight SpellCap guifg=#8fb9e8 guisp=#8fb9e8 gui=undercurl cterm=underline ctermfg=110
highlight SpellRare guifg=#c6a0e0 guisp=#c6a0e0 gui=undercurl cterm=underline ctermfg=183
highlight SpellLocal guifg=#8fc7b5 guisp=#8fc7b5 gui=undercurl cterm=underline ctermfg=116

" YouCompleteMe diagnostics: distinct readable error and warning colors.
highlight YcmErrorSign guifg=#ffb4ab guibg=#202631 ctermfg=224 ctermbg=235 gui=bold cterm=bold
highlight YcmWarningSign guifg=#f0c674 guibg=#202631 ctermfg=222 ctermbg=235 gui=bold cterm=bold
highlight YcmErrorLine guibg=NONE ctermbg=NONE gui=NONE cterm=NONE
highlight YcmWarningLine guibg=NONE ctermbg=NONE gui=NONE cterm=NONE
highlight YcmErrorSection guifg=#ffb4ab guisp=#ff6b6b gui=undercurl cterm=underline ctermfg=224
highlight YcmWarningSection guifg=#f0c674 guisp=#e7b86a gui=undercurl cterm=underline ctermfg=222
highlight YcmErrorText guifg=#ffb4ab ctermfg=224
highlight YcmWarningText guifg=#f0c674 ctermfg=222
highlight YcmErrorPopup guifg=#ffb4ab guibg=#39262d ctermfg=224 ctermbg=236
highlight YcmWarningPopup guifg=#f0c674 guibg=#383323 ctermfg=222 ctermbg=236

" Center-out palette: the fill stays near Normal; cool indigo/blue/cyan
" recedes into the center from the left, then olive/gold/orange warmth grows
" to the right, including position separators and occasional fields.
" All 19 primary panels have distinct GUI and 256-color backgrounds.
highlight StatuslineBufNr guifg=#e8e2f7 guibg=#4b438f ctermfg=231 ctermbg=61 gui=NONE cterm=NONE
highlight StatuslineLastBufferNr guifg=#e8e2f7 guibg=#4b438f ctermfg=231 ctermbg=61 gui=NONE cterm=NONE
highlight StatuslineFlag guifg=#e5e2f5 guibg=#414990 ctermfg=231 ctermbg=60 gui=NONE cterm=NONE
highlight StatuslinePath guifg=#e2e2f5 guibg=#36508a ctermfg=231 ctermbg=19 gui=NONE cterm=NONE
highlight StatuslineFileName guifg=#e2e2f5 guibg=#36508a ctermfg=231 ctermbg=19 gui=NONE cterm=NONE
highlight StatuslineFileEnc guifg=#e0e2f5 guibg=#2f527d ctermfg=231 ctermbg=25 gui=NONE cterm=NONE
highlight StatuslineFileFormat guifg=#dfe3f4 guibg=#29516d ctermfg=231 ctermbg=24 gui=NONE cterm=NONE
highlight StatuslineFileType guifg=#dce7f0 guibg=#254b5b ctermfg=231 ctermbg=23 gui=NONE cterm=NONE
highlight StatuslineFileBomb guifg=#e0e2f5 guibg=#2f527d ctermfg=231 ctermbg=25 gui=NONE cterm=NONE
highlight StatuslineTermEnc guifg=#e0e2f5 guibg=#2f527d ctermfg=231 ctermbg=25 gui=NONE cterm=NONE
highlight SpellLang guifg=#dfe3f4 guibg=#29516d ctermfg=231 ctermbg=24 gui=NONE cterm=NONE
highlight StatuslineFoldInfo guifg=#dce7f0 guibg=#254b5b ctermfg=231 ctermbg=23 gui=NONE cterm=NONE
highlight StatuslineRealSyn guifg=#dce7f0 guibg=#254b5b ctermfg=231 ctermbg=23 gui=NONE cterm=NONE
highlight StatuslineSyn guifg=#d9e7e6 guibg=#254249 ctermfg=231 ctermbg=234 gui=NONE cterm=NONE
highlight GetTagName guifg=#d9e7e6 guibg=#254249 ctermfg=231 ctermbg=234 gui=NONE cterm=NONE
" Neutral anchor near the editor background; inactive padding uses StatusLineNC.
highlight StatuslineFill guifg=#d8dee9 guibg=#222a35 ctermfg=231 ctermbg=235 gui=NONE cterm=NONE
highlight StatuslineChar guifg=#dce3d8 guibg=#2b3029 ctermfg=231 ctermbg=236 gui=NONE cterm=NONE
highlight StatuslineLine guifg=#dfe5d8 guibg=#34372a ctermfg=231 ctermbg=237 gui=NONE cterm=NONE
highlight StatuslineLineColumnSep guifg=#e4e6d9 guibg=#3d3d2b ctermfg=231 ctermbg=22 gui=NONE cterm=NONE
highlight StatuslineColumn guifg=#e8e6d8 guibg=#47432d ctermfg=231 ctermbg=28 gui=NONE cterm=NONE
highlight StatuslineColumnCountSep guifg=#ece6d8 guibg=#52482f ctermfg=16 ctermbg=64 gui=NONE cterm=NONE
highlight StatuslineLineCount guifg=#f0e5d5 guibg=#5d4c30 ctermfg=231 ctermbg=58 gui=NONE cterm=NONE
highlight StatuslinePercent guifg=#f3e5d5 guibg=#684f31 ctermfg=16 ctermbg=100 gui=NONE cterm=NONE
highlight StatuslineCapsBuddy guifg=#f5e4d5 guibg=#735132 ctermfg=16 ctermbg=136 gui=NONE cterm=NONE
highlight StatuslineBuddy guifg=#f6e3d5 guibg=#7d5033 ctermfg=231 ctermbg=94 gui=NONE cterm=NONE
highlight StatuslinePracticeStatus guifg=#fae1d5 guibg=#91523a ctermfg=231 ctermbg=130 gui=NONE cterm=NONE
highlight StatuslineHostName guifg=#f8e2d5 guibg=#875138 ctermfg=16 ctermbg=172 gui=bold cterm=bold
highlight MvpInfo guifg=#e8e6d8 guibg=#47432d ctermfg=231 ctermbg=28 gui=NONE cterm=NONE
highlight StatuslineSomething guifg=#aab4c5 guibg=#222834 ctermfg=249 ctermbg=235
highlight StatuslineTime guifg=#e2e2f5 guibg=#36508a ctermfg=231 ctermbg=19 gui=NONE cterm=NONE
" Compact Tagbar statusline follows Celibate's cold-to-warm direction.
highlight TagbarStatusTitle guifg=#e8e2f7 guibg=#4b438f ctermfg=231 ctermbg=61 gui=bold cterm=bold
highlight TagbarStatusFill guifg=#d8dee9 guibg=#222a35 ctermfg=231 ctermbg=235 gui=NONE cterm=NONE
highlight TagbarStatusMode guifg=#f5e4d5 guibg=#735132 ctermfg=16 ctermbg=136 gui=NONE cterm=NONE
" Shared layout for help, explorers, quickfix, terminals and reports.
highlight SpecialStatusTitle guifg=#e8e2f7 guibg=#4b438f ctermfg=231 ctermbg=61 gui=bold cterm=bold
highlight SpecialStatusInfo guifg=#d9e7e6 guibg=#254249 ctermfg=231 ctermbg=234 gui=NONE cterm=NONE
highlight SpecialStatusFill guifg=#d8dee9 guibg=#222a35 ctermfg=231 ctermbg=235 gui=NONE cterm=NONE
highlight SpecialStatusMode guifg=#f5e4d5 guibg=#735132 ctermfg=16 ctermbg=136 gui=NONE cterm=NONE

" Named-color fallback for terminals without 256-color support.
if &t_Co < 256
    highlight Normal ctermfg=White ctermbg=Black
    highlight Comment ctermfg=LightBlue
    highlight Constant ctermfg=LightRed
    highlight String ctermfg=LightGreen
    highlight Character ctermfg=LightGreen
    highlight Number ctermfg=LightYellow
    highlight Boolean ctermfg=LightYellow
    highlight Identifier ctermfg=LightGreen
    highlight Function ctermfg=LightMagenta
    highlight Statement ctermfg=Yellow
    highlight Conditional ctermfg=Yellow
    highlight Repeat ctermfg=Yellow
    highlight Operator ctermfg=LightMagenta
    highlight Type ctermfg=LightCyan
    highlight StorageClass ctermfg=Yellow
    highlight Structure ctermfg=LightCyan
    highlight Typedef ctermfg=LightCyan
    highlight PreProc ctermfg=LightGreen
    highlight Include ctermfg=LightGreen
    highlight Define ctermfg=LightGreen
    highlight Macro ctermfg=LightGreen
    highlight Special ctermfg=LightYellow
    highlight SpecialChar ctermfg=LightYellow
    highlight LineNr ctermfg=DarkGrey ctermbg=Black
    highlight SignColumn ctermfg=LightCyan ctermbg=Black
    highlight Folded ctermfg=LightGrey ctermbg=DarkGrey
    highlight FoldColumn ctermfg=LightBlue ctermbg=DarkGrey
    highlight NonText ctermfg=DarkGrey ctermbg=Black
    highlight CursorLine ctermbg=DarkGrey
    highlight CursorColumn ctermbg=DarkGrey
    highlight CursorLineNr ctermfg=LightYellow ctermbg=DarkGrey
    highlight Visual ctermfg=White ctermbg=DarkGrey
    highlight Search ctermfg=Black ctermbg=Yellow
    highlight IncSearch ctermfg=Black ctermbg=LightYellow
    highlight MatchParen ctermfg=White ctermbg=Blue
    highlight Pmenu ctermfg=White ctermbg=DarkGrey
    highlight PmenuSel ctermfg=White ctermbg=Blue
    highlight StatusLine ctermfg=White ctermbg=DarkBlue
    highlight StatusLineNC ctermfg=LightGrey ctermbg=Black
    highlight StatusLineTerm ctermfg=White ctermbg=DarkBlue
    highlight StatusLineTermNC ctermfg=LightGrey ctermbg=Black
    highlight TagbarStatusTitle ctermfg=White ctermbg=DarkBlue cterm=bold
    highlight TagbarStatusFill ctermfg=White ctermbg=Black
    highlight TagbarStatusMode ctermfg=Black ctermbg=DarkYellow
    highlight SpecialStatusTitle ctermfg=White ctermbg=DarkBlue cterm=bold
    highlight SpecialStatusInfo ctermfg=White ctermbg=Black
    highlight SpecialStatusFill ctermfg=White ctermbg=Black
    highlight SpecialStatusMode ctermfg=Black ctermbg=DarkYellow
    highlight YcmErrorSign ctermfg=LightRed ctermbg=Black
    highlight YcmWarningSign ctermfg=LightYellow ctermbg=Black
    highlight YcmErrorSection ctermfg=LightRed
    highlight YcmWarningSection ctermfg=LightYellow
endif

" Keep the dark Normal colors for new terminals, including PracticeRun panes.
highlight! link Terminal Normal
" vim: sw=4:ts=4:ft=vim:foldmethod=expr:tw=75:foldcolumn=2
