# iOS/macOS 系统能力：推送通知 (Push Notifications)

推送通知（Push Notifications）是移动应用与用户保持互动、传递重要信息和提升用户活跃度的最重要渠道之一。它允许你的服务器在应用未在前台运行时，向用户的设备发送一条简短的通知消息。

整个推送流程涉及三个主要角色：
1.  **你的服务器 (Provider Server)**: 负责构建通知的内容（Payload）并决定何时发送。
2.  **苹果推送通知服务 (APNs - Apple Push Notification service)**: 苹果官方的、安全的消息中继服务。你的服务器将通知发送给 APNs，APNs 负责将其可靠地传递到目标设备。
3.  **用户的设备 (User's Device)**: 接收来自 APNs 的通知，并将其显示给用户或传递给你的应用进行处理。

## 实现步骤概览

### 1. 启用推送通知能力

*   **Apple Developer 网站**: 在你的应用的 “Identifier” 配置中，启用 “Push Notifications” 服务。你需要为此 App ID 创建一个 APNs 认证密钥（`.p8` 文件）或证书（`.p12` 文件）。`.p8` 密钥是更现代、更推荐的方式，因为它可用于多个应用，且不会过期。
*   **Xcode 项目**: 在 “Signing & Capabilities” 标签页中，添加 “Push Notifications” 能力。

### 2. 请求用户授权

在你的应用首次尝试发送通知之前，必须向用户请求授权。

```swift
import UserNotifications

func requestNotificationAuthorization() {
    let center = UNUserNotificationCenter.current()
    center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
        if let error = error {
            print("请求授权失败: \(error)")
            return
        }
        
        if granted {
            print("用户已授权")
            // 授权成功后，立即在主线程上请求注册 device token
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        } else {
            print("用户已拒绝")
        }
    }
}
```

*   `options`: 你可以请求多种通知权限，如 `.alert` (显示弹窗), `.sound` (播放声音), `.badge` (在 App 图标上显示角标)。

### 3. 获取 Device Token

如果用户同意授权，你的应用需要向 APNs 注册，以获取一个唯一的、用于标识该设备上该应用的 **Device Token**。这是一个加密的字符串。

你需要在你的 `AppDelegate` 中实现以下两个代理方法：

```swift
class AppDelegate: NSObject, UIApplicationDelegate {
    // 注册成功时调用
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // 将 Data 类型的 token 转换为十六进制字符串
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("获取到 Device Token: \(tokenString)")
        
        // **关键步骤**: 将这个 tokenString 发送到你的服务器
        // 你的服务器需要保存这个 token，以便将来向这个特定的设备发送通知
        sendTokenToServer(tokenString)
    }

    // 注册失败时调用
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("注册推送通知失败: \(error)")
    }
}
```

**获取 Device Token 是整个流程中最关键的一步**。你必须将这个 Token 安全地发送并存储在你的服务器上。没有它，你的服务器就无法知道应该将通知发送到哪个设备。

### 4. 服务器端：发送推送通知

当你的服务器想要发送一个推送通知时，它需要：

1.  **构建 Payload**: 创建一个 JSON 对象，其中包含了通知的所有内容。这个 JSON 对象被称为 Payload。

    ```json
    {
        "aps": {
            "alert": {
                "title": "新消息",
                "subtitle": "来自 John Appleseed",
                "body": "嗨，这个周末有空一起写代码吗？"
            },
            "sound": "default",
            "badge": 1
        },
        "custom_data": {
            "user_id": "12345"
        }
    }
    ```
    *   `aps` 字典是系统保留的关键字，用于定义通知的标准部分（弹窗、声音、角标）。
    *   你可以在 `aps` 之外添加任何自定义的键值对（如 `custom_data`），这些数据会随着通知一起被传递到你的应用中。

2.  **发送到 APNs**: 你的服务器需要与 APNs 建立一个安全的连接（使用之前获取的 `.p8` 密钥进行认证），然后将 **Payload** 和目标设备的 **Device Token** 一起发送给 APNs。

    这通常需要使用一个服务器端的库，例如 Node.js 的 `node-apn`，Python 的 `apns2`，或直接使用 `curl` 和 HTTP/2 协议与 APNs API 进行交互。

### 5. 客户端：接收和处理通知

当你的应用在前台或后台运行时，收到的推送通知会通过 `AppDelegate` 的代理方法进行传递。

*   **应用在前台时收到通知**:

    ```swift
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // 在这里，你可以决定前台通知应该如何显示
        // .banner, .sound, .badge, .list
        completionHandler([.banner, .sound])
    }
    ```

*   **用户点击通知横幅，或在应用未运行时通过通知启动应用**:

    ```swift
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        
        // 在这里处理通知的 payload，例如进行页面跳转
        if let userID = userInfo["custom_data"] as? [String: String] {
            // ... 跳转到与 userID 相关的聊天页面 ...
        }
        
        completionHandler()
    }
    ```

要接收这些回调，你需要在 `AppDelegate` 的 `didFinishLaunchingWithOptions` 中，将 `UNUserNotificationCenter.current().delegate` 设置为 `self`。

## 总结

推送通知是一个涉及客户端、苹果服务器和你的后端服务器三方协作的复杂系统。

*   **客户端职责**: 
    1.  请求用户授权。
    2.  获取 **Device Token** 并发送给你的服务器。
    3.  处理接收到的通知（例如，在前台时如何显示，用户点击后如何响应）。
*   **服务器职责**: 
    1.  安全地存储每个用户的 Device Token。
    2.  在需要时，构建 JSON Payload，并使用 APNs 认证密钥，将通知和 Device Token 发送给 **APNs**。

尽管流程复杂，但推送通知是现代应用不可或缺的功能。通过它，你可以有效地与用户沟通，提升产品的活跃度和用户粘性。
