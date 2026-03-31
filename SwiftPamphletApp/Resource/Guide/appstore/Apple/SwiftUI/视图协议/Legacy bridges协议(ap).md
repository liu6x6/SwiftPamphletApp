# SwiftUI 与旧框架的桥接协议

尽管 SwiftUI 是苹果 UI 开发的未来，但在可预见的将来，我们仍然需要在 SwiftUI 和旧有的命令式框架（`UIKit` for iOS/tvOS, `AppKit` for macOS）之间进行协作。SwiftUI 提供了一套强大的“桥接”协议，使得我们可以在两个世界之间无缝地嵌入和交互视图及视图控制器。

这套桥接系统的核心是 `UIViewRepresentable` 和 `UIViewControllerRepresentable` (对于 UIKit)，以及 `NSViewRepresentable` 和 `NSViewControllerRepresentable` (对于 AppKit)。

## `UIViewRepresentable` / `NSViewRepresentable`

这两个协议允许你将一个 `UIKit` 的 `UIView` 或一个 `AppKit` 的 `NSView` 封装成一个完全合格的 SwiftUI 视图。这在你需要使用 SwiftUI 尚未提供，或者 `UIKit`/`AppKit` 中功能更成熟的组件时非常有用，例如 `MKMapView` (地图) 或 `WKWebView` (网页)。

要遵循此协议，你需要实现两个核心方法：

1.  **`makeUIView(context: Context)`** (或 `makeNSView`): 在这个方法中，创建并返回你的 `UIView`/`NSView` 实例。这个方法只会在视图的生命周期中被调用一次。
2.  **`updateUIView(_ uiView: UIViewType, context: Context)`** (或 `updateNSView`): 当 SwiftUI 视图的状态发生变化时，这个方法会被调用。你可以在这里用 SwiftUI 的最新状态来更新你的 `UIView`/`NSView`。

### 示例：封装一个 `UISlider`

假设我们需要一个带有特定外观的滑块，而 SwiftUI 的 `Slider` 无法满足要求。

```swift
import SwiftUI
import UIKit

// 1. 创建遵循 UIViewRepresentable 的结构体
struct CustomSlider: UIViewRepresentable {
    // 接收一个到 Double 的绑定，以便与 SwiftUI 状态交互
    @Binding var value: Double

    // 2. 创建 UIView 实例
    func makeUIView(context: Context) -> UISlider {
        let slider = UISlider()
        slider.minimumValue = 0
        slider.maximumValue = 100
        // 添加一个 target-action 来响应值的变化
        slider.addTarget(
            context.coordinator, // 使用 Coordinator
            action: #selector(Coordinator.valueChanged(_:)),
            for: .valueChanged
        )
        return slider
    }

    // 3. 用 SwiftUI 状态更新 UIView
    func updateUIView(_ uiView: UISlider, context: Context) {
        // 确保 UIView 的值与 SwiftUI 的状态同步
        uiView.value = Float(self.value)
    }

    // 4. 创建 Coordinator 来处理代理和回调
    func makeCoordinator() -> Coordinator {
        Coordinator(value: $value)
    }

    // 5. 定义 Coordinator 类
    class Coordinator: NSObject {
        var value: Binding<Double>

        init(value: Binding<Double>) {
            self.value = value
        }

        @objc func valueChanged(_ sender: UISlider) {
            // 当 UISlider 的值变化时，更新 SwiftUI 的绑定
            self.value.wrappedValue = Double(sender.value)
        }
    }
}

// 在 SwiftUI 视图中使用
struct RepresentableExample: View {
    @State private var sliderValue: Double = 50

    var body: some View {
        VStack {
            Text("自定义滑块值: \(Int(sliderValue))")
            CustomSlider(value: $sliderValue)
                .padding()
        }
    }
}
```

### `Coordinator` 的作用

`Coordinator` 是连接 SwiftUI 和旧框架事件处理机制的关键。在 `UIKit`/`AppKit` 中，我们通常使用代理（delegates）、目标-动作（target-action）或闭包回调来处理用户交互。`Coordinator` 的职责就是：

*   **充当代理**: 遵循 `UIView` 的代理协议（如 `UIScrollViewDelegate`）。
*   **提供回调方法**: 为 `target-action` 模式提供 `@objc` 方法。
*   **将旧框架的事件转换回 SwiftUI**: 在 `Coordinator` 的方法中，更新传递给它的 SwiftUI `Binding`，从而将事件通知回 SwiftUI 的世界。

## `UIViewControllerRepresentable` / `NSViewControllerRepresentable`

这两个协议的工作方式与视图代表（View Representable）非常相似，但它们用于封装整个视图控制器 (`UIViewController` / `NSViewController`)。

这在你需要集成一个功能完整的、由视图控制器管理的屏幕时非常有用，例如 `UIImagePickerController` (图片选择器) 或 `MFMailComposeViewController` (邮件发送)。

你需要实现 `makeUIViewController(context:)` 和 `updateUIViewController(_:context:)` 方法，其逻辑与视图代表完全相同。

## SwiftUI 嵌入旧框架

反向操作也是可能的：将一个 SwiftUI 视图嵌入到一个 `UIKit` 或 `AppKit` 的布局中。这通过 `UIHostingController` (或 `NSHostingController`) 来实现。

`UIHostingController` 是一个标准的 `UIViewController`，但它的 `view` 属性是由你提供的一个 SwiftUI 视图来驱动的。

```swift
// 假设你有一个 SwiftUI 视图
struct MySwiftUIView: View {
    var body: some View {
        Text("Hello from SwiftUI!").font(.largeTitle)
    }
}

// 在一个 UIKit 的 ViewController 中使用它
class MyViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        // 1. 创建 UIHostingController
        let swiftUIController = UIHostingController(rootView: MySwiftUIView())
        
        // 2. 将其作为子视图控制器添加
        addChild(swiftUIController)
        view.addSubview(swiftUIController.view)
        
        // 3. 设置布局
        swiftUIController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            swiftUIController.view.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            swiftUIController.view.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
        
        swiftUIController.didMove(toParent: self)
    }
}
```

## 总结

SwiftUI 的桥接协议是实现渐进式迁移和利用两个框架优势的关键。它们提供了一个强大而灵活的机制，让你可以在新旧代码之间无缝过渡。

*   **SwiftUI -> 旧框架**: 当你需要一个 SwiftUI 中不存在或功能不完善的组件时，使用 `(UI/NS)View(Controller)Representable` 将旧组件封装成 SwiftUI 视图。
    *   使用 `Coordinator` 来处理代理和回调。

*   **旧框架 -> SwiftUI**: 当你想在一个现有的 `UIKit`/`AppKit` 应用中，逐步引入新的 SwiftUI 视图时，使用 `(UI/NS)HostingController` 来承载 SwiftUI 视图。

熟练掌握这些桥接技术，将使你能够在任何项目中，根据实际需求自由地选择和组合最合适的工具，无论是 SwiftUI 还是旧有的框架。
