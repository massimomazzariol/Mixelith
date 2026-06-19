import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/batch_image_picker.dart';

final batchImagePickerProvider = Provider<BatchImagePicker>(
  (ref) => const MethodChannelBatchImagePicker(),
);
