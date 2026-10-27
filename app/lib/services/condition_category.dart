import 'body_map.dart';

/// 长期状况档案按身体系统分组（D-46）。顺序即档案页的显示顺序。
const conditionCategories = [
  '心血管',
  '呼吸',
  '消化',
  '泌尿生殖与乳腺',
  '内分泌与代谢',
  '骨骼肌肉',
  '皮肤',
  '眼耳鼻喉口腔',
  '神经与精神',
  '过敏与免疫',
  '感染',
  '其他',
];

const _organCategory = {
  'heart': '心血管',
  'lung': '呼吸',
  'trachea': '呼吸',
  'thymus': '呼吸',
  'esophagus': '消化',
  'stomach': '消化',
  'intestine': '消化',
  'liver': '消化',
  'gallbladder': '消化',
  'pancreas': '消化',
  'spleen': '消化',
  'kidney': '泌尿生殖与乳腺',
  'bladder': '泌尿生殖与乳腺',
  'prostate': '泌尿生殖与乳腺',
  'testis': '泌尿生殖与乳腺',
  'vasDeferens': '泌尿生殖与乳腺',
  'uterus': '泌尿生殖与乳腺',
  'ovary': '泌尿生殖与乳腺',
  'vagina': '泌尿生殖与乳腺',
  'breast': '泌尿生殖与乳腺',
  'thyroid': '内分泌与代谢',
  bloodOrganId: '内分泌与代谢',
  'brain': '神经与精神',
  'eye': '眼耳鼻喉口腔',
  'ear': '眼耳鼻喉口腔',
  'nose': '眼耳鼻喉口腔',
  'throat': '眼耳鼻喉口腔',
  'mouth': '眼耳鼻喉口腔',
};

/// 先于器官规则看的词：血压归心血管（人体图把它放在"血液与代谢"）。
const _before = {
  '心血管': ['血压'],
};

/// 人体图里没有的类别，器官规则认不出时再看。
const _after = {
  '骨骼肌肉': [
    '椎', '骨', '关节', '腰痛', '背痛', '颈痛', '肩', '膝', '腕', '踝', '扭伤',
    '韧带', '肌腱', '腱鞘', '肌肉', '劳损', '痛风',
  ],
  '皮肤': ['皮', '疹', '疣', '癣', '痤疮', '银屑', '荨麻', '痣', '脱发'],
  '眼耳鼻喉口腔': ['飞蚊', '屈光'],
  '消化': ['嗳气', '消化不良', '腹胀'],
  '内分泌与代谢': ['超重', '肥胖', '体重', '代谢', '基因', '叶酸', '维生素'],
  '神经与精神': ['失眠', '焦虑', '抑郁', '疲劳', '神经', '偏头痛'],
  '过敏与免疫': ['过敏', '变应', '抗体', '免疫'],
  '感染': ['感冒', '感染', '病毒', '细菌', '发热', '流感'],
};

/// 一个身体状况归哪个系统；认不出归"其他"。只看名称，规则改了下次
/// 打开就按新规则算（派生视图，不写库）。
String conditionCategory(String name) {
  for (final MapEntry(key: cat, value: words) in _before.entries) {
    if (words.any(name.contains)) return cat;
  }
  for (final organ in BodyMapRules.organsOfText(name)) {
    final cat = _organCategory[organ];
    if (cat != null) return cat;
  }
  for (final MapEntry(key: cat, value: words) in _after.entries) {
    if (words.any(name.contains)) return cat;
  }
  return '其他';
}
