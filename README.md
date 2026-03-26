# dotfiles

使用 `chezmoi` 管理的个人 dotfiles，目标是同时支持 macOS 和 Linux。

## 当前纳管范围

- `~/.zshrc`
- `~/.zprofile`
- `~/.gitconfig`
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

### macOS

1. 安装 `chezmoi`
   `brew install chezmoi`
2. 安装 `bw`
   `brew install bitwarden-cli`
3. 登录 Bitwarden
   `bw login`
4. 初始化 dotfiles
   `chezmoi init <dotfiles-repo>`
5. 可选：先检查依赖状态
   `~/.local/share/chezmoi/scripts/check-prereqs.sh`
6. 应用配置
   `chezmoi apply`

### Linux

1. 安装 `chezmoi`
2. 安装 `bw`
3. 登录 Bitwarden
   `bw login`
4. 初始化 dotfiles
   `chezmoi init <dotfiles-repo>`
5. 可选：先检查依赖状态
   `~/.local/share/chezmoi/scripts/check-prereqs.sh`
6. 应用配置
   `chezmoi apply`

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

当前已经接入一个真实场景：GitHub 的 Git credential helper。

在执行 `git push`、`git pull` 之前，先在当前 shell 解锁并导出 session：

```bash
export BW_SESSION="$(bw unlock --raw)"
```

之后 Git 会通过 `~/.local/bin/git-credential-bitwarden` 从 Bitwarden 的 `github.com` 条目读取凭据。
