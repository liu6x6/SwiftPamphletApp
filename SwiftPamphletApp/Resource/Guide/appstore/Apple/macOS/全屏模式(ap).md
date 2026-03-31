# macOS 上的全屏模式

在 macOS 上，为用户提供一个沉浸式的、无干扰的全屏工作模式，对于许多类型的应用（如视频播放器、游戏、演示文稿应用、专业创意工具等）来说是一项至关重要的功能。macOS 系统为窗口的全屏化提供了标准的 UI 和 API。

## 用户的视角：标准的全屏行为

对于用户来说，进入和退出全屏模式通常通过点击窗口左上角的**绿色“交通灯”按钮**来完成。当鼠标悬停在该按钮上时，会弹出一个菜单，其中包含“进入全屏”选项。进入全屏模式后，应用的菜单栏会自动隐藏，窗口会占据整个屏幕，并拥有一个自己独立的“空间”（Space）。用户可以通过触控板手势（通常是三指或四指横扫）在不同的全屏应用和桌面空间之间切换。

## AppKit 中的实现 (`NSWindow`)

在传统的 AppKit 开发中，对窗口全屏行为的控制主要通过 `NSWindow` 的 `collectionBehavior` 属性和 `toggleFullScreen(_:)` 方法来实现。

```swift
import AppKit

class MyWindowController: NSWindowController {
    override func windowDidLoad() {
        super.windowDidLoad()
        
        // 允许窗口进入全屏模式
        window?.collectionBehavior = .fullScreenPrimary
    }
    
    // 可以将一个菜单项或按钮的 action 连接到这个方法
    @IBAction func toggleFullScreen(_ sender: Any?) {
        window?.toggleFullScreen(sender)
    }
}
```

*   **`collectionBehavior`**: 这是一个 `NSWindow.CollectionBehavior` 选项集，用于定义窗口在系统环境（如 Mission Control 和全屏模式）中的行为。
    *   `.fullScreenPrimary`: 允许窗口成为一个主要的全屏窗口。
    *   `.fullScreenAuxiliary`: 允许窗口作为辅助窗口，可以浮动在全屏空间之上（例如，一个工具面板）。

## SwiftUI 中的实现

在纯 SwiftUI 应用中，你不能直接访问 `NSWindow`。那么如何控制全屏行为呢？

### 1. 默认行为

好消息是，对于一个标准的 SwiftUI `WindowGroup` 场景，其创建的窗口**默认就支持全屏模式**。你无需编写任何额外的代码，窗口左上角的绿色按钮就会自动包含“进入全屏”的功能。

```swift
import SwiftUI

@main
struct MyMacApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

### 2. 隐藏标题栏和工具栏 (`.toolbar(.hidden, for: .windowToolbar)`)

在创建沉浸式的全屏体验时，一个常见的需求是在进入全屏后，自动隐藏窗口的标题栏和工具栏。

从 macOS 13 开始，你可以使用 `.toolbar()` 修饰符的一个新变体来实现这一点。

```swift
struct FullScreenContentView: View {
    @Environment(\.isPresented) private var isPresented

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            Text("沉浸式全屏内容")
                .foregroundColor(.white)
                .font(.largeTitle)
        }
        // 当视图被呈现时（例如，在一个窗口中），隐藏窗口的工具栏
        .toolbar(.hidden, for: .windowToolbar)
    }
}
```

当包含 `FullScreenContentView` 的窗口进入全屏模式时，由于内容视图请求隐藏窗口工具栏，整个标题栏区域都会消失，从而提供一个完全无边框的沉浸式体验。

### 3. 以编程方式进入全屏

在 SwiftUI 中，没有一个直接的、跨平台的 API 来命令一个窗口进入全屏。这个操作在设计上是由用户通过标准的窗口控件来触发的。

如果你确实需要在代码中触发全屏，你将需要“深入”到 AppKit 层来获取当前的 `NSWindow` 实例，然后调用它的 `toggleFullScreen(_:)` 方法。这通常通过 `NSApplication.shared.keyWindow` 或 `NSApplication.shared.windows` 来实现。

```swift
func enterFullScreen() {
    guard let window = NSApplication.shared.keyWindow else { return }
    
    // 检查窗口是否已经处于全屏状态
    if !window.styleMask.contains(.fullScreen) {
        window.toggleFullScreen(nil)
    }
}
```

**注意**: 这种方法混合了 SwiftUI 和 AppKit 的概念，应该只在确实需要时才谨慎使用。对于大多数应用来说，让用户通过标准的系统控件来控制全屏是最佳实践。

## 总结

在 macOS 上，全屏模式是一个由系统管理的、用户熟悉的核心功能。

*   **SwiftUI 默认支持**: 使用 `WindowGroup` 创建的窗口默认就支持用户通过点击绿色按钮来进入全屏。
*   **沉浸式体验**: 要在全屏时获得无边框的沉浸式体验，可以在你的内容视图上使用 `.toolbar(.hidden, for: .windowToolbar)` 来隐藏标题栏和工具栏。
*   **编程式控制**: 虽然不推荐，但如果必须，可以通过访问 `NSApplication.shared.keyWindow` 来获取 `NSWindow` 实例，并调用其 `toggleFullScreen(_:)` 方法来以编程方式触发全屏。

对于大多数 SwiftUI Mac 应用，你无需为全屏模式编写太多特定的代码。更重要的是设计好你的视图，使其能够在不同的窗口尺寸（从一个小窗口到全屏）下都能良好地自适应布局。
