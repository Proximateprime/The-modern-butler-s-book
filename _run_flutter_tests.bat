@echo off
cd /d B:\
flutter test ^
  test/deterministic_services_equivalence_test.dart ^
  test/diagnostic_reasoning_test.dart ^
  test/dryer_mvp_paths_test.dart ^
  test/system_driven_interview_test.dart ^
  test/thermal_fuse_close_path_test.dart ^
  test/primary_verification_resolve_test.dart ^
  test/safety_stop_test.dart ^
  test/answer_ranking_acceptance_test.dart ^
  --reporter compact
exit /b %ERRORLEVEL%
