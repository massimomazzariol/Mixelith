import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mixelith/features/batch/data/batch_image_picker.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('mixelith/batch_image_picker');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('pickImage invokes the single-photo native picker', () async {
    final methods = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          methods.add(call.method);
          return {
            'success': true,
            'status': 'picked',
            'pickerApi': 'android_photo_picker',
            'items': [
              {
                'id': 'photo-1',
                'path': '/cache/photo-1.jpg',
                'displayName': 'photo-1.jpg',
                'extension': 'jpg',
                'width': 4000,
                'height': 3000,
              },
            ],
          };
        });

    final result = await const MethodChannelBatchImagePicker(
      channel: channel,
    ).pickImage();

    expect(methods, ['pickImage']);
    expect(result.pickerApi, ImagePickerApi.androidPhotoPicker);
    expect(result.items.single.path, '/cache/photo-1.jpg');
    expect(result.items.single.width, 4000);
    expect(result.hasError, isFalse);
  });

  test('pickImages parses ACTION_OPEN_DOCUMENT fallback marker', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'pickImages');
          return {
            'success': true,
            'status': 'picked',
            'pickerApi': 'action_open_document',
            'items': [
              {
                'id': 'photo-1',
                'path': '/cache/photo-1.jpg',
                'displayName': 'photo-1.jpg',
                'extension': 'jpg',
                'width': 640,
                'height': 480,
              },
            ],
          };
        });

    final result = await const MethodChannelBatchImagePicker(
      channel: channel,
    ).pickImages();

    expect(result.pickerApi, ImagePickerApi.actionOpenDocument);
    expect(result.pickerApi.label, 'ACTION_OPEN_DOCUMENT');
    expect(result.items.single.height, 480);
  });
}
