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
- `~/.ssh/id_ed25519.pub`
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

推荐直接执行一条命令完成引导：

```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/findix/dotfiles/main/scripts/bootstrap.sh)"
```

这个脚本会尽量自动完成：

- 安装基础依赖
- 安装 `chezmoi`
- 安装 `oh-my-zsh`
- 安装 `powerlevel10k`
- 安装 Meslo Nerd Font
- 安装 `vim_runtime`
- 安装 `tmux` TPM
- 初始化 dotfiles
- 备份现有受管文件
- 预览 `chezmoi diff`
- 交互确认后再 `chezmoi apply`

注意：
脚本会安装 Powerlevel10k 需要的字体文件，但终端软件里的字体选择通常仍需要手动切到 `MesloLGS NF`。
首次接入时，已存在的受管文件会先备份到 `~/.dotfiles-bootstrap-backup/<timestamp>/`，然后展示 diff，确认后才会覆盖。

如果需要手动分步执行，再看下面的细分步骤。

### macOS

1. 安装 `chezmoi`
   `brew install chezmoi`
2. 安装 `bw`
   `brew install bitwarden-cli`
3. 安装 `oh-my-zsh`
   `sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"`
4. 安装 `powerlevel10k`
   `git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/.oh-my-zsh/custom/themes/powerlevel10k`
5. 安装 Nerd Font
   `brew tap homebrew/cask-fonts && brew install --cask font-meslo-lg-nerd-font`
6. 安装 `vim_runtime`
   `git clone https://github.com/amix/vimrc.git ~/.vim_runtime && sh ~/.vim_runtime/install_awesome_vimrc.sh`
7. 登录 Bitwarden
   `bw login`
8. 初始化 dotfiles
   `chezmoi init https://github.com/findix/dotfiles.git`
9. 可选：先检查依赖状态
   `~/.local/share/chezmoi/scripts/check-prereqs.sh`
10. 应用配置
   `chezmoi apply`
11. 安装 tmux TPM 插件管理器
   `git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm`
12. 安装 tmux 插件
   `bash ~/.tmux/plugins/tpm/bin/install_plugins`

说明：
当前仓库已经纳管 `~/.p10k.zsh`，`chezmoi apply` 后会直接还原 Powerlevel10k 配置。
但终端字体仍需要你在 Terminal / iTerm2 / Warp / Kitty 等软件中手动切换到 `MesloLGS NF`。

### Linux

1. 安装 `chezmoi`
2. 安装 `bw`
3. 安装 `oh-my-zsh`
   `sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"`
4. 安装 `powerlevel10k`
   `git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/.oh-my-zsh/custom/themes/powerlevel10k`
5. 安装 Nerd Font
   将 `MesloLGS NF` 安装到用户字体目录，并在终端中手动切换字体
6. 安装 `vim_runtime`
   `git clone https://github.com/amix/vimrc.git ~/.vim_runtime && sh ~/.vim_runtime/install_awesome_vimrc.sh`
7. 登录 Bitwarden
   `bw login`
8. 初始化 dotfiles
   `chezmoi init https://github.com/findix/dotfiles.git`
9. 可选：先检查依赖状态
   `~/.local/share/chezmoi/scripts/check-prereqs.sh`
10. 应用配置
   `chezmoi apply`
11. 安装 tmux TPM 插件管理器
   `git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm`
12. 安装 tmux 插件
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

默认情况下，`git push` / `git pull` 和 SSH 私钥恢复脚本会优先尝试自动调用 `bw login` / `bw unlock`，你不需要先手动 `export BW_SESSION`。

只有在非交互环境里，脚本无法弹出输入时，才需要你手动先准备好 `BW_SESSION`。

之后 Git 会通过 `~/.local/bin/git-credential-bitwarden` 从 Bitwarden 的 `github.com PAT` 条目读取凭据。

### SSH 私钥

`ed25519` SSH 私钥不进入 Git 仓库，而是保存在 Bitwarden 的 `ssh-ed25519` 条目里。

- 仓库里只纳管公钥 `~/.ssh/id_ed25519.pub`
- `~/.ssh/config` 会优先对 `github.com` 和 `codeup.aliyun.com` 使用这把 key
- bootstrap 或手动执行 `~/.local/bin/restore-ssh-key-from-bitwarden` 时，会从 Bitwarden 恢复私钥到 `~/.ssh/id_ed25519`
- 如果当前终端可交互，恢复脚本会自动尝试 `bw login` / `bw unlock`

如果你要把这把新公钥加到平台上，可以直接使用：

```bash
cat ~/.ssh/id_ed25519.pub
```
