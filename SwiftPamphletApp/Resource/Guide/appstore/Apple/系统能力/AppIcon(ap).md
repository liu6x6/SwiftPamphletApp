# iOS/macOS 系统能力：动态更换 App 图标

从 iOS 10.3 开始，苹果允许应用在运行时动态地更改其主屏幕图标。这个功能为开发者提供了一种强大的方式来增加应用的个性化、响应用户的操作或庆祝特殊的事件。

常见的应用场景包括：
*   **主题切换**: 允许用户在应用的设置中选择不同的 App 图标主题。
*   **订阅奖励**: 为订阅了高级版本的用户提供专属的 App 图标。
*   **节日或活动**: 在特定的节日（如圣诞节）或活动期间，自动更换为节日主题的图标。

## 实现核心

实现动态更换 App 图标的核心是调用 `UIApplication.shared.setAlternateIconName()` 方法。这个过程需要满足几个前提条件。

### 1. 在 `Info.plist` 中声明备选图标

你必须在你的项目的 `Info.plist` 文件中，明确地声明所有你希望能够动态切换的备选图标。

1.  **准备图标文件**: 将你的所有图标文件（包括主图标和所有备选图标）添加到你的项目 Target 中。**注意：备选图标不应该放在 `Assets.xcassets` 中**，而应该作为普通的文件资源直接添加到项目中。

2.  **配置 `Info.plist`**: 
    *   找到 `Icon files (iOS 5)` (或 `CFBundleIcons`) 键。
    *   在其下，找到 `CFBundleAlternateIcons` 键（如果不存在，则创建一个类型为 `Dictionary` 的新键）。
    *   在 `CFBundleAlternateIcons` 字典中，为你的**每一个**备选图标创建一个新的键。这个键的名称就是你将来在代码中用来调用该图标的名称。
    *   每个备选图标的键对应一个字典，其中必须包含 `CFBundleIconFiles` (一个 `Array` 类型的键) 和 `UIPrerenderedIcon` (一个 `Boolean` 类型的键，通常设为 `NO`)。
    *   在 `CFBundleIconFiles` 数组中，放入你的图标文件的**文件名**（不含扩展名）。

一个典型的 `Info.plist` 源码配置如下：

```xml
<key>CFBundleIcons</key>
<dict>
    <key>CFBundlePrimaryIcon</key>
    <dict>
        <key>CFBundleIconFiles</key>
        <array>
            <string>AppIcon</string>
        </array>
    </dict>
    <key>CFBundleAlternateIcons</key>
    <dict>
        <key>darkIcon</key> <!-- 这是你在代码中使用的名字 -->
        <dict>
            <key>CFBundleIconFiles</key>
            <array>
                <string>my-dark-icon</string> <!-- 这是图标文件的名字 -->
            </array>
            <key>UIPrerenderedIcon</key>
            <false/>
        </dict>
        <key>lightIcon</key>
        <dict>
            <key>CFBundleIconFiles</key>
            <array>
                <string>my-light-icon</string>
            </array>
            <key>UIPrerenderedIcon</key>
            <false/>
        </dict>
    </dict>
</dict>
```

### 2. 调用 `setAlternateIconName()`

在你的代码中，调用 `UIApplication.shared.setAlternateIconName()` 来执行切换。

*   **切换到备选图标**: 传入你在 `Info.plist` 中定义的备选图标的**键名**。
*   **恢复到主图标**: 传入 `nil`。

这个方法是一个**异步**方法，它会接收一个完成回调（`completionHandler`），你可以在其中检查切换是否成功。

```swift
import SwiftUI

struct AppIconChangerView: View {
    // 通过 @Environment 读取 application 对象
    @Environment(\.scenePhase) private var scenePhase
    
    // 获取当前备选图标的名称
    private var currentIconName: String? {
        return UIApplication.shared.alternateIconName
    }

    var body: some View {
        Form {
            Section(header: Text("选择你的 App 图标")) {
                Button("默认图标") {
                    changeAppIcon(to: nil) // 传入 nil 来恢复主图标
                }
                .disabled(currentIconName == nil)
                
                Button("深色图标") {
                    changeAppIcon(to: "darkIcon")
                }
                .disabled(currentIconName == "darkIcon")
                
                Button("浅色图标") {
                    changeAppIcon(to: "lightIcon")
                }
                .disabled(currentIconName == "lightIcon")
            }
        }
    }

    func changeAppIcon(to iconName: String?) {
        // 检查当前应用是否支持更换图标
        guard UIApplication.shared.supportsAlternateIcons else {
            print("应用不支持更换图标。")
            return
        }

        // 调用异步方法来更换图标
        UIApplication.shared.setAlternateIconName(iconName) { error in
            if let error = error {
                print("更换图标失败: \(error.localizedDescription)")
            } else {
                print("图标更换成功！")
            }
        }
    }
}

#Preview {
    AppIconChangerView()
}
```

在这个 SwiftUI 示例中：
*   我们创建了一个简单的设置界面，包含几个按钮。
*   `changeAppIcon(to:)` 函数是核心逻辑。它首先检查 `supportsAlternateIcons` 属性，然后调用 `setAlternateIconName`。
*   当用户点击按钮时，系统会弹出一个**标准的系统警告框**，询问用户是否同意更改 App 图标。这是系统的强制行为，无法跳过。

## 注意事项

*   **需要用户确认**: 每次更换图标，系统都会弹出一个警告框请求用户确认。你无法以编程方式静默地更换图标。
*   **异步操作**: `setAlternateIconName` 是一个异步方法。你应该在其 `completionHandler` 中处理可能发生的错误。
*   **仅限应用内触发**: 图标的更换只能由用户在应用内的操作来触发，不能在后台或通过推送通知来触发。
*   **图标文件要求**: 确保你的备选图标文件也符合 App Store 的尺寸要求（例如，提供 `@2x` 和 `@3x` 版本），并将它们直接添加到你的项目 Target 中，而不是 `Assets.xcassets`。

## 总结

动态更换 App 图标是一个能够显著提升应用个性化和用户参与度的强大功能。

*   **核心 API**: `UIApplication.shared.setAlternateIconName()`。
*   **关键配置**: 必须在 `Info.plist` 的 `CFBundleAlternateIcons` 键中预先声明所有备选图标及其文件名。
*   **用户交互**: 切换操作必须由用户在应用内发起，并会触发一个系统级的确认弹窗。

通过遵循苹果的规范，你可以安全、可靠地为你的用户提供选择自己喜欢的 App 图标的乐趣。
