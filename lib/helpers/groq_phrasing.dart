/// Barrel for the phrasing layer. Session / ranking are not rebuilt here.
///
/// Layout:
/// - [phrasing_request.dart] — typed slots for the seven ON hooks
/// - [phrasing_service.dart] — display strings only
/// - [phrasing_safety_gate.dart] — attach-map gates
/// - `lib/services/groq_phrasing_client.dart` — HTTP
library;

export 'phrasing_request.dart';
export 'phrasing_safety_gate.dart';
export 'phrasing_service.dart';
