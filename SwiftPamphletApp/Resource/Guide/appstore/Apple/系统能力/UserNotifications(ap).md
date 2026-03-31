# iOS/macOS 系统能力：UserNotifications 框架

`UserNotifications` 框架是苹果官方提供的、用于在应用中创建、管理和处理**本地通知**和**远程通知（推送通知）**的统一 API。从 iOS 10 开始，它取代了旧的、分散的通知相关 API，提供了一套更强大、更一致的接口。

无论是你想在应用内安排一个定时的提醒（本地通知），还是处理从服务器发送过来的推送通知，你都需要与 `UserNotifications` 框架打交道。

## 核心概念

一个通知的生命周期主要涉及以下几个核心对象：

1.  **`UNNotificationContent`**: 通知的**内容**。它包含了用户将看到的所有信息，如标题（`title`）、副标题（`subtitle`）、正文（`body`）、声音（`sound`）、角标（`badge`）以及附件（`attachments`）。

2.  **`UNNotificationTrigger`**: 通知的**触发器**。它定义了通知应该在**何时**被递送。
    *   `UNTimeIntervalNotificationTrigger`: 在一段时间后触发（例如，5秒后）。
    *   `UNCalendarNotificationTrigger`: 在一个特定的日期和时间触发（例如，每天早上 8 点）。
    *   `UNLocationNotificationTrigger`: 当设备进入或离开某个地理区域时触发。
    *   对于远程推送通知，触发器是在苹果的服务器端，因此在客户端为 `UNPushNotificationTrigger`。

3.  **`UNNotificationRequest`**: 一个**通知请求**。它将 `content` 和 `trigger` 组合在一起，并包含一个唯一的标识符（`identifier`），用于在之后更新或移除这个请求。

4.  **`UNUserNotificationCenter`**: 管理所有通知交互的中心。你需要通过 `UNUserNotificationCenter.current()` 来获取其单例，并用它来请求用户授权、添加/移除通知请求，以及处理通知的响应。

## 1. 请求授权

在你的应用能够发送任何类型的通知之前，你**必须**首先向用户请求授权。

```swift
import UserNotifications

func requestNotificationAuthorization() {
    let center = UNUserNotificationCenter.current()
    center.requestAuthorization(options: [.alert, .sound, .badge, .provisional]) { granted, error in
        if granted {
            print("用户已授权通知")
        } else {
            print("用户已拒绝通知")
        }
    }
}
```

*   **`options`**: 你可以请求的权限类型，如 `.alert` (弹窗), `.sound` (声音), `.badge` (角标)。
*   **`.provisional`** (iOS 12+): “临时”授权。通知会直接、静默地发送到通知中心，而不会弹出授权请求。这是一种更温和的请求方式，让用户在体验到通知的价值后，再决定是否要将其升级为正式的、带有声音和弹窗的通知。

## 2. 创建和调度本地通知

```swift
func scheduleLocalNotification() {
    let center = UNUserNotificationCenter.current()

    // 1. 创建通知内容
    let content = UNMutableNotificationContent()
    content.title = "每日提醒"
    content.body = "是时候记录你今天的心情了！"
    content.sound = .default
    content.badge = 1

    // 2. 创建触发器 (例如，每天上午 10 点)
    var dateComponents = DateComponents()
    dateComponents.hour = 10
    dateComponents.minute = 0
    let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

    // 3. 创建通知请求
    let request = UNNotificationRequest(identifier: "daily-reminder", content: content, trigger: trigger)

    // 4. 将请求添加到通知中心
    center.add(request) { error in
        if let error = error {
            print("添加通知失败: \(error)")
        }
    }
}
```

*   **`identifier`**: 为请求提供一个唯一的字符串 ID。如果你使用相同的 ID 提交一个新的请求，它会覆盖掉旧的请求。

## 3. 处理通知的交互

要响应用户与通知的交互（例如，点击通知横幅），你需要设置 `UNUserNotificationCenter` 的代理（`delegate`）。这通常在 `AppDelegate` 中完成。

```swift
import UIKit

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // 设置代理
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    // 当应用在前台时，如何处理收到的通知
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // .banner: 显示横幅
        // .sound: 播放声音
        // .list: 在通知中心显示 (iOS 14+)
        completionHandler([.banner, .sound])
    }

    // 当用户点击通知（或通知中的 action）时调用
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        
        // 在这里根据 userInfo 或 response.actionIdentifier 来处理交互
        print("用户点击了通知: \(userInfo)")
        
        completionHandler()
    }
}
```

## 4. 通知 Action 和 Category

你可以为通知添加可交互的按钮（Actions）。

1.  **创建 `UNNotificationAction`**: 定义一个按钮，包含标题和选项。
2.  **创建 `UNNotificationCategory`**: 将一个或多个 `action` 组合成一个“类别”，并为其指定一个唯一的标识符。
3.  **注册类别**: 在应用启动时，通过 `center.setNotificationCategories(...)` 来注册你的类别。
4.  **发送时指定类别**: 在创建通知的 `UNMutableNotificationContent` 时，将其 `categoryIdentifier` 属性设置为你注册的类别标识符。

当用户收到这个通知时，他们就可以通过长按或下拉通知来看到你定义的这些操作按钮。

## 总结

`UserNotifications` 框架是 iOS 和 macOS 上所有通知功能的统一入口。

*   **统一 API**: 无论是本地通知还是远程推送通知，都使用相同的 `UNNotificationContent`, `UNNotificationRequest` 和 `UNUserNotificationCenterDelegate` 来处理。
*   **授权是前提**: 必须先通过 `requestAuthorization` 请求用户权限。
*   **本地通知**: 通过组合 `Content` 和 `Trigger` 来创建 `Request`，然后添加到 `UNUserNotificationCenter`。
*   **交互处理**: 通过实现 `UNUserNotificationCenterDelegate` 的代理方法，来响应用户在前台接收或点击通知的行为。
*   **丰富交互**: 通过 `UNNotificationAction` 和 `UNNotificationCategory`，可以为通知添加自定义的操作按钮。

通过熟练使用 `UserNotifications` 框架，你可以极大地增强应用的提醒、互动和用户召回能力。
