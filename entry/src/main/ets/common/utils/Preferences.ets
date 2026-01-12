import preferences from '@ohos.data.preferences';
import common from '@ohos.app.ability.common';

const PREFERENCES_NAME = 'favourites.db';
let authTokenPreferences: preferences.Preferences | null = null;

@Observed
export default class Preferences {
  static instance = new Preferences();
  authToken: string = '';

  private constructor() {}


  static async getInstance(context: common.UIAbilityContext): Promise<Preferences> {
    if (!Preferences.instance) {
      Preferences.instance = new Preferences();
      await Preferences.instance.initialize(context);
    }
    return Preferences.instance;
  }

  async initialize(context: common.UIAbilityContext) {
    await this.getPreferencesFromStorage(context);
    this.authToken = this.getPreference();
  }

  async getPreferencesFromStorage(context: common.UIAbilityContext) {
    authTokenPreferences = await preferences.getPreferences(context, PREFERENCES_NAME);
  }

  async on(callback: Callback<Record<string, preferences.ValueType>>) {
    authTokenPreferences?.on('dataChange', ['favourites'], callback);
  }

  async off() {
    authTokenPreferences?.off('dataChange', ['favourites']);
  }

  putPreference(data: string) {
    if (authTokenPreferences !== null) {
      authTokenPreferences.putSync('favourites', data);
      authTokenPreferences.flush();
    }
  }

  getPreference(): string {
    let authToken: string = '';
    if (authTokenPreferences !== null) {
      authToken = authTokenPreferences.getSync('favourites', '') as string;
    }
    return authToken;
  }
}
