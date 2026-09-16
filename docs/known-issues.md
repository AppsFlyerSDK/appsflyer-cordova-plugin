# Known Issues Log

Maintained by /al-debug. Checked before a fresh investigation; appended
after resolving one (or escalating one to an architecture question).

## iOS E2E HTTP 200 checks fail due to stale QA marker short-circuiting wait
- **Date:** 2026-09-16
- **Symptom:** `make e2e-ios` fails with 35/38 checks passed: `http_200_count` (Phase 1, found 1/3), `custom_event_http_200` (Phase 4, found 0/1), and `identity_event_http_200` (Phase 5, found 0/1).
- **Root cause:** Stale `af_qa_logs.txt` left on the booted simulator (`iPhone 16`) from an earlier failed/aborted run contained `[AF_QA][AUTO_APIS] --- Auto run complete ---`. In `scripts/af-scenario-runner.sh`, `wait_for_qa_marker` polled the file via `find ... -name af_qa_logs.txt` and immediately matched after 0s (`Marker observed after 0s`). The runner collected logs ~1s after app launch before the AppsFlyer SDK finished its network events. In Phase 4, the PID filter was additionally pointed at the terminated PID from before the `-deepLinkURL` trigger because `IOS_LAST_PID` was not updated after `xcrun simctl launch ... -deepLinkURL`.
- **Fix:** In `scripts/af-scenario-runner.sh`: (1) added `ios_get_qa_log_path` to query the specific app container via `xcrun simctl get_app_container` so unrelated/stale app containers are never picked up, (2) run unconditional `xcrun simctl uninstall` and remove any lingering `af_qa_logs.txt` on fresh-install phases, (3) dynamically update `IOS_LAST_PID` on deep-link launch output and live PID resolution, and (4) added 5s settling sleep after auto-run marker on iOS before log capture.
- **Tags:** race-condition | environment | logic
- **Status:** resolved
