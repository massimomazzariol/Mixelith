enum ImageSourceFormat {
  jpeg,
  png,
  webp,
  heic,
  heif,
  unknown;

  bool get isHeifFamily =>
      this == ImageSourceFormat.heic || this == ImageSourceFormat.heif;

  String get displayLabel => switch (this) {
    ImageSourceFormat.jpeg => 'JPEG',
    ImageSourceFormat.png => 'PNG',
    ImageSourceFormat.webp => 'WEBP',
    ImageSourceFormat.heic => 'HEIC',
    ImageSourceFormat.heif => 'HEIF',
    ImageSourceFormat.unknown => 'Unknown',
  };
}

ImageSourceFormat imageSourceFormatFromExtension(String? extension) {
  final normalized = extension?.trim().toLowerCase().replaceFirst(
    RegExp(r'^\.+'),
    '',
  );
  return switch (normalized) {
    'jpg' || 'jpeg' => ImageSourceFormat.jpeg,
    'png' => ImageSourceFormat.png,
    'webp' => ImageSourceFormat.webp,
    'heic' => ImageSourceFormat.heic,
    'heif' => ImageSourceFormat.heif,
    _ => ImageSourceFormat.unknown,
  };
}

ImageSourceFormat imageSourceFormatFromMimeType(String? mimeType) {
  return switch (mimeType?.trim().toLowerCase()) {
    'image/jpeg' || 'image/jpg' => ImageSourceFormat.jpeg,
    'image/png' => ImageSourceFormat.png,
    'image/webp' => ImageSourceFormat.webp,
    'image/heic' => ImageSourceFormat.heic,
    'image/heif' => ImageSourceFormat.heif,
    _ => ImageSourceFormat.unknown,
  };
}

ImageSourceFormat imageSourceFormatFromPath(String path) {
  final filename = path.split(RegExp(r'[\\/]')).last;
  final dotIndex = filename.lastIndexOf('.');
  if (dotIndex < 0 || dotIndex == filename.length - 1) {
    return ImageSourceFormat.unknown;
  }
  return imageSourceFormatFromExtension(filename.substring(dotIndex + 1));
}
