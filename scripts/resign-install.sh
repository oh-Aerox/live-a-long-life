#!/bin/bash
# 一键重签安装（D-19、P-50）。
# 免费签名 7 天过期，到期前把 iPhone 连上 Mac，跑一次本脚本即可：
#   ./scripts/resign-install.sh
# 先续期描述文件（到期日从今天起算 7 天），再重新构建；覆盖安装不动应用数据（A-07）。
set -euo pipefail

cd "$(dirname "$0")/../app"

# team、bundle ID 和默认设备都读本机的 app/Signing.xcconfig（不进 git，
# 照 Signing.example.xcconfig 填写）。接了别的设备时传设备 ID 作为第一个参数。
signing() { sed -nE "s/^[[:space:]]*$1[[:space:]]*=[[:space:]]*([^[:space:]]*).*/\1/p" Signing.xcconfig 2>/dev/null | tail -1; }
TEAM="$(signing DEVELOPMENT_TEAM)"
BUNDLE_ID="$(signing APP_BUNDLE_ID)"
DEVICE="${1:-$(signing IOS_DEVICE_ID)}"
if [ -z "$TEAM" ] || [ -z "$BUNDLE_ID" ] || [ -z "$DEVICE" ]; then
  echo "!! 先在 app/ 下 cp Signing.example.xcconfig Signing.xcconfig，填好 DEVELOPMENT_TEAM、APP_BUNDLE_ID、IOS_DEVICE_ID" >&2
  exit 1
fi

# 续期描述文件：Xcode 会一直复用本机缓存里还没过期的描述文件，只重新构建
# 不会延后到期日（2026-09-30 发现）。先把本应用的缓存挪开，再指定这台设备
# 构建一次让 Xcode 重新申请——免费账号必须指定已连接的设备才能生成，
# flutter build ios 构建的是通用目标，申请不到。失败时放回旧的，不影响已装的应用。
echo "==> 续期描述文件"
PROFILES="$HOME/Library/Developer/Xcode/UserData/Provisioning Profiles"
BACKUP="$(mktemp -d)"
for f in "$PROFILES"/*.mobileprovision; do
  [ -e "$f" ] || continue
  appid="$(security cms -D -i "$f" 2>/dev/null \
    | plutil -extract Entitlements.application-identifier raw -o - - 2>/dev/null || true)"
  if [[ "$appid" == *."$BUNDLE_ID" ]]; then mv "$f" "$BACKUP/"; fi
done
flutter build ios --release --config-only >/dev/null
if ! (cd ios && xcodebuild -workspace Runner.xcworkspace -scheme Runner \
    -configuration Release -destination "id=$DEVICE" \
    -allowProvisioningUpdates -allowProvisioningDeviceRegistration \
    -derivedDataPath "$BACKUP/dd" build >"$BACKUP/xcodebuild.log" 2>&1); then
  mv "$BACKUP"/*.mobileprovision "$PROFILES"/ 2>/dev/null || true
  echo "!! 申请描述文件失败，已放回旧的。日志：$BACKUP/xcodebuild.log" >&2
  exit 1
fi
rm -rf "$BACKUP"

echo "==> 重新构建并签名（team ${TEAM}）"
flutter build ios --release

# native-assets 原生库（sqlite3、objective_c）由 hooks 产出，构建缓存残留时
# 会漏打包或停留在 adhoc 签名：前者装上后启动空白，后者 devicectl 拒装。
# 出现时先 flutter clean 再重跑（不要只删 build/ios，hooks 缓存在 .dart_tool）。
for fw in sqlite3 objective_c; do
  path="build/ios/iphoneos/Runner.app/Frameworks/$fw.framework"
  # 先存输出再匹配：pipefail 下 grep -q 提前退出会让 codesign 收 SIGPIPE 误判失败。
  sig="$(codesign -dv "$path" 2>&1 || true)"
  if [ ! -d "$path" ] || [[ "$sig" != *"TeamIdentifier=$TEAM"* ]]; then
    echo "!! $fw.framework 缺失或未用团队证书签名，先在 app/ 下 flutter clean 后重跑本脚本" >&2
    exit 1
  fi
done

echo "==> 覆盖安装到设备 $DEVICE"
# 不用 flutter install：它会先卸载旧版，应用数据会被清掉（违反 A-07）。
# devicectl 原地升级安装，数据保留。
xcrun devicectl device install app --device "$DEVICE" build/ios/iphoneos/Runner.app

expiry="$(security cms -D -i build/ios/iphoneos/Runner.app/embedded.mobileprovision \
  | plutil -extract ExpirationDate raw -o - -)"
echo "==> 完成，签名到期：${expiry}（UTC）。打开应用确认此前的数据还在（A-07）。"
