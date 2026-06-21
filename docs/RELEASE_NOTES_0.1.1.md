# Mixelith 0.1.1 Release Notes

Mixelith 0.1.1 is a bugfix release focused on HEIC/HEIF support.

## Highlights

- Adds HEIC/HEIF photo import support on Android.
- Keeps the original source file untouched.
- Preserves HEIC/HEIF as the default export format when supported by the device.
- Falls back to JPEG with a user-facing message if HEIC export is unavailable.
- Keeps the offline-first behavior and no `INTERNET` permission.
