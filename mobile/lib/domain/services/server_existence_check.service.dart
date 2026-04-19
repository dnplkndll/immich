import 'package:immich_mobile/domain/models/store.model.dart';
import 'package:immich_mobile/entities/store.entity.dart';
import 'package:immich_mobile/infrastructure/repositories/backup.repository.dart';
import 'package:immich_mobile/services/api.service.dart';
import 'package:logging/logging.dart';
import 'package:openapi/api.dart';

class ServerExistenceCheckService {
  final DriftBackupRepository _backupRepository;
  final ApiService _apiService;
  final _log = Logger('ServerExistenceCheckService');

  static const int _metadataBatchSize = 500;

  ServerExistenceCheckService({required DriftBackupRepository backupRepository, required ApiService apiService})
    : _backupRepository = backupRepository,
      _apiService = apiService;

  /// Matches backup-selected assets to existing server assets by EXIF date +
  /// orientation-agnostic dimensions, then marks matched rows with a sentinel
  /// checksum so hashing + upload is skipped. Returns the number confirmed.
  Future<int> checkAndMarkExistingAssets() async {
    try {
      final String userId = Store.get(StoreKey.currentUser).id;
      final assetMetadata = await _backupRepository.getUnmatchedBackupAssetMetadata(userId);
      if (assetMetadata.isEmpty) return 0;

      int confirmedCount = 0;

      for (int i = 0; i < assetMetadata.length; i += _metadataBatchSize) {
        final batch = assetMetadata.sublist(
          i,
          i + _metadataBatchSize > assetMetadata.length ? assetMetadata.length : i + _metadataBatchSize,
        );

        final response = await _apiService.assetsApi.checkExistingAssetsByMetadata(
          CheckExistingAssetsByMetadataDto(
            assets: batch
                .where((a) => a.width > 0 && a.height > 0)
                .map(
                  (a) => CheckExistingAssetsByMetadataItem(
                    localId: a.id,
                    fileCreatedAt: a.createdAt,
                    width: a.width,
                    height: a.height,
                  ),
                )
                .toList(),
          ),
        );

        if (response != null && response.existingIdMap.isNotEmpty) {
          final matchedIds = response.existingIdMap.keys.toList();
          await _backupRepository.markAsServerConfirmed(matchedIds, remoteIdMap: response.existingIdMap);
          confirmedCount += matchedIds.length;
        }
      }

      _log.info('$confirmedCount/${assetMetadata.length} assets confirmed on server, skipping hash');
      return confirmedCount;
    } catch (e, s) {
      _log.warning('Server existence check failed, falling back to full hash', e, s);
      return 0;
    }
  }
}
