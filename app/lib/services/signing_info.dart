import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// 免费签名 7 天过期（D-19、P-52）：从应用包内的
/// embedded.mobileprovision 读出到期时间，用于设置页显示和到期前提醒。
/// TestFlight / 商店包没有这个文件，返回 null（不提醒）。
class SigningInfo {
  static Future<DateTime?> provisioningExpiry() async {
    if (!Platform.isIOS) return null;
    try {
      final bundleDir = p.dirname(Platform.resolvedExecutable);
      final file = File(p.join(bundleDir, 'embedded.mobileprovision'));
      if (!await file.exists()) return null;
      // 文件是 CMS 封装的 plist，直接在文本里找 ExpirationDate。
      final content = latin1.decode(await file.readAsBytes());
      final match = RegExp(
              r'<key>ExpirationDate</key>\s*<date>([^<]+)</date>')
          .firstMatch(content);
      if (match == null) return null;
      return DateTime.tryParse(match.group(1)!);
    } catch (_) {
      return null;
    }
  }
}
