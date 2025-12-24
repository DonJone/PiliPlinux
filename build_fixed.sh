#!/bin/bash
set -e # 遇到错误立即停止

# =================配置区域=================
# 请确认你的 appimagetool 路径是正确的
APPIMAGETOOL="$HOME/AppImages/appimagetool.appimage"
# =========================================

echo "🚀 [1/4] 开始构建原始 AppImage..."
rm -rf dist/ squashfs-root
flutter clean > /dev/null
flutter pub get > /dev/null
# 仅构建 AppImage，不发布
flutter_distributor package --platform linux --targets appimage --skip-clean

# 找到生成的 AppImage
ORIGINAL_APP=$(find dist -name '*.AppImage' | sort -V | tail -n 1)
if [ -z "$ORIGINAL_APP" ]; then
    echo "❌ 错误：未找到生成的 AppImage！"
    exit 1
fi
echo "📦 找到文件: $ORIGINAL_APP"
chmod +x "$ORIGINAL_APP"

echo "🔧 [2/4] 执行解包与清理 (Fixing libraries)..."
# 解压
"$ORIGINAL_APP" --appimage-extract > /dev/null

# 【核心修复】删除冲突库
echo "   - 移除 libmpv (修复闪退)..."
rm -f squashfs-root/usr/lib/libmpv.so*
echo "   - 移除 libasound (修复 ALSA 报错)..."
rm -f squashfs-root/usr/lib/libasound.so*

echo "🔨 [3/4] 重新打包为完美版..."
# 生成新文件名
NEW_NAME="${ORIGINAL_APP%.AppImage}-Fixed.AppImage"

# 使用 appimagetool 重打包
# ARCH=x86_64 是为了防止某些环境下报错
ARCH=x86_64 "$APPIMAGETOOL" squashfs-root "$NEW_NAME" > /dev/null

# 清理临时目录
rm -rf squashfs-root

echo "✅ [4/4] 构建完成！"
echo "--------------------------------------------------------"
echo "🎉 完美修复版已生成: $NEW_NAME"
echo "👉 请运行测试: $NEW_NAME"
echo "--------------------------------------------------------"
