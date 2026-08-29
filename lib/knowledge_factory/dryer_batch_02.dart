import 'dart:convert';

/// Dryer Knowledge Factory Batch 02 — twenty additional failure modes.
///
/// Source maps mirror [data/dryer_batch_02.v1.json]. Prefer editing the JSON
/// data file, then regenerating this embedding, or keep both aligned via tests.
const String dryerBatch02Id = 'dryer-batch-02';
const String dryerBatch02SchemaVersion = '1.0';

/// Embedded Batch 02 JSON document (`{ "batchId", "failureModes": [...] }`).
String get dryerBatch02Json => jsonEncode(_dryerBatch02Document);

const Map<String, Object?> _dryerBatch02Document = {
  'schemaVersion': dryerBatch02SchemaVersion,
  'batchId': dryerBatch02Id,
  'applianceFamily': 'dryer',
  'failureModes': _dryerBatch02Modes,
};

const List<Map<String, Object?>> _dryerBatch02Modes = [
  {
    'schemaVersion': '1.0',
    'id': 'cycling-thermostat-stuck-open',
    'title': 'Cycling thermostat stuck open',
    'applianceFamily': 'dryer',
    'symptomPhrasings': [
      'long dry times',
      'heat stops early',
      'clothes cold at end of cycle',
      'dryer runs but barely warms',
    ],
    'immediateCause':
        'The cycling thermostat stays open too long, so the heater is off for most of the cycle.',
    'rootCause':
        'A stuck-open cycling thermostat (or equivalent temperature control) keeps interrupting heat rather than maintaining normal cycling.',
    'contributingFactors': [
      'Age-related thermostat failure',
      'Prior overheating that damaged the thermostat',
      'Restricted airflow that stressed the control path',
    ],
    'evidenceSupports': [
      {'templateId': 'heat-pattern', 'answer': 'Some heat but clothes stay damp'},
      {'templateId': 'heat-observed', 'answer': 'Slight warmth'},
      {'templateId': 'cycle-heat-setting', 'answer': 'Yes, heat cycle'},
      {'templateId': 'clothes-feel-after-cycle', 'answer': 'Cold and still damp'},
      {'templateId': 'dry-time-change', 'answer': 'Much longer'},
    ],
    'evidenceExcludes': [
      {'templateId': 'heat-pattern', 'answer': 'Heat seems normal'},
      {'templateId': 'heat-observed', 'answer': 'Very hot'},
      {'templateId': 'heat-observed', 'answer': 'No warmth'},
      {'templateId': 'cycle-heat-setting', 'answer': 'No, air-only / fluff'},
      {'templateId': 'recent-overheat', 'answer': 'Yes, very hot or shut off from heat'},
    ],
    'commonMisdiagnoses': [
      'Heating element completely open when some warmth appears early in the cycle',
      'Batch 01 intermittent cycling thermostat when heat drops to cold for the rest of the cycle',
      'Thermal fuse open when heat was present earlier in the same cycle',
    ],
    'firstLineQuestions': [
      {
        'templateId': 'heat-pattern',
        'promptText':
            'After the dryer has run on a heat cycle, how does the load feel?',
        'answerChoices': [
          'No heat',
          'Some heat but clothes stay damp',
          'Too hot / overheating',
          'Heat seems normal',
          'Not sure',
          'Other / describe',
        ],
      },
    ],
    'verificationAsk':
        'On a heat cycle with lint filter clean and exterior airflow not obviously blocked, does warmth fade to cold for the rest of the cycle rather than staying steady?',
    'verificationWhy':
        'Separates stuck-open cycling from steady no-heat element/fuse patterns and from Batch 01 intermittent thermostat behavior.',
    'verificationSteps': [
      'Confirm heat cycle selected',
      'Clean lint filter and check visible vent path',
      'Run a short cycle and note whether heat drops off for good',
      'Do not test thermostats live — escalate',
    ],
    'safeGuidanceBoundary': [
      'No live thermostat or heater-circuit testing',
      'Confirm settings and beginner airflow checks only',
      'If heat fades to cold after an early warm period, call a qualified technician',
    ],
    'stopProfessionalConditions': [
      'Any electrical testing of thermostats or heaters',
      'Burning smell, smoke, or overheating cabinet',
      'Need to open the heater housing',
    ],
    'preventionActions': [
      'Keep venting clear to reduce thermal stress',
      'Stop using the dryer if it overheats or smells hot/electrical',
    ],
    'toolsRequired': ['None for observation'],
    'difficultyNotes':
        'Observation only for beginners. Thermostat service is professional.',
    'commonality': 'common',
    'safetyNotes': 'Do not guide live thermostat testing.',
    'allowResolvedWhenConfirmed': false,
    'preferProfessionalWhenNotConfirmed': true,
  },
  {
    'schemaVersion': '1.0',
    'id': 'cycling-thermostat-stuck-closed',
    'title': 'Cycling thermostat stuck closed',
    'applianceFamily': 'dryer',
    'symptomPhrasings': [
      'dryer runs very hot',
      'clothes scorching',
      'cabinet too hot to touch',
      'heat never cycles off',
    ],
    'immediateCause':
        'The cycling thermostat fails to open, so the heater runs continuously without normal temperature cycling.',
    'rootCause':
        'A stuck-closed cycling thermostat (or failed temperature control) allows excess heat until high-limit protection or user concern stops the cycle.',
    'contributingFactors': [
      'Failed cycling thermostat contacts',
      'Age-related control wear',
      'Restricted airflow that raises cabinet temperature',
    ],
    'evidenceSupports': [
      {'templateId': 'heat-observed', 'answer': 'Very hot'},
      {'templateId': 'heat-pattern', 'answer': 'Too hot / overheating'},
      {'templateId': 'cycle-heat-setting', 'answer': 'Yes, heat cycle'},
      {'templateId': 'recent-overheat', 'answer': 'Yes, very hot or shut off from heat'},
      {'templateId': 'clothes-feel-after-cycle', 'answer': 'Warm or hot but still damp'},
      {'templateId': 'clothes-feel-after-cycle', 'answer': 'Dry but unusually hot'},
      {'templateId': 'exterior-airflow', 'answer': 'Weak'},
    ],
    'evidenceExcludes': [
      {'templateId': 'heat-observed', 'answer': 'No warmth'},
      {'templateId': 'heat-pattern', 'answer': 'No heat'},
      {'templateId': 'heat-pattern', 'answer': 'Some heat but clothes stay damp'},
      {'templateId': 'cycle-heat-setting', 'answer': 'No, air-only / fluff'},
      {'templateId': 'recent-overheat', 'answer': 'No'},
    ],
    'commonMisdiagnoses': [
      'Batch 01 high-limit thermostat open (that mode is no heat after an overheat event, not ongoing excessive heat)',
      'Restricted vent alone when heat intensity is abnormally high throughout the cycle',
      'Normal high-heat cycle selection when the cabinet is dangerously hot',
    ],
    'firstLineQuestions': [
      {
        'templateId': 'heat-observed',
        'promptText': 'Is there any warmth after the dryer has run briefly?',
        'answerChoices': [
          'No warmth',
          'Slight warmth',
          'Normal heat',
          'Very hot',
          'Not sure',
          'Other / describe',
        ],
      },
    ],
    'verificationAsk':
        'During a normal heat cycle, does the cabinet or exhaust air feel abnormally hot without the heat ever backing off?',
    'verificationWhy':
        'Points to stuck-closed cycling rather than post-overheat no-heat protection.',
    'verificationSteps': [
      'Confirm a normal (not extra-high) heat cycle',
      'Note whether heat stays intense without cycling off',
      'Stop the cycle if the cabinet is too hot to touch safely',
      'Do not bypass any thermostat — escalate',
    ],
    'safeGuidanceBoundary': [
      'Stop the cycle if the cabinet is uncomfortably hot',
      'Check lint filter and visible vent restriction as a contributing factor only',
      'Never bypass cycling or high-limit thermostats',
      'Thermostat replacement is professional work',
    ],
    'stopProfessionalConditions': [
      'Burning smell, smoke, melting, or sparking',
      'Any plan to jumper or bypass thermostats',
      'Cabinet remains dangerously hot after stopping the cycle',
    ],
    'preventionActions': [
      'Clean lint filter every load',
      'Keep vent path clear',
      'Do not run the dryer if it overheats abnormally',
    ],
    'toolsRequired': ['None for observation'],
    'difficultyNotes':
        'Stop-and-observe for beginners. Thermostat service is professional.',
    'commonality': 'moderate',
    'safetyNotes': 'Never bypass thermostats. Stop for smoke or burning smell.',
    'allowResolvedWhenConfirmed': false,
    'preferProfessionalWhenNotConfirmed': true,
  },
  {
    'schemaVersion': '1.0',
    'id': 'thermistor-fault-electronic',
    'title': 'Thermistor fault (electronic control)',
    'applianceFamily': 'dryer',
    'symptomPhrasings': [
      'erratic heat',
      'temperature all over the place',
      'electronic dryer wrong temperature',
      'heat cuts in and out randomly',
    ],
    'immediateCause':
        'The electronic control receives bad temperature feedback from a failing thermistor, so heat output is erratic or wrong.',
    'rootCause':
        'A failed or drifting thermistor (or its wiring connection) misreports drum temperature to the control board.',
    'contributingFactors': [
      'Age-related thermistor drift',
      'Lint or moisture near the sensor area (professional inspection)',
      'Prior overheating events',
    ],
    'evidenceSupports': [
      {'templateId': 'heat-pattern', 'answer': 'Some heat but clothes stay damp'},
      {'templateId': 'heat-pattern', 'answer': 'Too hot / overheating'},
      {'templateId': 'heat-observed', 'answer': 'Slight warmth'},
      {'templateId': 'heat-observed', 'answer': 'Very hot'},
      {'templateId': 'cycle-heat-setting', 'answer': 'Yes, heat cycle'},
      {'templateId': 'panel-lights', 'answer': 'Yes, panel responds'},
    ],
    'evidenceExcludes': [
      {'templateId': 'heat-pattern', 'answer': 'No heat'},
      {'templateId': 'heat-pattern', 'answer': 'Heat seems normal'},
      {'templateId': 'cycle-heat-setting', 'answer': 'No, air-only / fluff'},
      {'templateId': 'panel-lights', 'answer': 'No lights at all'},
      {'templateId': 'heat-observed', 'answer': 'No warmth'},
    ],
    'commonMisdiagnoses': [
      'Batch 01 cycling thermostat failed on a mechanical-timer dryer',
      'Heating element open when heat is erratic rather than absent',
      'Control board failure assumed before noting electronic-control erratic heat pattern',
    ],
    'firstLineQuestions': [
      {
        'templateId': 'heat-pattern',
        'promptText':
            'After the dryer has run on a heat cycle, how does the load feel?',
        'answerChoices': [
          'No heat',
          'Some heat but clothes stay damp',
          'Too hot / overheating',
          'Heat seems normal',
          'Not sure',
          'Other / describe',
        ],
      },
    ],
    'verificationAsk':
        'After the safe checks below on a heat cycle, is the load sometimes warm but still damp, or too hot — rather than completely cold with no heat at all?',
    'verificationWhy':
        'Partial warmth, damp clothes, or overheating point toward sensor/control feedback faults. Completely cold throughout points toward steady no-heat paths.',
    'verificationSteps': [
      'Confirm heat cycle and that the panel responds normally',
      'Clean lint filter and check visible vent path',
      'Run a short cycle and note whether clothes are cold throughout, partly warm but damp, or too hot',
      'Do not probe thermistor wiring — escalate',
    ],
    'safeGuidanceBoundary': [
      'No live thermistor or control-board testing',
      'Beginner lint and vent checks only',
      'Uneven or extreme heat on electronic controls → qualified technician',
    ],
    'stopProfessionalConditions': [
      'Any control-board or thermistor wiring work',
      'Burning smell, smoke, or sparking',
      'Need to open the console or heater housing',
    ],
    'preventionActions': [
      'Keep lint and vent paths clear',
      'Stop use if heat becomes unpredictable or the cabinet overheats',
    ],
    'toolsRequired': ['None for observation'],
    'difficultyNotes': 'Observation only. Thermistor service is professional.',
    'commonality': 'common',
    'safetyNotes': 'Do not guide live sensor or board testing.',
    'allowResolvedWhenConfirmed': false,
    'preferProfessionalWhenNotConfirmed': true,
  },
  {
    'schemaVersion': '1.0',
    'id': 'relay-or-control-no-heat-output',
    'title': 'Heat relay or control output failure',
    'applianceFamily': 'dryer',
    'symptomPhrasings': [
      'no heat but drum turns',
      'electronic dryer tumbles cold',
      'panel works but no warmth',
      'heat never comes on heat cycle',
    ],
    'immediateCause':
        'The control or heat relay does not energize the heater circuit even though the drum tumbles on a heat cycle.',
    'rootCause':
        'A failed heat relay, triac, or control output on an electronic dryer prevents the heater from receiving command power.',
    'contributingFactors': [
      'Age-related relay or board failure',
      'Prior overheating that damaged the relay path',
      'Confusion with air-only cycle selection',
    ],
    'evidenceSupports': [
      {'templateId': 'cycle-heat-setting', 'answer': 'Yes, heat cycle'},
      {'templateId': 'relay-heat-output', 'answer': 'No heat despite heat cycle and tumble'},
      {'templateId': 'exterior-airflow', 'answer': 'Normal'},
      {'templateId': 'panel-lights', 'answer': 'Yes, panel responds'},
    ],
    'evidenceExcludes': [
      {'templateId': 'cycle-heat-setting', 'answer': 'No, air-only / fluff'},
      {'templateId': 'heat-observed', 'answer': 'Normal heat'},
      {'templateId': 'drum-turns', 'answer': 'Does not turn'},
      {'templateId': 'recent-overheat', 'answer': 'Yes, very hot or shut off from heat'},
      {'templateId': 'recent-overheat', 'answer': 'No'},
      {'templateId': 'relay-heat-output', 'answer': 'Heat works normally'},
      {'templateId': 'clothes-feel-after-cycle', 'answer': 'Cold and still damp'},
      {'templateId': 'wall-plug-seated', 'answer': 'Loose or only partly seated'},
      {'templateId': 'panel-lights', 'answer': 'No lights at all'},
      {'templateId': 'gas-dryer-type', 'answer': 'Yes, gas dryer'},
    ],
    'commonMisdiagnoses': [
      'Batch 01 heating element failed before confirming tumble and panel response',
      'Thermal fuse open when there is no recent overheat story',
      'Batch 01 electric supply fault when the drum tumbles and the plug looks normal',
    ],
    'firstLineQuestions': [
      {
        'templateId': 'relay-heat-output',
        'promptText':
            'On a heat cycle with the drum turning, does the heater produce any warmth at all?',
        'answerChoices': [
          'No heat despite heat cycle and tumble',
          'Intermittent heat only',
          'Heat works normally',
          'Not sure',
          'Other / describe',
        ],
      },
    ],
    'verificationAsk':
        'With a heat cycle selected, the drum turning, and the panel responding, does a short run still produce no warmth while exterior airflow looks normal?',
    'verificationWhy':
        'Confirms control-output no-heat pattern distinct from element open or supply faults.',
    'verificationSteps': [
      'Confirm heat cycle (not air-only / fluff)',
      'Confirm drum turns and panel responds',
      'Run a short cycle and feel for warmth',
      'If still cold, stop beginner DIY and call a technician',
    ],
    'safeGuidanceBoundary': [
      'Do not measure live voltage or open the control console',
      'Confirm heat cycle, tumble, and external plug condition only',
      'Relay and control output repair are professional tasks',
    ],
    'stopProfessionalConditions': [
      'Any relay, board, or live heater-circuit testing',
      'Burning smell, smoke, melting, or sparking',
      'Need to open the console or heater housing',
    ],
    'preventionActions': [
      'Keep vent and lint paths clear to reduce control stress',
      'Stop use if the dryer overheats abnormally',
    ],
    'toolsRequired': ['None for beginner external checks'],
    'difficultyNotes':
        'Settings and observation only. Relay/control repair is professional.',
    'commonality': 'common',
    'safetyNotes':
        'Do not guide live electrical testing of control or heater circuits.',
    'allowResolvedWhenConfirmed': false,
    'preferProfessionalWhenNotConfirmed': true,
  },
  {
    'schemaVersion': '1.0',
    'id': 'loose-power-cord-connection-electric',
    'title': 'Loose power cord connection (electric)',
    'applianceFamily': 'dryer',
    'symptomPhrasings': [
      'dryer plug loose',
      'cord wiggles at plug',
      'intermittent power at cord',
      'plug feels warm when touched',
    ],
    'immediateCause':
        'The dryer cord or plug connection is loose or degraded, interrupting full supply to the machine.',
    'rootCause':
        'A loose plug fit, worn cord grip, or damaged plug end prevents a solid high-voltage connection — external checks only.',
    'contributingFactors': [
      'Plug not fully seated in the outlet',
      'Damaged or discolored plug blades',
      'Dryer moved repeatedly without reseating the plug',
    ],
    'evidenceSupports': [
      {'templateId': 'wall-plug-seated', 'answer': 'Loose or only partly seated'},
      {'templateId': 'wall-plug-seated', 'answer': 'Plug or cord looks damaged / discolored'},
      {'templateId': 'panel-lights', 'answer': 'No lights at all'},
    ],
    'evidenceExcludes': [
      {'templateId': 'wall-plug-seated', 'answer': 'Fully seated, looks normal'},
      {'templateId': 'heat-observed', 'answer': 'Normal heat'},
      {'templateId': 'outlet-power-check', 'answer': 'Outlet appears dead / breaker tripped'},
      {'templateId': 'breaker-tripped-check', 'answer': 'Breaker clearly tripped'},
      {'templateId': 'gas-dryer-type', 'answer': 'Yes, gas dryer'},
    ],
    'commonMisdiagnoses': [
      'Batch 01 electric supply connection fault when the issue is specifically cord/plug looseness',
      'Heating element failed without checking external plug seating',
      'Missing 240V leg when the plug is visibly loose rather than a breaker issue',
    ],
    'firstLineQuestions': [
      {
        'templateId': 'wall-plug-seated',
        'promptText':
            'Is the dryer wall plug fully pushed in (no looseness; cord and plug look normal)?',
        'answerChoices': [
          'Fully seated, looks normal',
          'Loose or only partly seated',
          'Plug or cord looks damaged / discolored',
          'Not sure',
          'Other / describe',
        ],
      },
    ],
    'verificationAsk':
        'After unplugging, firmly reseating an undamaged-looking plug, and restoring power, do lights and heat behavior return to normal?',
    'verificationWhy':
        'Allows only external cord/plug seating. No live panel or terminal-block work.',
    'verificationSteps': [
      'Unplug the dryer before reseating the cord',
      'Inspect plug and cord visually for damage or discoloration',
      'Firmly reseat an undamaged plug — do not open the dryer terminal block',
      'If damaged or still abnormal, stop and call a professional',
    ],
    'safeGuidanceBoundary': [
      'External plug seating and visual cord condition only',
      'Unplug before reseating — no live terminal-block or panel work',
      'Damaged plug, cord, or warm/discolored outlet = professional immediately',
      'Do not measure live voltage',
    ],
    'stopProfessionalConditions': [
      'Damaged, burnt, or discolored plug, cord, or outlet',
      'Any terminal-block or internal wiring work',
      'Burning smell, smoke, sparking, or heat at the plug',
      'Need for live electrical testing',
    ],
    'preventionActions': [
      'Push the dryer plug fully into a matching dryer outlet',
      'Avoid yanking the cord when moving the dryer',
      'Stop use if the plug or outlet feels hot',
    ],
    'toolsRequired': ['None for external visual/seating check'],
    'difficultyNotes':
        'External seating only. Cord replacement and terminal work are professional.',
    'commonality': 'moderate',
    'safetyNotes': 'High voltage: external checks only. No live panel work.',
    'allowResolvedWhenConfirmed': true,
    'preferProfessionalWhenNotConfirmed': true,
  },
  {
    'schemaVersion': '1.0',
    'id': 'missing-leg-240v-supply',
    'title': 'Missing 240V supply leg',
    'applianceFamily': 'dryer',
    'symptomPhrasings': [
      'tumbles but no heat',
      'dryer runs on 120V only',
      'motor works no warmth',
      'one breaker leg out',
    ],
    'immediateCause':
        'The dryer receives only partial voltage, enough to run the motor but not the heater.',
    'rootCause':
        'One leg of the 240V supply is missing — tripped breaker pole, failed outlet leg, or supply fault. External checks only.',
    'contributingFactors': [
      'One pole of a double-pole breaker tripped',
      'Failed half of a dryer outlet (professional)',
      'Loose supply connection at the panel (professional)',
    ],
    'evidenceSupports': [
      {'templateId': 'breaker-tripped-check', 'answer': 'One pole tripped / half supply'},
      {'templateId': 'wall-plug-seated', 'answer': 'Fully seated, looks normal'},
    ],
    'evidenceExcludes': [
      {'templateId': 'drum-turns', 'answer': 'Does not turn'},
      {'templateId': 'heat-observed', 'answer': 'Normal heat'},
      {'templateId': 'panel-lights', 'answer': 'No lights at all'},
      {'templateId': 'cycle-heat-setting', 'answer': 'No, air-only / fluff'},
      {'templateId': 'breaker-tripped-check', 'answer': 'Both poles on, supply looks normal'},
      {'templateId': 'gas-dryer-type', 'answer': 'Yes, gas dryer'},
    ],
    'commonMisdiagnoses': [
      'Batch 01 heating element failed when the drum tumbles and panel lights work',
      'Batch 01 no power at outlet when some panel function remains',
      'Loose cord connection when the plug is fully seated and the breaker shows a half-trip pattern',
    ],
    'firstLineQuestions': [
      {
        'templateId': 'breaker-tripped-check',
        'promptText':
            'At the breaker panel (visual only, no panel dismantling), what do you see for the dryer circuit?',
        'answerChoices': [
          'One pole tripped / half supply',
          'Both poles on, supply looks normal',
          'Whole breaker tripped off',
          'Not sure',
          'Other / describe',
        ],
      },
    ],
    'verificationAsk':
        'After a visual breaker check and reset of a tripped pole (once only, if safe), does heat return on a short cycle with the drum turning?',
    'verificationWhy':
        'Restores a missing 240V leg without any live measurement or internal dryer wiring work.',
    'verificationSteps': [
      'Confirm drum turns and panel responds but there is no warmth on a heat cycle',
      'Visually check the dryer breaker — reset a tripped pole once if safe',
      'Do not repeatedly reset a breaker that trips again',
      'Do not measure live voltage or open the dryer terminal block',
    ],
    'safeGuidanceBoundary': [
      'Breaker visual check and single reset only — no outlet dismantling',
      'Do not measure live voltage at the dryer terminal block or outlet',
      'Repeated breaker trips, burnt smell, or damaged outlet = professional immediately',
      'No internal dryer wiring work as a beginner',
    ],
    'stopProfessionalConditions': [
      'Breaker trips again after reset',
      'Burning smell, smoke, hot plug, or discolored outlet',
      'Any outlet, panel, or terminal-block wiring work',
      'Need for live electrical testing',
    ],
    'preventionActions': [
      'Use a properly sized double-pole breaker for the dryer circuit',
      'Investigate repeated trips with a licensed electrician',
    ],
    'toolsRequired': ['None for breaker visual check'],
    'difficultyNotes':
        'Breaker glance/reset only. Outlet and panel work is professional.',
    'commonality': 'moderate',
    'safetyNotes':
        'External supply checks only. No live panel or terminal-block work.',
    'allowResolvedWhenConfirmed': true,
    'preferProfessionalWhenNotConfirmed': true,
  },
  {
    'schemaVersion': '1.0',
    'id': 'timer-advanced-no-heat-portion',
    'title': 'Timer advanced past heat portion',
    'applianceFamily': 'dryer',
    'symptomPhrasings': [
      'tumbles but no heat on timer dryer',
      'timer knob in wrong spot',
      'mechanical timer no heat segment',
      'dryer runs cold on timed cycle',
    ],
    'immediateCause':
        'The mechanical timer is positioned so the heat portion of the cycle is skipped or not engaged.',
    'rootCause':
        'Timer dial mis-set, worn timer cam, or failed timer heat contacts prevent the heater from energizing during tumble.',
    'contributingFactors': [
      'Timer dial turned to air-only segment',
      'Worn timer cam skipping heat contacts',
      'Age-related timer failure',
    ],
    'evidenceSupports': [
      {'templateId': 'timer-heat-portion', 'answer': 'Timer past heat / no heat segment'},
      {'templateId': 'timer-heat-portion', 'answer': 'Not sure timer position'},
    ],
    'evidenceExcludes': [
      {'templateId': 'timer-heat-portion', 'answer': 'Timer clearly on heat segment'},
      {'templateId': 'cycle-heat-setting', 'answer': 'No, air-only / fluff'},
      {'templateId': 'heat-observed', 'answer': 'Normal heat'},
      {'templateId': 'panel-lights', 'answer': 'Yes, panel responds'},
    ],
    'commonMisdiagnoses': [
      'Batch 01 air-fluff cycle selected on an electronic dryer',
      'Heating element failed on a mechanical timer dryer before checking timer position',
      'Batch 01 heating element failed when the timer segment is simply wrong',
    ],
    'firstLineQuestions': [
      {
        'templateId': 'timer-heat-portion',
        'promptText':
            'On a mechanical timer dryer, is the dial set to a segment that includes heat (not air-only)?',
        'answerChoices': [
          'Timer clearly on heat segment',
          'Timer past heat / no heat segment',
          'Not sure timer position',
          'Electronic controls (no timer dial)',
          'Other / describe',
        ],
      },
    ],
    'verificationAsk':
        'After setting the timer dial to a clearly labeled heat segment, does warmth return on a short run with the drum turning?',
    'verificationWhy':
        'Rules out timer mis-set before element or fuse diagnosis on mechanical dryers.',
    'verificationSteps': [
      'Identify whether the dryer uses a mechanical timer dial',
      'Set the dial to a clearly labeled heat segment',
      'Run a short cycle and feel for warmth',
      'If still cold on a confirmed heat segment, escalate',
    ],
    'safeGuidanceBoundary': [
      'Timer dial setting only — no timer disassembly or live wiring',
      'If heat segment is confirmed and still no warmth, call a technician',
      'Do not open the timer or console for contact testing',
    ],
    'stopProfessionalConditions': [
      'Timer replacement or internal timer wiring required',
      'Burning smell, smoke, or sparking',
      'Electronic-control dryer (use relay/control modes instead)',
    ],
    'preventionActions': [
      'Confirm timer dial position before starting',
      'Replace a worn timer that skips heat segments',
    ],
    'toolsRequired': ['None for dial setting check'],
    'difficultyNotes': 'Dial setting is beginner-safe. Timer repair is professional.',
    'commonality': 'common',
    'safetyNotes': 'Settings and observation only. No timer wiring work.',
    'allowResolvedWhenConfirmed': false,
    'preferProfessionalWhenNotConfirmed': true,
  },
  {
    'schemaVersion': '1.0',
    'id': 'belt-slipping-not-fully-broken',
    'title': 'Drive belt slipping (not fully broken)',
    'applianceFamily': 'dryer',
    'symptomPhrasings': [
      'drum turns slowly',
      'squeal then drum stops',
      'belt slipping',
      'intermittent tumble',
    ],
    'immediateCause':
        'The drive belt slips on the motor or idler pulley, so the drum turns poorly or stops intermittently.',
    'rootCause':
        'A glazed, stretched, or mis-routed belt slips without fully breaking, reducing tumble action.',
    'contributingFactors': [
      'Worn or glazed belt',
      'Weak idler tension',
      'Seized drum rollers increasing drag',
    ],
    'evidenceSupports': [
      {'templateId': 'belt-slip-observation', 'answer': 'Drum slips or turns slowly'},
      {'templateId': 'belt-slip-observation', 'answer': 'Squeal then drum stops briefly'},
      {'templateId': 'drum-turns', 'answer': 'Turns briefly then stops'},
      {'templateId': 'running-noise', 'answer': 'Squeal'},
      {'templateId': 'motor-audible', 'answer': 'Yes, clear motor sound'},
    ],
    'evidenceExcludes': [
      {'templateId': 'drum-turns', 'answer': 'Does not turn'},
      {'templateId': 'drum-turns', 'answer': 'Motor runs, drum still'},
      {'templateId': 'belt-slip-observation', 'answer': 'Drum turns normally throughout'},
      {'templateId': 'running-noise', 'answer': 'Thump'},
    ],
    'commonMisdiagnoses': [
      'Batch 01 broken drive belt when the drum still turns intermittently or slowly',
      'Batch 01 idler pulley wear alone when the drum actually stops during slip',
      'Motor failure when a clear motor sound is present with slipping tumble',
    ],
    'firstLineQuestions': [
      {
        'templateId': 'belt-slip-observation',
        'promptText':
            'Does the drum slip, turn slowly, or stop briefly while the motor sounds active?',
        'answerChoices': [
          'Drum turns normally throughout',
          'Drum slips or turns slowly',
          'Squeal then drum stops briefly',
          'Motor runs, drum never moves',
          'Not sure',
          'Other / describe',
        ],
      },
    ],
    'verificationAsk':
        'While the dryer runs, does the drum slip, turn slowly, or stop briefly while you still hear the motor active?',
    'verificationWhy':
        'Separates slipping belt from fully broken belt or pure motor hum patterns.',
    'verificationSteps': [
      'Start a cycle and watch drum motion',
      'Listen for squeal with intermittent drum movement',
      'Unplug before any internal inspection',
      'Escalate for belt/idler service',
    ],
    'safeGuidanceBoundary': [
      'External observation of drum motion only',
      'Unplug before any internal look',
      'Belt and idler service requires cabinet access — typically professional',
      'Do not reach into a running drum',
    ],
    'stopProfessionalConditions': [
      'Burning smell, smoke, or belt shredding',
      'Belt or idler replacement required',
      'Drum will not turn at all (see broken belt mode)',
    ],
    'preventionActions': [
      'Address squeal and slow tumble early before the belt breaks',
      'Avoid overloading the drum',
    ],
    'toolsRequired': ['None for external observation'],
    'difficultyNotes':
        'Motion observation is beginner-safe. Belt service is intermediate/pro.',
    'commonality': 'common',
    'safetyNotes': 'Inspect internally only after safe isolation.',
    'allowResolvedWhenConfirmed': true,
    'preferProfessionalWhenNotConfirmed': true,
  },
  {
    'schemaVersion': '1.0',
    'id': 'drum-glides-worn',
    'title': 'Worn drum glides or front seal rub',
    'applianceFamily': 'dryer',
    'symptomPhrasings': [
      'scraping front of drum',
      'metal on metal sound',
      'grinding at drum front',
      'squeak scrape each revolution',
    ],
    'immediateCause':
        'Worn front drum glides or seals let the drum rub the cabinet lip, creating scrape or grind each revolution.',
    'rootCause':
        'Glide pads or front bearing surfaces wear through, so the drum contacts metal during rotation.',
    'contributingFactors': [
      'Age and high cycle count',
      'Foreign objects caught at the drum lip',
      'Deferred noise repairs',
    ],
    'evidenceSupports': [
      {'templateId': 'running-noise', 'answer': 'Grind'},
      {'templateId': 'drum-turns', 'answer': 'Turns normally'},
      {'templateId': 'running-noise', 'answer': 'Squeal'},
    ],
    'evidenceExcludes': [
      {'templateId': 'running-noise', 'answer': 'No unusual sound'},
      {'templateId': 'running-noise', 'answer': 'Thump'},
      {'templateId': 'drum-turns', 'answer': 'Motor runs, drum still'},
      {'templateId': 'dryer-response', 'answer': 'Nothing happens'},
    ],
    'commonMisdiagnoses': [
      'Batch 01 worn drum rollers (more thump at rear than front scrape/grind)',
      'Batch 01 idler squeal without the front scrape character',
      'Broken belt when the drum is still turning with a front rub noise',
    ],
    'firstLineQuestions': [
      {
        'templateId': 'running-noise',
        'promptText':
            'Do you hear a squeal, thump, grind, hum, or another sound?',
        'answerChoices': [
          'No unusual sound',
          'Squeal',
          'Thump',
          'Grind',
          'Hum',
          'Not sure',
          'Other / describe',
        ],
      },
    ],
    'verificationAsk':
        'Does a scrape or grind repeat in time with the drum, especially seeming to come from the front of the drum?',
    'verificationWhy':
        'Front scrape/grind points to glides/seal rub rather than rear roller thump.',
    'verificationSteps': [
      'Run briefly and listen for front scrape/grind timed to drum rotation',
      'Unplug before any internal inspection',
      'Escalate for glide or front seal service',
    ],
    'safeGuidanceBoundary': [
      'Listening while tumbling is the beginner check',
      'Unplug before opening the cabinet',
      'Glide replacement is a technician-level repair for most users',
      'Do not lubricate sealed assemblies with household oils as a fix',
    ],
    'stopProfessionalConditions': [
      'Burning smell, smoke, or grinding metal that worsens quickly',
      'Cabinet disassembly required',
      'Drum will not turn',
    ],
    'preventionActions': [
      'Address front scrape noises early before cabinet damage worsens',
      'Check pockets for coins and small items',
    ],
    'toolsRequired': ['None for listening checks'],
    'difficultyNotes':
        'Listening checks are beginner-safe. Glide service is intermediate/pro.',
    'commonality': 'common',
    'safetyNotes': 'Limit checks to sound and safely isolated inspection.',
    'allowResolvedWhenConfirmed': true,
    'preferProfessionalWhenNotConfirmed': true,
  },
  {
    'schemaVersion': '1.0',
    'id': 'blower-wheel-loose-or-damaged',
    'title': 'Blower wheel loose or damaged',
    'applianceFamily': 'dryer',
    'symptomPhrasings': [
      'rattling airflow',
      'weak air with rattle',
      'blower wobble noise',
      'slow dry rattling exhaust',
    ],
    'immediateCause':
        'The blower wheel is loose, cracked, or missing vanes, so it moves air poorly and may rattle.',
    'rootCause':
        'A loose blower nut, cracked wheel, or damaged vanes reduce airflow and create rattle or wobble — distinct from a simple lint obstruction.',
    'contributingFactors': [
      'Loose blower fastener',
      'Cracked or broken blower vanes',
      'Prior foreign object impact',
    ],
    'evidenceSupports': [
      {'templateId': 'exterior-airflow', 'answer': 'Weak'},
      {'templateId': 'running-noise', 'answer': 'Grind'},
      {'templateId': 'vent-hose-condition', 'answer': 'Looks clear'},
      {'templateId': 'clothes-remain-damp', 'answer': 'Still damp'},
      {'templateId': 'dry-time-change', 'answer': 'Much longer'},
    ],
    'evidenceExcludes': [
      {'templateId': 'exterior-airflow', 'answer': 'Normal'},
      {'templateId': 'vent-hose-condition', 'answer': 'Yes, restricted'},
      {'templateId': 'running-noise', 'answer': 'No unusual sound'},
      {'templateId': 'clothes-feel-after-cycle', 'answer': 'Cold and still damp'},
    ],
    'commonMisdiagnoses': [
      'Batch 01 blower wheel obstruction when the hose is clear but the wheel rattles',
      'Batch 01 restricted exhaust when the visible vent path looks clear',
      'Heating element failure when clothes are warm but damp with weak air and rattle',
    ],
    'firstLineQuestions': [
      {
        'templateId': 'running-noise',
        'promptText':
            'Do you hear a squeal, thump, grind, hum, or another sound?',
        'answerChoices': [
          'No unusual sound',
          'Squeal',
          'Thump',
          'Grind',
          'Hum',
          'Not sure',
          'Other / describe',
        ],
      },
    ],
    'verificationAsk':
        'With the lint filter clean and visible vent hose clear, is exterior airflow still weak while you hear rattle or grind from the blower area?',
    'verificationWhy':
        'Points to loose/damaged blower hardware rather than external vent crush or lint obstruction alone.',
    'verificationSteps': [
      'Confirm lint filter is clean',
      'Confirm visible vent hose is not crushed/packed',
      'Run and note weak airflow plus rattle/grind',
      'Unplug; do not dig into the blower housing as a beginner',
    ],
    'safeGuidanceBoundary': [
      'External vent and filter checks only',
      'Do not dismantle the blower housing unless qualified',
      'Unplug before any internal access',
      'Escalate for blower wheel service',
    ],
    'stopProfessionalConditions': [
      'Burning smell, smoke, or sparking',
      'Blower housing disassembly required',
      'Severe metal grinding or wheel damage',
    ],
    'preventionActions': [
      'Clean the lint filter every load',
      'Check pockets for small items',
      'Keep the vent path clear',
    ],
    'toolsRequired': ['Flashlight for exterior checks'],
    'difficultyNotes':
        'Beginner exterior checks only. Blower service is professional.',
    'commonality': 'common',
    'safetyNotes':
        'Unplug before internal access. No beginner blower-housing teardown.',
    'allowResolvedWhenConfirmed': true,
    'preferProfessionalWhenNotConfirmed': true,
  },
  {
    'schemaVersion': '1.0',
    'id': 'cabinet-seal-or-air-leak-path',
    'title': 'Cabinet seal or air leak path',
    'applianceFamily': 'dryer',
    'symptomPhrasings': [
      'air leaking from dryer',
      'slow dry good vent',
      'feel air at door gap',
      'lint blowing inside laundry room',
    ],
    'immediateCause':
        'Air leaks out of the cabinet through a bad door seal, panel gap, or internal leak path instead of through the vent.',
    'rootCause':
        'Worn door gasket, loose panel, or internal air leak bypasses the exhaust path, reducing effective airflow through the load.',
    'contributingFactors': [
      'Worn door seal or felt',
      'Loose front or back panel',
      'Missing lint duct connection inside cabinet (professional)',
    ],
    'evidenceSupports': [
      {'templateId': 'cabinet-seal-gap', 'answer': 'Air leaks at door or panel gap'},
      {'templateId': 'exterior-airflow', 'answer': 'Normal'},
      {'templateId': 'vent-hose-condition', 'answer': 'Looks clear'},
      {'templateId': 'clothes-remain-damp', 'answer': 'Still damp'},
      {'templateId': 'dry-time-change', 'answer': 'Somewhat longer'},
    ],
    'evidenceExcludes': [
      {'templateId': 'exterior-airflow', 'answer': 'Weak'},
      {'templateId': 'exterior-airflow', 'answer': 'Almost none'},
      {'templateId': 'vent-hose-condition', 'answer': 'Yes, restricted'},
      {'templateId': 'cabinet-seal-gap', 'answer': 'No obvious leak felt'},
    ],
    'commonMisdiagnoses': [
      'Batch 01 restricted exhaust when exterior vent airflow is actually normal',
      'Batch 01 clogged lint pathway when the filter is clean but air leaks at the door',
      'Moisture sensor fault before checking for cabinet air leaks',
    ],
    'firstLineQuestions': [
      {
        'templateId': 'cabinet-seal-gap',
        'promptText':
            'With the dryer running, do you feel air leaking around the door, panel gaps, or inside the room rather than at the exterior vent?',
        'answerChoices': [
          'No obvious leak felt',
          'Air leaks at door or panel gap',
          'Lint or warm air in the room',
          'Not sure',
          'Other / describe',
        ],
      },
    ],
    'verificationAsk':
        'With exterior vent airflow looking normal and the visible hose clear, do you still feel air escaping at a door or panel gap during operation?',
    'verificationWhy':
        'Separates internal cabinet leaks from external vent restriction patterns.',
    'verificationSteps': [
      'Confirm lint filter is clean and exterior vent airflow looks normal',
      'Run briefly and feel for air at door/panel gaps (avoid hot surfaces)',
      'Unplug before any panel removal',
      'Escalate for seal or panel service',
    ],
    'safeGuidanceBoundary': [
      'External feel/listen checks only — avoid hot surfaces',
      'Do not remove panels unless qualified',
      'Seal and panel gasket replacement is typically professional',
    ],
    'stopProfessionalConditions': [
      'Burning smell, smoke, or sparking',
      'Panel disassembly or internal duct reconnection required',
      'Cabinet overheating',
    ],
    'preventionActions': [
      'Replace worn door seals when air leaks appear',
      'Ensure panels are seated after any prior service',
    ],
    'toolsRequired': ['None for external leak observation'],
    'difficultyNotes':
        'Leak observation is beginner-safe. Seal service is intermediate/pro.',
    'commonality': 'moderate',
    'safetyNotes': 'Avoid touching hot surfaces during running checks.',
    'allowResolvedWhenConfirmed': true,
    'preferProfessionalWhenNotConfirmed': true,
  },
  {
    'schemaVersion': '1.0',
    'id': 'internal-duct-lint-collapse',
    'title': 'Internal duct lint collapse or blockage',
    'applianceFamily': 'dryer',
    'symptomPhrasings': [
      'slow dry clear outside vent',
      'weak air hose looks fine',
      'lint packed inside dryer',
      'airflow poor internal blockage',
    ],
    'immediateCause':
        'Lint or a collapsed internal duct inside the cabinet blocks airflow before it reaches the exterior vent.',
    'rootCause':
        'Packed lint or a collapsed internal flex duct inside the dryer restricts air even when the exterior hose looks clear.',
    'contributingFactors': [
      'Long-term lint bypassing the filter',
      'Collapsed internal duct section',
      'Prior partial cleaning leaving internal packs',
    ],
    'evidenceSupports': [
      {'templateId': 'exterior-airflow', 'answer': 'Weak'},
      {'templateId': 'vent-hose-condition', 'answer': 'Looks clear'},
      {'templateId': 'lint-filter-condition', 'answer': 'Heavily clogged'},
      {'templateId': 'clothes-remain-damp', 'answer': 'Still damp'},
      {'templateId': 'dry-time-change', 'answer': 'Much longer'},
    ],
    'evidenceExcludes': [
      {'templateId': 'vent-hose-condition', 'answer': 'Yes, restricted'},
      {'templateId': 'exterior-airflow', 'answer': 'Normal'},
      {'templateId': 'clothes-feel-after-cycle', 'answer': 'Cold and still damp'},
      {'templateId': 'hazard-observation', 'answer': 'Yes'},
    ],
    'commonMisdiagnoses': [
      'Batch 01 restricted exhaust when the visible hose is clear but internal path is packed',
      'Batch 01 blower wheel obstruction when the issue is lint collapse in the internal duct',
      'Heating element failure when clothes are warm but damp with weak exterior air',
    ],
    'firstLineQuestions': [
      {
        'templateId': 'vent-hose-condition',
        'promptText': 'Is the visible vent hose crushed, kinked, or packed with lint?',
        'answerChoices': [
          'Looks clear',
          'Yes, restricted',
          'Not sure',
          'Other / describe',
        ],
      },
    ],
    'verificationAsk':
        'With the lint filter cleaned and the visible vent hose clear, is exterior airflow still weak on a short run?',
    'verificationWhy':
        'Weak air with a clear exterior hose points to internal duct blockage rather than hose crush alone.',
    'verificationSteps': [
      'Clean the lint filter thoroughly',
      'Confirm the visible vent hose is not crushed or packed',
      'Run and re-check exterior airflow',
      'If still weak, escalate for internal duct cleaning — do not dismantle cabinets as a beginner',
    ],
    'safeGuidanceBoundary': [
      'Lint filter and visible vent hose checks only',
      'Do not dismantle internal ductwork or cabinets as a beginner',
      'Internal duct cleaning is professional',
    ],
    'stopProfessionalConditions': [
      'Burning smell, smoke, melting, or sparking',
      'Cabinet disassembly required to reach internal duct',
      'Dryer still overheats after filter and hose cleaning',
    ],
    'preventionActions': [
      'Clean the lint filter before every load',
      'Vacuum accessible lint around the filter slot',
      'Schedule professional internal cleaning if slow dry persists with a clear hose',
    ],
    'toolsRequired': ['Vacuum for accessible lint (optional)', 'Flashlight'],
    'difficultyNotes':
        'Beginner filter/hose checks only. Internal duct work is professional.',
    'commonality': 'common',
    'safetyNotes': 'No beginner cabinet teardown for internal ducts.',
    'allowResolvedWhenConfirmed': true,
    'preferProfessionalWhenNotConfirmed': true,
  },
  {
    'schemaVersion': '1.0',
    'id': 'outdoor-vent-pest-nest',
    'title': 'Outdoor vent blocked by pest nest',
    'applianceFamily': 'dryer',
    'symptomPhrasings': [
      'bird nest in vent',
      'wasps in dryer vent',
      'blocked exterior hood nest',
      'no air at outside vent nest',
    ],
    'immediateCause':
        'A bird, insect, or rodent nest blocks the exterior vent hood, trapping moist exhaust air.',
    'rootCause':
        'Nesting material fills the exterior hood or short vent termination, restricting airflow despite an intact interior hose.',
    'contributingFactors': [
      'Missing or damaged vent hood screen',
      'Seasonal nesting activity',
      'Hood located in sheltered wall areas',
    ],
    'evidenceSupports': [
      {'templateId': 'vent-pest-blockage', 'answer': 'Nest or debris visible at hood'},
      {'templateId': 'vent-pest-blockage', 'answer': 'Hood flap will not open'},
      {'templateId': 'exterior-airflow', 'answer': 'Weak'},
      {'templateId': 'exterior-airflow', 'answer': 'Almost none'},
      {'templateId': 'vent-hose-condition', 'answer': 'Looks clear'},
      {'templateId': 'dry-time-change', 'answer': 'Much longer'},
    ],
    'evidenceExcludes': [
      {'templateId': 'exterior-airflow', 'answer': 'Normal'},
      {'templateId': 'vent-hose-condition', 'answer': 'Yes, restricted'},
      {'templateId': 'vent-pest-blockage', 'answer': 'Hood opens freely, no nest seen'},
      {'templateId': 'clothes-feel-after-cycle', 'answer': 'Cold and still damp'},
    ],
    'commonMisdiagnoses': [
      'Batch 01 restricted exhaust from hose crush when the hood is nest-blocked',
      'Internal duct collapse when a nest is visible at the exterior hood',
      'Heating element failure when clothes are warm but damp with blocked exterior air',
    ],
    'firstLineQuestions': [
      {
        'templateId': 'vent-pest-blockage',
        'promptText':
            'At the exterior vent hood, do you see nesting material or a flap that will not open?',
        'answerChoices': [
          'Hood opens freely, no nest seen',
          'Nest or debris visible at hood',
          'Hood flap will not open',
          'Cannot safely reach hood',
          'Not sure',
          'Other / describe',
        ],
      },
    ],
    'verificationAsk':
        'After safely clearing visible nesting debris from the exterior hood (no ladder risks beyond your comfort), is exterior vent airflow clearly stronger?',
    'verificationWhy':
        'Confirms a pest-specific exterior block rather than interior hose crush.',
    'verificationSteps': [
      'Unplug the dryer before moving it if needed',
      'Inspect the exterior hood from ground level or safe reach only',
      'Clear visible nest debris if safe — avoid live stinging insects; call pest control if needed',
      'Confirm the hood flap opens and re-check exterior airflow',
    ],
    'safeGuidanceBoundary': [
      'Exterior hood inspection and gentle debris removal only from safe reach',
      'Do not enter an active wasp/bee nest — call pest control',
      'Do not cut into walls to chase the vent',
      'Use a vent hood screen after clearing to reduce re-nesting',
    ],
    'stopProfessionalConditions': [
      'Active stinging insects or unsafe roof/ladder access',
      'Nest deep inside the wall vent beyond safe reach',
      'Burning smell, smoke, or continued overheating after hood clearing',
    ],
    'preventionActions': [
      'Install or maintain an exterior vent hood screen',
      'Inspect the hood seasonally',
      'Keep the lint filter clean to reduce lint buildup in the vent',
    ],
    'toolsRequired': ['Flashlight', 'Gloves (optional for debris removal)'],
    'difficultyNotes':
        'Ground-level hood checks are beginner-safe. Deep wall vent or pest removal may need pros.',
    'commonality': 'common',
    'safetyNotes': 'Avoid stinging insects and unsafe ladder work.',
    'allowResolvedWhenConfirmed': true,
    'preferProfessionalWhenNotConfirmed': true,
  },
  {
    'schemaVersion': '1.0',
    'id': 'long-duct-run-excessive-length',
    'title': 'Excessive vent duct run length',
    'applianceFamily': 'dryer',
    'symptomPhrasings': [
      'very long dryer vent',
      'slow dry long duct run',
      'multiple elbows vent',
      'weak air long run',
    ],
    'immediateCause':
        'The vent run is too long or has too many bends, so exhaust air cannot move efficiently.',
    'rootCause':
        'Excessive duct length, multiple elbows, or non-smooth duct material increases resistance and slows drying even when not fully blocked.',
    'contributingFactors': [
      'Vent run exceeds recommended length',
      'Multiple 90-degree elbows',
      'Long flexible plastic duct',
    ],
    'evidenceSupports': [
      {'templateId': 'duct-run-length', 'answer': 'Very long run or many elbows'},
      {'templateId': 'duct-run-length', 'answer': 'Not sure but run seems long'},
      {'templateId': 'exterior-airflow', 'answer': 'Weak'},
      {'templateId': 'dry-time-change', 'answer': 'Much longer'},
      {'templateId': 'vent-hose-condition', 'answer': 'Looks clear'},
      {'templateId': 'clothes-remain-damp', 'answer': 'Still damp'},
    ],
    'evidenceExcludes': [
      {'templateId': 'duct-run-length', 'answer': 'Short straight run'},
      {'templateId': 'exterior-airflow', 'answer': 'Normal'},
      {'templateId': 'vent-hose-condition', 'answer': 'Yes, restricted'},
      {'templateId': 'heat-observed', 'answer': 'No warmth'},
    ],
    'commonMisdiagnoses': [
      'Batch 01 restricted exhaust from crush when the hose is straight but excessively long',
      'Heating element failure when clothes are warm but dry times are long',
      'Moisture sensor fault before noting an unusually long vent layout',
    ],
    'firstLineQuestions': [
      {
        'templateId': 'duct-run-length',
        'promptText':
            'Roughly how long is the vent run from the dryer to the exterior hood (including elbows)?',
        'answerChoices': [
          'Short straight run',
          'Very long run or many elbows',
          'Not sure but run seems long',
          'Other / describe',
        ],
      },
    ],
    'verificationAsk':
        'With lint filter clean and no obvious hose crush, does the vent layout still involve a very long run or many elbows with weak exterior airflow?',
    'verificationWhy':
        'Separates layout resistance from crush/blockage patterns.',
    'verificationSteps': [
      'Trace the visible vent path and count elbows',
      'Clean lint filter and confirm no hose crush',
      'Note exterior airflow on a short run',
      'Consult a professional about shortening or smoothing the run if dry times stay long',
    ],
    'safeGuidanceBoundary': [
      'Visual layout assessment and lint/hose checks only',
      'Do not cut into walls or re-route duct as a beginner',
      'Professional vent routing may be needed to shorten the run',
    ],
    'stopProfessionalConditions': [
      'Need to re-route or rebuild in-wall vent (professional)',
      'Burning smell, smoke, or overheating',
      'Weak air plus visible nest or crush (check other modes first)',
    ],
    'preventionActions': [
      'Use the shortest, smoothest vent run practical',
      'Limit elbows and avoid long flexible plastic duct',
      'Clean lint filter every load',
    ],
    'toolsRequired': ['Flashlight for tracing visible duct'],
    'difficultyNotes':
        'Layout observation is beginner-safe. Re-routing is professional.',
    'commonality': 'common',
    'safetyNotes': 'No in-wall duct modification as a beginner.',
    'allowResolvedWhenConfirmed': true,
    'preferProfessionalWhenNotConfirmed': true,
  },
  {
    'schemaVersion': '1.0',
    'id': 'moisture-sensor-bars-contaminated',
    'title': 'Moisture sensor bars contaminated',
    'applianceFamily': 'dryer',
    'symptomPhrasings': [
      'auto dry ends too soon',
      'clothes damp cycle says done',
      'sensor dry stops early',
      'dryer thinks clothes are dry',
    ],
    'immediateCause':
        'Contaminated moisture sensor bars misread dryness, so auto-dry cycles end while clothes are still damp.',
    'rootCause':
        'Fabric softener residue, lint, or coating on the sensor bars prevents accurate moisture detection.',
    'contributingFactors': [
      'Fabric softener sheet residue',
      'Lint coating on sensor bars',
      'Using auto-dry on very small loads',
    ],
    'evidenceSupports': [
      {'templateId': 'moisture-sensor-bars', 'answer': 'Visible residue on bars'},
      {'templateId': 'moisture-sensor-bars', 'answer': 'Auto-dry ends early, clothes damp'},
      {'templateId': 'clothes-remain-damp', 'answer': 'Still damp'},
      {'templateId': 'exterior-airflow', 'answer': 'Normal'},
      {'templateId': 'heat-observed', 'answer': 'Normal heat'},
      {'templateId': 'dry-time-change', 'answer': 'Somewhat longer'},
    ],
    'evidenceExcludes': [
      {'templateId': 'exterior-airflow', 'answer': 'Weak'},
      {'templateId': 'exterior-airflow', 'answer': 'Almost none'},
      {'templateId': 'heat-observed', 'answer': 'No warmth'},
      {'templateId': 'moisture-sensor-bars', 'answer': 'Bars look clean, timed dry works normally'},
      {'templateId': 'vent-hose-condition', 'answer': 'Yes, restricted'},
    ],
    'commonMisdiagnoses': [
      'Batch 01 restricted exhaust when exterior airflow and heat are normal',
      'Heating element failure when heat is present but auto-dry stops early',
      'Batch 01 overloaded load when auto-dry misreads even on normal loads',
    ],
    'firstLineQuestions': [
      {
        'templateId': 'moisture-sensor-bars',
        'promptText':
            'Inside the drum, do the moisture sensor bars look coated or does auto-dry stop while clothes are still damp?',
        'answerChoices': [
          'Bars look clean, timed dry works normally',
          'Visible residue on bars',
          'Auto-dry ends early, clothes damp',
          'Not sure / cannot see bars',
          'Other / describe',
        ],
      },
    ],
    'verificationAsk':
        'After gently cleaning the sensor bars with rubbing alcohol on a cloth (dryer unplugged, per manual), does auto-dry finish with clothes actually dry on a normal load?',
    'verificationWhy':
        'Confirms sensor contamination rather than vent or heat failure.',
    'verificationSteps': [
      'Unplug the dryer',
      'Locate moisture sensor bars inside the drum (usually near the filter area)',
      'Gently wipe bars with rubbing alcohol on a soft cloth — no scraping',
      'Restore power and run auto-dry on a normal test load',
    ],
    'safeGuidanceBoundary': [
      'Unplug before wiping sensor bars',
      'Gentle alcohol wipe only — no abrasive scrubbing or disassembly',
      'If timed dry works but auto-dry still stops early after cleaning, escalate',
      'Do not open control boards or probe sensor wiring',
    ],
    'stopProfessionalConditions': [
      'Sensor wiring or board diagnosis required',
      'Burning smell, smoke, or sparking',
      'Auto-dry still fails after gentle cleaning on normal loads with good airflow',
    ],
    'preventionActions': [
      'Wipe sensor bars periodically',
      'Avoid overusing fabric softener sheets',
      'Use timed dry for very small loads if auto-dry misreads',
    ],
    'toolsRequired': ['Rubbing alcohol', 'Soft cloth'],
    'difficultyNotes':
        'Bar wipe is beginner-safe. Sensor replacement is professional.',
    'commonality': 'high',
    'safetyNotes': 'Unplug before cleaning bars. No wiring work.',
    'allowResolvedWhenConfirmed': true,
    'preferProfessionalWhenNotConfirmed': true,
  },
  {
    'schemaVersion': '1.0',
    'id': 'control-locked-or-child-lock',
    'title': 'Control locked or child lock blocking changes',
    'applianceFamily': 'dryer',
    'symptomPhrasings': [
      'buttons locked',
      'cannot change settings',
      'child lock icon on',
      'panel responds but settings frozen',
    ],
    'immediateCause':
        'Control Lock / Child Lock is active, preventing cycle or setting changes even though the panel may still display.',
    'rootCause':
        'The lock feature is engaged and must be cleared with the model-specific unlock sequence before settings or Start will respond normally.',
    'contributingFactors': [
      'Accidental long-press on a lock key',
      'Shared laundry users leaving lock on',
      'Unfamiliar control icons',
    ],
    'evidenceSupports': [
      {'templateId': 'control-lock-status', 'answer': 'Lock on'},
      {'templateId': 'panel-lights', 'answer': 'Yes, panel responds'},
      {'templateId': 'dryer-response', 'answer': 'Nothing happens'},
    ],
    'evidenceExcludes': [
      {'templateId': 'control-lock-status', 'answer': 'Lock off / not shown'},
      {'templateId': 'dryer-response', 'answer': 'Starts normally'},
      {'templateId': 'dryer-response', 'answer': 'Hums but does not start'},
      {'templateId': 'panel-lights', 'answer': 'No lights at all'},
    ],
    'commonMisdiagnoses': [
      'Batch 01 start switch failure when lock icon is visible',
      'Batch 01 door switch failure when the lock is actually on',
      'Control board failure before trying the unlock sequence',
    ],
    'firstLineQuestions': [
      {
        'templateId': 'control-lock-status',
        'promptText':
            'Look at the control panel: do you see a lock icon or '
            'Control Lock / Child Lock light?',
        'answerChoices': [
          'Lock off / not shown',
          'Lock on',
          'Not sure',
          'Other / describe',
        ],
      },
    ],
    'verificationAsk':
        'After turning Control Lock off using the model\'s unlock method, can you change settings and start a cycle normally?',
    'verificationWhy':
        'Distinguishes an active lock from start-switch or door-switch faults.',
    'verificationSteps': [
      'Look for a lock indicator on the display/panel',
      'Use the manual\'s unlock sequence (often a 3-second hold) — no tools',
      'Retry changing settings and Start with the door firmly closed',
    ],
    'safeGuidanceBoundary': [
      'Settings/unlock only — no tools or wiring',
      'If no lock feature exists and controls remain frozen, escalate',
      'Do not force the console apart',
    ],
    'stopProfessionalConditions': [
      'Burning smell, smoke, or sparking',
      'Unlock sequence fails and controls remain dead with no lock indicator — escalate',
    ],
    'preventionActions': [
      'Know how to toggle Control Lock on your model',
      'Check for a lock icon before assuming a parts failure',
    ],
    'toolsRequired': ['Owner manual or model unlock tip (optional)'],
    'difficultyNotes': 'Beginner settings check.',
    'commonality': 'high',
    'safetyNotes': 'Settings only. No electrical work.',
    'allowResolvedWhenConfirmed': true,
    'preferProfessionalWhenNotConfirmed': true,
  },
  {
    'schemaVersion': '1.0',
    'id': 'door-not-fully-latched-intermittent',
    'title': 'Door not fully latched (intermittent)',
    'applianceFamily': 'dryer',
    'symptomPhrasings': [
      'door opens mid cycle',
      'starts then stops randomly',
      'door seems closed but not latched',
      'intermittent door problem',
    ],
    'immediateCause':
        'The door intermittently loses latch contact, pausing or stopping the cycle even when it appears closed.',
    'rootCause':
        'A worn strike, weak spring, or failing door switch makes latch contact unreliable under vibration.',
    'contributingFactors': [
      'Worn door catch or hinge',
      'Loose door switch mount (professional)',
      'Heavy loads shifting the door',
    ],
    'evidenceSupports': [
      {'templateId': 'door-latch-intermittent', 'answer': 'Cycle pauses or stops mid-run'},
      {'templateId': 'door-latch-intermittent', 'answer': 'Door looks closed but not fully latched'},
      {'templateId': 'dryer-response', 'answer': 'Starts then stops'},
      {'templateId': 'door-closed-firmly', 'answer': 'Soft close / no click'},
    ],
    'evidenceExcludes': [
      {'templateId': 'door-closed-firmly', 'answer': 'Clicks shut firmly'},
      {'templateId': 'dryer-response', 'answer': 'Nothing happens'},
      {'templateId': 'dryer-response', 'answer': 'Starts normally'},
      {'templateId': 'door-latch-intermittent', 'answer': 'Door latches firmly every time'},
      {'templateId': 'panel-lights', 'answer': 'No lights at all'},
    ],
    'commonMisdiagnoses': [
      'Batch 01 door switch failure when the door clicks firmly every time',
      'Control board failure when the pattern is mid-cycle pause with a soft latch',
      'Batch 01 motor failure when the drum was tumbling before the pause',
    ],
    'firstLineQuestions': [
      {
        'templateId': 'door-latch-intermittent',
        'promptText':
            'Does the cycle pause or stop mid-run, or does the door look closed without a firm latch click?',
        'answerChoices': [
          'Door latches firmly every time',
          'Cycle pauses or stops mid-run',
          'Door looks closed but not fully latched',
          'Will not start at all',
          'Not sure',
          'Other / describe',
        ],
      },
    ],
    'verificationAsk':
        'When you press the door until it clicks firmly, does the cycle still pause or stop mid-run on vibration?',
    'verificationWhy':
        'Separates intermittent latch loss from a steady won\'t-start door switch fault.',
    'verificationSteps': [
      'Close the door until you feel/hear a firm click',
      'Run a cycle and note any mid-run pause',
      'Inspect strike/catch wear visually if accessible — no switch bypass',
      'Escalate for latch or switch service if intermittent',
    ],
    'safeGuidanceBoundary': [
      'Never bypass the door switch or safety interlock',
      'Firm door click and visual strike check only',
      'Do not probe switch terminals live',
      'Latch or switch replacement is professional if intermittent continues',
    ],
    'stopProfessionalConditions': [
      'Any plan to jumper/bypass the door switch',
      'Switch or strike replacement requiring wiring work',
      'Burning smell, smoke, or sparking',
    ],
    'preventionActions': [
      'Close the door firmly until it latches',
      'Replace a worn catch before it stops latching reliably',
      'Avoid overloading that shifts the door',
    ],
    'toolsRequired': ['None for latch observation'],
    'difficultyNotes':
        'Latch feel checks are beginner-safe. Switch replacement is professional.',
    'commonality': 'common',
    'safetyNotes': 'Never bypass the door switch or safety interlock.',
    'allowResolvedWhenConfirmed': true,
    'preferProfessionalWhenNotConfirmed': true,
  },
  {
    'schemaVersion': '1.0',
    'id': 'start-capacitor-or-start-assist-weak',
    'title': 'Weak start capacitor or start assist',
    'applianceFamily': 'dryer',
    'symptomPhrasings': [
      'slow to start tumbling',
      'hum then starts',
      'motor hesitates then runs',
      'takes long time to spin up',
    ],
    'immediateCause':
        'The motor start assist (capacitor or start winding path) is weak, so the motor hesitates before reaching full speed.',
    'rootCause':
        'A failing start capacitor or start switch/winding path cannot provide enough starting torque, causing delay or hum-before-start.',
    'contributingFactors': [
      'Age-related capacitor failure',
      'High-load start with a seized roller or idler',
      'Repeated start attempts overheating the assist circuit',
    ],
    'evidenceSupports': [
      {'templateId': 'motor-audible', 'answer': 'Hum / struggle only'},
      {'templateId': 'dryer-response', 'answer': 'Hums but does not start'},
      {'templateId': 'drum-turns', 'answer': 'Turns briefly then stops'},
      {'templateId': 'running-noise', 'answer': 'Hum'},
      {'templateId': 'door-closed-firmly', 'answer': 'Clicks shut firmly'},
    ],
    'evidenceExcludes': [
      {'templateId': 'motor-audible', 'answer': 'Silent — no motor sound'},
      {'templateId': 'dryer-response', 'answer': 'Nothing happens'},
      {'templateId': 'door-closed-firmly', 'answer': 'Soft close / no click'},
      {'templateId': 'drum-turns', 'answer': 'Motor runs, drum still'},
      {'templateId': 'drum-turns', 'answer': 'Turns normally'},
      {'templateId': 'panel-lights', 'answer': 'No lights at all'},
    ],
    'commonMisdiagnoses': [
      'Batch 01 motor failure when the motor eventually starts after a hum',
      'Broken belt when the drum does move after a delayed start',
      'Door switch failure when the door clicks firmly and a hum is present',
    ],
    'firstLineQuestions': [
      {
        'templateId': 'motor-audible',
        'promptText':
            'While the dryer tries to run, do you hear the motor humming or whirring?',
        'answerChoices': [
          'Yes, clear motor sound',
          'Hum / struggle only',
          'Silent — no motor sound',
          'Not sure',
          'Other / describe',
        ],
      },
    ],
    'verificationAsk':
        'With the door firmly latched, does Start produce a hum or delay before the drum eventually turns (or fail to reach speed)?',
    'verificationWhy':
        'Separates weak start assist from persistent motor failure or broken belt patterns.',
    'verificationSteps': [
      'Confirm the door clicks firmly shut',
      'Press Start once and listen for hum then delayed start',
      'Do not repeat rapid start attempts that overheat the motor',
      'Escalate for capacitor/motor start service',
    ],
    'safeGuidanceBoundary': [
      'Do not repeatedly hammer Start if the motor only hums',
      'Never open live motor or capacitor wiring',
      'Start capacitor testing and replacement are professional tasks',
      'Unplug if you smell hot insulation',
    ],
    'stopProfessionalConditions': [
      'Hum with burning smell, smoke, or sparking',
      'Any capacitor or motor electrical testing',
      'Cabinet access for capacitor replacement',
    ],
    'preventionActions': [
      'Address belt/roller drag before it overloads motor starts',
      'Do not run repeated start attempts on a humming motor',
    ],
    'toolsRequired': ['None for external listening'],
    'difficultyNotes':
        'Listening only for beginners. Capacitor service is professional.',
    'commonality': 'moderate',
    'safetyNotes': 'Capacitors store charge — no beginner electrical work.',
    'allowResolvedWhenConfirmed': false,
    'preferProfessionalWhenNotConfirmed': true,
  },
  {
    'schemaVersion': '1.0',
    'id': 'motor-overheat-protector-open',
    'title': 'Motor overheat protector open',
    'applianceFamily': 'dryer',
    'symptomPhrasings': [
      'dryer stopped mid cycle cool down',
      'motor hot will not restart',
      'worked then quit until cooled',
      'overheat reset on motor',
    ],
    'immediateCause':
        'The motor thermal protector opened after the motor overheated, stopping the dryer until it cools.',
    'rootCause':
        'Restricted airflow, mechanical drag, or repeated starts drove motor temperature high enough to trip the built-in protector.',
    'contributingFactors': [
      'Lint restriction raising motor area heat',
      'Seized rollers or blower drag',
      'Repeated start attempts on a struggling motor',
    ],
    'evidenceSupports': [
      {'templateId': 'motor-overheat-cooldown', 'answer': 'Stopped hot, restarts after cooling'},
      {'templateId': 'motor-overheat-cooldown', 'answer': 'Motor area felt very hot'},
      {'templateId': 'recent-overheat', 'answer': 'Yes, very hot or shut off from heat'},
      {'templateId': 'dryer-response', 'answer': 'Starts then stops'},
      {'templateId': 'running-noise', 'answer': 'Hum'},
    ],
    'evidenceExcludes': [
      {'templateId': 'motor-overheat-cooldown', 'answer': 'No overheat, stops immediately cold'},
      {'templateId': 'dryer-response', 'answer': 'Nothing happens'},
      {'templateId': 'panel-lights', 'answer': 'No lights at all'},
      {'templateId': 'door-closed-firmly', 'answer': 'Soft close / no click'},
    ],
    'commonMisdiagnoses': [
      'Batch 01 thermal fuse open (heater path, not motor cooldown pattern)',
      'Batch 01 motor failure when restart succeeds after cooling',
      'Door switch failure when the stop follows a hot run period',
    ],
    'firstLineQuestions': [
      {
        'templateId': 'motor-overheat-cooldown',
        'promptText':
            'Did the dryer stop after running hot, then restart only after cooling for 30+ minutes?',
        'answerChoices': [
          'Stopped hot, restarts after cooling',
          'Motor area felt very hot',
          'No overheat, stops immediately cold',
          'Not sure',
          'Other / describe',
        ],
      },
    ],
    'verificationAsk':
        'After letting the dryer cool unplugged for at least 30 minutes and cleaning the lint filter, does it start and run normally on a light load?',
    'verificationWhy':
        'Confirms motor protector cooldown rather than a steady dead motor or door switch fault.',
    'verificationSteps': [
      'Unplug the dryer and let it cool at least 30 minutes',
      'Clean the lint filter and check visible vent path',
      'Restore power and try a light load',
      'If it stops hot again quickly, escalate — do not bypass protectors',
    ],
    'safeGuidanceBoundary': [
      'Cooldown, lint, and vent checks only',
      'Never bypass motor thermal protectors',
      'No live motor wiring or protector testing',
      'Repeated hot stops → professional motor/mechanical service',
    ],
    'stopProfessionalConditions': [
      'Burning smell, smoke, sparking, or hot insulation odor',
      'Motor protector trips again on a light load after cooldown',
      'Any motor wiring or protector replacement work',
    ],
    'preventionActions': [
      'Keep lint and vent paths clear',
      'Do not repeat start attempts on a humming motor',
      'Service belt/roller/blower drag before motor overheats',
    ],
    'toolsRequired': ['None for cooldown and lint checks'],
    'difficultyNotes':
        'Cooldown and lint checks are beginner-safe. Motor service is professional.',
    'commonality': 'moderate',
    'safetyNotes':
        'Never bypass motor thermal protection. Stop for smoke or burning smell.',
    'allowResolvedWhenConfirmed': true,
    'preferProfessionalWhenNotConfirmed': true,
  },
  {
    'schemaVersion': '1.0',
    'id': 'gas-dryer-no-ignition-professional-only',
    'title': 'Gas dryer no ignition (professional only)',
    'applianceFamily': 'dryer',
    'symptomPhrasings': [
      'gas dryer tumbles no heat',
      'no flame in gas dryer',
      'gas dryer cold air',
      'gas valve clicks no ignition',
    ],
    'immediateCause':
        'The gas dryer tumbles on a heat cycle but the burner does not ignite, so no heat is produced.',
    'rootCause':
        'Gas ignition system, valve, or flame-sensing fault — gas appliance repair requires a qualified gas technician.',
    'contributingFactors': [
      'Closed gas supply valve',
      'Failed igniter or gas valve coil (professional)',
      'Flame sensor fault (professional)',
    ],
    'evidenceSupports': [
      {'templateId': 'gas-dryer-type', 'answer': 'Yes, gas dryer'},
      {'templateId': 'gas-ignition-observed', 'answer': 'No flame / no ignition'},
      {'templateId': 'gas-ignition-observed', 'answer': 'Not sure, cannot see burner'},
    ],
    'evidenceExcludes': [
      {'templateId': 'gas-dryer-type', 'answer': 'Electric dryer'},
      {'templateId': 'gas-ignition-observed', 'answer': 'Flame visible, normal heat'},
      {'templateId': 'heat-observed', 'answer': 'Normal heat'},
      {'templateId': 'cycle-heat-setting', 'answer': 'No, air-only / fluff'},
      {'templateId': 'hazard-observation', 'answer': 'Yes'},
    ],
    'commonMisdiagnoses': [
      'Batch 01 heating element failed on a gas dryer',
      'DIY gas valve or igniter replacement attempts',
      'Batch 01 air-fluff cycle when gas supply or ignition is the issue',
    ],
    'firstLineQuestions': [
      {
        'templateId': 'gas-dryer-type',
        'promptText':
            'Is this a gas dryer (gas line/supply valve present) rather than an all-electric dryer?',
        'answerChoices': [
          'Yes, gas dryer',
          'Electric dryer',
          'Not sure',
          'Other / describe',
        ],
      },
      {
        'templateId': 'gas-ignition-observed',
        'promptText':
            'On a heat cycle with the drum turning, do you observe burner ignition or warmth within the first few minutes?',
        'answerChoices': [
          'Flame visible, normal heat',
          'No flame / no ignition',
          'Not sure, cannot see burner',
          'Gas-like odor present',
          'Other / describe',
        ],
      },
    ],
    'verificationAsk':
        'After confirming the household gas supply valve is fully open (external valve only) and the cycle is set to heat, is there still no warmth or visible ignition?',
    'verificationWhy':
        'External gas supply and cycle checks only — ignition repair is never DIY.',
    'verificationSteps': [
      'Confirm this is a gas dryer and a heat cycle is selected',
      'Confirm the external gas supply valve is fully open — do not disassemble gas lines',
      'Run a short cycle; if gas odor is present, stop, ventilate, leave, and call emergency services per local guidance',
      'If no odor but no heat/ignition, call a qualified gas appliance technician',
    ],
    'safeGuidanceBoundary': [
      'External gas supply valve and cycle setting checks only',
      'Do not disassemble gas lines, burners, igniters, or valves',
      'Do not attempt gas ignition repair — call a qualified gas technician',
      'If gas odor is present, stop use, ventilate, evacuate if needed, and follow gas emergency procedures',
      'No live gas component testing',
    ],
    'stopProfessionalConditions': [
      'Any gas odor — follow gas emergency procedures',
      'Any need to service igniter, gas valve, burner, or flame sensor',
      'Burning smell, smoke, or carbon monoxide symptoms',
      'User asks for DIY gas ignition repair steps',
    ],
    'preventionActions': [
      'Keep lint and vent paths clear on gas dryers too',
      'Ensure the external gas supply valve stays accessible and fully open during use',
      'Schedule professional gas appliance service when ignition fails',
    ],
    'toolsRequired': ['None — external checks only; call gas technician'],
    'difficultyNotes':
        'Not a DIY repair path. External supply checks only, then professional gas service.',
    'commonality': 'common',
    'safetyNotes':
        'Gas ignition faults require a qualified gas technician. Never guide DIY gas valve or burner repair.',
    'allowResolvedWhenConfirmed': false,
    'preferProfessionalWhenNotConfirmed': true,
  },
];
