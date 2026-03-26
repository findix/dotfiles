#!/bin/sh
# 检查 Bitwarden CLI 和常见包管理器状态，便于新设备完成 dotfiles 初始化。

set -eu

os="$(uname -s | tr '[:upper:]' '[:lower:]')"

print_bw_hint() {
  case "$os" in
    darwin)
      echo "dotfiles: 缺少 bw，请先执行: brew install bitwarden-cli" >&2
      ;;
    linux)
      if command -v apt-get >/dev/null 2>&1; then
        echo "dotfiles: 缺少 bw，请先安装 Bitwarden CLI，例如: sudo apt-get install bitwarden-cli" >&2
      elif command -v dnf >/dev/null 2>&1; then
        echo "dotfiles: 缺少 bw，请先安装 Bitwarden CLI，例如: sudo dnf install bitwarden-cli" >&2
      elif command -v pacman >/dev/null 2>&1; then
        echo "dotfiles: 缺少 bw，请先安装 Bitwarden CLI，例如: sudo pacman -S bitwarden-cli" >&2
      else
        echo "dotfiles: 缺少 bw，请安装 Bitwarden CLI 后再配置 secret。" >&2
      fi
      ;;
    *)
      echo "dotfiles: 当前系统未配置 Bitwarden CLI 安装提示，请手动安装 bw。" >&2
      ;;
  esac
}

if ! command -v bw >/dev/null 2>&1; then
  print_bw_hint
  exit 0
fi

status="$(bw status 2>/dev/null || true)"
case "$status" in
  *'"status":"unlocked"'*)
    ;;
  *'"status":"locked"'*)
    echo "dotfiles: Bitwarden 已安装但处于 locked，请先执行 bw unlock。" >&2
    ;;
  *'"status":"unauthenticated"'*)
    echo "dotfiles: Bitwarden 已安装但未登录，请先执行 bw login。" >&2
    ;;
  *)
    echo "dotfiles: 无法确认 Bitwarden 状态，后续如启用 secret 模板请先执行 bw status 检查。" >&2
    ;;
esac
