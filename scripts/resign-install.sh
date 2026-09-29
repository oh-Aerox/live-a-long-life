#!/bin/bash
# 一键重签安装（D-19、P-50）。
# 免费签名 7 天过期，到期前把 iPhone 连上 Mac，跑一次本脚本即可：
#   ./scripts/resign-install.sh
# 重新构建会用当前日期的签名，覆盖安装不动应用数据（A-07）。
set -euo pipefail

cd "$(dirname "$0")/../app"

# 默认设备：Aerox。接了别的设备时传设备 ID 作为第一个参数。
DEVICE="${1:-00000000-0000000000000000}"

echo "==> 重新构建并签名（team XXXXXXXXXX）"
flutter build ios --release

# native-assets 原生库（sqlite3、objective_c）由 hooks 产出，构建缓存残留时
# 会漏打包或停留在 adhoc 签名：前者装上后启动空白，后者 devicectl 拒装。
# 出现时先 flutter clean 再重跑（不要只删 build/ios，hooks 缓存在 .dart_tool）。
for fw in sqlite3 objective_c; do
  path="build/ios/iphoneos/Runner.app/Frameworks/$fw.framework"
  if [ ! -d "$path" ] || ! codesign -dv "$path" 2>&1 | grep -q "TeamIdentifier=XXXXXXXXXX"; then
    echo "!! $fw.framework 缺失或未用团队证书签名，先在 app/ 下 flutter clean 后重跑本脚本" >&2
    exit 1
  fi
done

echo "==> 覆盖安装到设备 $DEVICE"
# 不用 flutter install：它会先卸载旧版，应用数据会被清掉（违反 A-07）。
# devicectl 原地升级安装，数据保留。
xcrun devicectl device install app --device "$DEVICE" build/ios/iphoneos/Runner.app

echo "==> 完成。打开应用确认此前的数据还在（A-07）。"
