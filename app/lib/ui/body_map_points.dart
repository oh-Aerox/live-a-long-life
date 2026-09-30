import 'package:flutter/painting.dart';

import '../services/body_map.dart';

/// 人体图上的点位与分区（D-31）。坐标是占图片宽高的比例（0～1），
/// 对应 assets/body/male.webp、female.webp（1040×1580，由 scripts/body_cutout.py 生成）。
/// 换图或改裁剪后要重标：人体页右上角"标点位"模式下点图片，
/// 坐标会显示在屏幕上并打印到日志。

class BodyPoint {
  const BodyPoint(this.x, this.y, {this.labelOnLeft = true});

  final double x;
  final double y;

  /// 标签放在人体左侧还是右侧。
  final bool labelOnLeft;

  Offset get offset => Offset(x, y);
}

class BodyFigure {
  const BodyFigure({
    required this.asset,
    required this.points,
    required this.regions,
  });

  final String asset;
  final Map<String, BodyPoint> points;

  /// 点分区放大时要铺满的范围。
  final Map<BodyRegion, Rect> regions;

  /// 图片宽高比（宽 / 高）。
  static const aspect = 1040 / 1580;
}

const _l = true;
const _r = false;

const maleFigure = BodyFigure(
  asset: 'assets/body/male.webp',
  points: {
    'brain': BodyPoint(0.512, 0.081, labelOnLeft: _r),
    'eye': BodyPoint(0.442, 0.191, labelOnLeft: _l),
    'ear': BodyPoint(0.700, 0.230, labelOnLeft: _r),
    'nose': BodyPoint(0.512, 0.223, labelOnLeft: _l),
    'mouth': BodyPoint(0.512, 0.262, labelOnLeft: _r),
    'throat': BodyPoint(0.504, 0.308, labelOnLeft: _l),
    'thyroid': BodyPoint(0.505, 0.345, labelOnLeft: _r),
    'trachea': BodyPoint(0.498, 0.375, labelOnLeft: _l),
    'esophagus': BodyPoint(0.515, 0.418, labelOnLeft: _l),
    'thymus': BodyPoint(0.506, 0.464, labelOnLeft: _r),
    'lung': BodyPoint(0.366, 0.499, labelOnLeft: _l),
    'breast': BodyPoint(0.608, 0.482, labelOnLeft: _r),
    'heart': BodyPoint(0.538, 0.513, labelOnLeft: _r),
    'liver': BodyPoint(0.398, 0.613, labelOnLeft: _l),
    'gallbladder': BodyPoint(0.447, 0.661, labelOnLeft: _l),
    'intestine': BodyPoint(0.431, 0.740, labelOnLeft: _l),
    'spleen': BodyPoint(0.657, 0.598, labelOnLeft: _r),
    'stomach': BodyPoint(0.587, 0.609, labelOnLeft: _r),
    'pancreas': BodyPoint(0.538, 0.659, labelOnLeft: _r),
    'kidney': BodyPoint(0.630, 0.684, labelOnLeft: _r),
    'bladder': BodyPoint(0.506, 0.818, labelOnLeft: _l),
    'prostate': BodyPoint(0.512, 0.836, labelOnLeft: _l),
    'vasDeferens': BodyPoint(0.576, 0.808, labelOnLeft: _r),
    'testis': BodyPoint(0.538, 0.861, labelOnLeft: _r),
  },
  regions: {
    BodyRegion.head: Rect.fromLTRB(0.291, 0.024, 0.743, 0.372),
    BodyRegion.chest: Rect.fromLTRB(0.269, 0.343, 0.743, 0.584),
    BodyRegion.abdomen: Rect.fromLTRB(0.312, 0.563, 0.700, 0.776),
    BodyRegion.pelvis: Rect.fromLTRB(0.388, 0.762, 0.646, 0.889),
  },
);

const femaleFigure = BodyFigure(
  asset: 'assets/body/female.webp',
  points: {
    'brain': BodyPoint(0.504, 0.088, labelOnLeft: _r),
    'eye': BodyPoint(0.431, 0.205, labelOnLeft: _l),
    'ear': BodyPoint(0.705, 0.243, labelOnLeft: _r),
    'nose': BodyPoint(0.501, 0.243, labelOnLeft: _l),
    'mouth': BodyPoint(0.501, 0.283, labelOnLeft: _r),
    'throat': BodyPoint(0.498, 0.324, labelOnLeft: _l),
    'thyroid': BodyPoint(0.498, 0.357, labelOnLeft: _r),
    'trachea': BodyPoint(0.493, 0.393, labelOnLeft: _l),
    'esophagus': BodyPoint(0.506, 0.435, labelOnLeft: _l),
    'thymus': BodyPoint(0.501, 0.471, labelOnLeft: _r),
    'lung': BodyPoint(0.345, 0.535, labelOnLeft: _l),
    'breast': BodyPoint(0.603, 0.503, labelOnLeft: _r),
    'heart': BodyPoint(0.528, 0.535, labelOnLeft: _r),
    'liver': BodyPoint(0.398, 0.645, labelOnLeft: _l),
    'gallbladder': BodyPoint(0.440, 0.693, labelOnLeft: _l),
    'kidney': BodyPoint(0.393, 0.719, labelOnLeft: _l),
    'intestine': BodyPoint(0.431, 0.769, labelOnLeft: _l),
    'spleen': BodyPoint(0.657, 0.637, labelOnLeft: _r),
    'stomach': BodyPoint(0.582, 0.648, labelOnLeft: _r),
    'pancreas': BodyPoint(0.528, 0.687, labelOnLeft: _r),
    'uterus': BodyPoint(0.501, 0.823, labelOnLeft: _l),
    'ovary': BodyPoint(0.582, 0.823, labelOnLeft: _r),
    // 膀胱在阴道后方，指到露出来的左侧浅蓝那块。
    'bladder': BodyPoint(0.468, 0.858, labelOnLeft: _l),
    'vagina': BodyPoint(0.501, 0.864, labelOnLeft: _r),
  },
  regions: {
    BodyRegion.head: Rect.fromLTRB(0.280, 0.031, 0.743, 0.386),
    BodyRegion.chest: Rect.fromLTRB(0.269, 0.372, 0.743, 0.598),
    BodyRegion.abdomen: Rect.fromLTRB(0.312, 0.591, 0.700, 0.797),
    BodyRegion.pelvis: Rect.fromLTRB(0.388, 0.769, 0.646, 0.896),
  },
);

BodyFigure figureFor(BodySex sex) =>
    sex == BodySex.female ? femaleFigure : maleFigure;
