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

  ServerExistenceCheckService({
    required DriftBackupRepository backupRepository,
    required ApiService apiService,
  })  : _backupRepository = backupRepository,
        _apiService = apiService;

  /// Checks which unhashed backup assets already exist on the server
  /// and marks them with a sentinel checksum to skip hashing.
  /// Returns the number of assets confirmed on server.
  Future<int> checkAndMarkExistingAssets() async {
    try {
      final unhashedIds = await _backupRepository.getUnhashedBackupAssetIds();
      if (unhashedIds.isEmpty) return 0;

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
          await _backupRepository.markAsServerConfirmed(response.existingIds);
          confirmedCount += response.existingIds.length;
        }
      }

      _log.info(
        '$confirmedCount/${unhashedIds.length} assets confirmed on server, skipping hash',
      );
      return confirmedCount;
    } catch (e, s) {
      _log.warning('Server existence check failed, falling back to full hash', e, s);
      return 0;
    }
  }
}
