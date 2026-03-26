# dotfiles

使用 `chezmoi` 管理的个人 dotfiles，目标是同时支持 macOS 和 Linux。

远端仓库：`https://github.com/findix/dotfiles.git`

## 当前纳管范围

- `~/.zshrc`
- `~/.zprofile`
- `~/.gitconfig`
- `~/.p10k.zsh`
- `~/.tmux.conf`
- `~/.vimrc`
- `~/.ssh/config`
- `~/.local/bin/env`
- `~/.config/btop/btop.conf`

## 明确不纳管

- `~/.git-credentials`
- `~/.tmux/plugins`
- `~/.zcompdump*`
- 运行时缓存、状态文件、数据库、下载物
- `~/.config/lnav` 下的数据库和 crash 信息
- `~/.config/opencode/node_modules` 等安装产物

## 约定

- 公共变量放在 `.chezmoidata.yaml`
- 系统差异只用 `.chezmoi.os`
- 机器差异只用 `.chezmoi.hostname`
- secret 不入仓库明文，统一通过 Bitwarden CLI 获取

## 新设备接入

`chezmoi` 只负责同步和渲染配置文件，不负责自动安装 `oh-my-zsh`、`powerlevel10k`、`vim_runtime`、`tpm` 这类依赖。新机器需要先装基础依赖，再执行 `chezmoi init` / `chezmoi apply`。

### macOS

1. 安装 `chezmoi`
   `brew install chezmoi`
2. 安装 `bw`
   `brew install bitwarden-cli`
3. 安装 `oh-my-zsh`
   `sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"`
4. 安装 `powerlevel10k`
   `git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/.oh-my-zsh/custom/themes/powerlevel10k`
5. 安装 `vim_runtime`
   `git clone https://github.com/amix/vimrc.git ~/.vim_runtime && sh ~/.vim_runtime/install_awesome_vimrc.sh`
6. 登录 Bitwarden
   `bw login`
7. 初始化 dotfiles
   `chezmoi init https://github.com/findix/dotfiles.git`
8. 可选：先检查依赖状态
   `~/.local/share/chezmoi/scripts/check-prereqs.sh`
9. 应用配置
   `chezmoi apply`
10. 安装 tmux TPM 插件管理器
   `git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm`
11. 安装 tmux 插件
   `bash ~/.tmux/plugins/tpm/bin/install_plugins`

说明：
当前仓库已经纳管 `~/.p10k.zsh`，`chezmoi apply` 后会直接还原 Powerlevel10k 配置。

### Linux

1. 安装 `chezmoi`
2. 安装 `bw`
3. 安装 `oh-my-zsh`
   `sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"`
4. 安装 `powerlevel10k`
   `git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/.oh-my-zsh/custom/themes/powerlevel10k`
5. 安装 `vim_runtime`
   `git clone https://github.com/amix/vimrc.git ~/.vim_runtime && sh ~/.vim_runtime/install_awesome_vimrc.sh`
6. 登录 Bitwarden
   `bw login`
7. 初始化 dotfiles
   `chezmoi init https://github.com/findix/dotfiles.git`
8. 可选：先检查依赖状态
   `~/.local/share/chezmoi/scripts/check-prereqs.sh`
9. 应用配置
   `chezmoi apply`
10. 安装 tmux TPM 插件管理器
   `git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm`
11. 安装 tmux 插件
   `bash ~/.tmux/plugins/tpm/bin/install_plugins`

说明：
Linux 下 Git 使用 `credential.helper=store`。如果需要保存 PAT，可以在本机自行写入 `~/.git-credentials`。

## tmux

`tmux` 配置现在直接由 `~/.tmux.conf` 承载，不再依赖独立的 `tmux-config` 仓库。

TPM 插件目录仍然使用 `~/.tmux/plugins`，不纳入版本管理。新机器上按需执行：

```bash
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
bash ~/.tmux/plugins/tpm/bin/install_plugins
```

## Bitwarden 用法

当前仓库先把 Bitwarden 作为标准 secret 后端和前置依赖约定下来；当某个配置需要 secret 时，模板中直接通过 `bw` CLI 获取，不写入仓库明文。

如果 `bw` 未安装或未登录，可以先运行 `~/.local/share/chezmoi/scripts/check-prereqs.sh` 获取提示，再继续处理 secret 相关配置。

当前已经接入一个真实场景：macOS 下 GitHub 的 Git credential helper。

在执行 `git push`、`git pull` 之前，先在当前 shell 解锁并导出 session：

```bash
export BW_SESSION="$(bw unlock --raw)"
```

之后 Git 会通过 `~/.local/bin/git-credential-bitwarden` 从 Bitwarden 的 `github.com PAT` 条目读取凭据。
