import { relationalStore } from '@kit.ArkData';
import Logger from '../common/utils/Logger';
import DBConstants from '../common/DBConstants';
import type { Context } from '@kit.AbilityKit';

export default class Rdb {
  private rdbStore: relationalStore.RdbStore | null = null;
  private tableName: string;
  private sqlCreateTable: string;
  private columns: Array<string>;
  private context: Context;

  constructor(tableName: string, sqlCreateTable: string, columns: Array<string>, context: Context) {
    this.tableName = tableName;
    this.sqlCreateTable = sqlCreateTable;
    this.columns = columns;
    this.context = context;
  }

  executeSql(sql: string, callback?: (err?: Error) => void): void {
    if (!this.rdbStore) {
      Logger.error('❌ RDB store not initialized.');
      callback?.(new Error('RDB store is null'));
      return;
    }

    this.rdbStore.executeSql(sql, (err) => {
      if (err) {
        Logger.error('❌ SQL execution failed:', err.message);
        callback?.(err);
      } else {
        Logger.info('✅ SQL executed successfully');
        callback?.();
      }
    });
  }

  getRdbStore(callback: Function = () => {
  }) {
    if (!callback || typeof callback === 'undefined' || callback === undefined) {
      Logger.info(DBConstants.RDB_TAG, 'getRdbStore() has no callback!');
      return;
    }
    if (this.rdbStore !== null) {
      Logger.info(DBConstants.RDB_TAG, 'The rdbStore exists.');
      callback();
      return
    }
    // Use the context provided in the constructor instead of getContext(this)
    relationalStore.getRdbStore(this.context, DBConstants.STORE_CONFIG, (err, rdb) => {
      if (err) {
        Logger.error(DBConstants.RDB_TAG, `gerRdbStore() failed, err: ${err.message}`);
        return;
      }
      this.rdbStore = rdb;
      this.rdbStore.executeSql(this.sqlCreateTable);
      Logger.info(DBConstants.RDB_TAG, 'getRdbStore() finished.');
      callback();
    });
  }

  insertData(data: relationalStore.ValuesBucket, callback: (success: boolean) => void = () => {
  }): void {
    if (!this.rdbStore) {
      return;
    }
    this.rdbStore.insert(this.tableName, data, (err) => {
      if (err) {
        Logger.error('[RDB] Insert Error:', err.message);
        callback(false);
        return;
      }
      callback(true);
    });
  }

  deleteData(predicates: relationalStore.RdbPredicates, callback: Function = () => {
  }) {
    if (!callback || typeof callback === 'undefined' || callback === undefined) {
      Logger.info(DBConstants.RDB_TAG, 'deleteData() has no callback!');
      return;
    }
    let resFlag: boolean = false;
    if (this.rdbStore) {
      this.rdbStore.delete(predicates, (err, ret) => {
        if (err) {
          Logger.error(DBConstants.RDB_TAG, `deleteData() failed, err: ${err.message}`);
          callback(resFlag);
          return;
        }
        Logger.info(DBConstants.RDB_TAG, `deleteData() finished: ${ret}`);
        callback(!resFlag);
      });
    }
  }

  query(predicates: relationalStore.RdbPredicates, callback: Function = () => {
  }) {
    if (!callback || typeof callback === 'undefined' || callback === undefined) {
      Logger.info(DBConstants.RDB_TAG, 'query() has no callback!');
      return;
    }
    if (this.rdbStore) {
      this.rdbStore.query(predicates, this.columns, (err, resultSet) => {
        if (err) {
          Logger.error(DBConstants.RDB_TAG, `query() failed, err:  ${err.message}`);
          return;
        }
        Logger.info(DBConstants.RDB_TAG, 'query() finished.');
        callback(resultSet);
      });
    }
  }
}