# Vim 配置和构建维护

全新机器、Windows 部署及插件安装见 [三端使用说明](README.md)。

在本仓库的 `config/` 编辑并提交共享配置。macOS 和 Linux 的 `~/.vim/config` 是部署目标，由 `~/.vimrc` 加载。Windows 使用 `~/vimfiles/config` 和 `~/_vimrc`。

各主机的 `~/.vim/vimrc.local` 保持独立，用于 Python、LLVM、项目和 GUI 设置。`config/maintenance/hosts/` 提供示例。LaOS 项目示例需要手动指定实际的内核仓库和可用工具链。

## 预览和部署

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

在目标主机运行对应的脚本。源码默认读取 `~/src/vim` 的 HEAD，可用 `VIM_SOURCE_DIR` 指定另一份仓库。需要纳入构建的源码改动须先提交。 如需从 Vim 源码目录用 `bash c.sh` 操作，可把已部署的 `~/.vim/config/maintenance/c.sh` 复制到源码目录。脚本将提交号和日志留在构建目录。终端 Vim 和 YCM 均使用 Python 3.13。

| 主机 | 脚本 | 安装 |
|---|---|---|
| macOS | `~/.vim/config/maintenance/build-macos.sh` | `~/.local/opt/vim`，MacVim 单独更新 |
| Gentoo | `~/.vim/config/maintenance/build-gentoo.sh` | `~/.local/opt/vim`，构建纯终端版与 GTK3 版 |

两台机器都在 `~/src/vim` 执行 `bash c.sh` 构建、验证并安装。`bash c.sh --build` 只构建和暂存，`bash c.sh --install` 安装最近一次成功暂存的产物，也可用 `--install <构建目录>` 指定产物。加上 `--verbose` 可实时查看构建输出和安装步骤，完整输出仍写入日志。暂存目录默认分别位于 `~/.cache/vim-macos-build` 和 `~/.cache/vim-gentoo-build`。切换前会验证暂存产物并备份旧安装。安装成功时，构建目录下的 `install-record.txt` 记录源码提交、安装路径及备份位置。Gentoo 的安装入口是 `~/.local/bin/vim` 和 `~/.local/bin/gvim`。将 `~/.local/bin` 加入 PATH，即可用这两个命令启动。登录桌面后可再验证 GTK3 窗口、剪贴板、字体和气泡。

## 第三方插件与 YCM

`bundle/` 和 `config/.vim-pack/` 独立于配置 Git 仓库。`config/plugins.lock` 记录核对过的提交。新增机器可用 `config/maintenance/portable-setup.py plugins` 按清单安装插件源码。YCM/ycmd 的原生扩展在各主机上用各自的 Python 3.13 构建。Gentoo 使用 `/usr/bin/python3.13`，macOS 使用 Python Framework 3.13。更新 Python 或 YCM 后应验证服务启动和 C 语言语义跳转。构建和依赖说明见 [YCM 官方文档](https://github.com/ycm-core/YouCompleteMe#installation)。
