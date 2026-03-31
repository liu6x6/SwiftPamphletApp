# SwiftUI 与 UIKit/AppKit 视图对标指南

对于有 UIKit (iOS) 或 AppKit (macOS) 开发经验的开发者来说，学习 SwiftUI 的一个有效方法是了解其视图组件与传统框架组件的对应关系。本指南旨在提供一个清晰的对标列表，帮助你快速将现有知识迁移到 SwiftUI。

## 核心概念转变

*   **UIViewController / NSViewController -> View**: 在 SwiftUI 中，没有传统意义上的视图控制器。`View` 协议本身承担了界面的定义、布局和状态管理。复杂的页面通常由多个小型、可复用的 `View` 组合而成。
*   **UIView / NSView -> View**: SwiftUI 的 `View` 是一个轻量级的结构体，它描述了 UI 的一部分，而不是像 `UIView` 那样是一个重量级的对象。SwiftUI 负责高效地渲染这些描述。
*   **Auto Layout -> 布局容器**: SwiftUI 使用 `VStack`, `HStack`, `ZStack`, `Grid` 等布局容器以及 `.padding()`, `.frame()` 等修饰符来管理布局，取代了 Auto Layout 的约束系统。

## 常用组件对标表

| UIKit / AppKit 组件 | SwiftUI 对应视图 | 简介与示例 |
| :--- | :--- | :--- |
| `UILabel` / `NSTextField` (label) | `Text` | 用于显示静态或动态的只读文本。 |
| | | ```swift
Text("Hello, SwiftUI!")
    .font(.title)
``` |
| `UIImageView` / `NSImageView` | `Image` | 用于显示图片，可以来自 app 的 asset catalog、SF Symbols 或网络。 |
| | | ```swift
Image(systemName: "star.fill")
    .foregroundColor(.yellow)
``` |
| `UIButton` / `NSButton` | `Button` | 响应用户点击操作的控件。 |
| | | ```swift
Button("Tap Me") {
    print("Button tapped!")
}
``` |
| `UITextField` / `NSTextField` (editable) | `TextField` | 用于接收单行文本输入。 |
| | | ```swift
@State private var username = ""
TextField("Username", text: $username)
``` |
| `UITextView` / `NSTextView` | `TextEditor` | 用于接收或显示多行文本。 |
| | | ```swift
@State private var content = ""
TextEditor(text: $content)
``` |
| `UISwitch` / `NSSwitch` | `Toggle` | 一个表示开/关状态的开关控件。 |
| | | ```swift
@State private var isOn = true
Toggle("Enable Feature", isOn: $isOn)
``` |
| `UISlider` / `NSSlider` | `Slider` | 允许用户在一定范围内选择一个值的滑块。 |
| | | ```swift
@State private var value = 0.5
Slider(value: $value, in: 0...1)
``` |
| `UIStepper` / `NSStepper` | `Stepper` | 用于增加或减少一个数值的控件。 |
| | | ```swift
@State private var quantity = 1
Stepper("Quantity: \(quantity)", value: $quantity, in: 1...10)
``` |
| `UIProgressView` / `NSProgressIndicator` | `ProgressView` | 显示任务进度的指示器，可以是线性的或圆形的。 |
| | | ```swift
ProgressView(value: 0.75)
// Indeterminate
ProgressView()
``` |
| `UITableView` / `NSTableView` | `List` | 用于显示单列、可滚动的行数据。 |
| | | ```swift
List(0..<10) { i in
    Text("Row \(i)")
}
``` |
| `UICollectionView` / `NSCollectionView` | `LazyVGrid`, `LazyHGrid`, `Grid` | 用于显示多行多列的网格布局。`Lazy` 版本会在视图进入屏幕时才创建它们。 |
| | | ```swift
let columns = [GridItem(.adaptive(minimum: 80))]
LazyVGrid(columns: columns) {
    ForEach(0..<50) { i in
        Text("Item \(i)")
    }
}
``` |
| `UINavigationController` / `NSViewController` (with navigation) | `NavigationStack` | 管理视图层级的导航，支持推入 (push) 和弹出 (pop) 操作。 |
| | | ```swift
NavigationStack {
    NavigationLink("Go to Detail", destination: DetailView())
}
``` |
| `UITabBarController` / `NSTabViewController` | `TabView` | 在多个子视图之间切换的标签页界面。 |
| | | ```swift
TabView {
    HomeView()
        .tabItem { Label("Home", systemImage: "house") }
    SettingsView()
        .tabItem { Label("Settings", systemImage: "gear") }
}
``` |
| `UIAlertController` / `NSAlert` | `.alert()`, `.confirmationDialog()` | 以模态方式向用户呈现重要信息或选项。 |
| | | ```swift
@State private var showAlert = false
Button("Show Alert") { showAlert = true }
.alert("Important Message", isPresented: $showAlert) {
    Button("OK") { }
}
``` |
| `UIScrollView` / `NSScrollView` | `ScrollView` | 一个可以滚动的容器视图。 |
| | | ```swift
ScrollView {
    VStack {
        ForEach(0..<50) { i in
            Text("Scrollable Content \(i)")
        }
    }
}
``` |
| `UIStackView` / `NSStackView` | `VStack`, `HStack`, `ZStack` | 用于组织视图的布局容器，分别对应垂直、水平和深度堆叠。 |
| | | ```swift
HStack {
    Text("Left")
    Spacer()
    Text("Right")
}
``` |

## 总结

虽然许多组件在概念上可以一一对应，但 SwiftUI 的工作方式有着本质的不同。它鼓励开发者构建更小、更专注、可复用的视图，并通过状态来驱动整个 UI 的更新。熟悉这个对标列表是很好的第一步，但真正掌握 SwiftUI 的关键在于理解其声明式、组合式和状态驱动的核心思想。
