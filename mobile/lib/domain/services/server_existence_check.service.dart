import 'dart:async';
import 'dart:convert';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/domain/models/store.model.dart';
import 'package:immich_mobile/entities/store.entity.dart';
import 'package:immich_mobile/infrastructure/repositories/backup.repository.dart';
import 'package:immich_mobile/providers/api.provider.dart';
import 'package:immich_mobile/services/api.service.dart';
import 'package:logging/logging.dart';
import 'package:openapi/api.dart';

/// Asks the server which of our backup-selected local assets it already has
/// via EXIF metadata (`POST /assets/exist/metadata`) and stamps the matched
/// ones with the sentinel checksum so the backup hash step skips them.
///
/// Designed for the case where iPhone local IDs don't line up with the
/// server's `deviceAssetId` (e.g., a CLI-uploaded library on the server +
/// the same photos on the phone). Without this, every such photo gets
/// re-hashed and re-uploaded.
class ServerExistenceCheckService {
  static final _log = Logger('ServerExistenceCheckService');

  /// Batch size for the server call. The endpoint runs one indexed lookup
  /// per item, so keep payloads moderate to stay within reasonable request
  /// timeouts.
  static const int kBatchSize = 250;

  final DriftBackupRepository _backupRepo;
  final ApiService _apiService;

  ServerExistenceCheckService(this._backupRepo, this._apiService);

  /// Runs one pass: fetches unmatched candidates, asks the server, marks
  /// confirmed assets locally. Returns the number of newly matched assets.
  Future<int> run() async {
    final userId = Store.tryGet(StoreKey.currentUser)?.id;
    if (userId == null) {
      _log.fine('No current user, skipping');
      return 0;
    }

    final candidates = await _backupRepo.getUnmatchedBackupAssetMetadata(userId);
    if (candidates.isEmpty) {
      _log.fine('No unmatched candidates');
      return 0;
    }

    _log.info('Checking ${candidates.length} unmatched local assets against server');

    var totalMatched = 0;
    for (var i = 0; i < candidates.length; i += kBatchSize) {
      final end = (i + kBatchSize < candidates.length) ? i + kBatchSize : candidates.length;
      final batch = candidates.sublist(i, end);

      final body = {
        'assets': batch
            .map(
              (c) => {
                'localId': c.id,
                'fileCreatedAt': c.createdAt.toUtc().toIso8601String(),
                'width': c.width,
                'height': c.height,
              },
            )
            .toList(),
      };

      try {
        final response = await _apiService.assetsApi.apiClient.invokeAPI(
          '/assets/exist/metadata',
          'POST',
          const <QueryParam>[],
          jsonEncode(body),
          <String, String>{},
          <String, String>{},
          'application/json',
        );

        if (response.statusCode >= 400) {
          _log.warning('Batch ${i ~/ kBatchSize} failed: ${response.statusCode} ${response.body}');
          continue;
        }

        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final existingIdMap = (decoded['existingIdMap'] as Map?)?.cast<String, String>() ?? const <String, String>{};

        if (existingIdMap.isEmpty) {
          continue;
        }

        await _backupRepo.markAsServerConfirmed(existingIdMap.keys.toList(), remoteIdMap: existingIdMap);
        totalMatched += existingIdMap.length;
      } catch (error, stack) {
        _log.warning('Batch ${i ~/ kBatchSize} threw', error, stack);
      }
    }

    _log.info('$totalMatched matched / ${candidates.length} candidates');
    return totalMatched;
  }
}

final serverExistenceCheckServiceProvider = Provider<ServerExistenceCheckService>(
  (ref) => ServerExistenceCheckService(
    ref.watch(backupRepositoryProvider),
    ref.watch(apiServiceProvider),
  ),
);
