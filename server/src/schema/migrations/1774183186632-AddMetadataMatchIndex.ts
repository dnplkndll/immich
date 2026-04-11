import { Kysely } from 'kysely';

// Stub migration — index was created by a previous fork deployment.
// The index was superseded by 1774295698444-AddExifDateDimensionsIndex.
// This file exists only to satisfy Kysely's migration integrity check.
export async function up(_db: Kysely<any>): Promise<void> {}

export async function down(_db: Kysely<any>): Promise<void> {}
