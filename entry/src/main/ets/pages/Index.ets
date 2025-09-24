import { rcp } from '@kit.RemoteCommunicationKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { router, promptAction } from '@kit.ArkUI';
import Preferences from '../common/utils/Preferences'

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
  @State password: string = '';
  private username: string = '';
  private authToken: string = '';
  @State color: Color = Color.Red

  aboutToDisappear(): void {
    Preferences.instance.off();
  }

  onPageShow(): void {
    this.getOrUpdatePreferences();
    if (this.authToken != '') {
      router.pushUrl({ url: 'pages/Listing' }).then(() => {
        console.info('Succeeded in jumping to the second page.')
      })
    }
  }

  getOrUpdatePreferences() {
    this.authToken = Preferences.instance.getPreference();
    console.log('authtoken', this.authToken)
  }

  build() {
    Column({ space: 12 }) {

      TextInput({
        placeholder: 'Username',
        text: 'emilys',
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
        text: 'emilyspass',
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
          if (this.username && this.password != '') {
            this.postTransferSyn()
          } else {
            promptAction.showToast({
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

  private postTransferSyn = async () => {
    const postURL = 'https://dummyjson.com/auth/login';
    let headers: rcp.RequestHeaders = {
      "Content-Type": "application/json"
    };
    const postContent: rcp.RequestContent =
      JSON.stringify({
        "username": this.username,
        "password": this.password,
        "expiresInMins": 30
      });

    const sessions = rcp.createSession();
    let req = new rcp.Request(postURL, "POST", headers, postContent);

    sessions.fetch(req).then((response) => {
      console.info(`Response ${response}`);
      return response.toJSON() as Promise<AuthResponse>;
    }).then((data: AuthResponse) => {
      this.authToken = data.accessToken
      console.info('Response succeeded:', JSON.stringify(this.authToken));
      if (this.authToken != '') {
        Preferences.instance.putPreference(data.accessToken)
        router.pushUrl({ url: 'pages/Listing' }).then(() => {
          console.info('Succeeded in jumping to the second page.')
        })
      }
    }).catch((error: BusinessError) => {
      console.error(`Response failed: error message is ${JSON.stringify(error)}`);
    });

  };

  pageTransition() {
    PageTransitionEnter({
      type: RouteType.Push,
      duration: 600
    })
      .slide(SlideEffect.Right)

    PageTransitionEnter({
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
