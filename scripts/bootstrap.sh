#!/bin/sh
# 一条命令完成新机器的 dotfiles 引导：安装依赖、初始化 chezmoi、应用配置并补装常用 shell/tmux 组件。

set -eu

REPO_URL="${DOTFILES_REPO_URL:-https://github.com/findix/dotfiles.git}"
CHEZMOI_BIN="${HOME}/.local/bin/chezmoi"
OS="$(uname -s | tr '[:upper:]' '[:lower:]')"

has_cmd() {
  command -v "$1" >/dev/null 2>&1
}

log() {
  printf 'dotfiles-bootstrap: %s\n' "$*"
}

run_sudo() {
  if has_cmd sudo; then
    sudo "$@"
  else
    "$@"
  fi
}

install_homebrew() {
  if has_cmd brew; then
    return
  fi

  log "安装 Homebrew"
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [ -x /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
}

brew_install_if_missing() {
  pkg="$1"
  cmd_name="${2:-$1}"
  if has_cmd "$cmd_name"; then
    return
  fi

  log "安装 ${pkg}"
  brew install "$pkg"
}

brew_install_cask_if_missing() {
  cask_name="$1"
  if brew list --cask "$cask_name" >/dev/null 2>&1; then
    return
  fi

  log "安装 ${cask_name}"
  brew install --cask "$cask_name"
}

linux_pkg_install() {
  if has_cmd apt-get; then
    run_sudo apt-get update
    run_sudo apt-get install -y "$@"
    return
  fi

  if has_cmd dnf; then
    run_sudo dnf install -y "$@"
    return
  fi

  if has_cmd pacman; then
    run_sudo pacman -Sy --noconfirm "$@"
    return
  fi

  log "未识别的 Linux 包管理器，请手动安装: $*"
}

install_chezmoi() {
  if has_cmd chezmoi; then
    return
  fi

  case "$OS" in
    darwin)
      install_homebrew
      brew_install_if_missing chezmoi
      ;;
    linux)
      mkdir -p "${HOME}/.local/bin"
      log "安装 chezmoi"
      sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "${HOME}/.local/bin"
      export PATH="${HOME}/.local/bin:${PATH}"
      ;;
    *)
      log "不支持的系统: ${OS}"
      exit 1
      ;;
  esac
}

install_base_packages() {
  case "$OS" in
    darwin)
      install_homebrew
      brew_install_if_missing git
      brew_install_if_missing bitwarden-cli bw
      brew_install_if_missing tmux
      ;;
    linux)
      if ! has_cmd git || ! has_cmd curl || ! has_cmd zsh || ! has_cmd tmux; then
        log "安装 Linux 基础依赖"
        linux_pkg_install git curl zsh tmux vim
      fi
      if ! has_cmd bw; then
        if has_cmd apt-get; then
          linux_pkg_install bitwarden-cli || true
        elif has_cmd dnf; then
          linux_pkg_install bitwarden-cli || true
        elif has_cmd pacman; then
          linux_pkg_install bitwarden-cli || true
        fi
      fi
      ;;
  esac
}

install_oh_my_zsh() {
  if [ -d "${HOME}/.oh-my-zsh" ]; then
    return
  fi

  log "安装 oh-my-zsh"
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
}

install_powerlevel10k() {
  target="${HOME}/.oh-my-zsh/custom/themes/powerlevel10k"
  if [ -d "$target" ]; then
    return
  fi

  log "安装 powerlevel10k"
  mkdir -p "$(dirname "$target")"
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$target"
}

install_nerd_font() {
  case "$OS" in
    darwin)
      install_homebrew
      brew tap homebrew/cask-fonts >/dev/null 2>&1 || true
      brew_install_cask_if_missing font-meslo-lg-nerd-font
      ;;
    linux)
      font_dir="${HOME}/.local/share/fonts"
      target="${font_dir}/MesloLGS NF Regular.ttf"
      if [ -f "$target" ]; then
        return
      fi

      log "安装 Meslo Nerd Font"
      mkdir -p "$font_dir"
      archive="/tmp/meslo-nerd-font.zip"
      curl -fsSL -o "$archive" https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF.zip
      if has_cmd unzip; then
        unzip -o "$archive" -d "$font_dir" >/dev/null
      else
        log "缺少 unzip，无法自动解压字体，请手动安装后重试。"
        return
      fi

      if has_cmd fc-cache; then
        fc-cache -f "$font_dir" >/dev/null 2>&1 || true
      fi
      ;;
  esac
}

install_vim_runtime() {
  if [ -d "${HOME}/.vim_runtime" ]; then
    return
  fi

  log "安装 vim_runtime"
  git clone https://github.com/amix/vimrc.git "${HOME}/.vim_runtime"
  sh "${HOME}/.vim_runtime/install_awesome_vimrc.sh"
}

install_tpm() {
  target="${HOME}/.tmux/plugins/tpm"
  if [ -d "$target" ]; then
    return
  fi

  log "安装 tmux TPM"
  mkdir -p "${HOME}/.tmux/plugins"
  git clone https://github.com/tmux-plugins/tpm "$target"
}

setup_bitwarden_session() {
  if ! has_cmd bw; then
    return
  fi

  status="$(bw status 2>/dev/null || true)"
  case "$status" in
    *'"status":"unlocked"'*)
      return
      ;;
    *'"status":"unauthenticated"'*)
      log "Bitwarden 未登录，开始交互登录"
      bw login
      ;;
  esac

  status="$(bw status 2>/dev/null || true)"
  case "$status" in
    *'"status":"unlocked"'*)
      return
      ;;
    *'"status":"locked"'*|*'"status":"unauthenticated"'*)
      if [ -t 0 ]; then
        log "解锁 Bitwarden，用于后续 GitHub 凭据读取"
        BW_SESSION="$(bw unlock --raw)"
        export BW_SESSION
      fi
      ;;
  esac
}

run_chezmoi() {
  if has_cmd chezmoi; then
    chezmoi init --apply "$REPO_URL"
    return
  fi

  "${CHEZMOI_BIN}" init --apply "$REPO_URL"
}

install_tmux_plugins() {
  if [ -x "${HOME}/.tmux/plugins/tpm/bin/install_plugins" ]; then
    log "安装 tmux 插件"
    sh "${HOME}/.tmux/plugins/tpm/bin/install_plugins"
  fi
}

main() {
  install_base_packages
  install_chezmoi
  install_oh_my_zsh
  install_powerlevel10k
  install_nerd_font
  install_vim_runtime
  install_tpm
  setup_bitwarden_session
  run_chezmoi
  install_tmux_plugins
  log "完成。建议重新打开 shell。"
}

main "$@"
