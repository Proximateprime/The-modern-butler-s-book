import 'local_backup.dart';
import 'stale_session.dart';

/// Household-facing copy. Never show stack traces or engine internals.
abstract final class UserFacingCopy {
  static const packageUnavailable =
      'This appliance guide isn’t on this device. Install it from the guides '
      'stored here, then try again.';
  static const packageInstallButton = 'Install from this device';
  static const installGuide = 'Install guide';
  static const missingGuideStartFreshHint =
      'Clears this in-progress repair. Start again after the guide is on '
      'this device. Appliances and tools are kept.';
  static const packageInstallHint =
      'Installing uses the copy stored on this device. It does not need the '
      'internet.';
  static const offlineGuidesStillWork =
      'Offline — guides on this device still work';
  static const simulateOfflineTitle = 'Simulate offline';
  static const simulateOfflineSubtitle =
      'Show the Offline banner. Guides and install from this device still work.';
  static const genericError =
      'This step couldn’t continue. Your progress is saved. Go back and try again.';
  static const noRepairsYet = 'No repairs yet';
  static const noMatchingRepairs =
      'No repairs match this search. Try different words, or clear the filters.';
  static const emptyRepairQuestions =
      'There aren’t questions for this appliance on this device yet.';
  static const emptyFurtherQuestionsTitle = 'No more questions for now';
  static const emptyFurtherQuestionsWithPrimary =
      'You can use the suggested cause above, or look through the list below.';
  static const emptyFurtherQuestionsWithoutPrimary =
      'You can pick a likely cause below, or End Session as Unresolved.';
  static const emptyEvidence = 'No answers recorded yet';
  static const emptyFailureModes =
      'This guide doesn’t list causes yet.';
  static const emptyHypotheses =
      'No working notes yet. They show up after you pick a most-likely cause.';
  static const emptyToolsNoHousehold =
      'Add a household first, then you can list the tools you own.';
  static const emptyTools =
      'No tools listed yet. Add them below, or tap “Also save to my tools” during a repair.';
  static const toolsNeedHousehold =
      'Add a household to keep a list of tools you own.';
  static const emptyMaintenance =
      'No upkeep reminders yet. You can add one when you like.';
  static const sessionNotFound =
      'This repair isn’t on this device anymore.';
  static const sessionAlreadyFinished = 'This repair is already finished.';
  static const reminderNeedsTitle = 'Add a short title for this reminder.';
  static const noDryersYet = 'No appliances yet.';
  static const emptyHomeNoHousehold =
      'Add a household to get started, then add an appliance.';
  static const emptyHomeNoDryer = 'Add an appliance to start a repair.';
  static const firstRunDoesTitle = 'What Butler does';
  static const firstRunDoesBody =
      'You notice. The book asks simple questions.\n\n'
      'It guides only beginner-safe checks.\n\n'
      'Appliances and repairs you finish stay in your House Book on this device '
      '(local repair history — not a premium add-on).';
  static const firstRunDoesNotTitle = 'What it doesn’t do';
  static const firstRunDoesNotBody =
      'It does not walk you through dangerous work — no gas, live electrical, '
      'or sealed cooling DIY.\n\n'
      'The camera never diagnoses. What you tap or type is what the book uses.';
  static const firstRunPrivacyTitle = 'Your household stays here';
  static const firstRunPrivacyBody =
      'Names, appliances, photos, tools, and repair notes are for this book '
      'on this device.\n\n'
      'Nothing is uploaded to a cloud account.';
  static const safetyDisclaimerTitle = 'Safety disclaimer';
  static const safetyDisclaimerBody =
      'This book is not a substitute for a licensed professional.\n\n'
      'Stop if the work involves gas, live electrical testing, or a sealed '
      'cooling system.\n\n'
      'You are responsible for safely isolating power — unplug the appliance '
      'or switch off its breaker — before any check. In-session safety stops '
      'still apply.';
  static const safetyDisclaimerAcknowledge = 'I understand';
  static const photoPermissionDenied =
      'Camera isn’t available. Type what you see, or enter brand and model by '
      'hand. Photos are optional and stay on this device.';
  static const voicePermissionDenied =
      'Microphone access was denied. Tap an answer chip or type Other / '
      'describe. Voice is never used to decide what’s wrong.';
  static const permissionsCameraMicWhy =
      'Camera is optional. It can read a rating plate for brand and model. '
      'Microphone is optional: speak an answer chip. '
      'What you tap or type is what the book uses — not the camera or microphone.';
  static const permissionsDeniedManual =
      'If you deny camera or microphone, keep going: type what you see and enter '
      'the model by hand.';
  static const ratingPlateOcrUnavailable =
      'Camera reading isn’t available here. Enter the brand, model, and serial '
      'from the rating plate by hand.';
  static const ratingPlateOcrEmpty =
      'Couldn’t read the rating plate. You can enter the details by hand.';
  static const barcodeScanUnavailable =
      'Barcode scanning isn’t available here. Enter the model by hand.';
  static const barcodeScanEmpty =
      'No barcode or QR mapped to a model. You can enter the details by hand.';
  static const privacyLocalFirst =
      'Local-first: household data stays on this device. Guides install from '
      'copies stored here. Nothing is uploaded to a cloud account.';
  static const privacyWhatIsStored =
      'Stored here: household profiles, appliances, repair sessions and '
      'outcomes, photos you attach, tools you list, reminders, and appearance. '
      'Appliance guides are engineering packages, not personal data.';
  static const privacyNoSkillProfiling =
      'Butler does not silently profile your skill. Tools and comfort are only '
      'what you choose to record. Skill never unlocks unsafe work.';
  static const guideLoading =
      'Loading the guide on this device…';
  static const brandTagline = 'A household repair book';
  static const backupExportTitle = 'Export household data';
  static const exportInventoryTitle = 'Export inventory';
  static const exportInventoryReady =
      'Inventory ready to share on this device.';
  static const exportInventoryPrivacy =
      'Readable list for insurance or a move. Built on this device — not uploaded.';
  static const backupImportTitle = 'Restore from backup';
  static const backupImportConfirm =
      'This replaces households, appliances, repair memory, tools, and '
      'reminders on this device with the backup. It does not use the cloud.';
  static const backupFileInvalid =
      'This file isn’t a household backup from this app. Your current data is unchanged.';
  static const backupImported = 'Household data restored from the backup.';
  static const backupExported = 'Household backup ready to save on this device.';
  static const staleSessionTitle = 'This session is old';
  static String get staleSessionBody =>
      'Evidence was recorded more than $staleOpenSessionHours hours ago and '
      'may be outdated.';
  static const staleSessionContinue = 'Continue';
  static const staleSessionStartFresh = startFresh;
  static const aboutTitle = 'About';
  static const aboutLicensesStub =
      'This app uses open-source packages on this device (Flutter, camera, '
      'speech, OCR, and local storage). Tap View licenses for the full list.';
  static const aboutViewLicenses = 'View licenses';
  static const priorRootCauseHintTitle = 'Earlier repair';
  static const priorRootCauseHintBody =
      'Hint only. Answer what you see this time. This does not skip questions.';
  static const opportunisticMaintenanceTitle = 'While you’re here';
  static const opportunisticMaintenanceBody =
      'Optional extras from the guide, because a panel, filter, or vent is '
      'already open. Skip all if you want to stay on this repair.';
  static const opportunisticSkipAll = 'Skip all';
  static const comfortSettingsTitle = 'Repair comfort';
  static const comfortSettingsExplainer =
      'This is not a skill score. You choose how much detail Safe Guidance '
      'shows for each appliance type. You can change it anytime. Safety stops '
      'and “do not” steps never go away.';
  static const comfortLearnTitle = 'Learn preferences';
  static const comfortLearnSubtitle =
      'Off by default. If you turn this on, after a repair you mark Fixed we '
      'may ask whether to use shorter steps next time for that appliance type. '
      'We never change this silently.';
  static const comfortShortenAskTitle = 'Shorter steps next time?';
  static const comfortShortenAskBody =
      'This repair was Fixed. Use shorter Safe Guidance for similar future '
      'steps on this appliance type? You can change this anytime in Settings. '
      'This is not a skill score.';
  static const comfortShortenYes = 'Use shorter steps';
  static const comfortShortenNo = 'Not now';
  static const warrantyHint =
      'May still be under typical manufacturer warranty — check your docs '
      'before paid parts.';
  static const impactTitle = 'Household impact';
  static const partsCostEstimatesOnly = 'Estimates only. Not a quote.';
  static const impactEstimatesLabel =
      'Estimates only. Not a quote, tax figure, or guaranteed savings.';
  static const impactRepairsLabel = 'Repairs logged';
  static const impactAppliancesLabel = 'Appliances kept in service';
  static const impactSavingsLabel = 'Money saved vs typical pro visit';
  static const impactDiyCostLabel = 'What you spent (DIY, optional)';
  static const expertModeTitle = 'Expert Mode';
  static const expertModeWarning =
      'Off by default. Expert Mode can show extra mechanical steps already '
      'flagged expert_ok in the guide. It does not unlock gas work, sealed '
      'cooling systems, or refrigerant handling. Safety stops still apply.';
  static const expertModeAdultConfirm =
      'I am an adult and I understand Expert Mode still forbids gas, '
      'sealed-system, and refrigerant work.';
  static const expertModeSwitchTitle = 'Enable Expert Mode';
  static const householdProTitle = 'Household Pro (debug)';
  static const householdProSubtitle =
      'No Store purchase in this build. Turns on extra formatting for '
      'inventory and repair-log shares. Repair, House Book, and safety stops '
      'stay free.';
  static const householdProNeverPaywallSafety =
      'Emergency stop copy and basic safety guidance are never behind a '
      'purchase. No countdown or limited-time offer.';
  static const householdProExtraHomeBlocked =
      'Extra homes are planned as Household Pro. Store billing is not '
      'available in this build.';
  static const householdProExtraPersonBlocked =
      'Extra people in a home are planned as Household Pro. Store billing is '
      'not available in this build.';
  static const freeObservationTitle = 'Something else I noticed';
  static const freeObservationHint =
      'Optional note. It is not an answer to the question above.';
  static const freeObservationSave = 'Save note';
  static const freeObservationChipsLead = 'Also mark this observation';
  static const otherObservationPickerTitle = 'A different observation';
  static const continueManually = 'Continue manually';
  static const startFresh = 'Start fresh';
  static const ok = 'OK';
  static const corruptSnapshot =
      'This device’s household book couldn’t be opened. You can start fresh, '
      'or continue with an empty book. Nothing is uploaded.';
  static const resumeFailed =
      'The last question couldn’t be restored. You can continue from here, or '
      'start this repair fresh. What you already typed is still saved.';
  static const skipToBestGuess = 'Skip to best guess';
  static const addApplianceWebHint =
      'Type brand and model here. Rating-plate scan is phone-only.';
  static const addApplianceScanHint =
      'Scan the rating plate for brand and model only, then edit anything '
      'that looks wrong.';
  static const addApplianceManualHint =
      'Enter the brand, model, and serial from the rating plate.';
  static const addApplianceSerialHint =
      'Optional — from the rating plate if you can see it.';
  static const addApplianceLocationHint =
      'Room label only — not an address or map.';
  static const addApplianceAgeHint = 'Optional';
  static const addApplianceKeepRatingPhoto = 'Keep a photo of the rating plate';
  static const addApplianceRatingPhotoStaysLocal =
      'The photo stays on this device. It is not used to diagnose.';
  static const applianceRetired =
      'This appliance is retired. Add a new one to start again.';
  static const voiceWorksBestOnPhone =
      'Voice works best on phone. Tap an answer chip or type Other / describe.';
  static const visualGuideCameraOnPhone =
      'This diagram shows a typical location — yours may vary. '
      'Optional camera on phone is only for looking around.';
  static const visualGuideTypicalCaption = 'Typical location — yours may vary.';
  static const visualGuideSafetyBanner =
      'Typical location only — yours may vary. Unplug first. '
      'The camera does not decide what’s wrong.';
  static const visualGuideTypicalLocation =
      'Typical dryer lint filter at the door opening — a pull-out mesh. '
      'Yours may vary.';
  static const inspectCameraDoesNotDiagnose =
      'Camera does not diagnose. Confirm what you see with the buttons.';
  static const inspectUseCameraWhileILook = 'Use camera while I look';
  static const inspectCameraGuideOnly =
      'Typical location — guide only. Yours may vary.';
  static const inspectCameraOnPhone =
      'Live camera works on a phone. Use the diagram and the buttons here.';
  static const inspectTabDiagram = 'Diagram';
  static const inspectTabCamera = 'Camera';
  static const inspectTypicalAreaConfirm =
      'Typical area — confirm on yours.';
  static const inspectTypicalLocationCaption =
      'Typical location — confirm on yours.';
  static const inspectShowMeWhatToCheck = 'Review what you checked';
  static const inspectReviewIntro =
      'These are the looks already on this path. Changing an answer later '
      'is in Evidence history — this does not start the interview over.';
  static const unmatchedStarterGuidance =
      'We’ll use what you typed; specific guidance may be limited.';
  static const inspectLookForHeading = 'LOOK FOR';
  static const inspectOkLooksLike = 'OK looks like';
  static const inspectNotOkLooksLike = 'Not OK looks like';
  static const whyAskThis = 'Why ask this?';
  static const bestMatchSoFar = 'Best match so far';
  static const bestMatchHumble =
      'This is the best match from your answers so far — not a certainty, '
      'and not a percentage.';
  static const voiceHazardConfirm =
      'Stop. A burning smell, smoke, or similar hazard is not a normal check. '
      'Unplug if it is safe, ventilate, and call a professional.';
  static const sessionObjectivePrompt =
      'What do you want from this session? (optional)';
  static const sessionObjectiveFixIt = 'Fix it';
  static const sessionObjectiveFigureOut = "Figure out what's wrong";
  static const sessionObjectiveRepairVsReplace = 'Decide repair vs replace';
  static const sessionObjectiveCallPro = 'Prepare to call a pro';
}

/// Local household snapshot JSON could not be read.
class CorruptSnapshotException implements Exception {
  const CorruptSnapshotException();
}

/// Session UI resume could not be applied.
class ResumeFailedException implements Exception {
  const ResumeFailedException();
}

/// Gallery/camera permission was refused. The session should continue.
class PhotoPermissionDeniedException implements Exception {
  const PhotoPermissionDeniedException();
}

/// Maps thrown errors to short human copy. Never returns a stack trace.
String userFacingErrorMessage(Object error) {
  if (error is BackupFileInvalidException) {
    return UserFacingCopy.backupFileInvalid;
  }
  if (error is CorruptSnapshotException) {
    return UserFacingCopy.corruptSnapshot;
  }
  if (error is ResumeFailedException) {
    return UserFacingCopy.resumeFailed;
  }
  if (error is PhotoPermissionDeniedException) {
    return UserFacingCopy.photoPermissionDenied;
  }
  final raw = error is StateError ? error.message : error.toString();
  if (_looksLikeStackOrEngineDump(raw)) {
    return UserFacingCopy.genericError;
  }
  final lower = raw.toLowerCase();
  if (lower.contains('knowledge package') ||
      lower.contains('package is attached') ||
      lower.contains('package was not found') ||
      lower.contains('could not be loaded')) {
    return UserFacingCopy.packageUnavailable;
  }
  if (lower.contains('permission') && lower.contains('denied')) {
    return UserFacingCopy.photoPermissionDenied;
  }
  if (lower.contains('session') && lower.contains('was not found')) {
    return UserFacingCopy.sessionNotFound;
  }
  if (lower.contains('already finished')) {
    return UserFacingCopy.sessionAlreadyFinished;
  }
  if (lower.contains('reminder title')) {
    return UserFacingCopy.reminderNeedsTitle;
  }
  if (raw.trim().isEmpty || raw.length > 180) {
    return UserFacingCopy.genericError;
  }
  return raw.trim();
}

bool _looksLikeStackOrEngineDump(String raw) {
  return raw.contains('\n#') ||
      raw.contains('#0 ') ||
      raw.contains('Exception:') ||
      raw.contains('Error:') ||
      raw.contains('package:flutter/') ||
      raw.contains('package:modern_butlers_book/');
}
