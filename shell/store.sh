#!/bin/bash
set -e

BASE_URL="https://repo.istoreos.com/repo/all/store/"
TARGET_DIR="store"
mkdir -p "$TARGET_DIR"

# 匹配的包名前缀
packages=(
  "luci-app-store"
  "luci-lib-taskd"
  "luci-lib-xterm"
  "taskd"
)

# 检测系统架构
arch=$(uname -m)
case "$arch" in
  armv7l|armv7)
    arch_pattern="(armv7|arm_cortex-a7|arm_cortex-a5|all)"
    arch_name="ARMv7 (Cortex-A5/A7)"
    ;;
  aarch64)
    arch_pattern="(aarch64|arm64|all)"
    arch_name="ARM64"
    ;;
  x86_64)
    arch_pattern="(x86_64|amd64|all)"
    arch_name="x86_64"
    ;;
  *)
    arch_pattern="all"
    arch_name="Unknown"
    ;;
esac

echo -e "\033[1;32m[+] Detected architecture: $arch_name\033[0m"
echo "[+] Fetching index page from $BASE_URL ..."
page_content=$(curl -fsSL --retry 3 "$BASE_URL")

# 提取所有 .ipk 文件
echo "[+] Parsing .ipk links..."
all_ipks=$(echo "$page_content" | grep -oP 'href="\K[^"]+\.ipk')

# 匹配并下载
for prefix in "${packages[@]}"; do
  match=$(echo "$all_ipks" | grep -E "^${prefix}_.*${arch_pattern}\.ipk$" | head -n1)
  if [ -n "$match" ]; then
    echo -e "\033[0;36m[+] Downloading $match ...\033[0m"
    curl -fsSL --retry 3 -o "$TARGET_DIR/$match" "${BASE_URL}${match}" || {
      echo -e "\033[0;31m[!] Failed to download $match\033[0m"
    }
  else
    echo -e "\033[0;33m[!] No matching .ipk found for $prefix ($arch_name)\033[0m"
  fi
done

echo -e "\033[1;32m[✓] All done. Packages saved in: $TARGET_DIR\033[0m"
