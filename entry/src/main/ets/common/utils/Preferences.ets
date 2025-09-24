import preferences from '@ohos.data.preferences';

const PREFERENCES_NAME = 'favourites.db';
let authTokenPreferences: preferences.Preferences | null = null;

@Observed
export default class Preferences {
  static instance = new Preferences();
  authToken: string = '';

  constructor() {
    this.initialize();
  }

  async initialize() {
    await this.getPreferencesFromStorage();
    this.authToken = this.getPreference();
  }

  async getPreferencesFromStorage() {
    const context = getContext(this) as Context;
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
