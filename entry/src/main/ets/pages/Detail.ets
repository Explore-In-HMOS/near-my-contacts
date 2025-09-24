import { DBHelper } from '../service/DBHelper';
import DBConstants from '../common/DBConstants';
import { UserRDB } from '../model/RdbModel';

import {
  ArcList,
  ArcListItem,
  ComponentContent,
  ArcListAttribute,
  ArcListItemAttribute,
  LengthMetrics
} from '@kit.ArkUI'

@Builder
function buildText() {
  Column() {
    Text($r('app.string.header_favorites_text'))
      .fontSize('60px')
      .fontWeight(FontWeight.Bold)
      .fontColor(Color.White)
  }.margin(0)
}


@Entry
@Component
struct Detail {
  dbHelper: DBHelper = DBHelper.getInstance();
  @State userList: UserRDB[] = [];
  private watchSize: string = '466px'
  private listSize: string = '414px'
  context: UIContext = this.getUIContext()
  header: ComponentContent<Object> = new ComponentContent(this.context, wrapBuilder(buildText));

  aboutToAppear(): void {
    this.dbHelper.getAllUsers((users) => {
      this.userList = users;
    });
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
        .width('100%')
        .padding('8px')
      }
      .width(this.listSize)
      .height('100px')
      .focusable(true)
      .focusOnTouch(true)
      .backgroundColor($r('app.color.button_background_color'))
      .onClick(() => {
        this.onUserDeleted(user)
      })
    }.align(Alignment.Center)
  }

  build() {
    ArcList({ initialIndex: 0, header: this.header }) {
      ForEach(this.userList, (user: UserRDB) => {
        this.ListCardItem(user)
      },(item: string, index: number) => item)
    }
    .height('100%')
    .width('100%')
    .backgroundColor('#004C5D')
    .space(LengthMetrics.px(10))
    .borderRadius(this.watchSize)
    .focusable(true)
    .focusOnTouch(true)
    .defaultFocus(true)
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

  onUserDeleted(user: UserRDB) {
    this.dbHelper.deleteByName(user.name, DBConstants.User_Table.tableName, () => {
      this.dbHelper.getAllUsers((users: UserRDB[]) => {
        console.log(users[0].name)
        this.userList = [...users]
      })
    })
  }
}
