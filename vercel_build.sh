#!/bin/bash

# Vercel Flutter 构建脚本
# 安装 Flutter 并构建 Web 应用

set -e

# 下载并解压 Flutter SDK
if [ ! -d "flutter" ]; then
  echo "下载 Flutter SDK..."
  curl -sL https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.0-stable.tar.xz -o flutter.tar.xz
  tar xf flutter.tar.xz
  rm flutter.tar.xz
fi

# 修复 git safe.directory 问题
git config --global --add safe.directory /vercel/path0/flutter
git config --global --add safe.directory /vercel/path0

# 添加到 PATH
export PATH="$PATH:$PWD/flutter/bin"

# 停用分析
flutter config --no-analytics

# 启用 web 支持
flutter config --enable-web

# 获取依赖
flutter pub get

# 构建
flutter build web --release

echo "构建完成"
