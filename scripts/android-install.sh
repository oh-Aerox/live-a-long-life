#!/bin/bash
# 安卓覆盖安装（plan-android AN-M0、P-51）。
# 手机开启 USB 调试并连上 Mac 后运行：
#   ./scripts/android-install.sh            # 只有一台安卓设备时
#   ./scripts/android-install.sh <序列号>    # 接了多台时，序列号见 adb devices
# 覆盖安装不动应用数据（A-07）。
set -euo pipefail

cd "$(dirname "$0")/../app"

SERIAL_ARGS=()
if [ $# -ge 1 ]; then SERIAL_ARGS=(-s "$1"); fi

echo "==> 构建 release APK（只打 arm64，小米 12 是 arm64）"
# release 暂用 debug 密钥签名（模板默认），与 flutter run 装的调试版签名一致，
# 两者之间可以互相覆盖安装。正式签名随发版一起做（D-30）。
flutter build apk --release --target-platform android-arm64

APK=build/app/outputs/flutter-apk/app-release.apk
echo "==> 覆盖安装 $APK"
# 不用 flutter install：它会先卸载旧版，应用数据会被清掉（违反 A-07）。
# -r 覆盖安装保留数据。小米需在开发者选项打开"USB 安装"，且每次安装手机上会弹
# 确认框，有倒计时，不点就报 INSTALL_FAILED_USER_RESTRICTED（2026-09-30 真机确认）。
adb "${SERIAL_ARGS[@]+"${SERIAL_ARGS[@]}"}" install -r "$APK"

echo "==> 启动"
adb "${SERIAL_ARGS[@]+"${SERIAL_ARGS[@]}"}" shell monkey -p io.github.oh_aerox.livealonglife -c android.intent.category.LAUNCHER 1 >/dev/null
echo "完成"
