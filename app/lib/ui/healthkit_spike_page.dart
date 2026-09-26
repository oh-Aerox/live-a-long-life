import 'package:flutter/material.dart';
import 'package:health/health.dart';

/// T1 HealthKit 技术试验（docs/plan-v0.1.md §1、P-10 前置）。
/// 只验证三件事：免费签名下能开 HealthKit、能申请睡眠读取权限、
/// 能读到睡眠样本。不写入任何数据，结果不入库。
class HealthKitSpikePage extends StatefulWidget {
  const HealthKitSpikePage({super.key});

  @override
  State<HealthKitSpikePage> createState() => _HealthKitSpikePageState();
}

class _HealthKitSpikePageState extends State<HealthKitSpikePage> {
  final _log = <String>[];
  bool _running = false;

  void _add(String line) {
    setState(() => _log.add(line));
  }

  Future<void> _run() async {
    setState(() {
      _log.clear();
      _running = true;
    });
    try {
      final health = Health();
      await health.configure();
      _add('1. HealthKit 插件初始化完成');

      const types = [HealthDataType.SLEEP_ASLEEP, HealthDataType.SLEEP_IN_BED];
      final granted = await health.requestAuthorization(types);
      _add('2. 申请睡眠读取权限：${granted ? '弹窗已处理' : '被拒绝或不可用'}');

      final now = DateTime.now();
      final samples = await health.getHealthDataFromTypes(
        types: types,
        startTime: now.subtract(const Duration(days: 30)),
        endTime: now,
      );
      _add('3. 近 30 天睡眠样本：${samples.length} 条');
      if (samples.isNotEmpty) {
        final s = samples.first;
        _add('   最早一条：${s.typeString} '
            '${s.dateFrom.month}/${s.dateFrom.day} '
            '${s.dateFrom.hour}:${s.dateFrom.minute.toString().padLeft(2, '0')}'
            ' 来源 ${s.sourceName}');
      }
      _add('试验完成。把这一页截图存入 docs/evidence/，更新平台矩阵。');
    } catch (e) {
      _add('失败：$e');
    } finally {
      setState(() => _running = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('HealthKit 试验（T1）')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('验证免费签名下能否申请 HealthKit 权限并读到睡眠样本。'
                '只读取，不写入。'),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _running ? null : _run,
              child: Text(_running ? '进行中…' : '开始试验'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  for (final line in _log)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(line,
                          style: const TextStyle(
                              fontFamily: 'monospace', fontSize: 13)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
