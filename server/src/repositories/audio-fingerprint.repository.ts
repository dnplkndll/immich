import { Injectable } from '@nestjs/common';
import { Kysely, sql } from 'kysely';
import { InjectKysely } from 'nestjs-kysely';
import { DummyValue, GenerateSql } from 'src/decorators';
import { DB } from 'src/schema';
import { asUuid } from 'src/utils/database';

@Injectable()
export class AudioFingerprintRepository {
  constructor(@InjectKysely() private db: Kysely<DB>) {}

  @GenerateSql({ params: [{ assetId: DummyValue.UUID, fingerprint: [1, 2, 3], duration: 10.5 }] })
  upsert(data: { assetId: string; fingerprint: number[]; duration: number }) {
    const pgArray = `{${data.fingerprint.join(',')}}`;
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
        0.1,
      )
      .execute();
  }
}
