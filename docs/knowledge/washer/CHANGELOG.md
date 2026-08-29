# washer-core changelog

## 0.2.3 (2026-08-22)

Second-pass primary paths (P2-09). No new appliance families.

- Drain-filter interview + inspect: packed vs clear. **Matches / OK** stores `No`; **Doesn't match** stores `Yes`. Clear trap excludes the filter mode.
- Against-evidence on hose look, taps vs screens, spin water vs unbalance, leak tap vs standpipe.
- Easy-check order: fill skips screens while a tap is closed; spin asks standing water before bunched load.
- Misdiagnoses: pump/panel first, screens-while-taps-closed, standing-water-as-motor.
- Latch close path: a firm click can finish as DIY; “otherwise call a technician” is fallback, not a hard pro-only stop.

Human sign-off: [`PACKAGE_RELEASE_CHECKLIST.md`](../PACKAGE_RELEASE_CHECKLIST.md).
