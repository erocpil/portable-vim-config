# 跨平台 Vim 配置

`dotvimrc` 是一份 Linux / Windows / macOS 配置，目标为具有多字节、autocmd、syntax 支持的 Vim 8.2+。主要设置和辅助函数内嵌于此文件；ManShow/Celibate 主题及 ManShow 状态栏维护版另存于 `colors/`、`plugin/`，供 GUI 与主题轮换加载。`vimrc.local` 仅是可选的机器专用覆盖文件，没有创建也不会影响加载。

首次部署、插件安装和验收见 [三端使用说明](../README.md)，构建及回退流程见 [维护说明](../README-git.md)。

用 `:EditVimConfig` 或 `<leader>ev` 打开实际加载的 `dotvimrc`，用 `:ReloadVimConfig` 重载。保存已加载的 `dotvimrc` 会自动重载。修改共享配置时，请编辑 Git 检出中的文件并重新部署。GUI 字体、工具链路径和项目覆盖使用本机 `vimrc.local`。

插件首选项已按 YouCompleteMe、Tagbar、NERDTree 等所属插件分组，并注明依赖和加载顺序。光标进入 Tagbar 后使用紧凑专用状态栏：左侧显示 `[Tagbar]`，右侧保留 `Name`/`Order` 排序方式及 `c/C/i/v` 标志；光标离开后显示弱化的 `[Name/Order] 标志`。源码文件名已经显示在相邻编辑窗口中，因此不在 30～45 列的 Tagbar 状态栏重复显示。该实现使用 Tagbar 原生 `g:tagbar_status_func` 接口，不修改第三方插件。内嵌 Python 的缩进保存在字符串中，避免 `gg=G` 再次破坏 Python 层级及 heredoc 结束标记。

当某个标签页中只有“源码窗口 + Tagbar”时，在源码窗口执行 `:q` 后不会留下孤立的 Tagbar 标签页：若还有其他标签页，配置会在窗口切换完成后关闭这个仅含 Tagbar 的标签页；单标签页退出、同一标签页仍有其他普通编辑窗口，以及从 Tagbar 选择符号后的行为不变。`g:tagbar_autoclose` 仍保持关闭，它只控制符号跳转后自动关闭 Tagbar。

NERDTree、Help/Man、普通终端、Preview、Netrw、Fugitive 和自定义只读报告使用统一的特殊窗口状态栏，只显示窗口用途及必要状态，不再套用源码窗口的编码、filetype、行列和主机名字段。quickfix 与 location list 分别显示 `[Quickfix]` 和 `[Location List]`；PracticeRun 终端继续使用原有的运行状态栏。非活动特殊窗口统一使用弱化的 `StatusLineNC`。

`OverLength` 是红底白字的长行提示，从第 101 个**显示列**开始，只对 Vim filetype 为 `c` 或 `cpp` 的缓冲区生效；Tab 和宽字符按实际显示宽度计算。切换文件、文件类型或窗口会更新/移除匹配。它不改变文件内容，也不负责自动换行；原有 `textwidth=78` 是另一项设置，适用于 c、cpp、java、html、xml、sh、perl、php。

## ManShow 配色

状态栏插件维护版位于 [plugin/ManShow.vim](plugin/ManShow.vim)，修复未命名缓冲区首次保存、另存为后只显示路径的问题，并清理简化布局末尾的反斜杠；结果窗口仍使用练习专用状态栏。普通窗口按宽度分为三档：低于 55 列只保留文件名、标记和行列，55–87 列增加文件类型、总行数和百分比，88 列起显示编码、格式、标签、光标字符、CapsLock 和表情。调整窗口大小时会重新布局；主机名始终显示并在插件加载时缓存；终端布局保留原有的 `local` 标记。非活动编辑窗口使用低对比度精简状态栏，只显示文件名、修改标记和行列。

CapsLock、Fugitive 和文件信息函数都通过只读安全包装调用：函数不存在或自身报错时隐藏相应字段，不让异常破坏状态栏，也不改写消息变量。状态栏自动命令使用独有的 `PortableManShowStatusline` 组，不会清空其它插件可能使用的通用 `Statusline` 组。MacVim 标题由同一个只读函数动态生成，普通编辑窗口先显示文件名，再显示文件所在目录的绝对路径，后接文件信息和行数；不再用窗口工作目录代替文件路径，切换窗口时也不清空全局 `titlestring`。GUI 设置 `titlelen=0`，避免 Vim 按默认宽度从左侧截断标题、隐藏开头的文件名；标题过长时仍可能受 macOS 标题栏可用空间限制。帮助、quickfix、location list 等特殊窗口显示对应短标题。quickfix/location list 还显示列表标题及当前项/总项数，帮助页显示主题，终端显示作业状态，netrw 显示当前目录，Fugitive 窗口显示分支；特殊窗口信息会按窗口宽度截短。

`:BuildResults`/`:BR`、`:SearchResults`、`:BuildLog`/`:BL` 和 `:BuildLogLoad`/`:BLL` 的结果固定在标签页底部以完整宽度打开，避免 Vim 在已有水平分屏时把窗口塞进右侧 NERDTree 的窄列。从 NERDTree、Tagbar、终端或其它辅助窗口执行时行为一致；关闭结果窗口后，原有代码区、PracticeRun 窗口和侧栏布局恢复。

表情动画沿用旧 VimBuddy 的规则：同一行内水平移动一列时，按新列轮换 `/ - \ |`，其它移动恢复 `:-)`；表情位于主机名前，状态栏只读当前表情。此前试验的四表情动画留在代码注释中。旧 VimBuddy 插件已停用；错误和状态消息由 Vim 原样显示。未使用的旧辅助函数及 `,t` 映射已移除。字段之间的分隔空格尽量使用相邻字段的高亮填色；特殊窗口复用主题的专用状态栏颜色。插件带重复加载保护。

维护版主题位于 [colors/ManShow.vim](colors/ManShow.vim)，随配置加载，保留浅绿背景及主要语法、彩色状态栏风格。GUI 与 256 色终端使用相应的浅色配色；注释和空白区域不再铺设不同背景，非活动状态栏改为柔和浅绿，并补齐补全菜单、分隔线、终端状态栏及 YCM 错误/警告高亮。错误与警告使用不同颜色的标记和下划线，不对整行着色。

主题不再修改光标形状或设置快捷键；`cursorline` 默认开启，使用浅青色 `#c8f6ff`；主题文件注释中保留浅绿备选值 `#e4f5dc`。切换窗口时不自动关闭，可手动 `:setlocal nocursorline`。原 `<leader>c` 来自主题的临时行标记映射不再设置；已有的 `<leader>cu` 列高亮快捷键保留。缩进辅助线按 `background` 明暗设置，切换主题时重新应用。终端默认前景/背景跟随 `Normal`，程序主动输出的 ANSI 颜色保留。

ManShow 与 Celibate 的状态栏都以中间空白为中性基准，但方向不同：ManShow 从左向右由暖转冷，Celibate 从左向右由冷转暖。每段是固定底色，不是逐字符渐变；窗口变窄或可选字段缺席时保留各字段的语义颜色，不重新分配色序。

| 从左到右的字段 | 色调方向 |
|---|---|
| 缓冲区编号、标记、文件名、编码、格式、类型、标签 | ManShow 从橙、琥珀逐步收敛；Celibate 从靛蓝、蓝、青逐步收敛 |
| 中间无信息区域 `StatuslineFill` | 接近编辑背景，ManShow 为 `#dcebcf`（Normal 为 `#daeece`），Celibate 为 `#222a35`（Normal 为 `#202631`） |
| 字符、当前行、冒号、列、斜线、总行数、百分比、CapsLock、表情、主机名、练习状态 | ManShow 逐步进入蓝、靛和冷紫；Celibate 逐步进入橄榄、金棕和橙棕 |

光标行、列、总行数分别使用 StatuslineLine、StatuslineColumn、StatuslineLineCount；冒号和斜线分别使用 StatuslineLineColumnSep、StatuslineColumnCountSep。虚拟列 %V 跟随列号颜色，显示格式仍为 行:列/总行数。主机名使用所在方向末端的强调色和粗体，不使用红色。GUI 浅底深字与深底浅字分别配色；256 色终端采用近似色阶，19 个有效色段均使用独立背景，文本与底色对比度至少为 4.5:1。非活动窗口填充仍使用 StatusLineNC 弱化。

终端简化布局、quickfix 和练习结果窗口沿用对应字段色；这些窗口的中间空白也使用 StatuslineFill。重复字段沿用同一语义色。手动检查色阶及对比度可运行 `python3 tests/statusline-palette.py`，不依赖第三方 Python 包。

## Celibate 配色

共享配置默认在支持 `termguicolors` 选项的终端 Vim 中开启真彩色。若终端不支持 RGB，可在本机 `vimrc.local` 中使用 `set notermguicolors`。

维护版 [colors/Celibate.vim](colors/Celibate.vim) 整理了原有深色主题：GUI 和真彩色终端使用深蓝灰背景 `#202631`，256 色回退使用深灰色号 235；保留蓝色注释、绿色预处理与类型、橙色语句、紫色函数等原风格；移除普通文本整体加粗及语法组的零散底色。按 Vim 内置 C/C++ 语法的实际组补充类型、存储类、运算符、标签等链接；旧主题里的 `cMathOperator` 等组不属于当前内置语法，未保留无效定义。补齐行号、折叠、补全菜单、终端状态栏和 YCM 诊断配色，错误与警告使用不同颜色，下划线为主而不铺整行底色。对低于 256 色的终端使用 ANSI 命名色回退。主题仅定义高亮，不再设置 `cursorline`、光标形状或映射。

Celibate 使用相同的语义分组，并换成适合深色背景的低饱和色值；中间使用接近编辑区的深蓝灰色。状态栏从左端冷靛蓝经过中性中央，向右过渡到暖橙棕；主机名使用暖棕色底和粗体字突出。

可用 `:colorscheme Celibate` 手动切换，或用 `<C-F9>` 在已安装主题间轮换。默认选择仍由 vimrc 决定：GUI 用 ManShow，终端用 molokai。终端 ANSI 程序输出仍可显示自己的颜色。

MacVim 使用透明标题栏时，建议在 Settings → Appearance → Dark mode selection
选择 `Use 'background' option`。这样 Celibate 的 `background=dark` 会同时切换
macOS 原生标题栏为深色外观，避免深色背景上仍使用浅色模式的深色标题文字；切回
ManShow 等浅色主题时，标题栏也会随 `background=light` 恢复。命令行等效设置为：

```sh
defaults write org.vim.MacVim MMAppearanceModeSelection -int 3
```

该设置通常需要关闭并重新打开 MacVim 窗口后完整生效。Vim 的 `Title` 高亮组只
控制 `:set all`、`:autocmd` 等命令输出中的标题，不控制 macOS 原生窗口标题栏。

## 已确认的功能取舍

折叠默认展开（`foldlevel=99`）。C/C++/Java 使用语法折叠；Perl/TeX/PHP/HTML/CSS/sh/Python 使用缩进折叠；其它类型默认手动折叠。Vimscript 保留完整函数折叠，并增加从第 1 列开始的顶层 `if/for/while/try` 块折叠，最多显示一层，函数和控制块内部不拆出嵌套折叠。该补充依赖正常缩进；有前导空格的顶层控制块不会由此规则识别。 主配置 `dotvimrc` 用按缓冲区修改缓存的扫描计算同样的折叠，打开时无需为整份配置计算语法折叠。其它 Vim 脚本仍使用语法折叠。txt/lisp 按连续非空行折叠，ero 保留原来的表达式规则。`zM` 全部折叠，`zR` 全部展开，`za` 切换当前折叠。

用户明确删除以下评估编号：

| 编号 | 删除内容 |
| --- | --- |
| 2 | 中文帮助、强制中文菜单及 locale、按语言环境强制字符双宽 |
| 8 | 未知文件默认 txt、calibre 文件类型识别 |
| 33 | OmniCppComplete |
| 38 | YankRing、Vimwiki |
| 40 | AStyle、GNU 缩进切换、C/C++ 外部字典 |
| 41 | PHP F6 语法检查及函数字典 |
| 42 | Perl 模板、prove、子程序生成、perldoc 模块打开、pltags |
| 43 | perltidy |
| 44 | 普通字典补全、英式英语拼写默认及 F3 拼写快捷键 |
| 45 | HTML 编码重读及自动闭合标签 |
| 49 | 作者头和时间戳生成、更新 |

编号 10（自动改变工作目录）于 2026-10-26 按用户要求恢复为 `set autochdir`。

Balloon 翻译也已明确删除，不加载翻译接口，不调用网络翻译服务。

其余原有已启用功能全部保留并修复。额外启用原来被注释的 Balloon 非翻译功能和主题轮换。其它原来被注释的示例继续保存在原件中，不自动启用。

## 保留功能及改进

| 功能 | 迁入后的实现 |
| --- | --- |
| 编码 | NFO 使用 CP437；txt 编码检查不丢弃修改，明确重读使用 `:ReloadEncoding 编码`。内部和新文件 UTF-8；BOM 优先，再尝试 UTF-8、GB18030、Big5、Latin1。传统编码仍可用 `:edit ++enc=cp936 文件` 明确指定 |
| 选择、鼠标、剪贴板 | 保留鼠标选择和可用的系统剪贴板；Windows 加载 mswin；Unix/macOS 使用原生按键 |
| 缩进与排版 | 四列 Tab，C/C++ 参数和表达式续行相对当前层级增加一级；括号和块注释搜索上限均为 100 行（`)100,*100`）。Python 空格、Make Tab，部分语言 78 列排版与中文格式选项 |
| 搜索和移动 | 智能大小写、增量搜索、括号高亮、跨行移动、可视选区搜索、行内百分比跳列 |
| 快捷键 | tab/buffer/window、Shift+方向键、Alt 移动、移动行、合并行、jj、去除 CR、make、编辑配置及自动重载 |
| 工作目录 | `set autochdir`：打开或切换文件时自动跟随文件所在目录 |
| 缓冲区与文件保护 | 支持未保存缓冲区切换；保留 swap 和 writebackup，避免原先关闭恢复保护。普通保存不强制覆盖只读文件 |
| 历史及 Session | 恢复原历史容量，使用 Vim 的用户 viminfo 路径；保留 unix/slash 和不保存 help 的 Session 设置 |
| 自动空白清理 | 仅处理配置的源代码文件类型；清理尾部空白和多余末尾空行。Markdown、普通文本和二进制不自动清理；手动 `:TrimWhitespace` 不删除末尾空行 |
| GUI | 字体、窗口大小/位置、菜单/工具栏/滚动条切换；MacVim 原生 F11 全屏；Windows DLL 功能仅在明确配置且文件存在时启用 |
| 主题 | GUI 优先 ManShow、终端优先 molokai，未安装则 desert；恢复主题专用高亮、缩进线、仅 C/C++ 超过 100 个显示列高亮、活动窗口光标行 |
| 状态和标签 | 若用户已安装 ManShow.vim 状态栏插件，由它负责布局，避免全局默认值与插件的局部追加重复；其它机器使用通用状态栏。可点击的短 tab 名称、修改标记、文件权限/类型/时间 GUI 提示；按 Unicode 字符截断并转义 `%` |
| 标记 | 手动 sign 放置、跳转、删除；补全原缺失的符号定义，使用独立组，避免清除 YCM 等插件的标记 |
| YCM | C/C++/Go，C 的两字符触发、定义跳转、诊断符号/高亮、候选阈值、预览自动关闭。使用命令区诊断且不在插入时更新；不再信任任意 extra_conf |
| tags | F12 / Ctrl-F12 统一生成 C/C++ tags；检查 Universal/Exuberant ctags，拒绝 BSD ctags；存在的系统 include 目录及其中的 tags 自动添加，可用 g:portable_vim_include_paths 指定 |
| 符号侧栏 | Tagbar 提供当前文件的结构化符号视图 |
| cscope | 使用 Vim 原生接口及一套查询映射，加载当前目录或 CSCOPE_DB 数据库；`\cs` 调用外部工具构建，避免重复连接和后台数据库实现冲突 |
| 文件和缓冲区浏览 | NERDTree 用于项目文件，netrw 作为内置后备；缓冲区使用 `:ls`、`:buffer`、`\bn` 和 `\bp` 管理 |
| 注释 | NERDCommenter 的 Alt-/ 在普通、可视和插入模式切换注释，并使用当前文件类型的注释语法 |
| 项目搜索 | `\G` 后输入查询，用 `:PortableGrep` 和 quickfix；优先 rg，其次 grep，无须额外 Grep.vim |
| 单文件编译运行 | Ctrl-F5 编译 C、Ctrl-F6 编译 C++；gcc/g++ 缺失时尝试 clang/clang++。参数转义，临时输出，编译成功才运行，显示退出状态 |
| 折叠 | 空格切换、语言语法/缩进折叠、Vim 按完整 function/def 折叠（内部空行不分断，默认不嵌套 if 折叠）、txt/lisp 空行分组及 ero 折叠，保留折叠文本提示 |
| 二进制 | `.bin` 自动显示 xxd；保存前校验，在隔离的原始字节缓冲区解码后使用 Vim 写入机制，保留可见十六进制缓冲区和撤销历史 |
| 文件管理器 | Ctrl-F11 / `:Explorer`，Windows Explorer 选择文件、macOS Finder 显示文件、Linux xdg-open 打开目录 |
| 打印 | 保留 A4、双面、页眉及 UTF-8 打印；Windows PostScript 字体设置只应用于相应平台 |
| HTML 导出 | 保留 TOhtml 动态折叠选项；手动执行导出 |
| 终端光标 | 保留模式相关形状，去除不通用的 OSC 光标颜色修改 |
| 辅助函数 | 保留手动调用的 Week_cn、CurTime、FileInfo、InfoGuiTooltip、ShortTabLabel、ChkLargeFile、RemoveTrailingSpace、ClosePair；PyCalc 改用 Python 3 |

保存清理可通过 `g:portable_vim_trim_types` 调整，或在缓冲区设置 `b:portable_preserve_whitespace=1` 跳过。全局 `iskeyword` 冒号和尖括号匹配原本用于 Perl 辅助设置，随第 42 项一起移除。

## Balloon 和主题轮换

MacVim 支持时自动开启 `ballooneval`，终端 Vim 支持时开启 `balloonevalterm`。鼠标位于当前窗口的闭合折叠时直接显示折叠内容：不超过 31 行显示全部，超过时显示前后各 15 行及省略行数。展开后没有拼写建议或 tags 信息时不弹出提示。手动启用 spell 时可显示拼写建议，没有恢复字典和拼写默认。窗口参数将从零开始的 v:beval_winnr 转换为从一开始的窗口编号。

折叠和拼写提示仅对当前窗口计算，避免在 `balloonexpr` 的 textlock 中切换窗口。其它窗口在 tags 设置匹配时可显示符号信息。终端悬浮还取决于终端对鼠标移动事件的支持。翻译功能已删除。

自定义功能以原实现为基准：Balloon 保留“折叠内容 → 拼写建议或 echofunc 函数声明”的分支，声明插件缺失或报错时才使用 tags 备用提示；保留原省略标记和多行能力判断，移除迁移时新增的文件名/单词提示。文本和 Lisp 保留按非空行折叠（仅含空白的行仍属于折叠），ero 保留原来的空行边界条件；Vim 函数整体折叠是针对函数被拆开的修复。标签栏恢复原 ErrorMsg 高亮和标签内容，保留 Unicode 截断、百分号转义和点击定位修复。时间字符串恢复原前导空格。

同时核对了日期、文件信息、GUI 提示、配对括号、注释、空白清理、标签跳转、主题轮换、编译运行、cscope、编码重读及二进制读写。保留的实现调整用于修复路径大小写/无扩展名文件、跨缓冲区注释变量污染、插件缺失、失败后运行旧程序、未保存修改丢失和二进制往返等问题。自动清理仍限制于源文件，以保护 Markdown 硬换行和普通文本尾部空行；主题仍按原主题列表循环，跳过未安装主题。

Ctrl-F9 或 `:RotateColorTheme` 轮换原主题列表中的已安装主题，跳过缺失项并循环返回。可在本地覆盖文件设置：

```vim
let g:portable_vim_themes = ['desert', 'ron', 'molokai']
```

## 使用及依赖

预览当前文件：

```sh
mvim -u /absolute/path/config/dotvimrc 文件
```

应用时先备份旧文件，再复制到 Linux/macOS 的 `~/.vimrc` 或 Windows 的 `~/_vimrc`。Vim 的家目录可以用 `:echo expand('~')` 确认。

Unix 用户 Vim 目录默认 `~/.vim`，Windows 默认 `~/vimfiles`。Vundle 位于其 `bundle/Vundle.vim` 下；没有 Vundle 时基本编辑功能仍能使用。已有 Vundle 时执行 `:PluginInstall` 安装配置中声明的缺失插件。本次没有下载插件、覆盖用户配置或删除旧插件目录。

当前主机使用 MacVim 9.2，具有 Python 3，已安装的 YCM 能正常启动。系统 `/usr/bin/vim` 9.1 没有 Python 3，使用它时不声明 YCM。YCM 自身还有版本/原生构建要求。

`vimrc.local` 的可选位置是 Unix `~/.vim/vimrc.local`、Windows `~/vimfiles/vimrc.local`，可放字体、clangd 路径及 DLL 路径。例如：

```vim
let g:ycm_clangd_binary_path = '/absolute/path/to/clangd'
if has('gui_running')
    set guifont=Menlo:h18
endif
" Windows 可选设置：
" let g:portable_vim_fullscreen_dll = 'C:/path/gvimfullscreen.dll'
" let g:portable_vim_tweak_dll = 'C:/path/vimtweak.dll'
```

也可在 vimrc 最前面预设 `g:portable_vim_home` 改变用户目录。`g:portable_vim_plugins=0` 禁用 Vundle 初始化，但 Vim 原生 runtime 插件仍按自身机制加载。需要持久撤销时创建用户目录下的 `undo/`。

外部工具按功能需要提供：ctags、cscope、xxd、gcc/g++ 或 clang/clang++、rg 或 grep。YCM 自动使用 PATH 中的 clangd（保留显式路径覆盖）；找不到时由 YCM 使用内置版本。本机原先的 `/opt/share/bin/clangd` 因此无需另建 vimrc.local。缺失时相关操作报告原因。部分旧 Vim 的 cscope 接口无法正确传递带空格的数据库路径，自动加载会显示错误原因；普通路径已经验证。

单文件编译运行用于小型、非交互程序，输出显示在临时窗口；项目构建继续使用 make，交互程序应从终端运行。打印及 Windows DLL 仍需对应系统和字体/库支持。

## 自动切换工作目录

已恢复原有的 `set autochdir`。打开或切换文件时，工作目录自动变为该文件所在目录。例如打开 `kernel/task.c` 后，可直接执行 `:edit task.h` 或 `:tabedit task.h` 打开同目录文件，用 `:pwd` 查看当前目录。相对路径的 `:edit`、`:!` 等命令都以当前工作目录为基准。

无需额外的 `<leader>cd`、`<leader>ee` 和 `<leader>et` 快捷键；原有 `<leader>ev` 仍用于打开 Vim 配置。选定项目后，`:BuildAsync` 和 `:BuildDatabase` 使用项目配置中的根目录作为构建目录。

## C 开发入口和项目配置

内置 C/C++ 缩进统一采用续行增加一级的风格：`(s` 控制函数声明、调用参数和多行条件等括号续行，`us` 控制嵌套括号，`+s` 控制一般表达式续行；每增加一层上下文，就增加一个 `shiftwidth`（默认 4 列）。`U1` 使单独起行的左括号后也遵循该规则，避免退回按字符位置对齐。该风格适用于内置自动缩进和 `=`/`gg=G`；修改选项不会自动重排已有代码。`:FormatCode` 仍使用项目的 clangd/clang-format 格式化规则。

内置 C 缩进的括号、块注释搜索上限均设置为 100 行。C/C++ 文件中，光标停留触发 `CursorHold` 时，会对比当前行在现有上限和扩大至文件开头的搜索范围下的 `cindent()` 结果；结果不同时显示 `C indent: ... may exceed search limits ...`，也可用 `:CIndentCheck` 手动检查。提示不修改源码、不自动重新缩进，检查结束会恢复原有 `cinoptions`；自动检查缓存同一行、同一内容和选项的结果，避免重复提示。它检测的是搜索限制对当前行缩进判断的影响，并不保证每个超过 100 行的括号或注释都会报警；若两次计算结果一致，就不提示。使用其它 `indentexpr` 或 `equalprg` 时跳过检查。历史提示可用 `:messages` 查看。

`<leader>` 默认是反斜杠 `\`，如自行设置 `mapleader` 则使用自己的前缀。新增入口不改动原有跳转和编译快捷键：

| 按键 | 操作 |
|---|---|
| `<leader>yd`（原有） | 跳转定义，找不到时尝试声明 |
| `<leader>ya` | 跳转声明 |
| `<leader>yr` | 查找引用 |
| `<leader>yt` | 查看类型 |
| `<leader>yx` | 手动应用 YCM FixIt 修复或选择代码操作 |
| `<leader>yi` | 在 `#include` 行跳转到包含的头文件 |
| `<leader>yh` | 通过 clangd 在关联源码和头文件之间跳转 |
| `<leader>yl` | 显示当前文件的 YCM 诊断列表（location list） |
| `<leader>ye` | 显示光标所在行的完整诊断 |
| `<leader>yk` | 查看符号文档及 Doxygen 注释（YCM 预览窗口） |
| `<leader>ys` | 输入 `:FindSymbol 查询字符串`，查找项目符号 |
| `<leader>yR` | 输入 `:RenameSymbol 新名称`，手动执行语义重命名 |
| `<leader>yf` | 普通模式格式化整个文件；可视模式格式化选区 |
| `<leader>qn` / `<leader>qp` | quickfix 下一项 / 上一项 |
| `<leader>qo` / `<leader>qc` | 打开 / 关闭 quickfix |
| `<leader>qb` / `<leader>qf` | 切换到较早 / 较新的 quickfix 列表 |
| `<leader>qg` | 输入 quickfix 筛选表达式（内置 cfilter 可用时） |
| `<leader>ln` / `<leader>lp` | 当前窗口 location list 下一项 / 上一项 |
| `<leader>lo` / `<leader>lc` | 打开 / 关闭 location list |
| `<leader>lb` / `<leader>lf` | 切换到较早 / 较新的 location list |
| `<leader>lg` | 输入 location list 筛选表达式（内置 cfilter 可用时） |

项目符号搜索示例：`:FindSymbol packet`。搜索通过 YCM `GoToSymbol` 使用 clangd 的符号索引；查询方式由后端决定，索引覆盖范围和构建数据库会影响结果。多个匹配显示在 quickfix，单个匹配可能直接跳转。`<leader>yk` 手动打开符号文档预览，可显示声明和可用的 Doxygen 注释，用 `:pclose` 关闭。见 [YCM 符号搜索](https://github.com/ycm-core/YouCompleteMe#the-gotosymbol-symbol-query-subcommand)及 [GetDoc](https://github.com/ycm-core/YouCompleteMe#the-getdoc-subcommand)。

Vim 自带 cfilter 时自动加载；不下载额外插件。筛选示例：`:Cfilter /error:/` 保留错误，`:Cfilter! /warning:/` 排除警告，`:Cfilter /src\/net\//` 保留指定目录相关结果，`:Lfilter /unused/` 筛选当前窗口诊断。表达式是 Vim 正则，同时匹配条目文本和文件名；`!` 表示排除匹配项。筛选生成新列表，`<leader>qb` 或 `<leader>lb` 可恢复筛选前的列表。见 [Vim 列表筛选说明](https://vimhelp.org/quickfix.txt.html#cfilter-plugin)。

诊断建议先用 `<leader>yl` 查看当前文件的错误，再用 `<leader>ln`/`lp` 定位，`<leader>ye` 阅读完整消息，需要时才用 `<leader>yx` 修复。YCM 诊断使用当前窗口的 location list；编译错误与引用结果使用 quickfix，分别导航。没有自动覆盖 location list 的新配置。诊断入口及头文件导航见 [YCM 官方说明](https://github.com/ycm-core/YouCompleteMe#the-ycmdiags-command)。

光标放在标识符上，按 `<leader>yR` 后输入新名称并回车，例如 `:RenameSymbol packet_count`。本入口接受 ASCII 字母、数字、下划线且不能以数字开头；语言关键字等语义合法性由 clangd 判断。它调用 YCM `RefactorRename`，更新声明、定义和使用处，作用范围由 clangd 的项目索引决定。多文件修改可能触发 YCM 自身的确认，并将修改位置放入 quickfix；用 `:copen` 检查、`:ls` 查看修改的缓冲区，再手动保存。修改不会自动写盘，撤销应在各修改缓冲区分别执行。见 [YCM 重构说明](https://github.com/ycm-core/YouCompleteMe#multi-file-refactor)。

`<leader>qb`/`qf` 切换列表历史，不是列表中的上一项/下一项。例如查询引用后可用 `<leader>qb` 返回之前的编译错误列表；`<leader>qf` 再回到引用结果。location list 的 `<leader>lb`/`lf` 同理，但历史属于当前窗口。边界没有更早或更新列表时，Vim 显示原生提示。见 [Vim quickfix 历史](https://vimhelp.org/quickfix.txt.html#%3Acolder)。

`<leader>yi` 需要光标位于 `#include` 行；`<leader>yh` 由 clangd 判断关联文件，没有对应头文件或源码时可能无法跳转。跳转后使用原生 `Ctrl-O` 返回、`Ctrl-I` 前进，不另占用快捷键。

`:FormatCode` 默认整个文件，`:2,5FormatCode` 格式化指定行。它转交给 YCM 的 `Format`，使用 clangd 的格式化能力和项目 `.clang-format`；缩进也受 YCM 传入的 Vim `shiftwidth`/`expandtab` 影响。没有保存时自动格式化，也不会自动执行 FixIt。插件缺失时显示提示。语义操作和格式化支持见 [YCM 文档](https://github.com/ycm-core/YouCompleteMe#semantic-commands)。

项目构建继续使用原有 `<leader>mk`（`:make`），通过 quickfix 查看编译错误。请先保存需要参与构建的文件。在项目根目录 `:lcd /path/to/project`，再按项目设置 `makeprg`；例如 CMake 项目可执行 `:let &l:makeprg = 'cmake --build build'`。GCC/Clang 输出可使用 `:compiler gcc` 设置错误解析，再设置项目自己的 `makeprg`。这些操作应在目标源文件窗口执行，不全局写死路径和构建工具。原 `<leader>mc` 是 `:make clean`，仅适用于接受这种参数的构建命令；CMake 清理可显式运行 `:make --target clean`。参见 [Vim quickfix 文档](https://vimhelp.org/quickfix.txt.html)。

优先为每个项目提供 `compile_commands.json`，让 clangd 使用真实的宏、头文件路径、标准和目标架构。CMake 可在项目根目录生成：

```sh
cmake -S . -B build -G Ninja -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
cmake --build build
```

需要安装 Ninja；已有构建目录应沿用原生成器，或另外创建构建目录。该选项支持 Ninja 和 Makefile 生成器，Visual Studio/Xcode 生成器不提供这份数据库，见 [CMake 文档](https://cmake.org/cmake/help/latest/variable/CMAKE_EXPORT_COMPILE_COMMANDS.html)。clangd 会在源文件的父目录及其 `build/` 子目录查找数据库，通常无需额外复制文件。其它构建目录可在项目 `.clangd` 设置 `CompileFlags: { CompilationDatabase: out }`，路径相对于该配置文件，见 [clangd 配置](https://clangd.llvm.org/config#compilationdatabase)。

Make 项目在已安装 Bear 时可使用 `bear -- make` 捕获编译命令。必须实际发生编译才能收集数据库；增量构建没有编译任何源文件时不会产生完整记录。按项目自身方式准备一次完整构建，见 [clangd 项目配置说明](https://clangd.llvm.org/installation)。

`.clang-format` 使用项目现有风格；没有时再由项目确定，不在 vimrc 中统一规定 C 标准和格式。clang-tidy 与交叉编译器 `--query-driver` 仍按项目需要配置，本次未自动启用。

可选的 clang-tidy 项目示例见 [clangd.example](examples/c-project/clangd.example)，采用两个检查并排除常见第三方和构建目录。将所需片段合并到项目 `.clangd`，按实际目录调整条件。已有 `.clang-tidy` 的项目应沿用其规则；`.clangd` 中的检查设置会与其合并，见 [clangd ClangTidy 配置](https://clangd.llvm.org/config#clangtidy)。如 YCM 的 clangd 尚未启用 tidy，在自己的 `vimrc.local` 中添加：

```vim
let g:ycm_clangd_args = get(g:, 'ycm_clangd_args', [])
if index(g:ycm_clangd_args, '--clang-tidy') < 0
    call add(g:ycm_clangd_args, '--clang-tidy')
endif
```

这会启用当前 YCM 会话的 tidy 诊断，检查范围由各项目的 `.clangd`/`.clang-tidy` 决定。修改启动参数后执行 `:YcmRestartServer`。不在全局启用 `bugprone-*` 或 C++ 专用规则。

交叉编译优先保留数据库中实际使用的编译器、`--sysroot` 和目标选项。若系统头文件仍无法解析，可在主机的 `vimrc.local` 的 `g:ycm_clangd_args` 中追加精确路径，例如 `--query-driver=/opt/toolchains/bin/aarch64-linux-gnu-gcc`，同时确保该路径与数据库中的编译器匹配。参数允许 clangd 运行该编译器来查询目标和包含目录，因此使用自己的实际工具链路径，见 [clangd 系统头文件说明](https://clangd.llvm.org/guides/system-headers)。`.clangd` 的 `CompileFlags.Compiler` 可用于替换解析时的编译器名称，但不改变实际构建工具链。

真实 C 集成验证脚本是 `tests/ycm-c-integration.vim`：创建临时项目和编译数据库，验证定义跳转、引用进入 quickfix、类型查询、手动格式化以及磁盘文件未被自动写入。

## 单文件算法练习

打开并保存一个 `.c` 或 `.cpp` 文件即可使用，不需要选择项目或生成编译数据库。

| 命令 / 快捷键 | 用途 |
|---|---|
| `:PracticeBuild` / `<leader>ab` | 编译当前文件，失败时打开 quickfix |
| `:PracticeRun` / `<leader>ar` | 编译成功后复用结果窗口，可用键盘输入 |
| `:PracticeRun input.txt` | 编译后以指定文件作为标准输入，输出保留在终端 |
| `:PracticeBuild!` | 使用 AddressSanitizer 和 UndefinedBehaviorSanitizer 编译 |
| `:PracticeRun! [输入文件]` / `<leader>ac` | 编译并运行检查模式，报告越界和未定义行为 |
| `:PracticeStop` / `<leader>ax` | 停止练习编译或正在运行的程序 |
| `:PracticeLast` | 直接查看最近一次实际运行的输出，关闭结果窗口后也可重新打开 |
| `:PracticeHistory [编号]` | 选择历史输出，或直接查看指定运行编号；编号支持 Tab 补全 |

默认使用 PATH 中的 `clang`/`clang++`，标准为 C17/C++17，参数为 `-Wall -Wextra -Wshadow -g -O0`。检查模式增加 `-fsanitize=address,undefined -fno-omit-frame-pointer -fno-sanitize-recover=all`，需要编译器支持对应的 sanitizer 运行库。产物在 Vim 临时目录，每次编译使用独立路径，失败后不会运行旧程序。编译和运行的工作目录都是源码所在目录；输入文件的相对路径按执行命令时的 Vim 工作目录解析，路径可以包含空格。

源码未保存时拒绝编译，不自动写文件。练习编译成功且没有有效诊断（包括警告）时，自动关闭对应的 quickfix 窗口；仍有警告时保留窗口。只关闭窗口，不清空诊断列表；不会自动关闭运行前由其它工具打开的 quickfix 窗口。`PracticeRun` 每次都会先编译，只有编译成功才运行本次生成的程序。结果窗口在发起运行的代码窗口正下方局部分割；Tagbar 位于左侧时保持左侧完整高度，结果位于右下方，不横跨整个底部。即使编译期间切到了 Tagbar，仍会先找到对应的结果窗口，或回到代码窗口创建结果窗口。运行输出保留在终端，退出码显示在消息中；按 `Ctrl-W N` 进入终端普通模式以浏览输出，按 `i` 返回输入。在结果窗口执行 `:close` 或 `:q` 后优先回到发起练习的代码窗口；原窗口已关闭时，选择同一标签页的源码窗口或其它普通编辑窗口，跳过 Tagbar 等特殊窗口。关闭后台结果窗口不会改变当前焦点。`:BuildLog` 查看编译日志，`:BuildResults` 查看编译诊断；程序输出和 sanitizer 运行时报告在终端中。练习编译与项目构建共用队列；停止交互程序可切回源码窗口执行 `:PracticeStop`。不更改项目配置、原来的 `makeprg` 和 `errorformat`。

Vim 自带的“已结束”（`finished`）表示终端关联的程序已经退出，不代表运行成功；成功与否由右侧的退出码判断。

练习结果终端通过 `term_highlight=Normal` 跟随当前主题的前景色、背景色，ANSI 彩色输出保持可用，无需另设固定背景色。已结束的终端保留当时的颜色，切换主题后重新运行即可使用新配色。此设置只影响练习结果终端。

练习结果窗口使用独立状态栏：左侧为 `Practice #编号  文件名  [Normal/Sanitizer]`，右侧为 `Running`、`Done · exit 0` 或 `Failed · exit 退出码`，不再显示源码编码、符号信息或重复的终端结束标记。历史输出显示对应记录的状态。

状态栏在练习编译时显示 `[Practice: compiling]`；程序启动后，结果窗口右侧显示 `Running`，结束后显示 `Done · exit 0` 或 `Failed · exit 退出码`。源码窗口在程序运行期间显示 `[Practice: running]`，即使结果窗口已关闭也可看到。查看历史时显示对应那次运行的状态，不推测程序是否正在等待输入。`:PracticeLast` 打开最近一次实际启动的程序输出；之后即使编译失败，该输出也仍然可查看。

同一个代码窗口反复执行 `PracticeRun` 会复用其结果窗口。每次先启动独立的终端缓冲区，再将它显示到结果窗。窗口空间不足时，程序仍可运行，可腾出空间后用 `:PracticeLast` 打开输出。默认保留当前 Vim 实例最近 10 次运行的记录，包括源码文件名、开始时间、普通/检查模式和退出码。编译失败不会新增运行记录，也不会覆盖之前的输出。历史不会写入磁盘，退出 Vim 后清空。

```vim
:PracticeRun
:PracticeHistory
:PracticeHistory 1
```

不带参数时按菜单序号选择，输入 `0` 取消；带参数时使用记录中显示的 `#` 后的运行编号，两者可能不同。查看历史只切换输出，不重新编译或运行。新运行会将结果窗口切回最新输出。程序仍在运行时可查看其它历史，使用 `:PracticeStop` 停止当前程序后再重新运行。

可在 `vimrc.local` 设置 `let g:portable_practice_history_limit = 10`，使用正整数。新增记录或程序结束时清理超额记录；运行中的程序不会被清理。移出历史的终端若仍在窗口中显示，或已被手动修改，会保留其缓冲区；其它已结束的旧终端自动清理。历史与窗口复用的验证见 [tests/practice-history.vim](tests/practice-history.vim)。

指定本机编译器可写到 `vimrc.local`，例如本机 LLVM 22：

```vim
let g:portable_practice_cc = '/opt/homebrew/Cellar/llvm@22/22.1.8/bin/clang'
let g:portable_practice_cxx = '/opt/homebrew/Cellar/llvm@22/22.1.8/bin/clang++'
```

只为当前缓冲区调整标准或添加参数：

```vim
let b:portable_practice_standard = 'c++20'
let b:portable_practice_flags = ['-Wconversion']
```

`b:portable_practice_compiler` 可覆盖该缓冲区的编译器；它是单个可执行文件路径，`b:portable_practice_flags` 是 argv 参数列表。这里的设置只影响实际练习编译，YCM 的补全参数仍由其配置决定。真实编译、交互输入、文件输入、检查模式和失败诊断的验证脚本见 [tests/practice.vim](tests/practice.vim)。

### 单文件模式的固定输出路径

默认产物放在 Vim 临时目录；需要从 LLDB 等工具反复打开同一个文件时，在源码缓冲区中设置：

```vim
let b:portable_practice_output = 'build/practice'
let b:portable_practice_checked_output = 'build/practice-check'
PracticeBuild
PracticeRun
```

相对路径以**源码所在目录**为基准，也支持绝对路径；父目录不存在时自动创建，路径含空格不需额外转义。Windows 请在路径中显式写出 `.exe`。这些选项只影响单文件模式，Makefile 模式仍使用其字典中的输出配置。

`PracticeBuild!` / `PracticeRun!` 优先使用 `b:portable_practice_checked_output`；未设置时沿用普通输出配置。输出路径为空时使用临时目录。固定路径每次成功编译后会更新，因此建议普通与 sanitizer 模式分开命名；运行历史保留的是输出记录，并非旧二进制副本。

查看最近一次产物：`echo g:portable_vim_practice_result.output`。恢复默认临时目录：

```vim
unlet! b:portable_practice_output b:portable_practice_checked_output
```

### 练习命令的简写

| 简写 | 完整命令 | 用法示例 |
|---|---|---|
| `PR` | `PracticeRun` | `PR -o .`、`PR! input.txt` |
| `PB` | `PracticeBuild` | `PB -o ./build`、`PB!` |
| `PL` | `PracticeLast` | `PL` |
| `PH` | `PracticeHistory` | `PH`、`PH 3` |
| `PS` | `PracticeStop` | `PS` |

这些是独立的用户命令，与完整命令使用相同实现；PR、PB 保留文件补全和 `!`，PH 保留历史编号补全。

交互输入 `:PR` 后按 Tab，会展开为 `:PracticeRun`，`PR!` 同样支持。空格和回车不再触发展开，直接回车仍执行短命令。仅在光标位于短命令末尾且尚未输入参数时展开；构建短命令也支持相同操作（见下表）。其它命令及文件参数保留原生 Tab 补全；搜索中的 Tab 保持原行为。

### 临时指定输出目录

```vim
PracticeRun -o .
PracticeRun -o ./build input.txt
PracticeRun! -o ./build-check input.txt
PracticeBuild -o .
```

`-o` 必须放在最前，后面跟**输出目录**，不是可执行文件名。相对目录以 Vim 当前窗口的有效工作目录（`:pwd`）为基准，自动创建目录，并使用源码文件名去掉扩展名作为程序名（Windows 加 `.exe`）。例如 `main.c` 配合 `-o .` 生成当前目录中的 `main`。

该参数仅覆盖本次操作，不修改缓冲区中的固定输出配置；带 `!` 也使用此次指定目录和相同程序名。程序运行目录仍为源码目录。Makefile 模式不接受 `-o`，请使用其 `output` / `checked_output` 配置。

路径含空格时使用 Vim 的反斜线转义或文件补全，例如 `PracticeRun -o ./my\ build input\ file.txt`，不使用 shell 引号。输入文件仍相对 Vim 当前目录解析；不带 `-o` 时沿用原有输入文件用法，如输入文件恰好名为 `-o`，使用 `PracticeRun -- -o`。

### 使用源码目录中的 Makefile

在已保存的 C/C++ 源码缓冲区中显式启用，不会自动查找或执行 Makefile：

```vim
let b:portable_practice_make = {
      \ 'target': 'practice', 'output': 'build/practice',
      \ 'checked_target': 'practice-check', 'checked_output': 'build/practice-check'}
PracticeRun
PracticeRun input.txt
PracticeRun! input.txt
PracticeBuild
```

构建与运行的工作目录始终是当前源码所在目录，不受 Vim 当前目录或所选 `Project` 影响，也不修改它们。`target` 是 make 目标，省略或为空时使用默认目标；`output` 是要运行的可执行文件，相对路径以源码目录为基准，也可使用绝对路径。Makefile 自己负责多文件依赖、编译器和参数；当前单文件模式的 compiler、standard、flags 设置不参与 Makefile 构建。运行前请保存相关源码和 Makefile；命令不会替你保存其它缓冲区。

可选键：`file` 指定相对源码目录的 Makefile 路径（默认 `Makefile`），`program` 指定 make 可执行文件（默认 `make`），`args` 为传给 make 的字符串参数列表，例如 `['-j4', 'CC=clang']`。参数通过 argv 传递，路径含空格也无需额外 shell 转义。输入文件参数沿用原用法，相对 Vim 当前目录解析。

带 `!` 必须设置 `checked_target`；该目标必须自行启用 AddressSanitizer/UBSan，配置不会擅自覆盖 Makefile 的编译参数。`checked_output` 指定检查模式产物，省略时沿用 `output`。建议使用不同产物，避免 make 将另一模式的旧程序判断为无需重建。例如：

```make
.PHONY: practice practice-check
practice: build/practice
build/practice: main.c helper.c
	mkdir -p build
	$(CC) -g -O0 -Wall -Wextra main.c helper.c -o $@
practice-check: main.c helper.c
	mkdir -p build
	$(CC) -g -O0 -fsanitize=address,undefined -fno-omit-frame-pointer main.c helper.c -o build/practice-check
```

Makefile 的命令行必须以 Tab 开头。构建失败会打开 quickfix，成功后沿用现有结果窗口、输入、历史、停止和状态栏逻辑；构建成功但没有生成指定的可执行文件时，不启动程序并提示产物路径。`PracticeBuild[!]` 仅构建。退出 Makefile 模式：

```vim
unlet! b:portable_practice_make
```

验证脚本：[tests/practice-make.vim](tests/practice-make.vim)，覆盖真实多文件构建、带空格目录、文件输入、检查目标、编译错误与缺失产物。

## 项目配置、异步构建与会话

新增功能仍在 `dotvimrc` 内；Fugitive 和 EditorConfig 已下载至相邻的隐藏目录 `.vim-pack/`，启动时直接加载，无需运行 `PluginInstall`。迁移配置时一并复制这个目录。版本及来源见 [.vim-pack/README.md](.vim-pack/README.md)。插件缺失不妨碍 Vim 启动；关闭 `g:portable_vim_plugins` 会跳过这两个插件的加载。

项目配置保存在 `g:portable_vim_projects` 字典，可写入现有 `vimrc.local`，也可手动 `:source` 示例。不会搜索或自动执行仓库里的本地 vimrc。每个配置至少提供 `root` 和 `build`，可选字段：

| 字段 | 含义 |
|---|---|
| `root` | 项目根目录 |
| `build` | 构建 shell 命令，可显式设置 PATH、架构和工具链 |
| `errorformat` | 可选诊断解析规则，默认使用 Vim 的 gcc compiler，兼容 Clang |
| `clangd` | clangd 可执行文件 |
| `clangd_args` | 该配置的 YCM clangd 参数列表；未指定时恢复第一次选项目前的参数 |
| `compilation_database` | 数据库所在目录，相对 root 或绝对路径；传递给 clangd 的 `--compile-commands-dir` |
| `database_command` | 显式生成编译数据库的 shell 命令 |
| `session` | 默认会话文件绝对路径 |

`:Project 名称` 支持 Tab 补全，选择当前标签页的项目，同时设置当前窗口目录、makeprg 和 errorformat。`:ProjectBuild`、原有 `<leader>mk` 和 `<leader>mc` 使用所选项目；在其它源文件窗口执行时也会重新应用目录与构建参数。未选项目时保留原来的 `:make` / `:make clean` 行为。CMake 清理使用 `:ProjectBuild --target clean`。

YCM 服务在整个 Vim 实例中共享。选择配置后用 `:YcmRestartServer` 应用 clangd 路径和参数；同时处理不同工具链的项目时，建议分别启动 mvim 实例。切换配置会恢复未显式指定的 clangd 默认设置，避免上一项目的编译数据库参数遗留。

本机 LaOS 可直接使用：

```vim
:source ~/.vim/config/examples/projects/laos.vim
:Project laos-x86_64
:YcmRestartServer
:BuildAsync
```

[LaOS 示例](examples/projects/laos.vim) 同时定义 `laos-x86_64` 和 `laos-arm64`。两者都在 PATH 前面加入 LLVM，并让同一 LLVM 安装中的 clangd 查找项目根目录数据库。x86_64 构建对齐 `run_x86_64.sh`：使用 LLVM clang 的 `x86_64-unknown-none-elf` target，并显式指定同套工具链的 `ld.lld`、`llvm-nm`，执行 `make ... iso`；ARM64 使用 `make ARCH=aarch64 ARM64_TOOLCHAIN=llvm`。可通过 `g:portable_laos_root`、`g:portable_llvm_bin` 和 `g:portable_lld_bin` 覆盖路径。`:BuildAsync` 增量构建 ISO，不执行脚本中的 `make clean`，也不启动 QEMU；`:BuildDatabase` 通过 Bear 和 `-B iso` 强制重建并更新编译数据库，需要 Bear。切换架构、宏或工具链后应重新生成数据库，并重启 YCM。另有 [CMake 示例](examples/projects/cmake.vim)，修改 root 后选择 `:Project c-app`。

生成 LaOS 的编译数据库需在当前标签页先选项目：

```vim
:source ~/.vim/config/examples/projects/laos.vim
:Project laos-x86_64
:BuildDatabase
```

示例路径请按配置所在位置调整。用 `:BuildLog` 查看输出、`:BuildResults` 查看诊断。等待构建成功后执行 `:YcmRestartServer`。仅设置 `makeprg` 不会设置数据库生成命令；项目选择按标签页保存。使用 ARM64 时项目名改为 `laos-arm64`。修改或重新加载项目定义后，需要再次执行对应的 `:Project laos-x86_64` 或 `:Project laos-arm64`，更新该标签页的配置副本。可通过 `:echo get(t:, 'portable_project', {})` 查看当前选择。

| 命令 / 快捷键 | 行为 |
|---|---|
| `:BuildAsync [参数]` / `<leader>mb` | 在项目目录启动异步构建，未选项目时使用当前 makeprg 和目录 |
| `:BuildStop` / `<leader>ms` | 请求终止正在运行的构建 |
| `:BuildResults` / `<leader>mq` | 打开最近构建的 quickfix 列表 |
| `:BuildDatabase` | 异步运行所选项目的数据库生成命令 |
| `:SaveSession[!] [文件]` | 手动保存窗口、文件、折叠、目录及各标签页项目配置；`!` 覆盖已有文件 |
| `:LoadSession [文件]` | 手动恢复会话；存在未保存缓冲区时拒绝加载 |

构建系列也提供独立的短命令，行为与完整命令一致：

| 简写 | 完整命令 | 用法示例 |
|---|---|---|
| `BA` | `BuildAsync` | `BA`、`BA test` |
| `BR` | `BuildResults` | `BR` 查看编译诊断 |
| `BS` | `BuildStop` | `BS` 停止构建 |
| `BD` | `BuildDatabase` | `BD` 生成所选项目的编译数据库 |
| `BL` | `BuildLog` | `BL` 查看当前构建日志 |
| `BLS` | `BuildLogSave` | `BLS /tmp/build.json`、`BLS! /tmp/build.json` |
| `BLL` | `BuildLogLoad` | `BLL /tmp/build.json` |

输入表中任一简写后按 Tab，会展开为对应的完整命令，例如 `BR<Tab>` → `BuildResults`、`BLS!<Tab>` → `BuildLogSave!`。直接回车仍执行短命令，空格不触发展开。

`BLS`、`BLL` 保留文件补全；`BLS!` 显式覆盖已有日志。省略路径时仍使用项目的 `log_file`。`BR` / `BL` 也可用于查看 `PR` / `PB` 的编译诊断和日志；程序运行输出使用 `PL` 查看。

异步构建不会保存缓冲区，请先保存要参与编译的内容。一次允许一个构建任务，合并 stdout/stderr，保留实际退出码和取消标记，输出进入该任务自己的 quickfix；编译期间产生的符号搜索列表保持当前状态。完成时重新解析整个日志，以处理多行诊断，文件路径基于构建目录，不受期间窗口和目录切换影响。可以继续使用现有 quickfix 筛选和历史导航。结果也保存在 `g:portable_vim_build_result`（status、root、lines、qfid、stopped）。shell 命令包含管道时，退出语义依所用 shell 决定；需要检查管道全部阶段的失败时，在项目命令中显式启用该 shell 的 pipefail。

会话保存文件和窗口布局、光标位置、折叠、工作目录及各标签页的项目配置；不保存未写盘的源码内容，不保存全局选项，不在启动或退出时自动加载/保存。会话文件是 Vim 脚本，仅加载自己保存的文件。

### 会话使用示例

有项目配置时，先选择项目，保存需要写盘的源码，再保存会话：

```vim
:Project laos-x86_64
:SaveSession
```

无路径参数使用项目字典的 `session` 字段。LaOS 示例分别保存为本配置目录下的 `laos-x86_64.session.vim` 或 `laos-arm64.session.vim`。文件已经存在时，显式覆盖：

```vim
:SaveSession!
```

没有项目配置也能使用，路径可以通过 Tab 补全，含空格时用反斜杠转义：

```vim
:SaveSession ~/work.session.vim
:SaveSession! ~/work.session.vim
:LoadSession ~/work.session.vim
```

新启动的 mvim 也可以直接执行 `:LoadSession /完整路径/laos-x86_64.session.vim`（或 ARM64 对应文件），无需先选择项目。已有项目时 `:LoadSession` 使用其默认路径。任何缓冲区有未保存修改都会拒绝恢复；先逐个保存或明确放弃修改，再加载会话。可以通过 `:echo v:this_session` 查看最近保存/加载的会话文件。

保存使用同目录临时文件，在内容和项目元数据写完后原子替换目标文件；失败时保留旧文件，清理临时文件，并恢复原 `sessionoptions` 和 `v:this_session`。目标父目录必须已经存在。原有文件权限在覆盖时保留。

恢复后同步当前标签页项目的 makeprg、errorformat 和 clangd 参数，使用保存的目录、工具链及数据库设置。若 YCM 服务已经运行，手动 `:YcmRestartServer` 应用新的 clangd 设置；不会自动重启或运行构建。各标签页的项目配置分别恢复，但 YCM 仍共享一个服务；需要不同工具链同时工作时使用独立 mvim 实例。配置文件中的项目设置后来有调整时，重新 `:Project 名称` 可应用最新定义。

`tests/session.vim` 在 mvim 验证覆盖保护、原子保存失败保留旧数据、临时文件清理、多标签页/光标/折叠恢复、未保存修改保护、构建与 clangd 设置恢复，以及另一个 mvim 实例的加载。

## 项目搜索、任务、日志和编译查看

以下入口复用现有项目配置；所有辅助函数仍在 `dotvimrc` 中，不需要下载新插件。

| 命令 | 用途 |
|---|---|
| `:ProjectSearch 正则` | 在所选项目根目录异步搜索，结果进入独立 quickfix |
| `:ProjectSearch! 正则` | 只搜索 `.c` 和 `.h` 文件 |
| `:ProjectWord[!]` / `<leader>sw` | 按完整单词搜索光标下的标识符；按字面值传参 |
| `:ProjectTodo[!]` / `<leader>st` | 搜索 TODO、FIXME、XXX |
| `:SearchResults` / `:SearchStop` | 查看最近搜索结果、停止搜索 |
| `:ProjectTask 名称` | 异步执行项目命名任务，支持 Tab 补全 |
| `:BuildLog` | 在只读窗口查看最近构建或任务的完整输出；运行中显示调用时已有的输出 |
| `:BuildLogSave[!] [文件]` | 保存最近完成的构建或任务；`!` 覆盖已有文件 |
| `:BuildLogLoad [文件]` | 导入保存的 JSON 日志或普通编译日志到新 quickfix |
| `:ProjectHealth` | 打开只读配置与工具链检查报告 |
| `:Preprocess [编号]` | 按当前源码的编译数据库条目生成预处理内容 |
| `:Assembly [编号]` | 按同一数据库生成目标架构的汇编 |
| `:InspectionStop` | 停止正在运行的编译查看任务 |

`:BuildLog` 查看内存中的输出，不需要日志文件；再次执行可查看新输出。`:BuildResults` 查看解析后的 quickfix。若要下次打开 mvim 时导入结果，先执行 `:BuildLogSave /path/build.json`，再用 `:BuildLogLoad /path/build.json`。保存和导入省略路径时使用项目的 `log_file`；构建不会自动生成该文件。保存仅接受已完成的构建，使用临时文件和替换操作，失败时保留旧日志。

搜索使用 ripgrep，遵守其 `.gitignore`、隐藏文件和二进制文件过滤规则；`search_globs` 字段可提供额外的 `-g` 规则。正则作为独立 argv 参数传递，不执行 shell 展开。退出码 1 表示没有匹配，2 表示搜索错误。搜索可以与构建同时进行；各自的输出进入各自列表，不覆盖期间查询的符号结果。原有 `PortableGrep` 入口继续保留。

项目字典可增加：

```vim
let g:portable_vim_projects['c-app'].tasks = {
    \ 'test': 'ctest --test-dir build --output-on-failure',
    \ 'check': {'command': 'your-check-command',
    \           'errorformat': '%f:%l:%c:%m'}}
let g:portable_vim_projects['c-app'].log_file = expand('~/c-app.build.json')
let g:portable_vim_projects['c-app'].search_globs = ['!vendor/**']
```

任务值可以是 shell 命令字符串，或带 `command`、`errorformat` 的字典。它与构建/数据库生成共享单任务执行限制、停止入口 `BuildStop`、结果入口 `BuildResults` 和实际退出码。任务不会自动保存或运行；显式输入 `:ProjectTask test` 才执行。修改字典后重新 `:Project c-app` 应用。

LaOS 示例提供 `kernel`、`module`、`image` 和 `check-config`。任务只有通过 `:ProjectTask 名称` 才会执行；配置不会自动启动 QEMU 或调试器。CMake 示例提供 `test`。

保存日志使用带版本标识的 JSON，包含原始输出行、命令、工作目录、errorformat、时间、退出码和停止标记；不会保存过期的 quickfix ID。另一 mvim 实例可直接导入，并按保存时的目录恢复相对诊断路径。普通文本日志使用当前项目目录和解析规则，退出码显示为 unknown；它本身没有足够元数据恢复原构建状态。省略路径时使用项目的 `log_file`；保存需显式调用，不会自动覆盖日志。导入只解析数据，不执行日志中的命令。quickfix 历史被清空或列表被淘汰后，当前进程的 `BuildResults` / `SearchResults` 仍可利用保留的输出重建列表。

健康报告显示所选项目、构建命令、配置的 clangd 路径/参数、PATH 中的工具、Vim 能力、数据库位置、当前文件匹配条目及其实际编译器/版本/参数。YCM 可用时也显示 `YcmDebugInfo`，方便比较配置与运行中的服务。工具列表中的缺失项是可用性信息，并非所有项目都需要 Bear、CMake 等工具。没有当前文件条目时明确显示 0；不会猜测头文件的编译命令。

预处理和汇编按 [编译数据库规范](https://clang.llvm.org/docs/JSONCompilationDatabase.html)优先读取 `arguments`，否则用 Python 3 按平台规则拆分 `command`，不执行 shell。保留目标架构、宏、包含路径和优化参数；直接运行数据库记载的 GCC/Clang。若同一文件有多条记录，默认使用第 1 条，`:Preprocess 2` / `:Assembly 2` 显式选择其它记录。Windows 支持 arguments 数组及 Python 3 的 Windows 命令行拆分；未在 Windows 实机验证。

生成前移除原有 `-o`、依赖文件、覆盖率和常见附加输出选项，用临时文件接收结果；汇编查看还移除 LTO / emit-llvm，以得到目标架构指令。参数依据 [Clang 命令行说明](https://clang.llvm.org/docs/ClangCommandLineReference.html)。响应文件、转发给预处理器/汇编器/cc1 的参数和编译器包装命令会明确拒绝，需先导出展开后的直接驱动参数。输出打开独立只读临时缓冲区，读取后删除临时文件；编译失败时诊断进入 quickfix。使用磁盘上的源码，未保存修改会提示并保持原状；原对象和依赖文件不被覆盖。

新增验证脚本为 `tests/project-tools.vim`，覆盖搜索匹配/无结果/错误、任务诊断与自定义格式、另一个 mvim 实例的日志恢复、quickfix 历史清空后的结果恢复、数据库多条记录和 command 拆分，以及 Clang 22 ARM64 宏展开与汇编。确认源文件未自动保存，原对象/依赖文件内容保持不变。`tests/laos-project-tools.vim` 还在真实 LaOS ARM64 主文件验证只读报告、预处理和汇编；数据库当前记录 `/usr/bin/clang`，健康报告如实显示，未修改数据库或内核源码。

## Git 与 EditorConfig

| 快捷键 | 操作 |
|---|---|
| `<leader>gs` | `:Git`，仓库状态和修改列表 |
| `<leader>gd` | `:Gdiffsplit`，比较当前文件与暂存区 |
| `<leader>gb` | `:GitBlame`，查看行的提交来源；兼容短文件与 scrolloff |
| `<leader>gl` | `:Git log --oneline`，提交历史 |

Git 集成使用 [Fugitive](https://github.com/tpope/vim-fugitive)，可直接使用其其它命令；这些快捷键不会提交或推送。差异窗口用 `:diffoff` 退出 diff 状态，再关闭不需要的窗口。

[EditorConfig](https://github.com/editorconfig/editorconfig-vim) 自动读取项目现有 `.editorconfig`，在文件类型默认设置之后应用缩进、编码、换行符等规则。没有规则时继续使用现有配置。项目的 `trim_trailing_whitespace=false` 会阻止原有的保存清理；手动 `:TrimWhitespace` 仍可主动清理。`insert_final_newline=false` 也会生效。修改规则后执行 `:EditorConfigReload`。未在 LaOS 仓库新增格式文件，也未统一覆盖各项目风格。

本次只使用 `/Applications/MacVim.app/Contents/MacOS/Vim`（mvim 的 Vim 9.2）验证，未使用系统 Vim。`tests/project-workflow.vim` 用临时真实 C 文件验证 Clang 22 警告/错误、成功构建、停止、Bear 实际数据库生成与 Clang 22 编译器记录、独立列表、含空格路径、目录切换、不自动写盘，以及 EditorConfig、会话恢复/修改保护、Git 状态/diff/blame。原有基础、保留功能、statusline、Vim 折叠、Balloon 和 C 命令回归也通过。Windows/Linux 实机尚未验证。

## C 调试

`:DebugProgram /path/to/program` 或 `<leader>db` 后输入可执行文件路径，在 Vim 内置终端中打开调试器控制台。macOS 优先 LLDB，其它系统优先 GDB；首选不存在时尝试另一个。参数通过列表传递，路径包含空格或 shell 特殊字符也不会变成 shell 命令。路径补全由 Vim 提供。入口只加载程序，不自动运行、不自动编译或保存源文件。Vim 缺少终端支持、程序不存在或未安装调试器时显示原因。

可在 `vimrc.local` 中指定自己的 GDB/LLDB 可执行文件：

```vim
let g:portable_vim_debugger = '/absolute/path/to/lldb'
```

`:DebugProgram` 的终端背景跟随当前主题。ManShow 还为该终端提供低饱和 ANSI 调色板，将 LLDB 的黄色提示改为在浅绿背景上更清晰的深琥珀色；它不改变 PracticeRun 和普通程序终端。需要临时或按主机覆盖时，可在 `vimrc.local` 设置包含 16 个颜色的 `g:portable_vim_debugger_ansi_colors`，顺序为标准 ANSI 的黑、红、绿、黄、蓝、品红、青、白及对应八个亮色。删除该变量即可恢复主题或 Vim 默认值。

程序需要调试符号。单文件示例在终端执行：

```sh
cc -g -O0 -Wall -Wextra sample.c -o sample
```

项目则使用自身的 Debug 构建，例如 CMake 配置时传入 `-DCMAKE_BUILD_TYPE=Debug`（单配置生成器），多配置生成器构建时使用 `--config Debug`。不修改全局编译选项，避免影响项目实际构建。

| 操作 | LLDB | GDB |
|---|---|---|
| main 断点 | `breakpoint set --name main` | `break main` |
| 运行 | `run` | `run` |
| 下一行，跳过调用 | `next` | `next` |
| 单步进入 | `step` | `step` |
| 继续 | `continue` | `continue` |
| 调用栈 | `bt` | `bt` |
| 查看变量 | `frame variable value` | `print value` |
| 退出 | `quit` | `quit` |

在调试器终端用 `Ctrl-W N` 进入终端普通模式，再用 `Ctrl-W` 窗口命令回到源码；回到终端按 `i` 继续输入。LLDB 的断点和单步说明见 [官方教程](https://lldb.llvm.org/use/tutorial.html)，终端模式见 [Vim 文档](https://vimhelp.org/terminal.txt.html)。本机已验证 LLDB 加载特殊字符路径的临时程序并在 main 断点停止；GDB 和其它平台尚未实测。

若已有可用 GDB，并希望源码窗口显示断点和执行位置，可手动执行 `:packadd termdebug` 后使用 `:Termdebug /path/to/program`，在源码中用其 `:Break`、`:Step`、`:Over`、`:Continue` 等命令。这是另一个按需入口，使用 Vim 自带 GDB/MI 前端；不能将普通 LLDB 直接配置为该前端的 GDB。见 [Vim termdebug](https://vimhelp.org/terminal.txt.html#terminal-debug)。

## 验证

基础配置、C 程序运行和 YCM 定义跳转的验收命令见 [三端使用说明](../README.md)。`tests/` 保留维护用的回归脚本。其中部分场景需要额外工具和项目路径，不能代替三端的安装检查。

参考：[Vundle](https://github.com/VundleVim/Vundle.vim#quick-start)、[YCM](https://github.com/ycm-core/YouCompleteMe#options)、[Tagbar](https://github.com/preservim/tagbar)、[NERDTree](https://github.com/preservim/nerdtree)、[NERDCommenter](https://github.com/preservim/nerdcommenter)。Vim 选项依据本机随发行版提供的帮助文档。
