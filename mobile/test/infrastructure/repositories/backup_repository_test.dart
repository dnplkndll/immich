import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:immich_mobile/constants/constants.dart';
import 'package:immich_mobile/domain/models/album/local_album.model.dart';
import 'package:immich_mobile/infrastructure/repositories/backup.repository.dart';
import 'package:immich_mobile/utils/option.dart';

import '../../medium/repository_context.dart';

void main() {
  late MediumRepositoryContext ctx;
  late DriftBackupRepository sut;

  setUp(() {
    ctx = MediumRepositoryContext();
    sut = DriftBackupRepository(ctx.db);
  });

  tearDown(() async {
    await ctx.dispose();
  });

  group('getAllCounts', () {
    late String userId;

    setUp(() async {
      final user = await ctx.newUser();
      userId = user.id;
    });

    test('returns zeros when no albums exist', () async {
      final result = await sut.getAllCounts(userId);
      expect(result.total, 0);
      expect(result.remainder, 0);
      expect(result.processing, 0);
    });

    test('returns zeros when no selected albums exist', () async {
      final album = await ctx.newLocalAlbum(backupSelection: BackupSelection.none);
      final asset = await ctx.newLocalAsset();
      await ctx.newLocalAlbumAsset(albumId: album.id, assetId: asset.id);

      final result = await sut.getAllCounts(userId);
      expect(result.total, 0);
      expect(result.remainder, 0);
      expect(result.processing, 0);
    });

    test('counts asset in selected album as total and remainder', () async {
      final album = await ctx.newLocalAlbum(backupSelection: BackupSelection.selected);
      final asset = await ctx.newLocalAsset();
      await ctx.newLocalAlbumAsset(albumId: album.id, assetId: asset.id);

      final result = await sut.getAllCounts(userId);
      expect(result.total, 1);
      expect(result.remainder, 1);
      expect(result.processing, 0);
    });

    test('backed up asset reduces remainder', () async {
      final album = await ctx.newLocalAlbum(backupSelection: BackupSelection.selected);
      final remote = await ctx.newRemoteAsset(ownerId: userId);
      final local = await ctx.newLocalAsset(checksum: remote.checksum);
      await ctx.newLocalAlbumAsset(albumId: album.id, assetId: local.id);

      final result = await sut.getAllCounts(userId);
      expect(result.total, 1);
      expect(result.remainder, 0);
      expect(result.processing, 0);
    });

    test('asset with null checksum is counted as processing', () async {
      final album = await ctx.newLocalAlbum(backupSelection: BackupSelection.selected);
      final asset = await ctx.newLocalAsset(checksumOption: const Option.none());
      await ctx.newLocalAlbumAsset(albumId: album.id, assetId: asset.id);

      final result = await sut.getAllCounts(userId);
      expect(result.total, 1);
      expect(result.remainder, 1);
      expect(result.processing, 1);
    });

    test('asset in excluded album is not counted even if also in selected album', () async {
      final selectedAlbum = await ctx.newLocalAlbum(backupSelection: BackupSelection.selected);
      final excludedAlbum = await ctx.newLocalAlbum(backupSelection: BackupSelection.excluded);
      final asset = await ctx.newLocalAsset();
      await ctx.newLocalAlbumAsset(albumId: selectedAlbum.id, assetId: asset.id);
      await ctx.newLocalAlbumAsset(albumId: excludedAlbum.id, assetId: asset.id);

      final result = await sut.getAllCounts(userId);
      expect(result.total, 0);
      expect(result.remainder, 0);
    });

    test('counts assets across multiple selected albums without duplicates', () async {
      final album1 = await ctx.newLocalAlbum(backupSelection: BackupSelection.selected);
      final album2 = await ctx.newLocalAlbum(backupSelection: BackupSelection.selected);
      final asset = await ctx.newLocalAsset();
      // Same asset in two selected albums
      await ctx.newLocalAlbumAsset(albumId: album1.id, assetId: asset.id);
      await ctx.newLocalAlbumAsset(albumId: album2.id, assetId: asset.id);

      final result = await sut.getAllCounts(userId);
      expect(result.total, 1);
    });

    test('backed up asset for different user is still counted as remainder', () async {
      final otherUser = await ctx.newUser();
      final album = await ctx.newLocalAlbum(backupSelection: BackupSelection.selected);
      final remote = await ctx.newRemoteAsset(ownerId: otherUser.id);
      final local = await ctx.newLocalAsset(checksum: remote.checksum);
      await ctx.newLocalAlbumAsset(albumId: album.id, assetId: local.id);

      final result = await sut.getAllCounts(userId);
      expect(result.total, 1);
      expect(result.remainder, 1);
    });

    test('mixed assets produce correct combined counts', () async {
      final selectedAlbum = await ctx.newLocalAlbum(backupSelection: BackupSelection.selected);

      // backed up
      final remote1 = await ctx.newRemoteAsset(ownerId: userId);
      final local1 = await ctx.newLocalAsset(checksum: remote1.checksum);
      await ctx.newLocalAlbumAsset(albumId: selectedAlbum.id, assetId: local1.id);

      // not backed up, has checksum
      final local2 = await ctx.newLocalAsset();
      await ctx.newLocalAlbumAsset(albumId: selectedAlbum.id, assetId: local2.id);

      // processing (null checksum)
      final local3 = await ctx.newLocalAsset(checksumOption: const Option.none());
      await ctx.newLocalAlbumAsset(albumId: selectedAlbum.id, assetId: local3.id);

      final result = await sut.getAllCounts(userId);
      expect(result.total, 3);
      expect(result.remainder, 2); // local2 + local3
      expect(result.processing, 1); // local3
    });

    test('sentinel-checksum asset counts as total but not remainder or processing', () async {
      final album = await ctx.newLocalAlbum(backupSelection: BackupSelection.selected);
      final asset = await ctx.newLocalAsset(checksum: kServerConfirmedChecksum);
      await ctx.newLocalAlbumAsset(albumId: album.id, assetId: asset.id);

      final result = await sut.getAllCounts(userId);
      expect(result.total, 1);
      expect(result.remainder, 0);
      expect(result.processing, 0);
    });

    test('mixed assets with sentinel produce correct counts', () async {
      final album = await ctx.newLocalAlbum(backupSelection: BackupSelection.selected);

      // server-confirmed (sentinel)
      final sentinel = await ctx.newLocalAsset(checksum: kServerConfirmedChecksum);
      await ctx.newLocalAlbumAsset(albumId: album.id, assetId: sentinel.id);

      // truly backed up (matched remote)
      final remote = await ctx.newRemoteAsset(ownerId: userId);
      final backedUp = await ctx.newLocalAsset(checksum: remote.checksum);
      await ctx.newLocalAlbumAsset(albumId: album.id, assetId: backedUp.id);

      // unhashed (processing)
      final unhashed = await ctx.newLocalAsset(checksumOption: const Option.none());
      await ctx.newLocalAlbumAsset(albumId: album.id, assetId: unhashed.id);

      // hashed but not on server
      final newAsset = await ctx.newLocalAsset();
      await ctx.newLocalAlbumAsset(albumId: album.id, assetId: newAsset.id);

      final result = await sut.getAllCounts(userId);
      expect(result.total, 4);
      expect(result.remainder, 2); // unhashed + newAsset
      expect(result.processing, 1); // unhashed
    });
  });

  group('getCandidates', () {
    late String userId;

    setUp(() async {
      final user = await ctx.newUser();
      userId = user.id;
    });

    test('returns empty list when no selected albums exist', () async {
      final album = await ctx.newLocalAlbum(backupSelection: BackupSelection.none);
      final asset = await ctx.newLocalAsset();
      await ctx.newLocalAlbumAsset(albumId: album.id, assetId: asset.id);

      final result = await sut.getCandidates(userId);
      expect(result, isEmpty);
    });

    test('returns asset in selected album that is not backed up', () async {
      final album = await ctx.newLocalAlbum(backupSelection: BackupSelection.selected);
      final asset = await ctx.newLocalAsset();
      await ctx.newLocalAlbumAsset(albumId: album.id, assetId: asset.id);

      final result = await sut.getCandidates(userId);
      expect(result.length, 1);
      expect(result.first.id, asset.id);
    });

    test('excludes asset already backed up for the same user', () async {
      final album = await ctx.newLocalAlbum(backupSelection: BackupSelection.selected);
      final remote = await ctx.newRemoteAsset(ownerId: userId);
      final local = await ctx.newLocalAsset(checksum: remote.checksum);
      await ctx.newLocalAlbumAsset(albumId: album.id, assetId: local.id);

      final result = await sut.getCandidates(userId);
      expect(result, isEmpty);
    });

    test('includes asset backed up for a different user', () async {
      final otherUser = await ctx.newUser();
      final album = await ctx.newLocalAlbum(backupSelection: BackupSelection.selected);
      final remote = await ctx.newRemoteAsset(ownerId: otherUser.id);
      final local = await ctx.newLocalAsset(checksum: remote.checksum);
      await ctx.newLocalAlbumAsset(albumId: album.id, assetId: local.id);

      final result = await sut.getCandidates(userId);
      expect(result.length, 1);
      expect(result.first.id, local.id);
    });

    test('excludes asset in excluded album even if also in selected album', () async {
      final selectedAlbum = await ctx.newLocalAlbum(backupSelection: BackupSelection.selected);
      final excludedAlbum = await ctx.newLocalAlbum(backupSelection: BackupSelection.excluded);
      final asset = await ctx.newLocalAsset();
      await ctx.newLocalAlbumAsset(albumId: selectedAlbum.id, assetId: asset.id);
      await ctx.newLocalAlbumAsset(albumId: excludedAlbum.id, assetId: asset.id);

      final result = await sut.getCandidates(userId);
      expect(result, isEmpty);
    });

    test('excludes asset with null checksum when onlyHashed is true', () async {
      final album = await ctx.newLocalAlbum(backupSelection: BackupSelection.selected);
      final asset = await ctx.newLocalAsset(checksumOption: const Option.none());
      await ctx.newLocalAlbumAsset(albumId: album.id, assetId: asset.id);

      final result = await sut.getCandidates(userId);
      expect(result, isEmpty);
    });

    test('includes asset with null checksum when onlyHashed is false', () async {
      final album = await ctx.newLocalAlbum(backupSelection: BackupSelection.selected);
      final asset = await ctx.newLocalAsset(checksumOption: const Option.none());
      await ctx.newLocalAlbumAsset(albumId: album.id, assetId: asset.id);

      final result = await sut.getCandidates(userId, onlyHashed: false);
      expect(result.length, 1);
      expect(result.first.id, asset.id);
    });

    test('returns assets ordered by createdAt descending', () async {
      final album = await ctx.newLocalAlbum(backupSelection: BackupSelection.selected);
      final asset1 = await ctx.newLocalAsset(createdAt: DateTime(2024, 1, 1));
      final asset2 = await ctx.newLocalAsset(createdAt: DateTime(2024, 3, 1));
      final asset3 = await ctx.newLocalAsset(createdAt: DateTime(2024, 2, 1));
      await ctx.newLocalAlbumAsset(albumId: album.id, assetId: asset1.id);
      await ctx.newLocalAlbumAsset(albumId: album.id, assetId: asset2.id);
      await ctx.newLocalAlbumAsset(albumId: album.id, assetId: asset3.id);

      final result = await sut.getCandidates(userId);
      expect(result.map((a) => a.id).toList(), [asset2.id, asset3.id, asset1.id]);
    });

    test('does not return duplicate when asset is in multiple selected albums', () async {
      final album1 = await ctx.newLocalAlbum(backupSelection: BackupSelection.selected);
      final album2 = await ctx.newLocalAlbum(backupSelection: BackupSelection.selected);
      final asset = await ctx.newLocalAsset();
      await ctx.newLocalAlbumAsset(albumId: album1.id, assetId: asset.id);
      await ctx.newLocalAlbumAsset(albumId: album2.id, assetId: asset.id);

      final result = await sut.getCandidates(userId);
      expect(result.length, 1);
      expect(result.first.id, asset.id);
    });

    test('excludes sentinel-checksum asset when onlyHashed is true', () async {
      final album = await ctx.newLocalAlbum(backupSelection: BackupSelection.selected);
      final asset = await ctx.newLocalAsset(checksum: kServerConfirmedChecksum);
      await ctx.newLocalAlbumAsset(albumId: album.id, assetId: asset.id);

      final result = await sut.getCandidates(userId);
      expect(result, isEmpty);
    });

    test('excludes sentinel-checksum asset when onlyHashed is false', () async {
      final album = await ctx.newLocalAlbum(backupSelection: BackupSelection.selected);
      final asset = await ctx.newLocalAsset(checksum: kServerConfirmedChecksum);
      await ctx.newLocalAlbumAsset(albumId: album.id, assetId: asset.id);

      final result = await sut.getCandidates(userId, onlyHashed: false);
      expect(result, isEmpty);
    });

    test('sentinel filter does not exclude null-checksum assets when onlyHashed is false', () async {
      final album = await ctx.newLocalAlbum(backupSelection: BackupSelection.selected);
      final nullAsset = await ctx.newLocalAsset(checksumOption: const Option.none());
      final sentinelAsset = await ctx.newLocalAsset(checksum: kServerConfirmedChecksum);
      await ctx.newLocalAlbumAsset(albumId: album.id, assetId: nullAsset.id);
      await ctx.newLocalAlbumAsset(albumId: album.id, assetId: sentinelAsset.id);

      final result = await sut.getCandidates(userId, onlyHashed: false);
      expect(result.length, 1);
      expect(result.first.id, nullAsset.id);
    });
  });

  group('getUnhashedBackupAssetIds', () {
    test('returns empty list when no albums exist', () async {
      final result = await sut.getUnhashedBackupAssetIds();
      expect(result, isEmpty);
    });

    test('returns only null-checksum assets in selected albums', () async {
      final album = await ctx.newLocalAlbum(backupSelection: BackupSelection.selected);

      final unhashed = await ctx.newLocalAsset(checksumOption: const Option.none());
      final hashed = await ctx.newLocalAsset();
      await ctx.newLocalAlbumAsset(albumId: album.id, assetId: unhashed.id);
      await ctx.newLocalAlbumAsset(albumId: album.id, assetId: hashed.id);

      final result = await sut.getUnhashedBackupAssetIds();
      expect(result, [unhashed.id]);
    });

    test('excludes assets in non-selected albums', () async {
      final noneAlbum = await ctx.newLocalAlbum(backupSelection: BackupSelection.none);
      final asset = await ctx.newLocalAsset(checksumOption: const Option.none());
      await ctx.newLocalAlbumAsset(albumId: noneAlbum.id, assetId: asset.id);

      final result = await sut.getUnhashedBackupAssetIds();
      expect(result, isEmpty);
    });

    test('excludes assets also in excluded albums', () async {
      final selected = await ctx.newLocalAlbum(backupSelection: BackupSelection.selected);
      final excluded = await ctx.newLocalAlbum(backupSelection: BackupSelection.excluded);
      final asset = await ctx.newLocalAsset(checksumOption: const Option.none());
      await ctx.newLocalAlbumAsset(albumId: selected.id, assetId: asset.id);
      await ctx.newLocalAlbumAsset(albumId: excluded.id, assetId: asset.id);

      final result = await sut.getUnhashedBackupAssetIds();
      expect(result, isEmpty);
    });

    test('does not return duplicates for assets in multiple selected albums', () async {
      final album1 = await ctx.newLocalAlbum(backupSelection: BackupSelection.selected);
      final album2 = await ctx.newLocalAlbum(backupSelection: BackupSelection.selected);
      final asset = await ctx.newLocalAsset(checksumOption: const Option.none());
      await ctx.newLocalAlbumAsset(albumId: album1.id, assetId: asset.id);
      await ctx.newLocalAlbumAsset(albumId: album2.id, assetId: asset.id);

      final result = await sut.getUnhashedBackupAssetIds();
      expect(result, [asset.id]);
    });
  });

  group('getUnmatchedBackupAssetMetadata', () {
    late String userId;

    setUp(() async {
      final user = await ctx.newUser();
      userId = user.id;
    });

    test('returns empty list when no assets', () async {
      final result = await sut.getUnmatchedBackupAssetMetadata(userId);
      expect(result, isEmpty);
    });

    test('returns unhashed assets with dimensions in selected albums', () async {
      final album = await ctx.newLocalAlbum(backupSelection: BackupSelection.selected);
      final createdAt = DateTime.utc(2024, 6, 15, 12, 30);
      final asset = await ctx.newLocalAsset(
        checksumOption: const Option.none(),
        name: 'IMG_1234.jpg',
        createdAt: createdAt,
        width: 4032,
        height: 3024,
      );
      await ctx.newLocalAlbumAsset(albumId: album.id, assetId: asset.id);

      final result = await sut.getUnmatchedBackupAssetMetadata(userId);
      expect(result.length, 1);
      expect(result.first.id, asset.id);
      expect(result.first.createdAt, createdAt);
      expect(result.first.width, 4032);
      expect(result.first.height, 3024);
    });

    test('includes hashed assets not on server', () async {
      final album = await ctx.newLocalAlbum(backupSelection: BackupSelection.selected);
      final hashed = await ctx.newLocalAsset();
      final unhashed = await ctx.newLocalAsset(checksumOption: const Option.none());
      await ctx.newLocalAlbumAsset(albumId: album.id, assetId: hashed.id);
      await ctx.newLocalAlbumAsset(albumId: album.id, assetId: unhashed.id);

      final result = await sut.getUnmatchedBackupAssetMetadata(userId);
      expect(result.length, 2); // both unhashed AND hashed-but-not-on-server
    });

    test('excludes hashed assets that exist on server', () async {
      final album = await ctx.newLocalAlbum(backupSelection: BackupSelection.selected);
      final remote = await ctx.newRemoteAsset(ownerId: userId);
      final matched = await ctx.newLocalAsset(checksum: remote.checksum);
      final unmatched = await ctx.newLocalAsset();
      await ctx.newLocalAlbumAsset(albumId: album.id, assetId: matched.id);
      await ctx.newLocalAlbumAsset(albumId: album.id, assetId: unmatched.id);

      final result = await sut.getUnmatchedBackupAssetMetadata(userId);
      expect(result.length, 1);
      expect(result.first.id, unmatched.id);
    });

    test('excludes sentinel-marked assets', () async {
      final album = await ctx.newLocalAlbum(backupSelection: BackupSelection.selected);
      final sentinel = await ctx.newLocalAsset(checksum: kServerConfirmedChecksum);
      final unmatched = await ctx.newLocalAsset();
      await ctx.newLocalAlbumAsset(albumId: album.id, assetId: sentinel.id);
      await ctx.newLocalAlbumAsset(albumId: album.id, assetId: unmatched.id);

      final result = await sut.getUnmatchedBackupAssetMetadata(userId);
      expect(result.length, 1);
      expect(result.first.id, unmatched.id);
    });
  });

  group('markAsServerConfirmed', () {
    test('does nothing for empty list', () async {
      await sut.markAsServerConfirmed([]);
      // No error thrown
    });

    test('sets sentinel checksum on specified assets', () async {
      final album = await ctx.newLocalAlbum(backupSelection: BackupSelection.selected);
      final asset1 = await ctx.newLocalAsset(checksumOption: const Option.none());
      final asset2 = await ctx.newLocalAsset(checksumOption: const Option.none());
      final asset3 = await ctx.newLocalAsset(checksumOption: const Option.none());
      await ctx.newLocalAlbumAsset(albumId: album.id, assetId: asset1.id);
      await ctx.newLocalAlbumAsset(albumId: album.id, assetId: asset2.id);
      await ctx.newLocalAlbumAsset(albumId: album.id, assetId: asset3.id);

      // Mark only asset1 and asset2
      await sut.markAsServerConfirmed([asset1.id, asset2.id]);

      // asset3 should still be unhashed
      final unhashed = await sut.getUnhashedBackupAssetIds();
      expect(unhashed, [asset3.id]);

      // Sentinel assets should not appear as candidates
      final user = await ctx.newUser();
      final candidates = await sut.getCandidates(user.id, onlyHashed: false);
      expect(candidates.length, 1);
      expect(candidates.first.id, asset3.id);
    });

    test('sentinel assets are excluded from getAllCounts remainder', () async {
      final user = await ctx.newUser();
      final album = await ctx.newLocalAlbum(backupSelection: BackupSelection.selected);
      final asset1 = await ctx.newLocalAsset(checksumOption: const Option.none());
      final asset2 = await ctx.newLocalAsset(checksumOption: const Option.none());
      await ctx.newLocalAlbumAsset(albumId: album.id, assetId: asset1.id);
      await ctx.newLocalAlbumAsset(albumId: album.id, assetId: asset2.id);

      // Before marking: both are processing + remainder
      var counts = await sut.getAllCounts(user.id);
      expect(counts.total, 2);
      expect(counts.remainder, 2);
      expect(counts.processing, 2);

      // Mark asset1 as server-confirmed
      await sut.markAsServerConfirmed([asset1.id]);

      // After marking: asset1 is no longer processing or remainder
      counts = await sut.getAllCounts(user.id);
      expect(counts.total, 2);
      expect(counts.remainder, 1); // only asset2
      expect(counts.processing, 1); // only asset2
    });

    test('stores remoteId when remoteIdMap is provided', () async {
      final album = await ctx.newLocalAlbum(backupSelection: BackupSelection.selected);
      final asset1 = await ctx.newLocalAsset(checksumOption: const Option.none());
      final asset2 = await ctx.newLocalAsset(checksumOption: const Option.none());
      await ctx.newLocalAlbumAsset(albumId: album.id, assetId: asset1.id);
      await ctx.newLocalAlbumAsset(albumId: album.id, assetId: asset2.id);

      await sut.markAsServerConfirmed(
        [asset1.id, asset2.id],
        remoteIdMap: {asset1.id: 'server-uuid-1', asset2.id: 'server-uuid-2'},
      );

      // Verify remoteId was stored via raw SQL
      final rows = await ctx.db.customSelect(
        'SELECT id, checksum, remote_id FROM local_asset_entity WHERE id IN (?, ?)',
        variables: [Variable.withString(asset1.id), Variable.withString(asset2.id)],
      ).get();
      final byId = {for (final r in rows) r.data['id'] as String: r.data};

      expect(byId[asset1.id]!['remote_id'], 'server-uuid-1');
      expect(byId[asset1.id]!['checksum'], kServerConfirmedChecksum);
      expect(byId[asset2.id]!['remote_id'], 'server-uuid-2');
      expect(byId[asset2.id]!['checksum'], kServerConfirmedChecksum);
    });

    test('works without remoteIdMap (backward compat)', () async {
      final album = await ctx.newLocalAlbum(backupSelection: BackupSelection.selected);
      final asset = await ctx.newLocalAsset(checksumOption: const Option.none());
      await ctx.newLocalAlbumAsset(albumId: album.id, assetId: asset.id);

      await sut.markAsServerConfirmed([asset.id]);

      final row = await ctx.db.customSelect(
        'SELECT checksum, remote_id FROM local_asset_entity WHERE id = ?',
        variables: [Variable.withString(asset.id)],
      ).getSingle();
      expect(row.data['checksum'], kServerConfirmedChecksum);
      expect(row.data['remote_id'], isNull);
    });
  });

  group('storeRemoteId', () {
    test('stores server asset UUID for a local asset', () async {
      final asset = await ctx.newLocalAsset();

      await sut.storeRemoteId(asset.id, 'server-uuid-123');

      final row = await ctx.db.customSelect(
        'SELECT remote_id FROM local_asset_entity WHERE id = ?',
        variables: [Variable.withString(asset.id)],
      ).getSingle();
      expect(row.data['remote_id'], 'server-uuid-123');
    });

    test('overwrites existing remoteId', () async {
      final asset = await ctx.newLocalAsset();

      await sut.storeRemoteId(asset.id, 'old-uuid');
      await sut.storeRemoteId(asset.id, 'new-uuid');

      final row = await ctx.db.customSelect(
        'SELECT remote_id FROM local_asset_entity WHERE id = ?',
        variables: [Variable.withString(asset.id)],
      ).getSingle();
      expect(row.data['remote_id'], 'new-uuid');
    });
  });
}
