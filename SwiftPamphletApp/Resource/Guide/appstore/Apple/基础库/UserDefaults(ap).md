# UserDefaults：轻量级本地持久化

\`UserDefaults\` 是 iOS 和 macOS 平台上最基础、最常用的轻量级数据存储方案。它本质上是读写应用沙盒中一个基于 XML/Plist 格式的配置文件的封装。

## 1. 适用场景

*   **应该使用的地方**：存储极其少量的用户偏好设置（如是否开启夜间模式、App 是否是第一次启动、用户选择的排序方式）。
*   **绝对禁止的地方**：
    *   **敏感数据**：千万不要存密码或 Token，它没有任何加密保护（应该用 Keychain）。
    *   **海量数据**：千万不要把庞大的 JSON 数组或几兆的图片 Data 塞进去。\`UserDefaults\` 会在 App 启动时被一次性全量加载到内存中，存储大文件会导致极其严重的性能和内存问题。

## 2. 基础读写操作

\`UserDefaults.standard\` 提供了一个全局共享的单例。

```swift
// 写入数据
let defaults = UserDefaults.standard
defaults.set(true, forKey: "isFirstLaunch")
defaults.set("John", forKey: "username")
defaults.set(25.5, forKey: "fontSize")

// 读取数据 (如果 key 不存在，基本类型会返回默认值，比如 Bool 默认返回 false)
let isFirstLaunch = defaults.bool(forKey: "isFirstLaunch")
// 对象类型会返回 Optional
let name = defaults.string(forKey: "username") ?? "Unknown" 
```

### 删除数据
```swift
defaults.removeObject(forKey: "username")
```

## 3. 在 SwiftUI 中的优雅使用：@AppStorage

在 SwiftUI 中，Apple 引入了 \`@AppStorage\` 这个属性包装器（Property Wrapper）。它完美地将 \`UserDefaults\` 的读写与视图的响应式状态刷新结合在了一起。

你不再需要手动调用 \`set\` 和 \`get\`，甚至不需要 \`@State\`。

```swift
import SwiftUI

struct SettingsView: View {
    // 声明一个与 UserDefaults 绑定的变量。
    // "isDarkMode" 是 key，false 是默认值。
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    var body: some View {
        Form {
            // 当用户拨动开关时，isDarkMode 的值改变，
            // SwiftUI 会自动将其写入 UserDefaults，并触发视图刷新！
            Toggle("夜间模式", isOn: $isDarkMode)
        }
    }
}
```

## 4. 存储自定义模型 (Codable)

\`UserDefaults\` 原生只支持存储系统基础类型（String, Int, Data, Date, Array, Dictionary 等）。
如果你想存一个自定义的 \`struct\`，必须先把它编码为 \`Data\`。

```swift
struct UserProfile: Codable {
    let name: String
    let age: Int
}

let profile = UserProfile(name: "Alice", age: 30)

// 写入：先用 JSONEncoder 转成 Data
if let encodedData = try? JSONEncoder().encode(profile) {
    UserDefaults.standard.set(encodedData, forKey: "currentUser")
}

// 读取：取出 Data，再解码回 UserProfile
if let savedData = UserDefaults.standard.data(forKey: "currentUser"),
   let decodedProfile = try? JSONDecoder().decode(UserProfile.self, from: savedData) {
    print(decodedProfile.name)
}
```

## 5. App Groups 跨进程共享

默认的 \`UserDefaults.standard\` 只在你的主 App 沙盒里有效。
如果你开发了一个 Widget（小组件）或者 Share Extension，想要它们能读取主 App 里的配置设置，你必须：
1. 在 Xcode 的开发者证书配置中开启 \`App Groups\` 功能。
2. 创建一个以 \`group.com.yourcompany.app\` 命名的容器。
3. **不能**使用 \`.standard\`，必须使用 \`suiteName\` 初始化实例：

```swift
// 在主 App 和 小组件 中，都使用这个特定的 suiteName 实例来读写
let sharedDefaults = UserDefaults(suiteName: "group.com.yourcompany.app")
sharedDefaults?.set("Hello Widget", forKey: "sharedMessage")
```
*(注意：在 SwiftUI 中对应的写法是 \`@AppStorage("sharedMessage", store: UserDefaults(suiteName: "group.com..."))\` )*
