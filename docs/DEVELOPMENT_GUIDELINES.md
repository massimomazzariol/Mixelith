# Development Guidelines: Mixelith

These rules define the public technical workflow for contributing to Mixelith.

## Starting a Task

1. Run `git status` before starting any task.
2. Read the documents in `docs/` before modifying code or specifications.
3. Check `docs/WORKLOG.md` and `BACKLOG.md` for current status and next phases.
4. Stop if there are unexpected uncommitted changes.

## Naming

- Product Name: Mixelith.
- Flutter Project Name: `mixelith`.
- Android Package: `com.mixelith`.
- GitHub Repository: `https://github.com/massimomazzariol/Mixelith.git`.

Do not introduce historical names, alternative names, or different packages.

## V1/0.1.0 Prohibitions

- No `android.permission.INTERNET` permission.
- No network calls.
- No backend.
- No Firebase.
- No login or registration.
- No telemetry, analytics, or remote crash reporting.
- No ads.
- No machine learning in 0.1.0.
- No share sheet in 0.1.0.
- Camera only as a documented 0.1.0 feature, photo-only and without `RECORD_AUDIO`.
- No `wechat_assets_picker` in 0.1.0.
- No `image_picker` as the architectural base.
- No `flutter_mosaic` or `flutter_image_filters` in 0.1.0.

## Dependencies

Every new dependency must be:

- Discussed and documented in `docs/DEPENDENCY_DECISIONS.md`;
- Checked with `flutter pub deps`;
- Verified in the merged manifests after Android builds;
- Isolated behind adapters if it accesses the platform, filesystem, gallery, or rendering APIs.

## Code and Performance

- Prefer simple and readable Dart code.
- Do not introduce premature abstractions.
- Keep the UI separate from plugins and engines.
- Execute heavy CPU filters outside of the UI thread.
- Use a debounce for sliders and fast controls.
- Discard obsolete asynchronous results.
- Do not promise a constant frame rate for complex CPU processing.

## Checks Before Important Commits

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
flutter build apk --release
```

After Android builds, inspect the merged manifests to confirm the absence of forbidden permissions.

## Documentation

Update `docs/WORKLOG.md`, `docs/ROADMAP.md`, and `BACKLOG.md` whenever the project's status, architecture, dependencies, or operational priorities change.
