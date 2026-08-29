import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/helpers/package_release_validator.dart';

void main() {
  test('bundled dryer, washer, and dishwasher packages pass release gates', () {
    final report = validateKnowledgePackages(repoRoot: findRepoRoot());
    expect(
      report.errors,
      isEmpty,
      reason: report.errors.map((error) => error.toString()).join('\n'),
    );
    expect(
      report.notes.join(' '),
      contains('does not publish'),
    );
  });

  test('unsafe-string grep flags instructions, not prohibitions', () {
    expect(
      lineLooksLikeUnsafeInstruction('Bypass the thermal fuse with a jumper.'),
      isTrue,
    );
    expect(
      lineLooksLikeUnsafeInstruction(
        'Do not probe live heater terminals or bypass safety devices.',
      ),
      isFalse,
    );
    expect(
      lineLooksLikeUnsafeInstruction(
        'Do not test live voltage, probe wiring, or work in an energized control box.',
      ),
      isFalse,
    );
  });
}
