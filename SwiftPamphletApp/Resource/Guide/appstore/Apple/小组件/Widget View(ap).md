# 构建小组件的视图 (Widget View)

Widget View 是决定你的小组件在桌面上长什么样的核心。它完全使用 **SwiftUI** 构建。但请注意：**小组件的 SwiftUI 与主 App 的 SwiftUI 并不完全一样。**

## 1. 入口点与环境参数

小组件的 View 通常接收一个由 Provider 生成的 \`TimelineEntry\` 数据模型。
此外，你必须经常利用 \`@Environment\` 变量来适配不同的尺寸和系统设置。

```swift
struct MyWidgetView: View {
    var entry: MyEntry
    
    // 获取当前小组件的尺寸类型 (Small, Medium, Large, ExtraLarge, 锁屏等)
    @Environment(\.widgetFamily) var family
    
    // 获取系统的色彩模式 (Dark / Light)
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        // 2. 根据不同的尺寸，渲染完全不同的布局
        switch family {
        case .systemSmall:
            SmallView(entry: entry)
        case .systemMedium:
            MediumView(entry: entry)
        case .accessoryCircular: // iOS 16 锁屏圆形组件
            LockScreenCircularView(entry: entry)
        default:
            Text("不支持的尺寸")
        }
    }
}
```

## 2. 被禁用的 SwiftUI 视图和特性

因为小组件本质上是被系统底层的渲染进程“序列化”并画到桌面的（并不是一个真正的活跃 App），以下这些交互式组件在 Widget View 中**绝对不能使用（会被系统忽略或导致崩溃）**：

*   **所有的滚动和复杂列表**：\`ScrollView\`, \`List\`, \`NavigationView\`, \`TabView\`。
*   **输入与重度交互控件**：\`TextField\`, \`TextEditor\`, \`Slider\`, \`Stepper\`, \`Map\`。
*   **多媒体与异步加载**：\`VideoPlayer\`, \`WebView\` (\`WKWebView\`), \`AsyncImage\` (必须在Provider下载好后用普通Image渲染)。
*   **生命周期修饰符**：\`.onAppear\`, \`.onReceive\` 是无效的，因为视图处于休眠状态。

## 3. iOS 17 新增的允许组件

在 iOS 17 的交互式小组件更新后，Apple 放宽了某些限制：
*   **\`Button\` 和 \`Toggle\`**：终于可用！但它们不能触发常规的代码闭包（action），而是必须绑定到一个预先定义好的 **\`AppIntent\`**，将操作意图甩给系统去后台执行。

```swift
// 只有 iOS 17+ 才能这么写
Button(intent: RefreshDataIntent()) {
    Image(systemName: "arrow.clockwise")
}
```

## 4. 布局最佳实践

1. **善用 \`ZStack\` 做背景**：经常使用 \`ContainerRelativeShape\` 配合渐变色或图片放在 ZStack 底层作为背景。
2. **极简主义**：在 `.systemSmall` 中不要试图塞入超过 3 条信息。字号要大（系统默认推荐最小字号不低于 11pt，通常标题用 16pt+）。
3. **支持深色模式**：必须测试 \`colorScheme\` 的表现。不要硬编码黑色文字，使用 \`.primary\` 或自定义带有深色变体的 Color Set。
4. **适配多种屏幕**：由于 iPhone 的屏幕尺寸极其碎片化（从 SE 的窄屏到 Pro Max 的宽屏），小组件的绝对尺寸也会拉伸。**永远不要使用硬编码的 frame 宽高数值去撑满屏幕**，必须依赖 \`VStack\`、\`HStack\` 配合 \`Spacer()\` 来实现弹性的相对布局。
