import { rcp } from '@kit.RemoteCommunicationKit';
import { url } from '@kit.ArkTS';
import { BusinessError } from '@kit.BasicServicesKit';
import Preferences from '../common/utils/Preferences'
import { UserRDB } from '../model/RdbModel';
import { User, RandomUserResponse } from '../model/UserModel'
import {
  ArcList,
  ArcListItem,
  ComponentContent,
  ArcListAttribute,
  ArcListItemAttribute,
  LengthMetrics
} from '@kit.ArkUI'
import { DBHelper } from '../service/DBHelper';
import Logger from '../common/utils/Logger';
import DBConstants from '../common/DBConstants';
import { DETAIL_PAGE } from './Detail';
import taskpool from '@ohos.taskpool';

export const LISTING_PAGE = 'ListingPage';

@Builder
export function ListingPageBuilder() {
  Listing();
}

export class NetworkQualityProvider {
  isNetworkFast: boolean = true

  public constructor(isNetworkFast: boolean) {
    this.isNetworkFast = isNetworkFast
  }
}

class ResponseCache {
  private readonly cache: Record<string, rcp.Response> = {};

  getResponse(url: string): rcp.Response {
    return this.cache[url];
  }

  setResponse(url: string, response: rcp.Response): void {
    this.cache[url] = response;
  }
}

class ResponseCachingInterceptor implements rcp.Interceptor {
  private readonly cache: ResponseCache;

  constructor(cache: ResponseCache) {
    this.cache = cache;
  }

  async intercept(context: rcp.RequestContext, next: rcp.RequestHandler): Promise<rcp.Response> {
    const url = context.request.url.href;
    const responseFromCache = this.cache.getResponse(url);

    if (responseFromCache) {
      return Promise.resolve(responseFromCache);
    }
    const promise = next.handle(context);
    promise.then((resp) => {
      resp.statusCode;
      this.cache.setResponse(url, resp);
    });
    return promise;
  }
}

export class RequestUrlChangeInterceptor implements rcp.Interceptor {
  private readonly networkQualityProvider: NetworkQualityProvider;

  constructor(networkQualityProvider: NetworkQualityProvider) {
    this.networkQualityProvider = networkQualityProvider;
  }


  async intercept(context: rcp.RequestContext, next: rcp.RequestHandler): Promise<rcp.Response> {
    if (context.request.method === 'GET' && !this.networkQualityProvider.isNetworkFast) {
      console.info('[RequestUrlChangeInterceptor]: Slow network is detected');
      let parts = context.request.url.href
      parts = parts.replace(/results=\d+/, 'results=2');
      context.request.url = url.URL.parseURL(parts);
      return next.handle(context);
    } else {
      console.info('[RequestUrlChangeInterceptor]: Network is fast');
    }
    return next.handle(context);
  }
}

const cache = new ResponseCache();


@Builder
function buildText() {
  Column() {
    Text($r('app.string.header_user_text'))
      .fontSize('60px')
      .fontWeight(FontWeight.Bold)
      .fontColor(Color.White)
  }.margin(0)
}


@Component
struct Listing {
  @Consume('NavPathStack') private pageStack: NavPathStack;
  dbHelper: DBHelper = DBHelper.getInstance();
  @State responseList: User[] = [];
  @State userList: UserRDB[] = [];
  @State requestNumber: string = '';
  image: Resource = $r('app.media.unfavorite')
  private authToken: string = '';
  private watchSize: string = '4696px'
  private listSize: string = '414px'
  context: UIContext = this.getUIContext()
  header: ComponentContent<Object> = new ComponentContent(this.context, wrapBuilder(buildText));

  aboutToAppear(): void {
    this.getOrUpdatePreferences();
  }

  aboutToDisappear(): void {
    Preferences.instance.off();
  }

  onPageShow(): void {
    this.getOrUpdatePreferences();
  }

  getOrUpdatePreferences() {
    this.authToken = Preferences.instance.getPreference();
  }

  @Builder
  itemEnd(item: UserRDB) {
    Row() {
      Button({ type: ButtonType.Circle }) {
        Image(item.isFavorite ? $r('app.media.favorite') : $r('app.media.unfavorite'))
          .width($r('app.float.favorite_icon_size'))
          .height($r('app.float.favorite_icon_size'))
      }
      .onClick(() => {
          this.getUIContext()?.animateTo({
          duration: 1000,
          curve: Curve.Smooth,
          iterations: 1,
          playMode: PlayMode.Normal
        }, () => {
          const index = this.userList.findIndex(u => u.email === item.email);
          const updatedUser: UserRDB = {
            gender: this.userList[index].gender,
            name: this.userList[index].name,
            adress: this.userList[index].adress,
            email: this.userList[index].email,
            phone: this.userList[index].phone,
            isFavorite: !this.userList[index].isFavorite
          };
          const updatedList: UserRDB[] = [];
          for (let i = 0; i < this.userList.length; i++) {
            updatedList.push(i === index ? updatedUser : this.userList[i]);
          }
          this.userList = updatedList;
          if (updatedUser.isFavorite) {
            this.onUserSaved(updatedUser);
          } else {
            this.onUserDeleted(updatedUser);
          }
        })
      })
    }
    .justifyContent(FlexAlign.SpaceEvenly)
  }

  @Builder
  ListCardItem(user: UserRDB) {
    ArcListItem() {
      Button({ type: ButtonType.Capsule }) {
        Column({ space: 2 }) {
          Text(`${user.name}`)
            .fontSize($r('app.float.user_name_font_size'))
            .fontColor(Color.White)

          Text(`${user.email}`)
            .fontSize($r('app.float.user_email_font_size'))
            .fontColor(Color.White)
        }
        .width('80%')
        .padding($r('app.float.arclist_padding'))
      }
      .height('100px')
      .focusable(true)
      .focusOnTouch(true)
      .backgroundColor($r('app.color.button_background_color'))
      .onClick(() => {
        console.info(`Clicked: ${user}`);
      })
    }.align(Alignment.Center)
    .swipeAction({
      end: {
        builder: () => {
          this.itemEnd(user);
        }
      }
    })
  }

  build() {
    NavDestination() {
      RelativeContainer() {
        ArcList({ initialIndex: 0, header: this.header }) {
          ForEach(this.userList, (user: UserRDB) => {
            this.ListCardItem(user)
          }, (item: string, index: number) => item)
          ArcListItem() {
            Button($r('app.string.refresh_button_text'))
              .width(this.listSize)
              .height('100px')
              .focusable(true)
              .focusOnTouch(true)
              .backgroundColor($r('app.color.button_background_color'))
              .onClick(() => {
                this.userList = []
                this.getValues()
              })
          }

          ArcListItem() {
            Button($r('app.string.detail_button_text'))
              .width(this.listSize)
              .height('100px')
              .focusable(true)
              .focusOnTouch(true)
              .backgroundColor($r('app.color.button_background_color'))
              .onClick(() => {
                this.pageStack.pushPath({
                  name: DETAIL_PAGE
                })
              })
          }

          ArcListItem() {
            Button($r('app.string.logout_button_text'))
              .width(this.listSize)
              .height('100px')
              .focusable(true)
              .focusOnTouch(true)
              .backgroundColor($r('app.color.button_background_color'))
              .onClick(() => {
                Preferences.instance.putPreference('')
                this.pageStack.pop()
              })
          }
        }
        .height('100%')
        .width('100%')
        .backgroundColor($r('app.color.page_background_color'))
        .space(LengthMetrics.px(10))
        .borderRadius($r('app.float.watch_size'))
        .focusable(true)
        .focusOnTouch(true)
        .defaultFocus(true)
        .visibility(this.responseList.length > 0 ? Visibility.Visible : Visibility.Hidden)

        Column() {
          TextInput({
            placeholder: $r('app.string.text_input_placeholder'),
            text: this.requestNumber
          })
            .onChange((value: string) => {
              this.requestNumber = value
            })
            .type(InputType.Number)
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .visibility(this.responseList.length === 0 ? Visibility.Visible : Visibility.Hidden)
            .margin({ bottom: 10 })
            .width('80%')

          Button($r('app.string.get_users_button_text'))
            .onClick(() => {
              this.getValues()
            }).backgroundColor($r('app.color.button_background_color'))
            .visibility(this.responseList.length === 0 ? Visibility.Visible : Visibility.Hidden)
        }
        .position({
          top: 0,
          bottom: 0,
          left: 0,
          right: 0
        })
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .zIndex(10)
        .width(this.responseList.length === 0 ? '100%' : '0')
        .height(this.responseList.length === 0 ? '100%' : '0')
        .visibility(this.responseList.length === 0 ? Visibility.Visible : Visibility.Hidden)

      }
      .height('100%')
      .width('100%')
      .backgroundColor($r('app.color.page_background_color'))
    }
    .hideTitleBar(true)
    .mode(NavDestinationMode.STANDARD)
  }

  getValues() {
    let kHttpServerAddress =  $r('app.string.freeapi') + `/api/?results=5`;
    kHttpServerAddress = kHttpServerAddress.replace(/results=\d+/, `results=${this.requestNumber}`);
    const request = new rcp.Request(kHttpServerAddress, 'GET');
    const networkStateSimulator = new NetworkQualityProvider(true);
    const session = rcp.createSession({
      interceptors: [
        new ResponseCachingInterceptor(cache),
        new RequestUrlChangeInterceptor(networkStateSimulator)
      ]
    });

    session.fetch(request).then(async (response: rcp.Response) => {
      console.info(`Response succeeded: ${response}`);
      const val = response.toJSON() as RandomUserResponse
      this.responseList = val.results;
      const task = new taskpool.Task(processRespTask,'',val);
      const userRDBList = (await taskpool.execute(task)) as UserRDB[];
      this.userList = userRDBList;
      return response.toJSON() as Promise<RandomUserResponse>;
    }).catch((error: BusinessError) => {
      console.error(`Response failed: error message is ${JSON.stringify(error)}`);
    });

  }


  onUserSaved(user: UserRDB) {
    this.dbHelper.insertUser(user, (success: boolean) => {
      if (success) {
        Logger.info(`Inserted Successfully! Username: ${user.name}`);
      } else {
        Logger.error('Failed to insert user.');
      }
    });
  }

  onUserDeleted(user: UserRDB) {
    this.dbHelper.deleteByName(user.name, DBConstants.USER_TABLE.tableName, () => {
    })
  }

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

@Concurrent
function processRespTask(err: BusinessError, data: RandomUserResponse) {
  if (err) {
    return [];
  }

  const result: UserRDB[] = data.results.map((user: User) => ({
    gender: user.gender,
    name: user.name.first,
    adress: user.location.street.name,
    email: user.email,
    phone: user.phone,
    isFavorite: false
  } as UserRDB));

  return result;
}

