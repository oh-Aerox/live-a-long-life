import 'dart:io';

/// 电脑端界面文字：按 Mac 的写法写，在 Windows 上把"Mac"换成"电脑"
/// （连同两侧的空格，"这台 Mac 上" → "这台电脑上"），"钥匙串"换成
/// "系统加密存储"：Windows 上 flutter_secure_storage 把密码与 key 加密存成
/// 应用数据目录里的文件，凭据管理器只保管加密用的密钥，用户在凭据管理器里
/// 找不到密码本身。
///
/// 只用于电脑端自己显示的文字。说的是手机上的菜单名（手机设置里的
/// "连接 Mac"）时不要用，手机端的文字也不变。[windows] 只给测试用。
String desktopText(String text, {bool? windows}) {
  if (!(windows ?? Platform.isWindows)) return text;
  return text
      .replaceAll(RegExp(r' ?Mac ?'), '电脑')
      .replaceAll('钥匙串', '系统加密存储');
}
