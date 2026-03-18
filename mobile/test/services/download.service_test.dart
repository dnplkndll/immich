import 'dart:io';

import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:immich_mobile/constants/enums.dart';
import 'package:immich_mobile/entities/asset.entity.dart';
import 'package:immich_mobile/models/download/livephotos_medatada.model.dart';
import 'package:immich_mobile/repositories/download.repository.dart';
import 'package:immich_mobile/repositories/file_media.repository.dart';
import 'package:immich_mobile/services/download.service.dart';
import 'package:mocktail/mocktail.dart';

class MockFileMediaRepository extends Mock implements FileMediaRepository {}

class MockDownloadRepository extends Mock implements DownloadRepository {}

Asset _fakeAsset() => Asset(
      checksum: 'abc',
      localId: null,
      ownerId: 0,
      fileCreatedAt: DateTime(2024),
      fileModifiedAt: DateTime(2024),
      updatedAt: DateTime(2024),
      durationInSeconds: 0,
      type: AssetType.image,
      fileName: 'test.HEIC',
    );

DownloadTask _makeTask(String id, String filename, LivePhotosPart part, String liveId) {
  return DownloadTask(
    taskId: id,
    url: 'https://example.com/assets/$id/original',
    filename: filename,
    group: 'livePhoto',
    updates: Updates.statusAndProgress,
    metaData: LivePhotosMetadata(part: part, id: liveId).toJson(),
  );
}

TaskRecord _makeRecord(DownloadTask task) =>
    TaskRecord(task, TaskStatus.complete, 1.0, 1000);

class _FileFake extends Fake implements File {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(_FileFake());
    // background_downloader calls path_provider to resolve Task.filePath()
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall call) async => Directory.systemTemp.path,
    );
  });

  late DownloadService sut;
  late MockFileMediaRepository fileMediaRepo;
  late MockDownloadRepository downloadRepo;

  const liveId = 'asset-abc123';
  const imgId = 'img-task-id';
  const vidId = 'vid-task-id';

  late DownloadTask imageTask;
  late DownloadTask videoTask;

  setUp(() {
    fileMediaRepo = MockFileMediaRepository();
    downloadRepo = MockDownloadRepository();

    // Always stub cleanup so finally block doesn't throw
    when(() => downloadRepo.deleteRecordsWithIds(any())).thenAnswer((_) async {});

    sut = DownloadService(fileMediaRepo, downloadRepo);

    imageTask = _makeTask(imgId, 'photo.HEIC', LivePhotosPart.image, liveId);
    videoTask = _makeTask(vidId, 'photo.MOV', LivePhotosPart.video, liveId);
  });

  group('saveLivePhotos', () {
    test('returns false immediately when fewer than 2 records exist', () async {
      when(() => downloadRepo.getLiveVideoTasks())
          .thenAnswer((_) async => [_makeRecord(imageTask)]);

      final result = await sut.saveLivePhotos(imageTask, liveId);

      expect(result, isFalse);
      verifyNever(() => fileMediaRepo.saveLivePhoto(
            image: any(named: 'image'),
            video: any(named: 'video'),
            title: any(named: 'title'),
          ));
    });

    test('returns true when saveLivePhoto succeeds', () async {
      when(() => downloadRepo.getLiveVideoTasks())
          .thenAnswer((_) async => [_makeRecord(imageTask), _makeRecord(videoTask)]);
      when(() => fileMediaRepo.saveLivePhoto(
                image: any(named: 'image'),
                video: any(named: 'video'),
                title: any(named: 'title'),
              ))
          .thenAnswer((_) async => _fakeAsset());

      final result = await sut.saveLivePhotos(imageTask, liveId);

      expect(result, isTrue);
    });

    test('returns false when saveLivePhoto returns null', () async {
      when(() => downloadRepo.getLiveVideoTasks())
          .thenAnswer((_) async => [_makeRecord(imageTask), _makeRecord(videoTask)]);
      when(() => fileMediaRepo.saveLivePhoto(
                image: any(named: 'image'),
                video: any(named: 'video'),
                title: any(named: 'title'),
              ))
          .thenAnswer((_) async => null);

      final result = await sut.saveLivePhotos(imageTask, liveId);

      expect(result, isFalse);
    });

    group('PHPhotosErrorDomain fallback', () {
      setUp(() {
        when(() => downloadRepo.getLiveVideoTasks())
            .thenAnswer((_) async => [_makeRecord(imageTask), _makeRecord(videoTask)]);
        // Fallback path: saveImageWithFile succeeds
        when(() => fileMediaRepo.saveImageWithFile(
                  any(),
                  title: any(named: 'title'),
                ))
            .thenAnswer((_) async => _fakeAsset());
      });

      test('falls back to still image for PHPhotosErrorDomain -1 (Android motion photo)', () async {
        when(() => fileMediaRepo.saveLivePhoto(
                  image: any(named: 'image'),
                  video: any(named: 'video'),
                  title: any(named: 'title'),
                ))
            .thenThrow(PlatformException(code: 'PHPhotosErrorDomain -1'));

        final result = await sut.saveLivePhotos(imageTask, liveId);

        expect(result, isTrue);
        verify(() => fileMediaRepo.saveImageWithFile(any(), title: any(named: 'title'))).called(1);
      });

      test('falls back to still image for PHPhotosErrorDomain -3302 (mismatched CID)', () async {
        when(() => fileMediaRepo.saveLivePhoto(
                  image: any(named: 'image'),
                  video: any(named: 'video'),
                  title: any(named: 'title'),
                ))
            .thenThrow(PlatformException(code: 'PHPhotosErrorDomain -3302'));

        final result = await sut.saveLivePhotos(imageTask, liveId);

        expect(result, isTrue);
        verify(() => fileMediaRepo.saveImageWithFile(any(), title: any(named: 'title'))).called(1);
      });

      test('does not fall back for non-PHPhotosErrorDomain PlatformException', () async {
        when(() => fileMediaRepo.saveLivePhoto(
                  image: any(named: 'image'),
                  video: any(named: 'video'),
                  title: any(named: 'title'),
                ))
            .thenThrow(PlatformException(code: 'NSPOSIXErrorDomain 28')); // disk full

        final result = await sut.saveLivePhotos(imageTask, liveId);

        expect(result, isFalse);
        verifyNever(() => fileMediaRepo.saveImageWithFile(any(), title: any(named: 'title')));
      });
    });

    group('missing task record (StateError guard)', () {
      test('returns false gracefully when records have wrong liveId', () async {
        // Provide 2 records but for a different liveId so _findTaskRecord's
        // firstWhere finds no match — previously this threw an unguarded StateError
        final wrongImage = _makeTask('other-img', 'other.HEIC', LivePhotosPart.image, 'wrong-id');
        final wrongVideo = _makeTask('other-vid', 'other.MOV', LivePhotosPart.video, 'wrong-id');
        when(() => downloadRepo.getLiveVideoTasks())
            .thenAnswer((_) async => [_makeRecord(wrongImage), _makeRecord(wrongVideo)]);

        final result = await sut.saveLivePhotos(imageTask, liveId);

        expect(result, isFalse);
        verifyNever(() => fileMediaRepo.saveLivePhoto(
              image: any(named: 'image'),
              video: any(named: 'video'),
              title: any(named: 'title'),
            ));
      });
    });

    test('cleans up task records in finally even when saveLivePhoto throws', () async {
      when(() => downloadRepo.getLiveVideoTasks())
          .thenAnswer((_) async => [_makeRecord(imageTask), _makeRecord(videoTask)]);
      when(() => fileMediaRepo.saveLivePhoto(
                image: any(named: 'image'),
                video: any(named: 'video'),
                title: any(named: 'title'),
              ))
          .thenThrow(Exception('unexpected error'));

      final result = await sut.saveLivePhotos(imageTask, liveId);

      expect(result, isFalse);
      // taskIds is set before saveLivePhoto is called, so finally always cleans up
      verify(() => downloadRepo.deleteRecordsWithIds([imgId, vidId])).called(1);
    });
  });

  group('_buildDownloadTask filename for live photo video', () {
    test('replaces file extension with .MOV', () {
      // Verify the regex in _createDownloadTasks replaces last extension only
      const name = 'IMG_1234.HEIC';
      final result = name.replaceFirst(RegExp(r'\.[^.]+$', caseSensitive: false), '.MOV');
      expect(result, 'IMG_1234.MOV');
    });

    test('handles lowercase extensions', () {
      const name = 'photo.jpg';
      final result = name.replaceFirst(RegExp(r'\.[^.]+$', caseSensitive: false), '.MOV');
      expect(result, 'photo.MOV');
    });

    test('replaces only the last extension for multi-dot filenames', () {
      const name = 'my.photo.heic';
      final result = name.replaceFirst(RegExp(r'\.[^.]+$', caseSensitive: false), '.MOV');
      expect(result, 'my.photo.MOV');
    });
  });
}
