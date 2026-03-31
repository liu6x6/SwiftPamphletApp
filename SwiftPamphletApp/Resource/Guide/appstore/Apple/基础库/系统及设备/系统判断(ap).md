# Swift 中的系统与设备信息获取

在开发跨平台或需要深度适配设备特性的应用时，获取当前运行环境的系统版本、设备型号、屏幕尺寸等信息是极其常见的需求。

## 1. 获取系统软件信息 (OS Version)

如果你只是想因为系统版本不同而执行不同代码，**绝对应该优先使用 \`#available\` 语法**（详见版本兼容一节）。

但如果你是要把用户的系统版本收集起来上报给后端（比如崩溃日志、数据埋点），你需要获取字符串格式的版本号。

```swift
import Foundation

// 获取系统名称，如 "iOS", "macOS", "iPadOS"
let osName = ProcessInfo.processInfo.operatingSystemVersionString 
// 返回类似 "Version 17.0.1 (Build 21A342)" 的极其详细的字符串

// 获取数字格式的版本结构体
let version = ProcessInfo.processInfo.operatingSystemVersion
print("Major: \(version.majorVersion), Minor: \(version.minorVersion)")
```

### 在 UIKit (iOS专属) 中获取
```swift
import UIKit
let systemName = UIDevice.current.systemName // "iOS" 或 "iPadOS"
let systemVersion = UIDevice.current.systemVersion // "17.0"
```

## 2. 获取硬件设备信息

### 基础设备类型判断
在编写跨平台 UI 时，我们经常需要判断当前是手机还是平板。

```swift
import UIKit

if UIDevice.current.userInterfaceIdiom == .pad {
    print("这是一台 iPad，请使用侧边栏布局")
} else if UIDevice.current.userInterfaceIdiom == .phone {
    print("这是一台 iPhone，请使用底部 Tab 布局")
} else if UIDevice.current.userInterfaceIdiom == .mac {
    print("这是运行在 macOS 上的 Catalyst 应用")
} else if UIDevice.current.userInterfaceIdiom == .vision {
    print("这是 Apple Vision Pro") // iOS 17+ 新增
}
```

### 获取具体的设备硬件标识 (Machine Identifier)
\`UIDevice.current.model\` 只能返回 "iPhone" 或 "iPad"。如果你需要极其精确地知道这是不是 "iPhone 15 Pro Max"（比如为了适配特定的灵动岛尺寸或摄像头特性），你需要读取底层的系统硬件信息。

```swift
import Foundation

func getDeviceIdentifier() -> String {
    var systemInfo = utsname()
    uname(&systemInfo)
    
    let machineMirror = Mirror(reflecting: systemInfo.machine)
    let identifier = machineMirror.children.reduce("") { identifier, element in
        guard let value = element.value as? Int8, value != 0 else { return identifier }
        return identifier + String(UnicodeScalar(UInt8(value)))
    }
    
    return identifier
    // 返回结果示例: 
    // "iPhone16,2" -> iPhone 15 Pro
    // "iPad14,1" -> iPad mini (6th generation)
    // "Mac14,2" -> MacBook Air (M2)
}
```
*(注意：拿到类似 \`iPhone16,2\` 的标识符后，通常需要你在项目中维护一个映射字典，将其翻译为用户友好的 "iPhone 15 Pro" 字符串。因为 Apple 每年都会发布新设备，这个字典需要持续更新。)*

## 3. 屏幕与物理特征状态

*   **获取电池电量与状态**（必须先开启电池监控）：
    ```swift
    UIDevice.current.isBatteryMonitoringEnabled = true
    let level = UIDevice.current.batteryLevel // 0.0 到 1.0
    let state = UIDevice.current.batteryState // .charging, .unplugged 等
    ```
*   **获取屏幕安全区域 (Safe Area) 与刘海屏判断**：
    通常在 \`UIApplication.shared.windows.first?.safeAreaInsets\` 中获取。如果有 bottom inset 大于 0，通常意味着这是一台全面屏（带 Home Indicator）的设备。
