import 'package:uuid/uuid.dart';

/// ID 与时间的统一入口，方便测试替换。
class IdGenerator {
  const IdGenerator();

  static const _uuid = Uuid();

  /// UUIDv7：全局唯一且按时间有序（schema.md §1.1）。
  String newId() => _uuid.v7();

  int nowMs() => DateTime.now().toUtc().millisecondsSinceEpoch;
}
