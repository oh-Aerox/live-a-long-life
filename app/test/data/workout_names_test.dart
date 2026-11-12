import 'package:flutter_test/flutter_test.dart';
import 'package:live_a_long_life/data/workout_names.dart';

void main() {
  test('苹果健康驼峰写法和插件枚举名都译成中文', () {
    expect(workoutLabel('functionalStrengthTraining'), '功能性力量训练');
    expect(workoutLabel('FUNCTIONAL_STRENGTH_TRAINING'), '功能性力量训练');
    expect(workoutLabel('cycling'), '骑行');
  });

  test('没有类型算体能训练，认不出的照原样或换成泛称', () {
    expect(workoutLabel(null), '体能训练');
    expect(workoutLabel('newSport'), 'newSport');
    expect(workoutLabel('newSport', unknown: '运动'), '运动');
  });
}
