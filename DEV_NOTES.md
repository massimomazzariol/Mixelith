# Dev Notes

## Git Workflow

- Run `git status` before starting any task.
- Keep commits small, readable, and focused.
- Do not push if tests or required builds fail.
- Do not push local backup branches or tags.
- Check `docs/WORKLOG.md` and `BACKLOG.md` before starting new phases.

## Verifications Before Important Commits

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
flutter build apk --release
```

After Android builds, check the merged manifests to confirm the absence of forbidden permissions.

## Basic Rollback

```bash
git restore .
git reset --hard HEAD
git revert <commit>
```

Do not use `git reset --hard HEAD` if there are unsaved or misunderstood changes. Create a backup first if there is any risk of losing useful work.
