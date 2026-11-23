# portable-vim-config

这套配置在 macOS、Linux 和 Windows 上共用 `dotvimrc`、配色、ManShow、快捷键和项目命令。Vim、编译器和 YCM 原生模块使用本机版本。macOS 和 Gentoo 的 Vim 源码构建流程见 [维护说明](README-git.md)。

## 首次部署与日常更新

先克隆仓库到单独的工作目录。

```sh
git clone https://github.com/erocpil/portable-vim-config.git
cd portable-vim-config
```

配置部署需要 Git、Vim 以及 Python 3.10 或更新版本。C/C++ 建议使用 LLVM 的 `clang`、`clang++` 和 `clangd`。Windows 可安装 [Vim 官方构建](https://github.com/vim/vim-win32-installer/releases)，并让 Vim 和 LLVM 可从 PATH 找到。运行 C 程序时，Clang 还需要能找到兼容的系统头文件、运行库和链接器。

macOS 和 Linux，在仓库目录中执行：

```sh
git pull --ff-only
python3 config/maintenance/portable-setup.py deploy
python3 config/maintenance/portable-setup.py deploy --apply
python3 config/maintenance/portable-setup.py plugins
```

Windows PowerShell，在仓库目录中执行：

```powershell
git pull --ff-only
.\config\maintenance\deploy-windows.ps1
.\config\maintenance\deploy-windows.ps1 -Apply
py -3 config/maintenance/portable-setup.py plugins
```

无 `--apply` 或 `-Apply` 时只预览。Windows 脚本可用 `-Vim 'C:\路径\vim.exe'` 指定 Vim，macOS 或 Linux 可通过 `--vim` 指定。应用时会备份改动前的文件、检查 Vim 启动，并记录部署的提交。原 Linux/macOS SSH 部署方式仍见维护说明。

| 设置 | macOS / Linux | Windows |
|---|---|---|
| Vim 入口 | `~/.vimrc` | `~/_vimrc` |
| 共享配置 | `~/.vim/config` | `~/vimfiles/config` |
| 本机覆盖 | `~/.vim/vimrc.local` | `~/vimfiles/vimrc.local` |
| 主机示例 | `config/maintenance/hosts/` | `config/maintenance/hosts/windows.vim.example` |

部署只覆盖仓库跟踪的共享文件，保留已有插件目录和本机覆盖。新的提交若删除共享文件，应手动移走目标上遗留的文件。日常改配置后拉取并重新部署即可，Vim 二进制和插件独立更新。

## 插件和 YCM

`plugins` 按 [插件清单](config/plugins.lock) 获取仓库及固定提交，并检查记录的 ycmd、Jedi 等子模块版本。该命令可以重复运行。它遇到已有目录的版本不符或目录没有 Git 元数据时会停止，请先备份该目录，再更新到锁定提交或把旧目录移出后重新运行。可以加 `--check` 只核对现有 Git 插件，或加 `--skip-ycm` 安装其它插件源码。

YCM 还需本机构建。使用支持 Python 3 且架构匹配的 Vim，准备 Python 3.13、CMake、C++ 工具链和系统的 `clangd`。Windows 使用 Visual Studio C++ Build Tools，并从 Developer PowerShell 启动构建。分别进入 `~/.vim/bundle/YouCompleteMe` 或 `~/vimfiles/bundle/YouCompleteMe`，用目标 Python 执行 `install.py`。Windows 可用 `py -3.13 install.py`。YCM 安装脚本默认拒绝以 root 编译，可在普通账号可访问的暂存目录构建后再部署。macOS 及 Gentoo 的解释器路径见维护说明。现有配置使用外部 clangd。构建后用 `:YcmDebugInfo` 检查服务和后端。

如要使用 Tagbar 或项目搜索，可分别准备 Universal Ctags 和 ripgrep。项目构建和调试命令由本机的项目配置、Make 和调试器决定。

## 验收与支持范围

部署后先运行基础检查，准备好 C 工具链和 YCM 后再运行完整检查：

```sh
python3 config/maintenance/portable-setup.py smoke
python3 config/maintenance/portable-setup.py smoke --practice --ycm
```

Windows 用 `py -3` 代替 `python3`。检查调用已部署的 Vim，验证配置入口和编辑命令，可选验证 `:PracticeRun` 执行 C 程序，以及 YCM/clangd 跳转到函数定义。

| 平台 | 使用方式 | 验收范围 |
|---|---|---|
| macOS | MacVim 或源码构建的终端 Vim | 本机验证配置、运行与 YCM；CI 检查终端 Vim 启动和 C 运行 |
| Linux | Gentoo 可用双版本构建脚本；其他发行版可用兼容的 Vim 包 | Gentoo 本机验证配置、运行与 YCM；CI 用 Ubuntu 检查启动和 C 运行 |
| Windows | 官方终端 Vim / GVim；PowerShell 配置部署 | CI 检查官方终端 Vim 的部署和启动；C 运行、YCM 及 GUI 需在 Windows 上另行验收 |
