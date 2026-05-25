import { Kysely, sql } from 'kysely';

export async function up(db: Kysely<any>): Promise<void> {
  await sql`CREATE INDEX IF NOT EXISTS "idx_asset_exif_date_dimensions" ON "asset_exif" ("dateTimeOriginal", "exifImageWidth", "exifImageHeight");`.execute(
    db,
  );
}

export async function down(db: Kysely<any>): Promise<void> {
  await sql`DROP INDEX IF EXISTS "idx_asset_exif_date_dimensions";`.execute(db);
}
