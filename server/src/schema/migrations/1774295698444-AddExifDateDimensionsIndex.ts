import { Kysely } from 'kysely';

// Stub migration — index was created by a previous fork deployment under
// this timestamp. The index is now owned by 1776544600000-AddExifDateDimensionsIndex
// (which uses CREATE INDEX IF NOT EXISTS, safe on both fresh and upgraded DBs).
// This file exists only to satisfy Kysely's migration integrity check.
export async function up(_db: Kysely<any>): Promise<void> {}

export async function down(_db: Kysely<any>): Promise<void> {}
