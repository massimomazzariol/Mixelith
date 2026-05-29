enum MediaPermissionStatus {
  notDetermined,
  authorized,
  limited,
  denied,
  restricted,
}

extension MediaPermissionStatusAccess on MediaPermissionStatus {
  bool get hasAccess =>
      this == MediaPermissionStatus.authorized ||
      this == MediaPermissionStatus.limited;

  bool get isLimited => this == MediaPermissionStatus.limited;
}
