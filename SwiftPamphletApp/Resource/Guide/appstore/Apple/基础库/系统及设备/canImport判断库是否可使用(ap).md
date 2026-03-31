# #if canImport()：跨平台模块的条件编译

在 Swift 中，**\`#if canImport(ModuleName)\`** 是一个极其重要的编译控制指令（Compiler Directive）。它主要用于处理**跨平台代码共享**以及**可选依赖库**的优雅降级。

## 1. 为什么需要 canImport()？

随着 Apple 生态的扩张（iOS, macOS, watchOS, tvOS, visionOS），很多开发者希望写一份 Swift 源码就能跑在所有平台上。

然而，不同平台拥有的底层框架是不一样的：
*   \`UIKit\` 只存在于 iOS/tvOS/visionOS，在 macOS 上是不存在的。
*   \`AppKit\` 只存在于 macOS。
*   某些特定的硬件驱动框架（如 \`HealthKit\`, \`ARKit\`）可能在某些老版本系统或特定平台上缺失。

如果你在一个 macOS 项目中直接写 \`import UIKit\`，编译器会立即报错并停止编译。为了解决这个问题，我们需要使用 \`#if canImport()\`。

## 2. 核心用法：跨平台 UI 适配

这是最经典的使用场景。你可以通过这个宏，在一个文件中同时兼容 iOS 和 macOS 的颜色和图片类型：

```swift
// 如果编译器发现当前环境可以导入 UIKit (说明是 iOS 等移动端环境)
#if canImport(UIKit)
import UIKit
typealias AppColor = UIColor
typealias AppImage = UIImage

// 如果不能导入 UIKit，再检查能否导入 AppKit (说明是 macOS 环境)
#elseif canImport(AppKit)
import AppKit
typealias AppColor = NSColor
typealias AppImage = NSImage

#else
// 兜底逻辑，比如纯 Linux 服务端环境
#error("不支持的平台，缺少必要的 UI 框架")
#endif

// 业务代码：现在你可以无缝使用 AppColor，编译器会在底层自动替换为 UIColor 或 NSColor
struct MyTheme {
    static let primaryColor: AppColor = .blue
}
```

## 3. 与 #if os() 的区别与选择

你可能也见过 \`#if os(iOS)\` 这样的写法。它们有什么区别？

*   **\`#if os(iOS)\`**：判断当前编译的目标**操作系统**是不是 iOS。
*   **\`#if canImport(UIKit)\`**：判断当前环境**是否拥有并能够导入** \`UIKit\` 这个模块。

**为什么强烈推荐使用 \`canImport\`？**
因为系统环境是会演进的！比如 **Mac Catalyst** 技术。
如果你写了 \`#if os(iOS)\`，在 Mac Catalyst 环境下（本质是在 Mac 上跑 iOS 代码），这个宏为 false，你的 iOS UI 代码就不会被编译，导致各种问题。
但如果你写的是 \`#if canImport(UIKit)\`，因为 Catalyst 环境下 Apple 注入了 UIKit，这个条件为真，你的代码就能完美兼容原生 iOS 和 Mac Catalyst。

**结论：当你是因为需要某个框架（如 UIKit, WatchKit）才做条件判断时，永远优先使用 \`#if canImport()\`。只有当你的逻辑确实与某个具体操作系统死死绑定时，才使用 \`#if os()\`。**

## 4. 可选第三方依赖处理 (Optional Dependencies)

在开发大型开源 SDK 或 Swift Package 时，\`canImport\` 也非常有用。
假设你写了一个日志库，如果用户的主工程里碰巧安装了 \`Alamofire\`，你希望提供一个自动上传日志的扩展功能；如果没安装，也不报错。

```swift
// 在你的日志库源码中：

#if canImport(Alamofire)
import Alamofire

extension Logger {
    func uploadLogToNetwork() {
        AF.request("https://api.log.com/upload", method: .post).response { _ in }
    }
}
#endif
```
只要主工程没有把 Alamofire 加入依赖图，这段代码在编译时就会被直接抹去，仿佛它从未存在过一样，做到了极其优雅的解耦。
