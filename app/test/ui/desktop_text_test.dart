import 'package:flutter_test/flutter_test.dart';
import 'package:live_a_long_life/ui/desktop_text.dart';

void main() {
  test('Windows 上 Mac 改称电脑，去掉两侧空格；钥匙串改系统加密存储', () {
    expect(desktopText('长命百岁（Mac 副本）', windows: true), '长命百岁（电脑副本）');
    expect(desktopText('这台 Mac 保存手机同步来的完整副本', windows: true),
        '这台电脑保存手机同步来的完整副本');
    expect(desktopText('\n\n在 Mac 上用这台 Mac 配置的模型', windows: true),
        '\n\n在电脑上用这台电脑配置的模型');
    expect(desktopText('Mac 分析', windows: true), '电脑分析');
    expect(desktopText('密码存在这台 Mac 的钥匙串里', windows: true),
        '密码存在这台电脑的系统加密存储里');
  });

  test('Mac 上原样返回', () {
    expect(desktopText('这台 Mac 的钥匙串', windows: false), '这台 Mac 的钥匙串');
  });
}
