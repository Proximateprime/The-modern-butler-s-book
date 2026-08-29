import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/helpers/dryer_close_path.dart';
import 'package:modern_butlers_book/helpers/pro_scope.dart';

void main() {
  test('dryer no-heat paths cannot finish as DIY', () {
    final fuse = closePathForFailureMode('thermal-fuse-open')!;
    final element = closePathForFailureMode('heating-element-failed')!;
    expect(closePathDiyCannotComplete(fuse), isTrue);
    expect(closePathDiyCannotComplete(element), isTrue);
    expect(
      fuse.safeGuidanceSteps.any(isProHandoffGuidanceStep),
      isTrue,
    );
    expect(
      safeCheckGuidanceSteps(fuse.safeGuidanceSteps).any(
        isProHandoffGuidanceStep,
      ),
      isFalse,
    );
    expect(
      safeCheckGuidanceSteps(fuse.safeGuidanceSteps).first.toLowerCase(),
      contains('lint filter'),
    );
    expect(proHandoffWhy(fuse).toLowerCase(), contains('electrical'));
    expect(proHandoffWhy(element).toLowerCase(), contains('heater'));
    expect(
      isProHandoffGuidanceStep(
        'If still no warmth, escalate to a qualified technician',
      ),
      isTrue,
    );
  });

  test('DIY-completable lint path is not a pro-scope warning', () {
    final path = closePathForFailureMode('clogged-lint-pathway')!;
    expect(closePathDiyCannotComplete(path), isFalse);
  });

  test('washer and dishwasher latch paths can finish as DIY', () {
    final washer = closePathForFailureMode('washer-door-not-latched')!;
    final dishwasher = closePathForFailureMode('dishwasher-door-not-latched')!;
    expect(closePathDiyCannotComplete(washer), isFalse);
    expect(closePathDiyCannotComplete(dishwasher), isFalse);
  });
}
