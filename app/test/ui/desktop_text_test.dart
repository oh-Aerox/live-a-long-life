import 'package:flutter_test/flutter_test.dart';
import 'package:live_a_long_life/ui/desktop_text.dart';

void main() {
  test('电脑端把 Mac 改称电脑端，去掉两侧空格和后面的"上"', () {
    for (final os in ['macos', 'windows']) {
      expect(desktopText('同步后在 Mac 上重新生成', os: os), '同步后在电脑端重新生成');
      expect(desktopText('Mac 分析', os: os), '电脑端分析');
    }
  });

  test('钥匙串只在 Windows 上改称系统加密存储', () {
    expect(desktopText('密码存在电脑端的钥匙串里', os: 'windows'),
        '密码存在电脑端的系统加密存储里');
    expect(desktopText('密码存在电脑端的钥匙串里', os: 'macos'), '密码存在电脑端的钥匙串里');
  });

  test('手机上原样返回', () {
    for (final os in ['ios', 'android']) {
      expect(desktopText('在 Mac 上的钥匙串', os: os), '在 Mac 上的钥匙串');
    }
  });
}
