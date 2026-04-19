import { Injectable } from '@nestjs/common';
import { JOBS_ASSET_PAGINATION_SIZE } from 'src/constants';
import { OnJob } from 'src/decorators';
import { AssetVisibility, JobName, JobStatus, QueueName } from 'src/enum';
import { BaseService } from 'src/services/base.service';
import { JobItem, JobOf } from 'src/types';
import { isAudioFingerprintingEnabled } from 'src/utils/misc';

// Chromaprint returns unsigned 32-bit ints; PostgreSQL integer is signed 32-bit.
// Reinterpret as signed — XOR/popcount is bit-identical either way.
function toSigned32(n: number): number {
  // Reinterpret unsigned 32-bit as signed via DataView
  const view = new DataView(new ArrayBuffer(4));
  view.setUint32(0, n);
  return view.getInt32(0);
}

function popcount32(n: number): number {
  n = n - ((n >>> 1) & 0x55_55_55_55);
  n = (n & 0x33_33_33_33) + ((n >>> 2) & 0x33_33_33_33);
  return Math.trunc((((n + (n >>> 4)) & 0x0f_0f_0f_0f) * 0x01_01_01_01) >>> 24);
}

function computeBer(a: number[], b: number[]): number {
  const minLen = Math.min(a.length, b.length);
  if (minLen === 0) {
    return 1;
  }
  // Reject pairs where lengths differ by more than 20% — truncated fingerprints
  // would produce artificially low BER over the overlapping region
  const maxLen = Math.max(a.length, b.length);
  if ((maxLen - minLen) / maxLen > 0.2) {
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

    if (asset.type !== 'VIDEO') {
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

    const signedFingerprint = result.fingerprint.map((n) => toSigned32(n));

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
      this.logger.debug(`Found ${matches.length} audio duplicate${matches.length === 1 ? '' : 's'} for asset ${id}`);
      await this.updateDuplicates(
        { id, duplicateId: asset.duplicateId },
        matches.map((m) => ({ assetId: m.assetId, duplicateId: m.duplicateId })),
      );
    }

    await this.assetRepository.upsertJobStatus({ assetId: id, audioFingerprintedAt: new Date() });

    return JobStatus.Success;
  }

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
    const assetIdsToUpdate = [
      ...duplicateAssets.filter((a) => a.duplicateId !== targetDuplicateId).map((a) => a.assetId),
      asset.id,
    ];

    await this.duplicateRepository.merge({
      targetId: targetDuplicateId,
      assetIds: assetIdsToUpdate,
      sourceIds: duplicateIds,
    });
  }
}
