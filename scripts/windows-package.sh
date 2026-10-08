#!/bin/bash
# Windows 安装包：构建 release 并用 Inno Setup 打成 setup.exe。
# 在 Windows 的 Git Bash 里运行（需要装好 Flutter、VS C++ 工具和 Inno Setup 6.5+）：
#   ./scripts/windows-package.sh            # 版本号取 pubspec.yaml 的 version
#   ./scripts/windows-package.sh 0.4.0      # 指定版本号（不改 pubspec）
# 产物在 app/build/windows/installer/。
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# release 构建在含中文的路径下会失败（编译步骤把"项目"读成乱码，找不到 app.dill；
# debug 不受影响）。用 subst 把仓库映射到一个空闲盘符，在纯英文路径下构建。
DRIVE=""
for letter in L M N P Q R S T U V W X Y Z; do
  if [ ! -d "$letter:/" ]; then DRIVE="$letter:"; break; fi
done
if [ -z "$DRIVE" ]; then echo "没有空闲盘符可用于 subst" >&2; exit 1; fi
MSYS_NO_PATHCONV=1 subst "$DRIVE" "$(cygpath -w "$ROOT")"
# 退出时也删掉 CMake 缓存：它记着 subst 盘符，盘符撤掉后 flutter run 会配置失败。
trap 'rm -f "$ROOT/app/build/windows/x64/CMakeCache.txt"; MSYS_NO_PATHCONV=1 subst "$DRIVE" /D' EXIT
ROOT="/${DRIVE%:}"
ROOT="${ROOT,,}"
cd "$ROOT/app"

PUBSPEC_VERSION="$(sed -n 's/^version: *//p' pubspec.yaml | tr -d '\r')"
VERSION="${1:-${PUBSPEC_VERSION%%+*}}"
BUILD_NUMBER="${PUBSPEC_VERSION##*+}"

ISCC="${ISCC:-/c/Program Files (x86)/Inno Setup 6/ISCC.exe}"
if [ ! -x "$ISCC" ]; then
  echo "找不到 Inno Setup：$ISCC（可用 ISCC 环境变量指定）" >&2
  exit 1
fi

echo "==> 构建 release（$VERSION+$BUILD_NUMBER）"
# CMake 缓存记着上次配置时的源码路径（flutter run 用的是 C:\ 下的中文路径），
# 换到 subst 盘符后要重新配置，否则两套路径混用，找不到 cpp_client_wrapper。
rm -f build/windows/x64/CMakeCache.txt
flutter build windows --release --build-name "$VERSION" --build-number "$BUILD_NUMBER"

BUILD_DIR="$ROOT/app/build/windows/x64/runner/Release"

echo "==> 放入 VC++ 运行库"
# Flutter 的 exe 依赖这三个 DLL，干净的系统上可能没有。取本机 64 位系统目录的版本
# （Git Bash 是 64 位进程，System32 不会被重定向到 SysWOW64）。
for dll in msvcp140.dll vcruntime140.dll vcruntime140_1.dll; do
  cp "/c/Windows/System32/$dll" "$BUILD_DIR/"
done

echo "==> 打安装包"
# 关掉 Git Bash 的路径转换，否则 /Q、/D 开头的参数会被当成路径改写。
MSYS_NO_PATHCONV=1 "$ISCC" /Q \
  "/DAppVersion=$VERSION" \
  "/DBuildDir=$(cygpath -w "$BUILD_DIR")" \
  "$(cygpath -w "$ROOT/scripts/windows/installer.iss")"

echo "完成：$(ls "$ROOT"/app/build/windows/installer/*"$VERSION"*-setup.exe)"
