import { rcp } from '@kit.RemoteCommunicationKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { promptAction } from '@kit.ArkUI';
import common from '@ohos.app.ability.common';
import Preferences from '../common/utils/Preferences'
import { ListingPageBuilder, LISTING_PAGE } from './Listing';
import { DetailPageBuilder, DETAIL_PAGE } from './Detail';
import taskpool from '@ohos.taskpool';
import { http } from '@kit.NetworkKit';

export interface AuthResponse {
  accessToken: string;
  refreshToken: string;
  id: number;
  username: string;
  email: string;
  firstName: string;
  lastName: string;
  gender: string;
  image: string;
}

@Entry
@Component
struct LoginPage {
  @Provide('NavPathStack') pageStack: NavPathStack = new NavPathStack()
  @State password: string = '';
  private username: string = '';
  private authToken: string = '';
  @State color: Color = Color.Red
  isPreferencesReady: boolean = false;

  @Builder
  PagesMap(name: string) {
    if (name === LISTING_PAGE) {
      ListingPageBuilder();
    } else if (name === DETAIL_PAGE) {
      DetailPageBuilder();
    }
  }


  async aboutToAppear() {
    const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    await Preferences.getInstance(context);
    this.isPreferencesReady = true;
  }

  aboutToDisappear(): void {
    Preferences.instance?.off();
  }

  async onPageShow() {
    if (this.isPreferencesReady) {
      await this.getOrUpdatePreferences();
      if (this.authToken !== '') {
        this.pageStack.pushPath({
          name: LISTING_PAGE
        })
      }
    }
  }

  async getOrUpdatePreferences() {
    if (Preferences.instance) {
      this.authToken = Preferences.instance.getPreference();
      console.info('authtoken', this.authToken)
    }
  }

  build() {
    Navigation(this.pageStack) {
      Column({ space: 12 }) {

        TextInput({
          placeholder: 'Username',
          text: 'emilys'
        })
          .onChange((value: string) => {
            this.username = value
          }).type(InputType.USER_NAME)
          .margin({
            top: 20
          }
          )

        TextInput({
          placeholder: 'Password',
          text: 'emilyspass'
        })
          .onChange((value: string) => {
            this.password = value
            if (this.password.length > 3) {
              this.color = Color.Green
            } else {
              this.color = Color.Red
            }
          }).type(InputType.Password)
          .maxLength(15)

        Button($r('app.string.login_button_text'))
          .onClick(() => {
            if (this.username && this.password !== '') {
              this.postTransferSyn()
            } else {
              promptAction.openToast({
                message: $r('app.string.empty_input_warning'),
                duration: 1000,
                showMode: promptAction.ToastShowMode.DEFAULT,
                bottom: 130
              })
            }
          }
          ).backgroundColor($r('app.color.button_background_color'))
      }.padding($r('app.float.login_textinput_padding'))
      .backgroundColor($r('app.color.button_background_color'))
      .height('100%')
    }
    .mode(NavigationMode.Stack)
    .hideTitleBar(true)
    .navDestination(this.PagesMap)
    .hideBackButton(true)
    .ignoreLayoutSafeArea()
  }

  private postTransferSyn = async () => {
    const postURL = $r('app.string.dummyjson') + '/auth/login';
    const headers: rcp.RequestHeaders = {
      'Content-Type': 'application/json'
    };
    const postContent =
      JSON.stringify({
        'username': this.username,
        'password': this.password,
        'expiresInMins': 30
      });


    const httpRequest = http.createHttp();
    httpRequest.request(postURL, {
      method : http.RequestMethod.POST,
      header : {
        'Content-Type' : 'application/json'
      },
      extraData : postContent
    }, async (err: Error, data: http.HttpResponse) => {
      const task = new taskpool.Task(processRespTask, err,data);
      const isLogin = await taskpool.execute(task);
      if (isLogin) {
        this.pageStack.pushPath({
          name : LISTING_PAGE
        })
      }
    });
  };


  pageTransition() {
    PageTransitionEnter({
      type: RouteType.Push,
      duration: 600
    })
      .slide(SlideEffect.Right)

    PageTransitionEnter( {
      type: RouteType.Pop,
      duration: 600
    })
      .slide(SlideEffect.Left)

    PageTransitionExit({
      type: RouteType.Push,
      duration: 600
    })
      .slide(SlideEffect.Left)

    PageTransitionExit({
      type: RouteType.Pop,
      duration: 600
    })
      .slide(SlideEffect.Right)
  }
}


@Concurrent
function processRespTask(err: BusinessError, data: http.HttpResponse) {
  if (!err) {
  return true
  } else {
   return false
  }

}


