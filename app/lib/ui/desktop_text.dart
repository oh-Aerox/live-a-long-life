import 'dart:io';

/// 电脑端（Mac 与 Windows）界面文字。
///
/// 电脑端自己的页面直接写"电脑端"，不提 Mac。手机与电脑端共用的页面按手机
/// 的写法写（手机上把电脑端称作"Mac"），在电脑端用这个函数把"Mac"换成
/// "电脑端"（连同两侧的空格和后面的"上"："在 Mac 上重新生成" → "在电脑端
/// 重新生成"）。手机上原样返回。
///
/// Windows 上另把"钥匙串"换成"系统加密存储"：flutter_secure_storage 在
/// Windows 上把密码与 key 加密存成应用数据目录里的文件，凭据管理器只保管
/// 加密用的密钥，用户在凭据管理器里找不到密码本身。
///
/// [os] 取 [Platform.operatingSystem] 的值，只给测试用。
String desktopText(String text, {String? os}) {
  final system = os ?? Platform.operatingSystem;
  if (system != 'macos' && system != 'windows') return text;
  final replaced = text.replaceAll(RegExp(r' ?Mac ?上?'), '电脑端');
  return system == 'windows'
      ? replaced.replaceAll('钥匙串', '系统加密存储')
      : replaced;
}
