# 小组件：深入解析配置选项 (Configuration Options)

当我们在 \`Widget\` 结构体中定义一个 \`StaticConfiguration\` 或 \`AppIntentConfiguration\` 时，苹果提供了许多链式修饰符（Modifiers）来精细控制小组件在系统层面上的行为和展示。

## 1. 基础信息配置

这些配置决定了用户在小组件画廊（长按桌面 -> 点击左上角加号）中看到的内容。

```swift
var body: some WidgetConfiguration {
    AppIntentConfiguration(...) { ... }
    
    // 1. 小组件的显示名称 (黑体大字)
    .configurationDisplayName("极速待办")
    
    // 2. 小组件的描述信息 (下方的小字)
    .description("随时随地查看你今天的任务并快速打卡。")
}
```

## 2. 限制支持的尺寸 (Supported Families)

这是最常用的配置。并非所有的小组件都能适应从小方块到超大面板的所有尺寸。如果你没有针对某种尺寸编写 UI，就必须把它排除掉，否则会发生严重的 UI 错位或崩溃。

```swift
    .supportedFamilies([
        .systemSmall,    // 2x2 正方形
        .systemMedium,   // 2x4 长方形
        .systemLarge,    // 4x4 大正方形
        .systemExtraLarge // 仅仅 iPadOS 支持的超大尺寸
    ])
```

## 3. 锁屏小组件 (Accessory Widgets - iOS 16+)

从 iOS 16 开始，iPhone 引入了锁屏小组件。为了支持这些特定区域，你需要添加 Accessory 家族：

```swift
    .supportedFamilies([
        // 主屏幕尺寸
        .systemSmall,
        
        // 锁屏上方日期旁边的单行文本区域
        .accessoryInline,
        // 锁屏下方的一排圆形小图标
        .accessoryCircular,
        // 锁屏下方的矩形信息条
        .accessoryRectangular
    ])
```
*注意：在你的 Widget View 里，必须使用 \`@Environment(\.widgetFamily)\` 判断如果当前是 Accessory 类型，就要使用无背景、纯单色（通常利用透明度和纯白/黑）的极其极简的 UI 布局，因为系统会用遮罩和滤镜来给锁屏组件上色。*

## 4. StandBy 待机显示模式支持 (iOS 17+)

iOS 17 引入了将手机横放充电时的待机显示（StandBy）。如果你希望你的小组件在这种模式下看起来不那么刺眼，并且支持深色护眼模式，你需要使用 \`disfavorsSiriSuggestion\` 或是针对它进行优化（大部分普通 Widget 会自动被支持，但布局逻辑有细微差异）。

## 5. 背景与边距的消隐 (.contentMarginsDisabled)

从 iOS 17 开始，系统默认给所有的小组件强加了一层内边距（Margins）。这对于大多数标准卡片来说很好，但如果你的设计是需要**全屏铺满一张图片**或者渐变色背景直达物理边缘，你就需要显式禁用这个系统边距。

```swift
var body: some WidgetConfiguration {
    AppIntentConfiguration(...) { ... }
    .configurationDisplayName(...)
    
    // iOS 17 专属：移除系统默认强制附加的 padding
    .contentMarginsDisabled()
}
```

在视图内部，如果启用了这个修饰符，你需要自己用 \`ContainerRelativeShape\` 配合正确的边距来管理内边距，否则文字会直接贴在屏幕或者圆角边缘上。

## 6. (已弃用/受限) Siri 建议
早期可以使用 \`.disfavorsSiriSuggestion()\` 来防止 Siri 把你的小组件自动塞进用户的智能叠放中。现在的机制更多依赖于用户习惯和 AppIntent 的 donate。
