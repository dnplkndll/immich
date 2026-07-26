import { Injectable } from '@nestjs/common';
import { JOBS_ASSET_PAGINATION_SIZE } from 'src/constants';
import { OnJob } from 'src/decorators';
import { AssetType, AssetVisibility, JobName, JobStatus, QueueName } from 'src/enum';
import { BaseService } from 'src/services/base.service';
import { JobItem, JobOf } from 'src/types';
import { isAudioFingerprintingEnabled } from 'src/utils/misc';

// Reject fingerprint pairs whose lengths differ by more than this fraction: a
// truncated fingerprint would produce an artificially low BER over the overlap.
const MAX_LENGTH_MISMATCH_RATIO = 0.2;

// Chromaprint returns unsigned 32-bit ints; PostgreSQL integer is signed 32-bit.
// Reinterpret as signed — XOR/popcount is bit-identical either way.
// Exported for unit testing.
export function toSigned32(n: number): number {
  return n | 0;
}

export function popcount32(n: number): number {
  n = n - ((n >>> 1) & 0x55555555);
  n = (n & 0x33333333) + ((n >>> 2) & 0x33333333);
  return (((n + (n >>> 4)) & 0x0f0f0f0f) * 0x01010101) >>> 24;
}

export function computeBer(a: number[], b: number[]): number {
  const minLen = Math.min(a.length, b.length);
  if (minLen === 0) {
    return 1;
  }
  const maxLen = Math.max(a.length, b.length);
  if ((maxLen - minLen) / maxLen > MAX_LENGTH_MISMATCH_RATIO) {
    return 1;
  }
  let bits = 0;
  for (let i = 0; i < minLen; i++) {
    bits += popcount32(a[i] ^ b[i]);
  }
  return bits / (32 * minLen);
}

@Injectable()
export class AudioFingerprintService extends BaseService {
  @OnJob({ name: JobName.AudioFingerprintQueueAll, queue: QueueName.AudioAnalysis })
  async handleQueueAll({ force }: JobOf<JobName.AudioFingerprintQueueAll>): Promise<JobStatus> {
    const { audioFingerprinting } = await this.getConfig({ withCache: false });
    if (!isAudioFingerprintingEnabled(audioFingerprinting)) {
      return JobStatus.Skipped;
    }

    let jobs: JobItem[] = [];
    const queueAll = async () => {
      await this.jobRepository.queueAll(jobs);
      jobs = [];
    };

    const assets = this.assetJobRepository.streamForAudioFingerprint(force);
    for await (const asset of assets) {
      jobs.push({ name: JobName.AudioFingerprint, data: { id: asset.id } });
      if (jobs.length >= JOBS_ASSET_PAGINATION_SIZE) {
        await queueAll();
      }
    }

    await queueAll();

    return JobStatus.Success;
  }

  @OnJob({ name: JobName.AudioFingerprint, queue: QueueName.AudioAnalysis })
  async handleFingerprint({ id }: JobOf<JobName.AudioFingerprint>): Promise<JobStatus> {
    const { audioFingerprinting } = await this.getConfig({ withCache: true });
    if (!isAudioFingerprintingEnabled(audioFingerprinting)) {
      return JobStatus.Skipped;
    }

    const asset = await this.assetJobRepository.getForAudioFingerprintJob(id);
    if (!asset) {
      this.logger.error(`Asset ${id} not found`);
      return JobStatus.Failed;
    }

    if (asset.type !== AssetType.Video) {
      return JobStatus.Skipped;
    }

    if (asset.visibility === AssetVisibility.Hidden) {
      return JobStatus.Skipped;
    }

    const result = await this.mediaRepository.fingerprintAudio(asset.originalPath);
    if (!result) {
      this.logger.debug(`Asset ${id} has no audio track or fingerprinting failed, skipping`);
      // Still mark as processed — videos without audio tracks won't benefit from retry
      await this.assetRepository.upsertJobStatus({ assetId: id, audioFingerprintedAt: new Date() });
      return JobStatus.Skipped;
    }

    const signedFingerprint = result.fingerprint.map(toSigned32);

    await this.audioFingerprintRepository.upsert({
      assetId: id,
      fingerprint: signedFingerprint,
      duration: result.duration,
    });

    const candidates = await this.audioFingerprintRepository.getCandidates(asset.ownerId, result.duration);

    const matches = candidates
      .filter((c) => c.assetId !== id && Array.isArray(c.fingerprint) && c.fingerprint.length > 0)
      .filter((c) => computeBer(signedFingerprint, c.fingerprint as number[]) < audioFingerprinting.maxDistance);

    if (matches.length > 0) {
      this.logger.debug(
        `Found ${matches.length} audio duplicate${matches.length === 1 ? '' : 's'} for asset ${id}`,
      );
      await this.updateDuplicates(
        { id, duplicateId: asset.duplicateId },
        matches.map((m) => ({ assetId: m.assetId, duplicateId: m.duplicateId })),
      );
    }

    await this.assetRepository.upsertJobStatus({ assetId: id, audioFingerprintedAt: new Date() });

    return JobStatus.Success;
  }

  // NOTE: audio and visual dedup share the single asset.duplicateId column. The
  // visual DuplicateService clears duplicateId when it finds no *visual* duplicates
  // ("removing duplicateId"), which will wipe an audio-derived grouping if visual
  // detection re-runs afterwards. Until the two subsystems are reconciled (e.g. a
  // separate column, or gating the visual reset on audioFingerprintedAt), audio
  // fingerprinting must run AFTER visual dedup and is best treated as subordinate.
  // This duplicates DuplicateService.updateDuplicates — a shared helper is a follow-up.
  private async updateDuplicates(
    asset: { id: string; duplicateId: string | null },
    duplicateAssets: Array<{ assetId: string; duplicateId: string | null }>,
  ): Promise<void> {
    const duplicateIds = [
      ...new Set(
        duplicateAssets
          .filter((a): a is { assetId: string; duplicateId: string } => !!a.duplicateId)
          .map((a) => a.duplicateId),
      ),
    ];

    const targetDuplicateId = asset.duplicateId ?? duplicateIds.shift() ?? this.cryptoRepository.randomUUID();
    const assetIdsToUpdate = duplicateAssets
      .filter((a) => a.duplicateId !== targetDuplicateId)
      .map((a) => a.assetId);
    assetIdsToUpdate.push(asset.id);

    await this.duplicateRepository.merge({
      targetId: targetDuplicateId,
      assetIds: assetIdsToUpdate,
      sourceIds: duplicateIds,
    });
  }
}
