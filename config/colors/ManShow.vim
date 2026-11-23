" ManShow: light green theme, based on the original personal ManShow theme.
" Colors only: editor behavior and mappings belong in vimrc.
set background=light
highlight clear
if exists("syntax_on")
    syntax reset
endif
let g:colors_name = 'ManShow'

" ANSI palette for :DebugProgram terminals.  LLDB uses yellow for prompts and
" emphasis; muted amber remains readable on ManShow's light green background.
" Normal program terminals retain Vim's standard ANSI palette.
let g:portable_vim_debugger_theme_ansi_colors = [
            \ '#203020', '#a32222', '#356a38', '#805100',
            \ '#174f9e', '#7a368f', '#0b6870', '#64715f',
            \ '#53634d', '#c43b32', '#2f7a42', '#6b5a00',
            \ '#2868bd', '#9147a4', '#087985', '#000000']

highlight CursorColumn guibg=#d0e5c4 ctermbg=252 cterm=NONE
highlight MatchParen guibg=Yellow guifg=#00B2BF gui=bold ctermfg=37 ctermbg=226 cterm=bold
highlight lCursor guifg=White guibg=Black ctermfg=231 ctermbg=16 cterm=NONE
highlight Normal guifg=#000000 guibg=#daeece ctermfg=16 ctermbg=194 cterm=NONE
highlight NonText guifg=#64745d guibg=#daeece gui=NONE ctermfg=241 ctermbg=194 cterm=NONE
highlight SpecialKey guifg=#64745d guibg=NONE ctermfg=241 ctermbg=NONE cterm=NONE
highlight Title guifg=Black gui=bold ctermfg=16 cterm=bold
highlight Visual guibg=#bbddff ctermbg=153 cterm=NONE
highlight Comment guifg=#40654a guibg=NONE gui=italic ctermfg=239 ctermbg=NONE cterm=NONE
highlight Constant guifg=#aa0000 ctermfg=124 cterm=NONE
highlight Number guifg=#aa0000 ctermfg=124 cterm=NONE
highlight String guifg=Blue ctermfg=21 cterm=NONE
highlight Identifier guifg=#0033cc ctermfg=26 cterm=NONE
highlight Operator guifg=#944078 gui=bold ctermfg=96 cterm=bold
highlight Function guifg=#7a368f guibg=NONE gui=NONE ctermfg=96 ctermbg=NONE cterm=NONE
highlight PreProc guifg=#8b287f guibg=NONE ctermfg=90 ctermbg=NONE cterm=NONE
highlight Special guifg=#cc6600 ctermfg=166 cterm=NONE
highlight Statement guifg=#8B22F4 gui=bold ctermfg=93 cterm=bold
highlight Type guifg=#0066cc ctermfg=26 cterm=NONE
highlight Directory guifg=#0066cc gui=bold ctermfg=26 cterm=bold
highlight DiffAdd guibg=#ccffcc ctermbg=194 cterm=NONE
highlight DiffChange guibg=#ffffcc ctermbg=230 cterm=NONE
highlight DiffDelete guifg=#6699cc guibg=#bbeeff gui=bold ctermfg=68 ctermbg=159 cterm=bold
highlight DiffText guibg=#ffcccc gui=bold ctermbg=224 cterm=bold
highlight Folded guifg=#53634d guibg=#cde0c2 ctermfg=240 ctermbg=252 cterm=NONE
highlight SignColumn guifg=#315d8a guibg=#daeece ctermfg=60 ctermbg=194 cterm=NONE
highlight LineNr guifg=#63775c guibg=#d4e8c8 ctermfg=65 ctermbg=188 cterm=NONE
highlight FoldColumn guifg=#63775c guibg=#d4e8c8 ctermfg=65 ctermbg=188 cterm=NONE
highlight Search gui=reverse guibg=Black guifg=LightGreen ctermfg=120 ctermbg=16 cterm=reverse
highlight IncSearch gui=reverse cterm=reverse
highlight vimOper guifg=Purple ctermfg=129 cterm=NONE
highlight vimHiAttrib guifg=#00B2BF ctermfg=37 cterm=NONE
highlight vimOption gui=bold guifg=#0F99FF ctermfg=33 cterm=bold
" Alternative green background: guibg=#e4f5dc
highlight CursorLine guibg=#c8f6ff gui=NONE ctermbg=195 cterm=NONE
" Center-out palette: the fill stays near Normal; warmth grows to the left
" (tag, type, format, encoding, filename, flags, buffer number), while cool
" cyan/blue/indigo grows to the right, including separators and rare fields.
" All 19 primary panels have distinct GUI and 256-color backgrounds.
highlight StatuslineBufNr guifg=#5e3326 guibg=#e9bca5 ctermfg=16 ctermbg=216 gui=NONE cterm=NONE
highlight StatuslineLastBufferNr guifg=#5e3326 guibg=#e9bca5 ctermfg=16 ctermbg=216 gui=NONE cterm=NONE
highlight StatuslineFlag guifg=#593a26 guibg=#ebc8ac ctermfg=16 ctermbg=223 gui=NONE cterm=NONE
highlight StatuslinePath guifg=#534126 guibg=#ecd3b5 ctermfg=16 ctermbg=180 gui=NONE cterm=NONE
highlight StatuslineFileName guifg=#534126 guibg=#ecd3b5 ctermfg=16 ctermbg=180 gui=NONE cterm=NONE
highlight StatuslineFileEnc guifg=#4e4629 guibg=#e9ddbd ctermfg=16 ctermbg=186 gui=NONE cterm=NONE
highlight StatuslineFileFormat guifg=#44472b guibg=#e5e3c4 ctermfg=16 ctermbg=187 gui=NONE cterm=NONE
highlight StatuslineFileBomb guifg=#4e4629 guibg=#e9ddbd ctermfg=16 ctermbg=186 gui=NONE cterm=NONE
highlight StatuslineFileType guifg=#3e472d guibg=#e1e7c9 ctermfg=16 ctermbg=229 gui=NONE cterm=NONE
highlight StatuslineTermEnc guifg=#4e4629 guibg=#e9ddbd ctermfg=16 ctermbg=186 gui=NONE cterm=NONE
highlight SpellLang guifg=#44472b guibg=#e5e3c4 ctermfg=16 ctermbg=187 gui=NONE cterm=NONE
highlight StatuslineFoldInfo guifg=#3e472d guibg=#e1e7c9 ctermfg=16 ctermbg=229 gui=NONE cterm=NONE
highlight TextMode guifg=#3e472d guibg=#e1e7c9 ctermfg=16 ctermbg=229 gui=NONE cterm=NONE
highlight StatuslineRealSyn guifg=#3e472d guibg=#e1e7c9 ctermfg=16 ctermbg=229 gui=NONE cterm=NONE
highlight StatuslineSyn guifg=#39462e guibg=#dfe9cc ctermfg=16 ctermbg=193 gui=NONE cterm=NONE
highlight GetTagName guifg=#39462e guibg=#dfe9cc ctermfg=16 ctermbg=193 gui=NONE cterm=NONE
highlight FileTime guifg=#534126 guibg=#ecd3b5 ctermfg=16 ctermbg=180 gui=NONE cterm=NONE
highlight StatusLine guifg=#344438 guibg=#dcebcf ctermfg=16 ctermbg=194 gui=NONE cterm=NONE
highlight MvpInfo guifg=#294054 guibg=#bddbe9 ctermfg=16 ctermbg=153 gui=NONE cterm=NONE
" Neutral anchor near the editor background; inactive padding uses StatusLineNC.
highlight StatuslineFill guifg=#344438 guibg=#dcebcf ctermfg=16 ctermbg=194 gui=NONE cterm=NONE
highlight StatuslineChar guifg=#2c4745 guibg=#d1e9dd ctermfg=16 ctermbg=158 gui=NONE cterm=NONE
highlight StatuslineCapsBuddy guifg=#313056 guibg=#b7c1ec ctermfg=16 ctermbg=146 gui=NONE cterm=NONE
highlight StatuslineBuddy guifg=#352e56 guibg=#b6b9e9 ctermfg=16 ctermbg=104 gui=NONE cterm=NONE
highlight StatuslineLine guifg=#29474c guibg=#c8e5e2 ctermfg=16 ctermbg=159 gui=NONE cterm=NONE
highlight StatuslineLineColumnSep guifg=#29444f guibg=#c2e1e6 ctermfg=16 ctermbg=152 gui=NONE cterm=NONE
highlight StatuslineColumn guifg=#294054 guibg=#bddbe9 ctermfg=16 ctermbg=153 gui=NONE cterm=NONE
highlight StatuslineColumnCountSep guifg=#2b3b56 guibg=#bbd5eb ctermfg=16 ctermbg=110 gui=NONE cterm=NONE
highlight StatuslineLineCount guifg=#2c3656 guibg=#bcd2ed ctermfg=16 ctermbg=111 gui=NONE cterm=NONE
highlight StatuslinePercent guifg=#2e3256 guibg=#b8c9ed ctermfg=16 ctermbg=147 gui=NONE cterm=NONE
highlight StatuslinePracticeStatus guifg=#3c2a56 guibg=#b9ace5 ctermfg=16 ctermbg=99 gui=NONE cterm=NONE
highlight StatuslineTime guifg=#534126 guibg=#ecd3b5 ctermfg=16 ctermbg=180 gui=NONE cterm=NONE
highlight StatuslineSomething guifg=#64715f guibg=#e0e8dc ctermfg=241 ctermbg=254 gui=NONE cterm=NONE
highlight StatusLineNC guifg=#64715f guibg=#e0e8dc gui=NONE ctermfg=241 ctermbg=254 cterm=NONE
highlight StatuslineHostName guifg=#392c56 guibg=#b5b2e6 ctermfg=16 ctermbg=105 gui=bold cterm=bold
" Compact Tagbar statusline: warm title, neutral fill, cool mode.
highlight TagbarStatusTitle guifg=#5e3326 guibg=#e9bca5 ctermfg=16 ctermbg=216 gui=bold cterm=bold
highlight TagbarStatusFill guifg=#344438 guibg=#dcebcf ctermfg=16 ctermbg=194 gui=NONE cterm=NONE
highlight TagbarStatusMode guifg=#2c3656 guibg=#bcd2ed ctermfg=16 ctermbg=111 gui=NONE cterm=NONE
" Shared layout for help, explorers, quickfix, terminals and reports.
highlight SpecialStatusTitle guifg=#5e3326 guibg=#e9bca5 ctermfg=16 ctermbg=216 gui=bold cterm=bold
highlight SpecialStatusInfo guifg=#44472b guibg=#e5e3c4 ctermfg=16 ctermbg=187 gui=NONE cterm=NONE
highlight SpecialStatusFill guifg=#344438 guibg=#dcebcf ctermfg=16 ctermbg=194 gui=NONE cterm=NONE
highlight SpecialStatusMode guifg=#2c3656 guibg=#bcd2ed ctermfg=16 ctermbg=111 gui=NONE cterm=NONE
highlight Cursor gui=bold guifg=White guibg=Magenta ctermfg=231 ctermbg=201 cterm=bold
highlight iCursor guifg=White guibg=red ctermfg=231 ctermbg=196 cterm=NONE
highlight CursorIM guifg=Purple guibg=Red ctermfg=129 ctermbg=196 cterm=NONE
highlight StdFunction guifg=#7a368f guibg=NONE gui=bold ctermfg=96 ctermbg=NONE cterm=bold
highlight cUserLabel guifg=Purple gui=bold,italic ctermfg=129 cterm=bold
highlight UserLabel2 guifg=#c96129 gui=bold ctermfg=166 cterm=bold
highlight StdName guifg=#5276e6 gui=bold ctermfg=68 cterm=bold
highlight MicroController guifg=#d00000 gui=bold ctermfg=160 cterm=bold
highlight AnsiFuncPtr guifg=#ff0000 gui=NONE ctermfg=196 cterm=NONE
highlight PreCondit guifg=#a06129 gui=NONE ctermfg=130 cterm=NONE
highlight OperatorBold guifg=#875700 gui=bold ctermfg=94 cterm=bold
highlight BlockBraces guifg=#875700 gui=bold ctermfg=94 cterm=bold
highlight cMathOperator guifg=#2207E4 ctermfg=20 cterm=NONE
highlight cPointerOperator gui=bold guifg=#0EAFA2 ctermfg=37 cterm=bold
highlight cLogicalOperator guifg=#FF0F0F ctermfg=196 cterm=NONE
highlight cBinaryOperator guifg=#F0088C gui=NONE ctermfg=198 cterm=NONE
highlight cBinaryOperatorError guifg=white guibg=#b2377a ctermfg=231 ctermbg=132 cterm=NONE
highlight cSemicolon guifg=#077F7F ctermfg=30 cterm=NONE
highlight cThis gui=bold guifg=LimeGreen ctermfg=77 cterm=bold
highlight ccString guifg=#5BBD2B ctermfg=70 cterm=NONE
highlight cccout guifg=#79378B ctermfg=96 cterm=NONE
highlight ccendl guifg=#C57CAC ctermfg=175 cterm=NONE
highlight cAsk guifg=#FF0000 ctermfg=196 cterm=NONE
highlight cDefine guifg=#0F0FF0 ctermfg=21 cterm=NONE
highlight TabIndent guifg=Grey40 ctermfg=241 cterm=NONE
highlight cParenError gui=bold guifg=red guibg=Grey80 ctermfg=196 ctermbg=252 cterm=bold
highlight Error guifg=#a32222 guibg=#f2d5cb gui=bold ctermfg=124 ctermbg=224 cterm=bold
highlight cCustomFunc gui=bold guifg=#AE0072 ctermfg=125 cterm=bold
highlight cCustomClass gui=bold guifg=#F57CAC ctermfg=211 cterm=bold
highlight cCustomScope gui=bold guifg=#00F5FF ctermfg=51 cterm=bold
highlight cType guifg=#A00F15 ctermfg=124 cterm=NONE
highlight Q_OBJECT guifg=#300A15 ctermfg=234 cterm=NONE
highlight qfLineNr guibg=Yellow guifg=Black ctermfg=16 ctermbg=226 cterm=NONE
highlight cStorageClass gui=bold guifg=#0B90E1 ctermfg=32 cterm=bold
highlight gtkType gui=italic guifg=#00B2BF ctermfg=37 cterm=NONE
highlight gtkFunction gui=italic guifg=#0B90E1 ctermfg=32 cterm=NONE
highlight gdkFunction gui=bold guifg=#0B90E1 ctermfg=32 cterm=bold
highlight gdkType gui=bold guifg=#0A90E1 ctermfg=32 cterm=bold
highlight glibType gui=italic,bold guifg=#0B90E1 ctermfg=32 cterm=bold
highlight gtkMacro gui=italic guifg=#0B90E1 ctermfg=32 cterm=NONE
highlight glibMacro gui=bold guifg=#0B90E1 ctermfg=32 cterm=bold
highlight CursorLineNr guifg=#294f31 guibg=#d4e8c8 gui=bold ctermfg=237 ctermbg=188 cterm=bold
highlight VertSplit guifg=#a7b99b guibg=#daeece gui=NONE ctermfg=248 ctermbg=194 cterm=NONE
highlight Pmenu guifg=#20351e guibg=#c6dbba ctermfg=235 ctermbg=187 cterm=NONE
highlight PmenuSel guifg=#ffffff guibg=#426c4b gui=bold ctermfg=231 ctermbg=239 cterm=bold
highlight PmenuSbar guibg=#b2c9a4 ctermbg=151 cterm=NONE
highlight PmenuThumb guibg=#6f8c63 ctermbg=65 cterm=NONE
highlight ErrorMsg guifg=#a32222 guibg=NONE gui=bold ctermfg=124 ctermbg=NONE cterm=bold
highlight WarningMsg guifg=#805100 guibg=NONE gui=bold ctermfg=94 ctermbg=NONE cterm=bold
highlight YcmErrorSign guifg=#a32222 guibg=#daeece gui=bold ctermfg=124 ctermbg=194 cterm=bold
highlight YcmWarningSign guifg=#805100 guibg=#daeece gui=bold ctermfg=94 ctermbg=194 cterm=bold
highlight YcmErrorSection guisp=#b52b2b gui=undercurl cterm=underline
highlight YcmWarningSection guisp=#946000 gui=undercurl cterm=underline
highlight YcmErrorText guifg=#a32222 guibg=NONE ctermfg=124 ctermbg=NONE cterm=NONE
highlight YcmWarningText guifg=#805100 guibg=NONE ctermfg=94 ctermbg=NONE cterm=NONE

" Follow Normal automatically; preserve ANSI colors emitted by programs.
highlight! link Terminal Normal
highlight! link StatusLineTerm StatusLine
highlight! link StatusLineTermNC StatusLineNC
highlight! link YcmErrorPopup ErrorMsg
" Underline diagnostics without painting entire source lines.
highlight YcmErrorLine gui=NONE cterm=NONE
highlight YcmWarningLine gui=NONE cterm=NONE
