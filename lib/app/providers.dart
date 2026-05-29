import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../media/data/dev_media_repository.dart';
import '../media/data/photo_manager_media_repository.dart';
import '../media/domain/media_repository.dart';
import '../storage/data/path_provider_cache_service.dart';
import '../storage/domain/cache_service.dart';

final appTitleProvider = Provider<String>((ref) => 'Mixelith');

final mediaRepositoryProvider = Provider<MediaRepository>(
  (ref) => switch (defaultTargetPlatform) {
    TargetPlatform.windows => const DevMediaRepository(),
    _ => const PhotoManagerMediaRepository(),
  },
);

final cacheServiceProvider = Provider<CacheService>(
  (ref) => PathProviderCacheService(),
);
