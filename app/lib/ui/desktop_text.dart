import 'dart:io';

/// 电脑端界面文字：按 Mac 的写法写，在 Windows 上把"Mac"换成"电脑"
/// （连同两侧的空格，"这台 Mac 上" → "这台电脑上"），"钥匙串"换成
/// Windows 上存密码与 key 的"凭据管理器"。
///
/// 只用于电脑端自己显示的文字。说的是手机上的菜单名（手机设置里的
/// "连接 Mac"）时不要用，手机端的文字也不变。[windows] 只给测试用。
String desktopText(String text, {bool? windows}) {
  if (!(windows ?? Platform.isWindows)) return text;
  return text
      .replaceAll(RegExp(r' ?Mac ?'), '电脑')
      .replaceAll('钥匙串', '凭据管理器');
}
