# iOS/macOS 应用的程序入口点

每个应用程序都需要一个“入口点”（Entry Point），这是操作系统在启动应用时调用的第一个代码。它负责初始化应用、设置主事件循环，并开始渲染用户界面。在苹果生态的开发历史中，这个入口点的形式也经历了一系列演进。

## 传统的 `main` 文件与 `UIApplicationMain`

在 SwiftUI 出现之前，以及在一些需要深度定制启动流程的场景中，iOS 应用的入口点通常是一个名为 `main.swift` 的文件。在这个文件中，你会调用 `UIApplicationMain` 函数。

```swift
// main.swift (传统方式)
import UIKit

UIApplicationMain(
    CommandLine.argc,       // 命令行参数计数
    CommandLine.unsafeArgv, // 命令行参数值
    nil,                    // Principal class name, nil for UIApplication
    NSStringFromClass(AppDelegate.self) // App Delegate class name
)
```

这个函数做了几件关键的事情：
1.  创建 `UIApplication` 的单例对象，这是应用的核心。
2.  创建你在第四个参数中指定的 `AppDelegate` 的实例。
3.  设置主事件循环（`RunLoop`），开始接收和分发触摸、通知等事件。
4.  加载应用的初始 UI（通常是从 `Info.plist` 中指定的 `Main.storyboard`）。

`AppDelegate` 在这个模型中扮演着至关重要的角色，它负责响应应用的生命周期事件，如 `application(_:didFinishLaunchingWithOptions:)`, `applicationWillResignActive`, `applicationDidEnterBackground` 等。

## `@UIApplicationMain` / `@NSApplicationMain` 属性

为了简化上述过程，Swift 引入了 `@UIApplicationMain` (iOS) 和 `@NSApplicationMain` (macOS) 这两个属性。当你将这个属性标记在你的 `AppDelegate` (或 `NSApplicationDelegate`) 类上时，编译器会自动为你生成一个包含 `main` 函数和 `UIApplicationMain` 调用的“隐式” `main.swift` 文件。

```swift
// AppDelegate.swift
import UIKit

@UIApplicationMain // 告诉编译器自动生成 main 入口点
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // 应用启动后的自定义设置
        return true
    }
    
    // ... 其他生命周期方法
}
```

这种方式避免了手动创建 `main.swift` 文件，成为了在 UIKit/AppKit 时代创建应用的标准方式。

## SwiftUI 的 `@main` 属性 (现代方式)

随着 SwiftUI 的推出，苹果引入了一种全新的、更简洁、更具声明性的方式来定义应用入口点：`@main` 属性。

`@main` 是一个类型属性，你可以将它应用于一个遵循 `App` 协议的结构体上。这完全取代了 `AppDelegate` 和 `UIApplicationMain` 的传统模式。

```swift
import SwiftUI

@main // 标记 MyApp 为应用的入口点
struct MyApp: App { // 遵循 App 协议
    
    // body 属性定义了应用的场景（UI 层级）
    var body: some Scene {
        WindowGroup { // WindowGroup 是一个场景，代表一个窗口
            ContentView() // 窗口中显示的根视图
        }
    }
}
```

### `@main` 的工作原理

当你使用 `@main` 时，编译器会：
1.  识别出 `MyApp` 是程序的入口。
2.  自动为你生成一个 `main` 函数。
3.  在这个 `main` 函数中，调用 `MyApp.main()`，启动 SwiftUI 应用的生命周期管理。
4.  SwiftUI 框架在内部处理了所有关于创建 `UIApplication`、设置场景、管理窗口和事件循环的复杂工作。

这种方式的巨大优势在于：
*   **声明式**: 你只需要声明你的应用包含哪些场景 (`Scene`) 和视图 (`View`)，而无需关心底层的命令式设置代码。
*   **简洁**: 代码量大大减少，结构更清晰。
*   **跨平台**: 同一套 `@main` 和 `App` 协议的结构，可以同时适用于 iOS, macOS, watchOS 等多个平台。

## 在 SwiftUI 应用中重新引入 AppDelegate

尽管 `@main` 是现代 SwiftUI 应用的首选，但有时你仍然需要处理一些传统的、只能通过 `AppDelegate` 来响应的事件，例如注册远程推送通知、处理特定的应用启动链接等。

SwiftUI 提供了 `@UIApplicationDelegateAdaptor` (iOS) 和 `@NSApplicationDelegateAdaptor` (macOS) 属性包装器，让你可以在 SwiftUI 应用中平滑地集成一个 `AppDelegate`。

```swift
import SwiftUI

// 1. 像以前一样定义一个 AppDelegate
class MyAppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        print("App Delegate: didFinishLaunchingWithOptions")
        // 在这里执行传统的启动时任务，如配置第三方库
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // 处理推送通知的 device token
    }
}

@main
struct MyApp: App {
    // 2. 使用属性包装器来连接 AppDelegate
    @UIApplicationDelegateAdaptor(MyAppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

通过这种方式，你既可以享受 `@main` 带来的声明式便利，又不会失去访问底层应用生命周期事件的能力。SwiftUI 会自动创建 `MyAppDelegate` 的实例，并将其连接到应用的生命周期中。

## 总结

| 入口点方式 | 框架 | 优点 | 缺点 |
| :--- | :--- | :--- | :--- |
| `main.swift` + `UIApplicationMain` | UIKit/AppKit | 完全控制启动流程。 | 繁琐，样板代码多。 |
| `@UIApplicationMain` | UIKit/AppKit | 简化了入口点，无需 `main.swift`。 | 仍然强依赖于 `AppDelegate`。 |
| `@main` + `App` 协议 | **SwiftUI** | **声明式、简洁、跨平台。** | 某些底层事件需要额外处理。 |
| `@main` + `@UIApplicationDelegateAdaptor` | **SwiftUI** | **两全其美**：兼具 SwiftUI 的简洁和 AppDelegate 的底层能力。 | 增加了少量复杂性。 |

对于所有新的 SwiftUI 项目，`@main` 都是标准的、推荐的入口点定义方式。当你需要处理推送通知、通用链接等高级功能时，再通过 `@UIApplicationDelegateAdaptor` 来引入 `AppDelegate`，这是一种清晰、现代且可扩展的架构方式。
