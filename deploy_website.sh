#!/usr/bin/env bash
# 官网发布脚本 —— 把 官网/ 目录同步到腾讯云 COS 静态站桶
#
# 用法：
#   ./deploy_website.sh              # 预演（默认，不写入任何东西）
#   ./deploy_website.sh --apply      # 真正上传
#
# 环境变量：
#   WEB_BUCKET   静态站桶名，默认 pdgait-web-2026-tsy-1506787885
#   COSCLI       coscli 路径，默认 ~/.local/bin/coscli
#   APK_PATH     要发布的 APK，默认取 PDGaitMonitor 的 release 构建产物
#
# 前置：桶必须已创建、已开启静态网站、已绑定备案域名（或在控制台用默认域名预览）。

set -euo pipefail

SITE_DIR="$(cd "$(dirname "$0")" && pwd)"
WEB_BUCKET="${WEB_BUCKET:-pdgait-web-2026-tsy-1506787885}"
COSCLI="${COSCLI:-$HOME/.local/bin/coscli}"
APK_PATH="${APK_PATH:-$SITE_DIR/../PDGaitMonitor/app/build/outputs/apk/release/app-release.apk}"
APPLY=0

for arg in "$@"; do
  case "$arg" in
    --apply) APPLY=1 ;;
    -h|--help) sed -n '2,16p' "$0"; exit 0 ;;
    *) echo "未知参数：$arg" >&2; exit 2 ;;
  esac
done

if [[ ! -x "$COSCLI" ]]; then
  echo "找不到 coscli：$COSCLI" >&2
  echo "安装或设置 COSCLI=/path/to/coscli" >&2
  exit 1
fi

echo "站点目录 : $SITE_DIR"
echo "目标桶   : cos://$WEB_BUCKET/"
echo "模式     : $([[ $APPLY -eq 1 ]] && echo 'APPLY（会写入）' || echo 'DRY-RUN（只预演）')"
echo

# 1) 准备 APK
if [[ -f "$APK_PATH" ]]; then
  APK_NAME="$(basename "$APK_PATH")"
  # 发布名带版本号，方便用户分辨
  VERSION="$(grep -oP 'versionName\s*=\s*"\K[^"]+' "$SITE_DIR/../PDGaitMonitor/app/build.gradle.kts" | head -1 || true)"
  DEST_APK="$SITE_DIR/download/PDGaitMonitor-${VERSION:-latest}.apk"
  echo "[APK] $APK_PATH -> download/$(basename "$DEST_APK")"
  if [[ $APPLY -eq 1 ]]; then
    mkdir -p "$SITE_DIR/download"
    cp -f "$APK_PATH" "$DEST_APK"
  fi
else
  echo "[APK] 未找到构建产物，跳过：$APK_PATH"
fi

# 2) 检查必填占位是否还留着
if grep -rq "XXXXXXXX" "$SITE_DIR"/*.html; then
  echo
  echo "⚠ 页面里仍有 ICP 备案号占位 XXXXXXXX。"
  echo "  备案通过后请替换 官网/*.html 与页脚中的备案号，再重新发布。"
  echo
fi

# 3) 同步
SYNC_ARGS=(
  sync "$SITE_DIR/" "cos://$WEB_BUCKET/"
  --exclude "deploy_website.sh"
  --exclude "README*"
  --exclude "*.sh"
  --delete
  --err-retry-num 3
)

echo "[sync] 将同步 HTML / CSS / JS / 图片 / APK"
if [[ $APPLY -eq 1 ]]; then
  "$COSCLI" "${SYNC_ARGS[@]}"
  echo
  echo "✅ 上传完成。若已配置 CDN，请刷新缓存："
  echo "   控制台 → CDN → 域名管理 → 缓存配置 → 刷新 URL/目录"
  echo
  echo "验证："
  echo "   curl -I https://pdgait.com.cn/"
else
  # dry-run：只列出会变化的文件（coscli 没有 dry-run，用本地清单代替）
  echo "[dry-run] 本地待发布文件："
  (cd "$SITE_DIR" && find . -type f \
    ! -name "deploy_website.sh" ! -name "README*" ! -name "*.sh" \
    -printf '  %P\n' | sort)
  echo
  echo "确认无误后执行：$0 --apply"
fi
