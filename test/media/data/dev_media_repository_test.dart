import 'package:flutter_test/flutter_test.dart';
import 'package:mixelith/media/data/dev_media_repository.dart';
import 'package:mixelith/media/domain/media_asset_availability.dart';
import 'package:mixelith/media/domain/media_permission_status.dart';

void main() {
  test('DevMediaRepository exposes authorized placeholder assets', () async {
    const repository = DevMediaRepository();

    final permission = await repository.getPermissionStatus();
    final assets = await repository.getRecentAssets();
    final secondPage = await repository.getRecentAssets(page: 1);

    expect(permission, MediaPermissionStatus.authorized);
    expect(assets, hasLength(12));
    expect(assets.first.id, 'dev-preview-1');
    expect(assets.first.availability, MediaAssetAvailability.localAvailable);
    expect(secondPage, isEmpty);
  });

  test('DevMediaRepository resolves placeholder original files', () async {
    const repository = DevMediaRepository();
    final asset = (await repository.getRecentAssets()).first;

    final file = await repository.getOriginalFile(asset);

    expect(file, isNotNull);
    expect(file!.path, endsWith('.png'));
    expect(file.extension, 'png');
    expect(file.width, asset.width);
    expect(file.height, asset.height);
    expect(file.availability, MediaAssetAvailability.localAvailable);
  });
}
