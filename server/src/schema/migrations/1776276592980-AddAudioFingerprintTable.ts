import { Kysely, sql } from 'kysely';

export async function up(db: Kysely<any>): Promise<void> {
  await sql`
    CREATE TABLE "audio_fingerprint" (
      "assetId" uuid PRIMARY KEY REFERENCES "asset"("id") ON DELETE CASCADE,
      "fingerprint" integer[] NOT NULL,
      "duration" double precision NOT NULL
    )
  `.execute(db);

  await sql`
    CREATE INDEX "idx_audio_fingerprint_duration"
    ON "audio_fingerprint" ("duration")
  `.execute(db);

  await sql`
    ALTER TABLE "asset_job_status"
    ADD COLUMN "audioFingerprintedAt" timestamp with time zone
  `.execute(db);
}

export async function down(db: Kysely<any>): Promise<void> {
  await sql`ALTER TABLE "asset_job_status" DROP COLUMN "audioFingerprintedAt"`.execute(db);
  await sql`DROP TABLE "audio_fingerprint"`.execute(db);
}
