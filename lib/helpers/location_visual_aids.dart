/// AR_PARKED=true until a real curated (non-generated) diagram exists.
///
/// Do not flip this for CustomPaint schematics, SVG placeholders, or future
/// vision models. Re-enable later: set [arParked] to `false`. Pictures then
/// show only when [inspectHasCuratedImage] is true. Show me where stays gated
/// by [locationVisualAidsEnabled] in `session_screen.dart`.
const bool arParked = true;

/// Inverse of [arParked]. Keep false while AR / junk location pictures are off.
const bool locationVisualAidsEnabled = !arParked;
