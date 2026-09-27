import '../data/db/app_database.dart';

/// 从服务地址推断数据边界（schema §4.3、D-16）：
/// 本机 → device，局域网 → lan，其余 → cloud。
/// 推断结果在配置页展示，用户可改；整理发送前按它检查（A-11）。
DataBoundary inferDataBoundary(String baseUrl) {
  final uri = Uri.tryParse(baseUrl);
  final host = uri?.host ?? '';
  if (host == 'localhost' || host == '127.0.0.1' || host == '::1') {
    return DataBoundary.device;
  }
  if (host.endsWith('.local') || _isPrivateIp(host)) {
    return DataBoundary.lan;
  }
  return DataBoundary.cloud;
}

bool _isPrivateIp(String host) {
  final parts = host.split('.');
  if (parts.length != 4) return false;
  final nums = parts.map(int.tryParse).toList();
  if (nums.any((n) => n == null || n < 0 || n > 255)) return false;
  final a = nums[0]!, b = nums[1]!;
  if (a == 10) return true;
  if (a == 192 && b == 168) return true;
  if (a == 172 && b >= 16 && b <= 31) return true;
  return false;
}
