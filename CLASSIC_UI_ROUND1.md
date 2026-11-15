# Classic UI — round 1

This branch restores the primary v0.8.94 presentation on the v0.9.3 / PE business layer. It is the first implementation round. Advanced editors, request/connection records, logs and several tools intentionally keep their current presentation for round 2.

## Baselines

- PE source: `fc22d32069ee10b50bbc721acbe7ff5de35c6f05`.
- Official functional baseline: `be84736605527034689c95bf27828ff27d912c5e` (v0.9.3).
- Official visual reference: `7e7f1f89f363c31bbb7aa5af3f34a8b5c32a7a19` (v0.8.94).
- Flutter 3.47.6; core and Prism submodule commits remain pinned.
- Do not use PE's same-named tags as substitutes for official reference commits.

## Try the interface

Open Tools → Theme → Interface style → Classic interface. The default remains Modern interface for existing installations. In classic mode, Tools → Theme offers the reverse switch.

## Round 1 implementation

- A fixed mobile navigation bar and desktop NavigationRail, lazy page retention, per-destination navigation stacks and visibility/ticker scopes.
- A Material theme sharing the app's brightness, system/custom seed, selected font and text scale. The classic appearance screen includes theme modes, pure black, seed choices and text scaling.
- Independent classic dashboard card ordering and visibility, legacy identifier migration, layout editing, traffic charts, traffic totals, outbound mode, network address/exit information and platform-specific proxy/VPN/TUN controls.
- The classic start/stop FAB uses SetupAction and authoritative provider state.
- Proxy list/tab layouts, lazy node grids, current-node location, search, group/node delay tests, cancel, selected/pinned semantics, long-press/right-click menus (including add-to-local), delay state and layout/card-size settings use the new providers and actions.
- Profile card grid, subscription usage, selection, import from URL/file/QR, AGE key input, basic profile edit, sorting, preview, delete confirmation and batch-update failure details.
- Generic shared confirmation/alert messages use a Material renderer in classic mode. Existing complex input and feature-specific forms remain reusable and retain their own renderers. DNS queries, resources, disclaimer and developer tools remain reachable.
- No alternate core, database, configuration-generation pipeline or platform service state machine.

## Persistence

`AppSettingProps.classicUi` selects the presentation. `classicLayoutVersion` and `classicDashboard` store classic layout independently of modern `dashboardWidgets`. Legacy layout identifiers are captured before the modern layout migration normalizes them. A backup already rewritten by a newer version cannot recover original dimensions that are no longer present.

## Tests and builds

Implementation review: business operations remain in existing providers/actions; the new layer owns rendering, route stacks and form state. Core and Prism gitlinks and database schema are unchanged.

CI evidence from workflow [#43682094097](https://github.com/iqonli/FlClash_PE/actions/runs/43682094097) at source commit `3ab4c0d`:
- All 4,882 Dart tests passed, with 6 skipped; format and static analysis passed.
- All seven packaging jobs completed successfully: Android, Windows x64/ARM64, Linux x64/ARM64, and macOS Intel/ARM64. Separate desktop debug builds and Go/Rust/Android unit test jobs passed.
- The overall measured coverage was 86.30%. The new `lib/presentation` directory measured 43.7%; its own 43% initial coverage floor is now tracked in `tool/check_coverage.dart`, without reducing any established group floor. The earlier workflow's red status was solely the absence of that new floor, not a test or compile failure.
- Six viewport widths (360, 412, 600, 601, 800 and 1280 dp) were exercised with 18 synthetic-data preview images. These are rendering checks, not live-device tests.

The outstanding manual acceptance checks are: install/upgrade, classic ↔ modern presentation toggling while the core is running, profile import/update, node changes and delay tests, Android VPN/TUN permissions, desktop system proxy/TUN, connection restoration, and perceived performance on real devices. No results for these have been claimed.

The branch workflow generates localization and model code, formats it, commits generated output, analyzes the result, then checks and builds that exact generated SHA. Publishing a Release is not part of this workflow.

`test/presentation/classic_test.dart` covers persistence, legacy migration, independent dashboard edits, profile selection and unsaved form navigation. `classic_preview_test.dart` exercises shell navigation and produces 360, 412, 600, 601, 800 and 1280 dp previews with explicitly synthetic subscription/node data. Previews are not device screenshots or evidence of runtime proxy connectivity.

Real-device timing, installed application upgrade compatibility and manual platform service tests must be reported separately from widget/build results. Do not call this complete restoration of every screen.

## Round 2

- Fully restyle the request/live-connection feeds and details, DNS query feed and logs while keeping the current polling/filter/record infrastructure.
- Restyle advanced configuration, DNS/NTP/sniffer/TUN overrides, custom profiles, extension/script forms, resources, access control, font picker, backup/update/about/developer views and complex input dialogs.
- Finish pixel/geometry comparisons against v0.8.94, motion comparisons, accessibility and large-data/device performance validation.
- Confirm all newer feature entrances and platform/feature gates against the official baseline. Preserve the primary-page behavior tests while adapting additional views.

Local Flutter initialization was blocked by automatic approval review because it attempted to contact the instance metadata endpoint. No bypass was used. Generation, analysis, widget tests and package builds are delegated to the authorized GitHub Actions environment; local edits and offline formatting remain available.
