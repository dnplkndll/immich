import { Column, ForeignKeyColumn, Index, Table } from '@immich/sql-tools';
import { AssetTable } from 'src/schema/tables/asset.table';

@Table('audio_fingerprint')
@Index({ name: 'idx_audio_fingerprint_duration', columns: ['duration'] })
export class AudioFingerprintTable {
  @ForeignKeyColumn(() => AssetTable, { onDelete: 'CASCADE', primary: true })
  assetId!: string;

  @Column({ type: 'integer', array: true })
  fingerprint!: number[];

  @Column({ type: 'double precision' })
  duration!: number;
}
