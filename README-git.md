# Vim 配置和构建维护

全新机器、Windows 部署及插件安装见 [三端使用说明](README.md)。

在本仓库的 `config/` 编辑并提交共享配置。macOS 和 Linux 的 `~/.vim/config` 是日常使用的 Git 检出，由 `~/.vimrc` 加载。Windows 使用 `~/vimfiles/config` 和 `~/_vimrc`。

各主机的 `~/.vim/vimrc.local` 保持独立，用于 Python、LLVM、项目和 GUI 设置。`config/maintenance/hosts/` 提供示例。LaOS 项目示例需要手动指定实际的内核仓库和可用工具链。

## 旧版复制式部署

以下命令适用于仍使用复制式部署的主机。使用 Git 检出的主机直接拉取更新。

在仓库根目录运行：

```sh
git status --short
config/maintenance/deploy.sh
config/maintenance/deploy.sh --host user@gentoo-host
config/maintenance/deploy.sh --apply
config/maintenance/deploy.sh --apply --host user@gentoo-host
```

默认预览 HEAD 的内容差异，可用 `--revision <提交>` 指定其他提交。脚本按 Git 提交覆盖共享文件，保留目标已有的第三方插件、主机覆盖和其他文件。若在仓库中删除共享文件，部署预览不会删除目标旧文件，应单独移走该文件。应用前备份配置和入口至 `~/.vim/backups/deploy-*`，启动检查失败时恢复。成功后可查 `~/.vim/config/.deployed-revision`。这个记录表示最近部署的提交，本地后续编辑用 `git status` 或部署预览检查。

## 更新和构建 Vim

在各主机的 `~/src/vim` 执行 `git pull --ff-only`。Gentoo 访问 GitHub 超时时，可在 macOS 更新官方源码，使用 Gentoo 当前提交作为 Git bundle 的基线，再经 SSH 转运。具体命令见 `config/maintenance/build-gentoo.sh`。

在目标主机运行对应的脚本。源码默认读取 `~/src/vim` 的 HEAD，可用 `VIM_SOURCE_DIR` 指定另一份仓库。需要纳入构建的源码改动须先提交。 如需从 Vim 源码目录用 `bash c.sh` 操作，可把`~/.vim/config/config/maintenance/c.sh` 复制到源码目录。脚本将提交号和日志留在构建目录。终端 Vim 和 YCM 均使用 Python 3.13。

| 主机 | 脚本 | 安装 |
|---|---|---|
| macOS | `~/.vim/config/config/maintenance/build-macos.sh` | `~/.local/opt/vim`，MacVim 单独更新 |
| Gentoo | `~/.vim/config/config/maintenance/build-gentoo.sh` | `~/.local/opt/vim`，构建纯终端版与 GTK3 版 |

两台机器都在 `~/src/vim` 执行 `bash c.sh` 构建、验证并安装。`bash c.sh --build` 只构建和暂存，`bash c.sh --install` 安装最近一次成功暂存的产物，也可用 `--install <构建目录>` 指定产物。加上 `--verbose` 可实时查看构建输出和安装步骤，完整输出仍写入日志。暂存目录默认分别位于 `~/.cache/vim-macos-build` 和 `~/.cache/vim-gentoo-build`。切换前会验证暂存产物并备份旧安装。安装成功时，构建目录下的 `install-record.txt` 记录源码提交、安装路径及备份位置。Gentoo 的安装入口是 `~/.local/bin/vim` 和 `~/.local/bin/gvim`。将 `~/.local/bin` 加入 PATH，即可用这两个命令启动。登录桌面后可再验证 GTK3 窗口、剪贴板、字体和气泡。

## 第三方插件与 YCM

YCM 安装在 `~/.vim/bundle/YouCompleteMe`，Windows 安装在 `~/vimfiles/bundle/YouCompleteMe`。本机编译需要 CMake、C++ 工具链和 Python 开发头文件。Vim 需要 `+python3`，`ycm_core` 必须用运行 ycmd 的 Python 和对应架构构建。若本机覆盖文件中设置了 `g:ycm_server_python_interpreter`，让它与 `--python` 指向同一解释器。项目目前在 macOS 和 Gentoo 使用 Python 3.13。

### macOS 和 Gentoo

以下命令从配置仓库根目录运行。首次安装配置后，先用 `python3 config/maintenance/portable-setup.py plugins --skip-ycm` 准备 Vundle 和其他插件。随后运行对应平台的命令：

```sh
# macOS
python3 config/maintenance/portable-setup.py ycm \
  --python /Library/Frameworks/Python.framework/Versions/3.13/bin/python3 \
  --vim "$(command -v mvim)"

# Gentoo 普通用户
/usr/bin/python3.13 config/maintenance/portable-setup.py ycm \
  --python /usr/bin/python3.13 --vim "$HOME/.local/bin/vim"

# Gentoo root 账户使用的 Vim
/usr/bin/python3.13 config/maintenance/portable-setup.py ycm \
  --python /usr/bin/python3.13 --vim /root/.local/bin/vim --build-user nobody
```

Linux 若以 root 安装，可用 `--build-user` 指定已有的普通账号。工具通过 `runuser` 让该账号在 `/var/tmp` 下构建，然后由安装账号完成验证和切换。脚本会在暂存目录编译并用当前 Vim 配置测试 C 函数定义跳转。通过后才替换插件，并在正式路径再测试一次。安装后验证失败时会恢复旧版。此前的插件目录备份在 `~/.vim/backups/ycm-*/YouCompleteMe`，成功后脚本会打印确切路径。可用 `--verbose` 查看详细构建输出。

本项目默认使用系统安装的 `clangd`，可在 `vimrc.local` 中通过 `g:ycm_clangd_binary_path` 指定路径。若希望由 YCM 下载自带的 `clangd`，在命令后加 `--clangd-completer`，并在本机覆盖中把 `g:ycm_clangd_binary_path` 设为空字符串。 [YCM 官方安装说明](https://github.com/ycm-core/YouCompleteMe#installation)

也可以手动构建。先在配置仓库运行 `python3 config/maintenance/portable-setup.py plugins` 获取插件源码，再在普通账号下进入 `~/.vim/bundle/YouCompleteMe`。macOS 执行 `/Library/Frameworks/Python.framework/Versions/3.13/bin/python3 install.py`，Gentoo 执行 `/usr/bin/python3.13 install.py`。在已有安装中手动重编前，先备份插件目录。

### GitHub 访问受限时

从能访问 GitHub 的机器转运一个包含 `.git` 和全部递归子模块的 YCM 检出，例如 macOS 上已完整初始化子模块的检出。把它解包在 Gentoo 的暂存目录后，给上述命令增加 `--source /path/to/YouCompleteMe`。在 Gentoo 解包时用 `tar --no-same-owner`，让 Git 检出的文件归当前账号所有。脚本从本地 Git 检出获取源码和子模块，在目标机器编译。可排除 `*.so`、`*.dylib` 和 `__pycache__` 以缩小传输大小。

如果 CMake 下载 Abseil 时也超时，按所用 ycmd 的 `cpp/CMakeLists.txt` 中 `FetchContent_Declare(absl ...)` 记录的提交下载并解包 Abseil。在命令前设置 `EXTRA_CMAKE_ARGS=-DFETCHCONTENT_SOURCE_DIR_ABSL=/path/to/abseil`。使用 `--build-user` 时，该账号需要对解包目录有读取和遍历权限。

### Windows 手动编译

安装支持 Python 3 的 Vim、匹配架构的 Python 3.13、CMake、Visual Studio C++ Build Tools 和 `clangd`。从 Developer PowerShell 在配置仓库中执行：

```powershell
py -3 config/maintenance/portable-setup.py plugins
Set-Location "$env:USERPROFILE/vimfiles/bundle/YouCompleteMe"
py -3.13 install.py
```

需要 YCM 自带的 `clangd` 时可为 `install.py` 加 `--clangd-completer`，并清空本机覆盖中的外部后端路径。可以用 `py -3.13 -c "import sys; print(sys.executable)"` 获取解释器路径，供 `g:ycm_server_python_interpreter` 使用。

### 验证

安装后重启 Vim，在 C 文件中运行 `:YcmDebugInfo` 查看 ycmd 解释器和 clangd 后端。也可从配置仓库运行：

```sh
python3 config/maintenance/portable-setup.py smoke --ycm --vim /path/to/vim
```

Windows 用 `py -3` 启动该工具。检查确认加载的是目标 YCM 检出，并通过一个独立 C 示例测试跳转到定义。
