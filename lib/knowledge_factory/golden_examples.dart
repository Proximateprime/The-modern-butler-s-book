/// Built-in Knowledge Factory golden example JSON.
///
/// Mirrors [data/dryer_thermal_fuse_restricted_vent.v1.json] for compile-time
/// import without asset bundling. Keep both files aligned when editing.
const String dryerThermalFuseRestrictedVentGoldenJson = r'''
{
  "schemaVersion": "1.0",
  "id": "thermal-fuse-open",
  "title": "Thermal fuse open",
  "applianceFamily": "dryer",
  "symptomPhrasings": [
    "no heat",
    "drum turns but clothes stay cold",
    "no warmth on a heat cycle",
    "worked before a hot/overheat episode"
  ],
  "immediateCause": "The thermal fuse has opened and interrupted power to the heater circuit.",
  "rootCause": "The fuse opened after an overheating condition, most often from restricted exhaust airflow or a clogged lint pathway that prevented heat from leaving the cabinet.",
  "contributingFactors": [
    "Crushed, kinked, or lint-packed vent hose",
    "Blocked exterior vent hood",
    "Neglected lint filter cleaning",
    "Long flexible plastic vent runs that trap lint and restrict flow",
    "Repeated high-heat cycles with poor exhaust"
  ],
  "evidenceSupports": [
    { "templateId": "heat-observed", "answer": "No warmth" },
    { "templateId": "cycle-heat-setting", "answer": "Yes, heat cycle" },
    { "templateId": "recent-overheat", "answer": "Yes, very hot or shut off from heat" },
    { "templateId": "clothes-feel-after-cycle", "answer": "Cold and still damp" }
  ],
  "evidenceExcludes": [
    { "templateId": "heat-observed", "answer": "Normal heat" },
    { "templateId": "heat-observed", "answer": "Very hot" },
    { "templateId": "recent-overheat", "answer": "No" },
    { "templateId": "cycle-heat-setting", "answer": "No, air-only / fluff" },
    { "templateId": "exterior-airflow", "answer": "Normal" }
  ],
  "commonMisdiagnoses": [
    "Heating element failed (similar no-heat symptom; airflow history often differs)",
    "Timer or control board failure assumed without checking heat-cycle setting and vent path",
    "Supply/connection fault assumed when the drum still tumbles normally on a heat cycle"
  ],
  "firstLineQuestions": [
    {
      "templateId": "heat-observed",
      "promptText": "Is there any warmth after the dryer has run briefly?",
      "answerChoices": [
        "No warmth",
        "Slight warmth",
        "Normal heat",
        "Very hot",
        "Not sure",
        "Other / describe"
      ]
    },
    {
      "templateId": "recent-overheat",
      "promptText": "On a recent run, did the dryer feel unusually hot or stop early because of heat?",
      "answerChoices": [
        "Yes, very hot or shut off from heat",
        "No",
        "Not sure",
        "Other / describe"
      ]
    },
    {
      "templateId": "exterior-airflow",
      "promptText": "How strong is the airflow at the exterior vent while the dryer runs?",
      "answerChoices": [
        "Weak",
        "Almost none",
        "Normal",
        "Not sure",
        "Other / describe"
      ]
    }
  ],
  "verificationAsk": "With a heat cycle selected, the drum tumbling, and the lint filter and visible vent path already cleared, is there still no warmth at all on a short test run?",
  "verificationWhy": "A thermal fuse is a one-shot safety device. Clearing the vent corrects the overheating that opened it, but it cannot restore heat on its own. Still completely cold after the airflow path is clear matches an open fuse, which a technician must test and replace — confirming this does not mean the dryer is fixed.",
  "verificationSteps": [
    "Confirm the cycle is set to heat (not air-only / fluff)",
    "Clear the lint filter and the visible vent path so the overheating cause is corrected",
    "Restore power and run a short heat cycle with the drum turning",
    "Feel for warmth — still completely cold matches an open thermal fuse",
    "Stop here and book a technician; do not meter live circuits or jumper the fuse"
  ],
  "safeGuidanceBoundary": [
    "Unplug the dryer and turn OFF the dryer circuit breaker at the panel. Confirm the control panel shows no lights and Start does nothing.",
    "Do not measure live voltage, test the fuse while energized, or bypass it with foil, wire, or a jumper.",
    "Stop here and call a qualified technician to test and replace the thermal fuse. Confirming no warmth is not a completed repair.",
    "A new fuse alone without fixing restricted airflow can open again.",
    {
      "text": "With the dryer unplugged and the breaker off, you may open an accessible heater service panel to locate the thermal fuse.",
      "expert_ok": true
    },
    {
      "text": "If you can reach it without live testing, you may replace the fuse with an exact-match part. Never jumper it. Reassemble before restoring power.",
      "expert_ok": true
    }
  ],
  "stopProfessionalConditions": [
    "Burning smell, smoke, melting, sparking, or fire signs",
    "Need to test or replace the fuse with live electrical work",
    "Desire to bypass or jumper the thermal fuse",
    "Cabinet must be opened for heater-circuit diagnosis beyond beginner-safe checks"
  ],
  "preventionActions": [
    "Clean the lint filter before every load",
    "Inspect and clear the visible vent hose of crush, kinks, and packed lint",
    "Keep the exterior vent hood free of lint, nests, and debris",
    "Avoid long crushed flexible vent runs when a short smooth path is possible",
    "Stop using the dryer if it overheats or shuts off mid-cycle from heat until airflow is corrected"
  ],
  "toolsRequired": [
    "None for beginner airflow and isolation checks",
    "Screwdriver for Expert Mode panel work (optional)",
    "Flashlight (optional)"
  ],
  "difficultyNotes": "Beginner-safe work stops at heat-cycle confirmation, lint cleaning, and exterior vent observation. Fuse replacement and heater-circuit testing are professional tasks.",
  "commonality": "veryHigh",
  "safetyNotes": "Never bypass a thermal fuse. Replace only with power fully isolated. Fix restricted airflow after any fuse swap.",
  "allowResolvedWhenConfirmed": false,
  "preferProfessionalWhenNotConfirmed": true
}
''';
