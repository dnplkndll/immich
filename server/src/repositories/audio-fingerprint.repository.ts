import { Injectable } from '@nestjs/common';
import { Kysely, sql } from 'kysely';
import { InjectKysely } from 'nestjs-kysely';
import { DummyValue, GenerateSql } from 'src/decorators';
import { DB } from 'src/schema';
import { asUuid } from 'src/utils/database';

// Only compare fingerprints whose durations are within this fraction of each other;
// clips of very different length can't be the same recording, and this bounds the
// candidate scan (backed by idx_audio_fingerprint_duration).
const DURATION_BAND_RATIO = 0.1;

@Injectable()
export class AudioFingerprintRepository {
  constructor(@InjectKysely() private db: Kysely<DB>) {}

  @GenerateSql({ params: [{ assetId: DummyValue.UUID, fingerprint: [1, 2, 3], duration: 10.5 }] })
  upsert(data: { assetId: string; fingerprint: number[]; duration: number }) {
    const pgArray = `{${data.fingerprint.join(',')}}`;
    // `as any`: the fingerprint column is written via a raw `integer[]` SQL literal,
    // which doesn't line up with the generated Insertable column type.
    return this.db
      .insertInto('audio_fingerprint')
      .values({
        assetId: asUuid(data.assetId),
        fingerprint: sql`${pgArray}::integer[]`,
        duration: data.duration,
      } as any)
      .onConflict((oc) =>
        oc.column('assetId').doUpdateSet({
          fingerprint: sql`${pgArray}::integer[]`,
          duration: data.duration,
        } as any),
      )
      .execute();
  }

  @GenerateSql({ params: [DummyValue.UUID, 10.5] })
  getCandidates(ownerId: string, duration: number) {
    return this.db
      .selectFrom('audio_fingerprint')
      .innerJoin('asset', 'asset.id', 'audio_fingerprint.assetId')
      .select([
        'audio_fingerprint.assetId',
        'audio_fingerprint.fingerprint',
        'audio_fingerprint.duration',
        'asset.duplicateId',
      ])
      .where('asset.ownerId', '=', asUuid(ownerId))
      .where('asset.deletedAt', 'is', null)
      .where(
        sql`abs(audio_fingerprint.duration - ${duration}) / greatest(audio_fingerprint.duration, ${duration}, 1)`,
        '<',
        DURATION_BAND_RATIO,
      )
      .execute();
  }
}
