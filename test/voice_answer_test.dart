import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/helpers/user_facing_error.dart';
import 'package:modern_butlers_book/helpers/voice_answer.dart';
import 'package:modern_butlers_book/services/voice_answer.dart';
import 'package:modern_butlers_book/ui/app_dependencies.dart';

import 'support/session_test_helpers.dart';

const _dryerStartChoices = [
  'Nothing happens',
  'Starts normally',
  'Hums but does not start',
  'Starts then stops',
  'Not sure',
  'Other / describe',
];

void main() {
  test('clear spoken chip matches uniquely', () {
    expect(
      matchVoiceToAnswerChoice('nothing happens', _dryerStartChoices),
      'Nothing happens',
    );
    expect(
      matchVoiceToAnswerChoice('No warmth.', ['No warmth', 'Normal heat']),
      'No warmth',
    );
    expect(matchVoiceToAnswerChoice('yes', ['Yes', 'No', 'Not sure']), 'Yes');
    expect(matchVoiceToAnswerChoice('no', ['Yes', 'No', 'Not sure']), 'No');
    expect(
      matchVoiceToAnswerChoice('confirmed', ['Confirmed', 'Not confirmed']),
      'Confirmed',
    );
  });

  test('ambiguous or unclear speech does not guess a chip', () {
    expect(
      matchVoiceToAnswerChoice('start', _dryerStartChoices),
      isNull,
    );
    expect(
      matchVoiceToAnswerChoice('there is a weird rattle in the back', _dryerStartChoices),
      isNull,
    );
    expect(matchVoiceToAnswerChoice('   ', _dryerStartChoices), isNull);
  });

  testWidgets('mic matches a clear chip without opening Other/describe', (
    tester,
  ) async {
    final dependencies = AppDependencies(
      clock: () => DateTime.utc(2026, 8, 16, 19),
      voiceAnswer: ScriptedVoiceAnswerListener(
        VoiceAnswerCapture.heard('nothing happens'),
      ),
    );
    await openDryerSession(tester, dependencies, 'Voice Chip Household');

    expect(find.byKey(const Key('voice-answer-mic')), findsOneWidget);
    await tapVisible(tester, find.byKey(const Key('voice-answer-mic')));

    await expandEvidenceHistory(tester);
    expect(find.textContaining('Answer: Nothing happens'), findsOneWidget);
    expect(find.byKey(const Key('answer-other-note-field')), findsNothing);
  });

  testWidgets('unclear speech fills Other/describe with the transcript', (
    tester,
  ) async {
    final dependencies = AppDependencies(
      clock: () => DateTime.utc(2026, 8, 16, 19, 5),
      voiceAnswer: ScriptedVoiceAnswerListener(
        VoiceAnswerCapture.heard('there is a weird rattle in the back'),
      ),
    );
    await openDryerSession(tester, dependencies, 'Voice Other Household');

    await tapVisible(tester, find.byKey(const Key('voice-answer-mic')));
    expect(find.byKey(const Key('answer-other-note-field')), findsNothing);

    await expandEvidenceHistory(tester);
    expect(
      find.textContaining('Answer: Other / describe: there is a weird rattle in the back'),
      findsOneWidget,
    );
  });

  testWidgets('permission denied shows how to continue by tapping chips', (
    tester,
  ) async {
    final dependencies = AppDependencies(
      clock: () => DateTime.utc(2026, 8, 16, 19, 10),
      voiceAnswer: ScriptedVoiceAnswerListener(
        VoiceAnswerCapture.permissionDenied,
      ),
    );
    await openDryerSession(tester, dependencies, 'Voice Denied Household');

    await tapVisible(tester, find.byKey(const Key('voice-answer-mic')));
    expect(find.byType(SnackBar), findsNothing);
    expect(find.byKey(const Key('error-banner-microphone')), findsOneWidget);
    expect(find.text(UserFacingCopy.voicePermissionDenied), findsOneWidget);
    expect(find.byKey(const Key('answer-choice-panel')), findsOneWidget);
    expect(find.byKey(const Key('voice-answer-mic')), findsNothing);

    await tapVisible(
      tester,
      find.byKey(const Key('answer-choice-starts-normally')),
    );
    await expandEvidenceHistory(tester);
    expect(find.textContaining('Answer: Starts normally'), findsOneWidget);
  });

  testWidgets('unavailable voice shows phone hint and chips still work', (
    tester,
  ) async {
    final dependencies = AppDependencies(
      clock: () => DateTime.utc(2026, 8, 17, 16, 30),
      voiceAnswer: ScriptedVoiceAnswerListener(
        VoiceAnswerCapture.heard('nothing happens'),
        available: false,
      ),
    );
    await openDryerSession(tester, dependencies, 'Voice Phone Hint Household');

    expect(find.byKey(const Key('voice-works-best-on-phone')), findsOneWidget);
    expect(find.text(UserFacingCopy.voiceWorksBestOnPhone), findsOneWidget);
    expect(find.byKey(const Key('voice-answer-mic')), findsNothing);
    await tapVisible(
      tester,
      find.byKey(const Key('answer-choice-starts-normally')),
    );
    await expandEvidenceHistory(tester);
    expect(find.textContaining('Answer: Starts normally'), findsOneWidget);
  });

  test('hazard keywords in speech do not auto-confirm a chip', () {
    expect(transcriptSuggestsHazard('I smell smoke in the laundry'), isTrue);
    expect(transcriptSuggestsHazard('burning plastic maybe'), isTrue);
    expect(transcriptSuggestsHazard('a spark at the plug'), isTrue);
    expect(transcriptSuggestsHazard('gas smell near the dryer'), isTrue);
    expect(transcriptSuggestsHazard('I smell gas'), isTrue);
    expect(transcriptSuggestsHazard('gas leak at the valve'), isTrue);
    expect(transcriptSuggestsHazard('nothing happens'), isFalse);
    expect(
      matchVoiceToAnswerChoice('yes', ['Yes', 'No', 'Not sure']),
      'Yes',
    );
  });

  testWidgets('hazard transcript forces the structured safety question', (
    tester,
  ) async {
    final dependencies = AppDependencies(
      clock: () => DateTime.utc(2026, 8, 17, 16, 20),
      voiceAnswer: ScriptedVoiceAnswerListener(
        VoiceAnswerCapture.heard('there is smoke coming out'),
      ),
    );
    await openDryerSession(tester, dependencies, 'Voice Hazard Household');

    await tapVisible(tester, find.byKey(const Key('voice-answer-mic')));
    expect(find.byKey(const Key('voice-hazard-confirm-banner')), findsOneWidget);
    expect(
      find.text(UserFacingCopy.voiceHazardConfirm),
      findsOneWidget,
    );
    expect(find.byKey(const Key('safety-stop-banner')), findsOneWidget);
    expect(find.byKey(const Key('answer-choice-panel')), findsNothing);
  });
}
