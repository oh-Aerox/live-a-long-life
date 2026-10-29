import 'package:flutter_test/flutter_test.dart';
import 'package:live_a_long_life/data/lab_catalog.dart';
import 'package:live_a_long_life/data/lab_names.dart';
import 'package:live_a_long_life/data/same_item.dart';

void main() {
  test('内置目录（D-49）：缩写、旧称、部位前缀归到标准名，分组按目录', () {
    // 2026-10-29 用户数据：新报告带进来的重复项。
    expect(SameItem.labKey('BMI'), '体重指数');
    expect(SameItem.labKey('体重指数/BMI'), '体重指数');
    expect(SameItem.labKey('HR'), '心率');
    expect(SameItem.labKey('心脏-心率'), '心率');
    expect(SameItem.labKey('肺-呼吸频率'), '呼吸频率');
    expect(SameItem.labKey('螃蟹'), SameItem.labKey('蟹'));
    expect(SameItem.labKey('黄豆'), SameItem.labKey('大豆'));
    expect(SameItem.labKey('每博心排血量 SV'), '每搏输出量');
    expect(SameItem.labKey('★活化部分凝血活酶'), '活化部分凝血活酶时间');
    expect(SameItem.labKey('★国际标准比率'), '国际标准化比值');
    expect(SameItem.labKey('癌抗原19-9（联）'),
        SameItem.labKey('癌抗原19-9（CA19-9）（发光法）'));
    expect(SameItem.labKey('乙肝表面抗原定性'), '乙型肝炎病毒表面抗原');
    expect(SameItem.labKey('TRUST'), '梅毒甲苯胺红不加热血清试验');
    // 分组：心率不再落进"心电""内科"，BMI 不再落进"其他"。
    expect(SameItem.trendGroup('心电', SameItem.labKey('HR')), '一般检查');
    expect(SameItem.trendGroup(null, SameItem.labKey('BMI')), '一般检查');
    expect(SameItem.trendGroup('内科', '心脏-心率'), '一般检查');
    expect(SameItem.trendGroup('四肢动脉血压值', '上臂（右）SBP'), '动脉硬化检测');
    // 口径不同的仍分开。
    expect(SameItem.labKey('尿素'), isNot(SameItem.labKey('尿素氮')));
    expect(SameItem.labKey('游离前列腺特异性抗原'),
        isNot(SameItem.labKey('前列腺特异性抗原')));
    expect(SameItem.labKey('脉搏'), isNot(SameItem.labKey('心率')));
    expect(SameItem.labKey('葡萄糖', panel: '尿常规'),
        isNot(SameItem.labKey('空腹血糖')));
  });

  test('目录里的别名不重复、标准名都能查回自己', () {
    for (final e in LabCatalog.entries) {
      expect(LabCatalog.canonical(e.name), e.name);
      for (final a in e.aliases) {
        expect(LabCatalog.canonical(a), e.name, reason: a);
      }
    }
  });

  test('左右两侧分开，各家写法归一（ABI（R）与 ABI：右侧）', () {
    expect(SameItem.labKey('ABI（R）'), SameItem.labKey('ABI：右侧'));
    expect(SameItem.labKey('ABI（L）'), SameItem.labKey('ABI：左侧'));
    expect(SameItem.labKey('ABI（R）'), isNot(SameItem.labKey('ABI（L）')));
    expect(SameItem.labKey('PWV（右）'), '臂踝脉搏波传导速度（右）');
    expect(SameItem.labKey('BAI（R）'), 'BAI（右）');
  });

  test('记录里的标准名优先：用户拆出的写法不再被目录并回', () {
    expect(SameItem.labKey('BMI', std: 'BMI'), 'BMI');
    expect(
        SameItem.resultKey({'item_name_raw': '葡萄糖 （Glu）', 'item_std': '尿葡萄糖'}),
        '尿葡萄糖');
  });

  group('提取时对号入座（LabNames.assign）', () {
    Map<String, Object?> r(String name, {String? panel, String? unit}) =>
        {'item_name_raw': name, 'panel_raw': panel, 'unit_raw': unit};

    void assign(Map<String, Object?> x, Object? std,
            {Map<String, String> known = const {},
            Set<String> existing = const {},
            Map<String, Set<String>> units = const {}}) =>
        LabNames.assign(x,
            modelStd: std, known: known, existingKeys: existing, units: units);

    test('目录已认得的写法不听模型的', () {
      final x = r('谷丙转氨酶');
      assign(x, '天门冬氨酸氨基转移酶');
      expect(x['item_std'], isNull);
      expect(x['item_std_suggested'], isNull);
    });

    test('模型给目录名或已有项目名：直接生效', () {
      final x = r('最大通气量(一分钟)');
      assign(x, '最大自主通气量');
      expect(x['item_std'], '最大自主通气量');
      final y = r('上臂右侧收缩压');
      assign(y, '上臂（右）SBP', existing: {'上臂（右）SBP'});
      expect(y['item_std'], '上臂（右）SBP');
    });

    test('新名字、跨标本：待确认', () {
      final x = r('每分钟最大呼吸次数');
      assign(x, '最大通气时呼吸频率');
      expect(x['item_std'], isNull);
      expect(x['item_std_suggested'], '最大通气时呼吸频率');
      // 没标大项的"葡萄糖"，模型按上下文认成尿糖：标本不同，要用户确认。
      final y = r('葡萄糖 （Glu）');
      assign(y, '尿葡萄糖');
      expect(y['item_std'], isNull);
      expect(y['item_std_suggested'], '尿葡萄糖');
    });

    test('单位对不上不合', () {
      final x = r('血尿素氮', unit: 'mg/dL');
      assign(x, '尿素', units: {'尿素': {'mmol/l'}});
      expect(x['item_std'], isNull);
      expect(x['item_std_suggested'], isNull);
    });

    test('以前定过的写法照旧；跨标本的不往下传', () {
      final x = r('一分钟通气');
      assign(x, null, known: {'一分钟通气': '最大自主通气量'});
      expect(x['item_std'], '最大自主通气量');
      final y = r('葡萄糖');
      assign(y, null, known: {'葡萄糖': '尿葡萄糖'});
      expect(y['item_std'], isNull);
    });
  });

  test('整理现有名称的建议：跨标本、单位不符、同名的不收', () {
    expect(
        LabNames.checkProposal('每博心排血量', '每搏输出量',
            fromUnits: {'ml'}, units: const {}),
        '每搏输出量');
    expect(
        LabNames.checkProposal('PH值', '尿液酸碱度',
            fromUnits: const {}, units: const {}),
        isNull);
    expect(
        LabNames.checkProposal('血尿素氮', '尿素',
            fromUnits: {'mg/dl'}, units: {'尿素': {'mmol/l'}}),
        isNull);
    expect(
        LabNames.checkProposal('体重', '体重', fromUnits: const {}, units: const {}),
        isNull);
  });
}
