import { relationalStore } from '@kit.ArkData';

export interface TableDefinition {
  tableName: string;
  sqlCreate: string;
  columns: string[];
}

export default class DBConstants {
  static readonly STORE_CONFIG: relationalStore.StoreConfig = {
    name: 'user.db',
    securityLevel: relationalStore.SecurityLevel.S1
  };
  static readonly USER_TABLE: TableDefinition = {
    tableName: 'UserInfo',
    sqlCreate: `CREATE TABLE IF NOT EXISTS UserInfo (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    gender TEXT,
    name TEXT,
    adress TEXT,
    email TEXT,
    phone TEXT
    )`,
    columns: ['id', 'gender', 'name', 'adress', 'email', 'phone']
  };
  static readonly RDB_TAG = '[Debug.Rdb]';
  static readonly USER_TABLE_TAG = '[Debug.TasksTable]';
  static readonly INDEX_TAG = '[Debug.Index]';
  static readonly ID_COLUMN = 'id';
}
