import 'package:flutter_test/flutter_test.dart';
import 'package:live_a_long_life/data/lab_catalog.dart';
import 'package:live_a_long_life/data/lab_explain.dart';
import 'package:live_a_long_life/data/repositories/settings_repository.dart';

import 'test_helpers.dart';

void main() {
  test('内置说明的键都是目录里的标准名；别名也查得到；常识项目和过敏原不写', () {
    for (final name in LabExplain.builtInNames) {
      expect(LabCatalog.byName.containsKey(name), isTrue, reason: name);
    }
    expect(LabExplain.builtIn('ALT')!.meaning, contains('肝细胞'));
    expect(LabExplain.builtIn('谷丙转氨酶'), same(LabExplain.builtIn('丙氨酸氨基转移酶')));
    final hbsab = LabExplain.builtIn('乙型肝炎病毒表面抗体')!;
    expect(hbsab.highLabel, '阳性');
    expect(hbsab.low, isNull);
    expect(LabExplain.builtIn('身高'), isNull);
    expect(LabExplain.builtIn('鸡蛋白'), isNull);
  });

  test('只有目录外、不是过敏原的项目才让模型生成', () {
    expect(LabExplain.canGenerate('丙氨酸氨基转移酶'), isFalse);
    expect(LabExplain.canGenerate('身高'), isFalse); // 目录里、本来就不需要
    expect(LabExplain.canGenerate('猫毛皮屑', group: '过敏原检测'), isFalse);
    expect(LabExplain.canGenerate('MTHFR', group: '基因检测'), isTrue);
  });

  test('模型生成的说明存本机设置，不需要说明的也记下', () async {
    final env = await TestEnv.create();
    addTearDown(env.dispose);
    final settings = SettingsRepository(env.db);
    expect(await LabExplain.generated(settings, 'MTHFR'), isNull);
    await LabExplain.saveGenerated(settings, 'MTHFR',
        const LabExplanation('叶酸代谢相关基因', related: '同型半胱氨酸'), '2026-10-30');
    await LabExplain.saveGenerated(settings, '色觉', null, '2026-10-30');
    final g = (await LabExplain.generated(settings, 'MTHFR'))!;
    expect(g.explanation!.meaning, '叶酸代谢相关基因');
    expect(g.explanation!.related, '同型半胱氨酸');
    expect(g.date, '2026-10-30');
    final skipped = (await LabExplain.generated(settings, '色觉'))!;
    expect(skipped.explanation, isNull);
  });
}
