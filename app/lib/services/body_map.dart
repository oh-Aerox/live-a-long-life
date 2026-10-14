import 'dart:convert';

import '../data/db/app_database.dart';
import '../data/field_meta.dart';
import '../data/repositories/profile_repository.dart';
import '../data/repositories/record_repository.dart';
import '../data/same_item.dart';
import '../data/condition_entry.dart';

/// 人体图（D-31）：把检验数值、报告文字、身体状况、身体不适归到器官上。
///
/// 归属是本地规则算出来的派生视图，不写库、不同步：规则改了下次打开就按
/// 新规则算。未核对的内容照样列出，但单独标"待核对"（D-04：未核对不算
/// 事实）。

enum BodyRegion { head, chest, abdomen, pelvis }

enum BodySex { male, female }

class Organ {
  const Organ(this.id, this.name, this.region, {this.sex});

  final String id;
  final String name;
  final BodyRegion region;

  /// 只在这个性别的图上标出；null 两种图都有。
  final BodySex? sex;
}

const regionNames = {
  BodyRegion.head: '头颈部',
  BodyRegion.chest: '胸部',
  BodyRegion.abdomen: '腹部',
  BodyRegion.pelvis: '盆腔',
};

const organs = [
  Organ('brain', '脑', BodyRegion.head),
  Organ('eye', '眼', BodyRegion.head),
  Organ('ear', '耳', BodyRegion.head),
  Organ('nose', '鼻', BodyRegion.head),
  Organ('mouth', '口腔', BodyRegion.head),
  Organ('throat', '咽喉', BodyRegion.head),
  Organ('thyroid', '甲状腺', BodyRegion.head),
  Organ('trachea', '气管', BodyRegion.chest),
  Organ('esophagus', '食管', BodyRegion.chest),
  Organ('lung', '肺', BodyRegion.chest),
  Organ('heart', '心脏', BodyRegion.chest),
  Organ('breast', '乳房', BodyRegion.chest),
  Organ('thymus', '胸腺', BodyRegion.chest),
  Organ('liver', '肝', BodyRegion.abdomen),
  Organ('gallbladder', '胆囊', BodyRegion.abdomen),
  Organ('stomach', '胃', BodyRegion.abdomen),
  Organ('pancreas', '胰腺', BodyRegion.abdomen),
  Organ('spleen', '脾', BodyRegion.abdomen),
  Organ('kidney', '肾', BodyRegion.abdomen),
  Organ('intestine', '肠', BodyRegion.abdomen),
  Organ('bladder', '膀胱', BodyRegion.pelvis),
  Organ('prostate', '前列腺', BodyRegion.pelvis, sex: BodySex.male),
  Organ('testis', '睾丸', BodyRegion.pelvis, sex: BodySex.male),
  Organ('vasDeferens', '输精管', BodyRegion.pelvis, sex: BodySex.male),
  Organ('uterus', '子宫', BodyRegion.pelvis, sex: BodySex.female),
  Organ('ovary', '卵巢', BodyRegion.pelvis, sex: BodySex.female),
  Organ('vagina', '阴道', BodyRegion.pelvis, sex: BodySex.female),
];

/// 不在人体图上的两个归类，列在图下方。
const bloodOrganId = 'blood';
const otherOrganId = 'other';
const extraOrganNames = {bloodOrganId: '血液与代谢', otherOrganId: '其他'};

String organName(String id) =>
    extraOrganNames[id] ??
    organs.firstWhere((o) => o.id == id, orElse: () => Organ(id, id, BodyRegion.head)).name;

enum BodyFindingKind { lab, finding, condition, symptom }

/// 挂在某个器官上的一条需要关注的内容。
class BodyFinding {
  const BodyFinding({
    required this.kind,
    required this.title,
    this.detail,
    this.date,
    required this.reviewed,
    required this.recordId,
    this.medicalDocumentId,
    this.locator,
  });

  final BodyFindingKind kind;
  final String title;
  final String? detail;

  /// yyyy-MM-dd，可空。
  final String? date;

  /// 已确认或已修改（D-04）。自述的不适算已核对。
  final bool reviewed;
  final String recordId;
  final String? medicalDocumentId;

  /// 原件定位（同 schema §5.2 locator），可空。
  final Map<String, Object?>? locator;
}

/// 归属规则。规则按顺序匹配，靠前的更具体（"尿白细胞"要先于"白细胞"）。
class BodyMapRules {
  /// 一条规则：中文按包含匹配；纯 ASCII 缩写要求前后不是字母数字，
  /// 免得 "T3" 命中 "FT3"、"Ca" 命中 "CA125"。
  static List<(String, List<RegExp>)> _compile(Map<String, List<String>> m) => [
        for (final e in m.entries)
          (
            e.key,
            [
              for (final w in e.value)
                RegExp(
                    RegExp(r'^[\x00-\x7f]+$').hasMatch(w)
                        ? '(?<![A-Za-z0-9])${RegExp.escape(w)}(?![A-Za-z0-9])'
                        : RegExp.escape(w),
                    caseSensitive: false),
            ],
          ),
      ];

  static final _labRules = _compile(const {
    'bladder': ['尿白细胞', '亚硝酸盐', '尿细菌', '尿上皮'],
    'kidney': [
      '肌酐', '尿素', '胱抑素', '肾小球', 'eGFR', 'β2微球蛋白', 'β2-微球蛋白',
      '尿蛋白', '尿微量白蛋白', '尿隐血', '尿潜血', '尿红细胞', '尿比重',
      '尿管型', '尿液酸碱度',
      'CREA', 'Cr', 'Scr', 'BUN', 'UREA', 'Cys-C', 'CysC',
    ],
    'thyroid': [
      '甲状腺', '促甲状腺', '三碘甲状腺', '甲状旁腺',
      'TSH', 'FT3', 'FT4', 'T3', 'T4', 'TT3', 'TT4', 'TPOAb', 'TGAb',
      'A-TPO', 'A-TG', 'PTH',
    ],
    'prostate': ['前列腺', 'PSA', 'fPSA', 'tPSA', 'f/tPSA', 'FPSA/TPSA'],
    'liver': [
      '转氨酶', '谷丙', '谷草', '丙氨酸', '天门冬', '天冬氨酸', '谷氨酰',
      '碱性磷酸酶', '胆红素', '总蛋白', '前白蛋白', '白蛋白', '球蛋白', '白球比',
      '甲胎蛋白', '乙肝', '乙型肝炎', '丙肝', '胆汁酸', '胆碱酯酶',
      'ALT', 'AST', 'GPT', 'GOT', 'GGT', 'γ-GT', 'ALP', 'AKP', 'TBIL',
      'DBIL', 'IBIL', 'TP', 'ALB', 'GLB', 'A/G', 'AFP', 'HBsAg', 'HBsAb',
      'HBeAg', 'HBeAb', 'HBcAb', 'TBA', 'CHE',
    ],
    'heart': [
      '肌钙蛋白', '肌酸激酶', '利钠肽', '肌红蛋白', '乳酸脱氢酶',
      'cTnI', 'cTnT', 'TnI', 'CK', 'CK-MB', 'CKMB', 'BNP', 'NT-proBNP',
      'LDH', 'MYO',
    ],
    'pancreas': ['淀粉酶', '脂肪酶', 'AMY', 'LPS', 'CA199', 'CA19-9'],
    'stomach': [
      '胃蛋白酶原', '胃泌素', '幽门螺杆菌', '碳13', '碳14',
      'Hp', 'PGI', 'PGII', 'PG I', 'PG II', 'CA724', 'CA72-4', '13C', '14C',
    ],
    'intestine': ['便潜血', '便隐血', '粪便隐血', '大便隐血', '粪隐血', 'FOBT'],
    'lung': [
      '细胞角蛋白19', '神经元特异性烯醇化酶', '胃泌素释放肽前体',
      'CYFRA21-1', 'CYFRA', 'NSE', 'ProGRP', 'SCC',
    ],
    'ovary': ['抗缪勒', '抗苗勒', 'CA125', 'CA-125', 'AMH', 'HE4'],
    'breast': ['CA153', 'CA15-3'],
    'uterus': ['宫颈', 'HPV', 'TCT'],
    bloodOrganId: [
      '血红蛋白', '红细胞', '白细胞', '血小板', '中性粒', '淋巴细胞', '单核细胞',
      '嗜酸', '嗜碱', '血细胞比容', '葡萄糖', '血糖', '糖化', '胆固醇',
      '甘油三酯', '脂蛋白', '同型半胱氨酸', '尿酸', '钾', '钠', '氯', '钙',
      '镁', '磷', '铁', '维生素', '叶酸', 'C反应蛋白', '血沉', '凝血',
      '纤维蛋白原', '癌胚抗原', '尿糖',
      'WBC', 'RBC', 'HGB', 'Hb', 'PLT', 'HCT', 'MCV', 'MCH', 'MCHC', 'RDW',
      'NEUT', 'LYM', 'GLU', 'HbA1c', 'TC', 'TG', 'HDL', 'LDL', 'HDL-C',
      'LDL-C', 'ApoA1', 'ApoB', 'Lp(a)', 'HCY', 'UA', 'K', 'Na', 'Cl', 'Ca',
      'CRP', 'hs-CRP', 'ESR', 'CEA', 'FIB', 'PT', 'APTT',
    ],
  });

  static final _textRules = _compile(const {
    'thyroid': ['甲状腺', '甲亢', '甲减', '桥本'],
    'breast': ['乳腺', '乳房', '乳头'],
    'prostate': ['前列腺'],
    'testis': ['睾丸', '附睾', '精索', '阴囊', '鞘膜'],
    'vasDeferens': ['输精管', '精囊'],
    'uterus': ['子宫', '宫颈', '宫腔', '月经', '痛经', '内膜'],
    'vagina': ['阴道', '白带'],
    'ovary': ['卵巢', '输卵管', '附件'],
    'gallbladder': ['胆囊', '胆管', '胆结石', '胆汁'],
    'pancreas': ['胰'],
    'spleen': ['脾'],
    'kidney': ['肾', '输尿管'],
    'bladder': ['膀胱', '尿道', '尿频', '尿急', '尿痛'],
    'liver': ['肝'],
    'esophagus': ['食管', '食道', '反流', '烧心'],
    'stomach': ['胃', '幽门', '十二指肠', '恶心', '呕吐', '反酸'],
    'intestine': ['肠', '阑尾', '痔', '腹泻', '便秘', '便血'],
    'heart': [
      '心脏', '心肌', '心律', '心电', '心动', '心房', '心室', '心包', '心悸',
      '心绞痛', '心衰', '冠心', '冠状动脉', '早搏', '房颤', '瓣膜', '胸闷',
      '动脉',
    ],
    'thymus': ['胸腺'],
    'lung': ['肺', '胸膜', '咳嗽', '咳痰', '哮喘'],
    'trachea': ['气管'],
    'brain': ['脑', '颅', '头痛', '头疼', '头晕', '眩晕'],
    'eye': [
      '眼', '视力', '视网膜', '白内障', '青光眼', '结膜', '角膜', '近视', '远视',
      '散光', '晶状体', '玻璃体',
    ],
    'ear': ['耳', '听力', '鼓膜'],
    'nose': ['鼻'],
    'throat': ['咽', '喉', '扁桃体', '声带'],
    'mouth': ['口腔', '牙', '龈', '舌'],
    bloodOrganId: [
      '血压', '糖尿病', '血糖', '血脂', '胆固醇', '甘油三酯', '尿酸', '痛风',
      '贫血', '白细胞', '血小板',
    ],
  });

  /// 检验项目归到哪个器官；认不出返回 [otherOrganId]。
  static String organOfLabItem(String itemName) {
    for (final (organ, patterns) in _labRules) {
      if (patterns.any((p) => p.hasMatch(itemName))) return organ;
    }
    return otherOrganId;
  }

  /// 一段文字提到的器官，按规则顺序，去重；一个都没有返回空列表。
  /// 匹配过的字抹掉再往下匹配（"胆管"先归胆囊，不再让"肝"之外的规则重复命中）。
  static List<String> organsOfText(String text) {
    var rest = text;
    final found = <String>[];
    for (final (organ, patterns) in _textRules) {
      for (final p in patterns) {
        if (!p.hasMatch(rest)) continue;
        if (!found.contains(organ)) found.add(organ);
        rest = rest.replaceAll(p, ' ');
      }
    }
    return found;
  }

  /// 数值异常：报告上有异常标记，或数值超出参考范围，或定性结果阳性而参考为阴性。
  static bool isAbnormalLab({
    String? flagRaw,
    String? valueRaw,
    double? valueNum,
    double? refLow,
    double? refHigh,
    String? refRangeRaw,
  }) {
    final flag = flagRaw?.trim() ?? '';
    if (flag.isNotEmpty && !_normalFlag.hasMatch(flag)) return true;
    if (valueNum != null) {
      if (refLow != null && valueNum < refLow) return true;
      if (refHigh != null && valueNum > refHigh) return true;
    }
    final v = valueRaw ?? '';
    if ((refRangeRaw ?? '').contains('阴性') &&
        (v.contains('阳性') || RegExp(r'^\s*\++').hasMatch(v))) {
      return true;
    }
    return false;
  }

  static final _normalFlag = RegExp(r'^(-|—|N|正常|阴性|/)$', caseSensitive: false);

  static final _abnormalWord = RegExp(
      '结节|囊肿|结石|息肉|增生|肥大|增大|肿大|增厚|钙化|占位|肿物|肿块|积液|狭窄|'
      '扩张|硬化|脂肪肝|炎|溃疡|糜烂|反流|异常|偏高|偏低|升高|降低|减退|亢进|'
      '病变|损伤|不齐|早搏|阻滞|缺血|畸形|斑块|贫血|糖尿病|高血压|回声不均|'
      '低回声|强回声|阳性|骨折|突出|膨出|变性|衰竭|梗|血栓|肌瘤|腺瘤|瘤|癌|'
      '出血|感染|梗阻|紊乱|不全');
  static final _negation = RegExp('未见|未发现|未探及|未显示|未触及|没有|排除|否认|无(?!回声)');
  static final _clauseBreak = RegExp(r'[，,。；;：:]'); // 顿号不断开：否定管到整串并列

  /// 报告文字里提示异常的句子（按句号、分号、换行切）。同一小句里关键词
  /// 前面有"未见""无"之类否定、或小句写着"正常"的不算（"肝内未见明显占位"
  /// "异常糖链糖蛋白检测正常"）；解释原因、给建议的句子不算（体检汇总里
  /// "脂肪肝的发生与肥胖……有关""建议定期复查"，D-32）。
  static List<String> abnormalSentences(String text) {
    final out = <String>[];
    for (final raw in text.split(RegExp(r'[。；;\n]'))) {
      // 检查名前缀（"肿瘤检测提示："）里的字不算：判断的是后面写的结果。
      final s = SameItem.problemText(raw);
      if (s.isEmpty || _advice.hasMatch(s)) continue;
      for (final m in _abnormalWord.allMatches(s)) {
        final head = s.substring(0, m.start);
        final clauseStart = head.lastIndexOf(_clauseBreak) + 1;
        final tail = s.substring(m.end);
        final nextBreak = tail.indexOf(_clauseBreak);
        final clause = s.substring(
            clauseStart, nextBreak < 0 ? s.length : m.end + nextBreak);
        if (_negation.hasMatch(head.substring(clauseStart))) continue;
        if (clause.contains('正常')) continue;
        out.add(s);
        break;
      }
    }
    return out;
  }

  static final _advice = RegExp(
      '建议|请|注意|有关|相关|危险因素|可能|如果|如有|若|必要时|不必|不需|无需|'
      '可见于|定期|随着|随年龄|一般|酌情|风险|专科|就诊|诊治|治疗|干预|复查|前兆|所致|引起');

  /// 这些栏目是建议与处理，内容跟诊断重复，不单独列。
  static final skipSection = RegExp('建议|处理|医嘱|治疗|用药|处方');

  /// 生理性别的自由文本（资料页手填）识别成男/女；认不出返回 null。
  static BodySex? parseSex(Object? value) {
    final s = '${value ?? ''}'.trim().toLowerCase();
    if (s.isEmpty) return null;
    if (s.contains('女') || s.startsWith('f')) return BodySex.female;
    if (s.contains('男') || s.startsWith('m')) return BodySex.male;
    return null;
  }
}

/// 人体图数据：器官 ID → 需要关注的内容（新的在前）。
class BodyMapData {
  BodyMapData(this.byOrgan, this.sex);

  final Map<String, List<BodyFinding>> byOrgan;

  /// 资料里的生理性别；没填或认不出为 null。
  final BodySex? sex;

  List<BodyFinding> of(String organId) => byOrgan[organId] ?? const [];

  int countIn(Iterable<String> organIds) =>
      organIds.fold(0, (n, id) => n + of(id).length);
}

class BodyMapService {
  BodyMapService({required this.records, required this.profile});

  final RecordRepository records;
  final ProfileRepository profile;

  /// 临时疾病、身体不适只看近 30 天（与 D-25 分析口径一致）。
  static const recentDays = 30;

  /// 看的是"当前状况"（D-32）：同一个检验项目、同一个问题只留最新一次；
  /// 后来的报告没再提到的，用能取到的最后一次。
  Future<BodyMapData> load({DateTime? now}) async {
    final today = now ?? DateTime.now();
    final recentFrom = _ymd(today.subtract(const Duration(days: recentDays)));
    final byOrgan = <String, List<BodyFinding>>{};
    void add(String organ, BodyFinding f) => (byOrgan[organ] ??= []).add(f);

    // —— 身体状况：同一问题的各份报告归一组，只看最新那条 ——
    final conditions = <ConditionEntry>[];
    for (final rec in await records.byType(RecordType.condition)) {
      final rev = await records.currentRevisionOf(rec.id);
      final data = jsonDecode(rev.data);
      if (data is! Map) continue;
      conditions.add(ConditionEntry(rec, rev, data.cast<String, Object?>(),
          FieldMetaMap.decode(rev.fieldMeta)));
    }
    // 某份文件在某个器官上已经有诊断：这份文件的报告文字不再单列到这个器官
    // （诊断是对所见的归纳，汇总和明细各写一遍的文字都算在诊断里）。
    final diagnosedIn = <String, Set<String>>{};
    for (final c in conditions) {
      final doc = c.medicalDocumentId;
      if (doc == null) continue;
      final hit = _organsOfCondition(c);
      for (final o in hit.isEmpty ? [otherOrganId] : hit) {
        (diagnosedIn[doc] ??= {}).add(o);
      }
    }
    final shownConditions = <ConditionEntry>[];
    for (final group in ConditionEntry.groups(conditions)) {
      final latest = group.first;
      if (latest.resolved) continue;
      if (!latest.longTerm && (latest.date ?? '').compareTo(recentFrom) < 0) {
        continue;
      }
      shownConditions.add(latest);
      final earlier = [
        for (final c in group.skip(1))
          if (c.date != latest.date)
            '${c.date ?? '日期未知'} ${c.name}',
      ];
      final finding = BodyFinding(
        kind: BodyFindingKind.condition,
        title: latest.name,
        detail: [
          if (latest.data['development_text'] is String)
            latest.data['development_text'] as String
          else if (latest.data['evidence_text'] is String)
            SameItem.problemText(latest.data['evidence_text'] as String),
          if (earlier.isNotEmpty) '此前：${earlier.join('；')}',
        ].join(' · '),
        date: latest.date,
        reviewed: latest.reviewed,
        recordId: latest.record.id,
        medicalDocumentId: latest.medicalDocumentId,
        locator: _map(latest.data['locator']),
      );
      final hit = _organsOfCondition(latest);
      for (final o in hit.isEmpty ? [otherOrganId] : hit) {
        add(o, finding);
      }
    }

    // —— 检验数值与报告文字 ——
    // 检验：每个项目只看最近一次，最近一次仍异常才列（已恢复正常的不提示）。
    final latestLab = <String, (String?, String, BodyFinding?)>{};
    // 报告文字：器官 → 候选（同一问题跨报告只留最新）。
    final texts = <String, List<BodyFinding>>{};
    for (final rec in await records.byType(RecordType.labPanel)) {
      final rev = await records.currentRevisionOf(rec.id);
      final data = jsonDecode(rev.data);
      if (data is! Map) continue;
      final meta = FieldMetaMap.decode(rev.fieldMeta);
      final docId = data['medical_document_id'] as String?;
      final date = rec.localDate;

      final results = data['results'];
      if (results is List) {
        for (var i = 0; i < results.length; i++) {
          final r = results[i];
          if (r is! Map) continue;
          final name = r['item_name_raw'];
          final value = r['value_raw'];
          if (name is! String || value is! String) continue;
          final panel = r['panel_raw'] is String ? r['panel_raw'] as String : null;
          final key = RecordRepository.labItemKey(name, panel: panel);
          final prev = latestLab[key];
          // 同一天（同一份报告汇总与明细）后面的覆盖前面的：明细信息更全。
          if (prev != null && (prev.$1 ?? '').compareTo(date ?? '') > 0) {
            continue;
          }
          final abnormal = BodyMapRules.isAbnormalLab(
            flagRaw: r['flag_raw'] as String?,
            valueRaw: value,
            valueNum: (r['value_num'] as num?)?.toDouble(),
            refLow: (r['ref_low'] as num?)?.toDouble(),
            refHigh: (r['ref_high'] as num?)?.toDouble(),
            refRangeRaw: r['ref_range_raw'] as String?,
          );
          final unit = r['unit_raw'] as String? ?? '';
          final flag = r['flag_raw'] as String? ?? '';
          final ref = r['ref_range_raw'] as String?;
          final shown = value.trim().endsWith(unit.trim()) ? value : '$value$unit';
          latestLab[key] = (
            date,
            name,
            abnormal
                ? BodyFinding(
                    kind: BodyFindingKind.lab,
                    title: '$name $shown${flag.isEmpty ? '' : ' $flag'}',
                    detail: ref == null ? null : '参考范围 $ref',
                    date: date,
                    reviewed: meta['results.$i']?.isProtected ?? false,
                    recordId: rec.id,
                    medicalDocumentId: docId,
                    locator: _map(r['locator']),
                  )
                : null,
          );
        }
      }

      final findings = data['findings'];
      if (findings is List) {
        for (var i = 0; i < findings.length; i++) {
          final f = findings[i];
          if (f is! Map) continue;
          final text = f['text_raw'];
          if (text is! String) continue;
          final section = f['section_raw'] as String?;
          if (section != null && BodyMapRules.skipSection.hasMatch(section)) {
            continue;
          }
          for (final s in BodyMapRules.abnormalSentences(text)) {
            final problem = SameItem.problemText(s);
            final hit = BodyMapRules.organsOfText(problem);
            final finding = BodyFinding(
              kind: BodyFindingKind.finding,
              title: problem,
              detail: section,
              date: date,
              reviewed: meta['findings.$i']?.isProtected ?? false,
              recordId: rec.id,
              medicalDocumentId: docId,
              locator: _map(f['locator']),
            );
            for (final o in hit.isEmpty ? [otherOrganId] : hit) {
              if (docId != null && (diagnosedIn[docId]?.contains(o) ?? false)) {
                continue;
              }
              (texts[o] ??= []).add(finding);
            }
          }
        }
      }
    }
    for (final MapEntry(:key, value: (_, name, f)) in latestLab.entries) {
      if (f == null) continue;
      // 同一份报告已经据此下了诊断（"尿酸高"与"尿酸 463 ↑"）：只列诊断。
      if (shownConditions.any((c) =>
          c.medicalDocumentId != null &&
          c.medicalDocumentId == f.medicalDocumentId &&
          key.length >= 2 &&
          c.name.contains(key))) {
        continue;
      }
      // 尿、便检查的项目按带标本的键归器官（"白细胞"在尿常规里是"尿白细胞"，
      // 归膀胱而不是血液，D-36）。
      add(BodyMapRules.organOfLabItem(key == SameItem.labKey(name) ? name : key),
          f);
    }
    for (final e in texts.entries) {
      for (final group in SameItem.groups(e.value, (f) => f.title, (f) => f.date)) {
        add(e.key, group.first);
      }
    }

    // —— 身体不适（自述）：仍在持续的，或近 30 天内的 ——
    for (final rec in await records.byType(RecordType.symptom)) {
      final rev = await records.currentRevisionOf(rec.id);
      final data = jsonDecode(rev.data);
      if (data is! Map || data['status'] != 'present') continue;
      if (data['ongoing'] != true &&
          (rec.localDate ?? '').compareTo(recentFrom) < 0) {
        continue;
      }
      final site = data['body_site'] as String? ?? '';
      final desc = data['description'] as String? ?? '';
      var hit = BodyMapRules.organsOfText(site);
      if (hit.isEmpty) hit = BodyMapRules.organsOfText(desc);
      final finding = BodyFinding(
        kind: BodyFindingKind.symptom,
        title: [site, desc].where((s) => s.isNotEmpty).join('：'),
        detail: data['severity_text'] as String?,
        date: rec.localDate,
        reviewed: true,
        recordId: rec.id,
      );
      for (final o in hit.isEmpty ? [otherOrganId] : hit) {
        add(o, finding);
      }
    }

    for (final list in byOrgan.values) {
      list.sort((a, b) => (b.date ?? '').compareTo(a.date ?? ''));
    }
    final sexRow = await profile.current('sex_at_birth');
    return BodyMapData(byOrgan, BodyMapRules.parseSex(sexRow?.$2));
  }

  static List<String> _organsOfCondition(ConditionEntry c) {
    final hit = BodyMapRules.organsOfText(c.name);
    final evidence = c.data['evidence_text'];
    if (hit.isNotEmpty || evidence is! String) return hit;
    return BodyMapRules.organsOfText(SameItem.problemText(evidence));
  }

  static Map<String, Object?>? _map(Object? v) =>
      v is Map ? v.cast<String, Object?>() : null;

  static String _ymd(DateTime t) =>
      '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';
}
