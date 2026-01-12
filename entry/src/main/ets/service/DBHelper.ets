import DBConstants from '../common/DBConstants';
import Rdb from './DBService';
import { relationalStore } from '@kit.ArkData';
import { UserRDB } from '../model/RdbModel';

export class DBHelper {
  private static instance: DBHelper | null = null;
  private static _applicationContext: Context | null = null;
  private userTable: Rdb;

  private constructor() {
    if (!DBHelper._applicationContext) {
      throw new Error('DBHelper: Application context not set. Call setApplicationContext() before getInstance().');
    }

    this.userTable = new Rdb(
      DBConstants.USER_TABLE.tableName,
      DBConstants.USER_TABLE.sqlCreate,
      DBConstants.USER_TABLE.columns,
      DBHelper._applicationContext
    );
    this.userTable.getRdbStore();

  }

  /**
   * Sets the application context for the DBHelper singleton.
   * This MUST be called once at application startup BEFORE calling getInstance().
   * @param context The application Context.
   */
  public static init(context: Context): void {
    DBHelper._applicationContext = context;
    DBHelper.instance = new DBHelper();
  }

  public static getInstance(): DBHelper {
    if (!DBHelper._applicationContext) {
      throw new Error('DBHelper.getInstance() called before setApplicationContext().');
    }
    return DBHelper.instance!;
  }

  private getUserRDB(callback: Function = () => {
  }) {
    this.userTable.getRdbStore(callback);
  }

  insertUser(user: UserRDB, callback: (success: boolean) => void) {
    const valueBucket: relationalStore.ValuesBucket = {
      gender: user.gender,
      name: user.name,
      adress: user.adress,
      email: user.email,
      phone: user.phone
    };

    this.getUserRDB(() => {
      this.userTable.insertData(valueBucket, callback);
    });
  }


  deleteByName(name: string, tableName: string, callback: Function) {
    const predicates = new relationalStore.RdbPredicates(tableName);
    predicates.equalTo('name', name);
    this.userTable.deleteData(predicates, callback);
  }


  async getAllUsers(callback: (users: UserRDB[]) => void): Promise<void> {
    this.getUserRDB(() => {
      const predicates = new relationalStore.RdbPredicates(DBConstants.USER_TABLE.tableName);
      predicates.orderByDesc(DBConstants.ID_COLUMN);
      this.userTable.query(predicates, async (resultSet: relationalStore.ResultSet | null) => {
        if (!resultSet || resultSet.rowCount === 0) {
          callback([]);
          return;
        }

        const results: UserRDB[] = [];
        resultSet.goToFirstRow();

        for (let i = 0; i < resultSet.rowCount; i++) {
          const userInstance: UserRDB = {
            gender: resultSet.getString(resultSet.getColumnIndex('gender')),
            name: resultSet.getString(resultSet.getColumnIndex('name')),
            adress: resultSet.getString(resultSet.getColumnIndex('adress')),
            email: resultSet.getString(resultSet.getColumnIndex('email')),
            phone: resultSet.getString(resultSet.getColumnIndex('phone')),
            isFavorite: true
          };

          results.push(userInstance);
          resultSet.goToNextRow();
        }
        resultSet.close();
        callback(results);
      });
    });
  }
}