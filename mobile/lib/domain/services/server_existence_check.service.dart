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

  static const int _batchSize = 5000;
  static const int _metadataBatchSize = 500;

  ServerExistenceCheckService({
    required DriftBackupRepository backupRepository,
    required ApiService apiService,
  })  : _backupRepository = backupRepository,
        _apiService = apiService;

  /// Checks which unhashed backup assets already exist on the server
  /// and marks them with a sentinel checksum to skip hashing.
  ///
  /// Phase 1: Match by deviceAssetId (fast, exact match for same device).
  /// Phase 2: Match remaining by metadata (filename + createdAt) for cross-device dedup.
  ///
  /// Returns the number of assets confirmed on server.
  Future<int> checkAndMarkExistingAssets() async {
    try {
      final unhashedIds = await _backupRepository.getUnhashedBackupAssetIds();
      if (unhashedIds.isEmpty) return 0;

      int confirmedCount = 0;

      // Phase 1: Match by deviceAssetId
      confirmedCount += await _checkByDeviceAssetIds(unhashedIds);

      // Phase 2: Metadata fallback for assets still unhashed after Phase 1
      confirmedCount += await _checkByMetadataFallback();

      _log.info(
        '$confirmedCount/${unhashedIds.length} assets confirmed on server, skipping hash',
      );
      return confirmedCount;
    } catch (e, s) {
      _log.warning('Server existence check failed, falling back to full hash', e, s);
      return 0;
    }
  }

  Future<int> _checkByDeviceAssetIds(List<String> unhashedIds) async {
    final String deviceId = Store.get(StoreKey.deviceId);
    int confirmedCount = 0;

    for (int i = 0; i < unhashedIds.length; i += _batchSize) {
      final batch = unhashedIds.sublist(
        i,
        i + _batchSize > unhashedIds.length ? unhashedIds.length : i + _batchSize,
      );

      final response = await _apiService.assetsApi.checkExistingAssets(
        CheckExistingAssetsDto(
          deviceAssetIds: batch,
          deviceId: deviceId,
        ),
      );

      if (response != null && response.existingIds.isNotEmpty) {
        await _backupRepository.markAsServerConfirmed(
          response.existingIds,
          remoteIdMap: response.existingIdMap,
        );
        confirmedCount += response.existingIds.length;
      }
    }

    return confirmedCount;
  }

  /// Matches remaining unmatched assets by filename + creation date.
  /// Includes both unhashed and hashed-but-not-on-server assets,
  /// excluding sentinel-marked ones (already confirmed by Phase 1).
  Future<int> _checkByMetadataFallback() async {
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
              .map((a) => CheckExistingAssetsByMetadataItem(
                    localId: a.id,
                    fileCreatedAt: a.createdAt,
                    width: a.width,
                    height: a.height,
                  ))
              .toList(),
        ),
      );

      if (response != null && response.existingIdMap.isNotEmpty) {
        final matchedIds = response.existingIdMap.keys.toList();
        await _backupRepository.markAsServerConfirmed(
          matchedIds,
          remoteIdMap: response.existingIdMap,
        );
        confirmedCount += matchedIds.length;
      }
    }

    if (confirmedCount > 0) {
      _log.info('Metadata fallback matched $confirmedCount additional assets');
    }

    return confirmedCount;
  }
}
