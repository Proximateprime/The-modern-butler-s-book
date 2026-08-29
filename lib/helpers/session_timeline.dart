import '../models/evidence.dart';
import 'dryer_problem_starter.dart';
import 'evidence_prompt_match.dart';
import 'failure_mode_standing.dart';
import 'free_observation_intake.dart';

/// One answered observation for the session timeline (display only).
class SessionTimelineObservation {
  const SessionTimelineObservation({
    required this.prompt,
    required this.answer,
    this.localPhotoPath,
  });

  final String prompt;
  final String answer;
  final String? localPhotoPath;
}

/// Ordered answered observations. Interview answers plus the start note.
/// Excludes close-path verification and empty rows. Not a reasoning dump.
List<SessionTimelineObservation> sessionTimelineObservations(
  List<Evidence> evidence,
) {
  final items = <SessionTimelineObservation>[];
  for (final item in evidence) {
    final photoPath = item.localPhotoPath?.trim();
    final hasPhoto = photoPath != null && photoPath.isNotEmpty;
    final answer = item.answer?.trim();
    if (item.templateId == problemStarterComplaintTemplateId) {
      if (answer == null || answer.isEmpty) {
        if (hasPhoto) {
          items.add(
            SessionTimelineObservation(
              prompt: 'What you noticed',
              answer: 'Attached photo',
              localPhotoPath: photoPath,
            ),
          );
        }
        continue;
      }
      items.add(
        SessionTimelineObservation(
          prompt: 'What you noticed',
          answer: answer,
          localPhotoPath: hasPhoto ? photoPath : null,
        ),
      );
      continue;
    }
    if (isFreeObservationNote(item)) {
      if (answer == null || answer.isEmpty) {
        continue;
      }
      final prompt = item.observation.trim();
      items.add(
        SessionTimelineObservation(
          prompt: prompt.isEmpty ? 'Something else I noticed' : prompt,
          answer: answer,
          localPhotoPath: hasPhoto ? photoPath : null,
        ),
      );
      continue;
    }
    if (isInterviewObservationEvidence(item)) {
      if (answer == null || answer.isEmpty) {
        if (hasPhoto) {
          final prompt = item.observation.trim();
          items.add(
            SessionTimelineObservation(
              prompt: prompt.isEmpty ? 'Observation' : prompt,
              answer: 'Attached photo',
              localPhotoPath: photoPath,
            ),
          );
        }
        continue;
      }
      final prompt = item.observation.trim();
      items.add(
        SessionTimelineObservation(
          prompt: prompt.isEmpty ? 'Observation' : prompt,
          answer: answer,
          localPhotoPath: hasPhoto ? photoPath : null,
        ),
      );
      continue;
    }
    if (hasPhoto || item.type == EvidenceType.photo) {
      final prompt = item.observation.trim();
      items.add(
        SessionTimelineObservation(
          prompt: prompt.isEmpty ? 'Photo' : prompt,
          answer:
              (answer == null || answer.isEmpty) ? 'Attached photo' : answer,
          localPhotoPath: hasPhoto ? photoPath : null,
        ),
      );
    }
  }
  return List.unmodifiable(items);
}

/// One plain sentence for why the current leader is ahead, if standing data
/// exists. Reads counts only — does not rank or change thresholds.
String? leaderWhySentence({
  required String? leaderLabel,
  required FailureModeStanding? leaderStanding,
  FailureModeStanding? runnerUpStanding,
}) {
  final name = leaderLabel?.trim();
  if (name == null || name.isEmpty || leaderStanding == null) {
    return null;
  }
  if (leaderStanding.supportCount < 1 && !leaderStanding.isSupported) {
    return null;
  }
  final aheadOfNext =
      runnerUpStanding == null || leaderStanding.net > runnerUpStanding.net;
  if (aheadOfNext && leaderStanding.supportCount >= 2) {
    return '$name is leading because more of your answers match it than '
        'the other possibilities.';
  }
  if (leaderStanding.isSupported) {
    return '$name is leading because your answers currently match it best.';
  }
  return null;
}

/// Builds [leaderWhySentence] from already-ranked mode order. Display only.
String? leaderWhyFromStandings({
  required List<String> orderedIds,
  required List<String> orderedLabels,
  required Map<String, FailureModeStanding> standings,
  String? preferredLabel,
}) {
  if (orderedIds.isEmpty) {
    return null;
  }
  final preferred = preferredLabel?.trim();
  return leaderWhySentence(
    leaderLabel:
        (preferred != null && preferred.isNotEmpty)
            ? preferred
            : orderedLabels.first,
    leaderStanding: standings[orderedIds.first],
    runnerUpStanding:
        orderedIds.length > 1 ? standings[orderedIds[1]] : null,
  );
}
