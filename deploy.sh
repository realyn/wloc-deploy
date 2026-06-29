#!/usr/bin/env bash
#
# wloc 自部署一键脚本
#   拉取上游更新 → 部署到 Cloudflare Workers → 推送到私有仓库
#
# 用法：在仓库根目录执行
#   ./deploy.sh            # 同步上游 + 部署 + 推送
#   ./deploy.sh --no-sync  # 跳过上游同步，仅部署当前代码
#   ./deploy.sh --no-push  # 部署后不推送到私有仓库
#
set -euo pipefail

# 切到脚本所在目录（仓库根），保证相对路径稳定
cd "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

SYNC=1
PUSH=1
for arg in "$@"; do
  case "$arg" in
    --no-sync) SYNC=0 ;;
    --no-push) PUSH=0 ;;
    -h|--help)
      grep '^#' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "未知参数: $arg（可用 --no-sync / --no-push / --help）"; exit 2 ;;
  esac
done

step() { printf '\n\033[1;36m==> %s\033[0m\n' "$1"; }
warn() { printf '\033[1;33m!! %s\033[0m\n' "$1"; }

# --- 0. 前置检查：Cloudflare 是否已登录 ---
step "检查 Cloudflare 登录状态"
if ! npx --yes wrangler whoami >/dev/null 2>&1; then
  warn "尚未登录 Cloudflare。请先运行： npx wrangler login"
  exit 1
fi
echo "已登录 ✓"

# --- 1. 同步上游 ---
if [ "$SYNC" -eq 1 ]; then
  step "同步上游更新 (upstream/main)"
  if git remote | grep -qx upstream; then
    git fetch upstream
    if ! git merge --no-edit upstream/main; then
      warn "合并上游时出现冲突，请手动解决后重跑（可加 --no-sync 跳过同步先部署）。"
      exit 1
    fi
  else
    warn "未配置 upstream remote，跳过上游同步。"
  fi
else
  step "跳过上游同步 (--no-sync)"
fi

# --- 2. 安装依赖 ---
step "安装依赖 (worker/)"
( cd worker && npm install )

# --- 3. 部署 ---
step "部署到 Cloudflare Workers"
( cd worker && npm run deploy )

# --- 4. 推送到私有仓库 ---
if [ "$PUSH" -eq 1 ]; then
  step "推送到私有仓库 (origin)"
  if git remote | grep -qx origin; then
    if [ -n "$(git status --porcelain)" ]; then
      warn "工作区有未提交改动，先提交再推送。"
      git add -A
      git commit -m "chore: 自部署同步" || true
    fi
    git push origin HEAD
  else
    warn "未配置 origin remote，跳过推送。"
  fi
else
  step "跳过推送 (--no-push)"
fi

printf '\n\033[1;32m✅ 完成。Worker 地址见上方部署输出（https://wloc-spoofer.<你的子域名>.workers.dev）。\033[0m\n'
