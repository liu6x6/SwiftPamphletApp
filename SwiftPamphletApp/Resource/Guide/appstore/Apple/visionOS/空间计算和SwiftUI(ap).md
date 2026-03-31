# 空间计算环境下的 SwiftUI

SwiftUI 是构建 Apple 平台 UI 的通用框架。在 visionOS（空间计算）的加持下，SwiftUI 经历了一次维度的升级，从 2D 的平面排版延伸到了具有深度（Z 轴）和材质的 3D 空间。

## 1. 原生 3D 修饰符

在 visionOS 中，SwiftUI 新增了一批专门针对 Z 轴（深度）控制的 Modifier，这是以前 iOS 开发中绝对没有的。

### \`.offset(z:)\` 和 \`.padding(.depth)\`
你可以让某个普通的 2D 按钮在空间中向用户“凸出来”。

```swift
ZStack {
    // 这是一个位于底层的玻璃背景卡片
    Color.clear.glassBackgroundEffect()
    
    // 文字会悬浮在卡片前方 30pt 的位置，产生极强的立体感和阴影
    Text("空间悬浮文字")
        .offset(z: 30)
}
```

### \`.rotation3DEffect\` 的真实物理感
在 iOS 中，3D 旋转通常只是一种视觉特效。而在 visionOS 中，当你使用这个修饰符让一个卡片旋转 45 度时，它是真正在物理空间中侧过来的，你能清楚地看到它的侧面厚度和空间透视。

## 2. Glass Material (玻璃材质)

这是 visionOS 的设计灵魂。由于背景是用户的真实房间，你不应该使用极其刺眼的纯白色背景卡片。
SwiftUI 提供了一个专属修饰符：**\`.glassBackgroundEffect()\`**。

它不仅仅是降低透明度或高斯模糊。系统会在底层利用光线追踪，让这块玻璃背景实时折射和反射周围真实房间的灯光、颜色，甚至是投射在上面的其他窗口的阴影。

## 3. 空间交互特性的适配

由于 visionOS 的核心交互是“眼睛看（瞄准） + 手指捏合（点击）”，SwiftUI 的组件在底层进行了大量的默认优化：

*   **注视反馈 (Hover Effect)**：
    所有的标准 \`Button\`、\`Toggle\`、\`NavigationLink\`，当用户的眼睛注视它们时，系统会自动让它们发出极其柔和的光晕并轻微前凸，提示用户“我已经准备好被捏合点击了”。
    如果是你用 \`Text\` 加 \`.onTapGesture\` 手写的非标准按钮，**必须手动加上 \`.hoverEffect()\`**，否则用户用眼睛看着它时将没有任何反馈，导致极其糟糕的体验。
    
*   **工具栏与导航**：
    在 visionOS 中，\`TabView\` 会被自动渲染成一个悬浮在主窗口左侧的、极其优雅的垂直玻璃侧边栏（Ornaments）。当用户眼睛看向它时它会自动展开显示文字，移开视线时它会缩回仅显示图标。

## 4. 融合 3D 模型的利器

SwiftUI 现在可以直接与 \`RealityKit\` 互操作：
*   **\`Model3D\`**：像加载图片一样轻松地在普通的 VStack/HStack 布局中加载一个静态 3D 模型。
*   **\`RealityView\`**：提供一个强大的闭包，允许你将极其复杂的 3D 场景树（Entity）嵌入到 SwiftUI 布局中，并能在闭包中接收 SwiftUI 的状态更新（例如根据 \`@State\` 的变化，改变模型的大小或颜色）。

## 5. 跨平台代码共享策略

虽然 SwiftUI 号称“学会一次，到处编写”，但不要试图写一个文件就能完美跑在 iPhone 和 Vision Pro 上。

**最佳实践**：
把网络层、数据模型 (\`Codable\`)、业务逻辑 (ViewModel) 抽离在一个独立跨平台的 Swift Package 中。
然后，在 App 的 UI 层，大量使用 \`#if os(visionOS)\` 编译宏，或者干脆为 visionOS 编写一套带有 \`glassBackgroundEffect\` 和 3D Z轴偏移的专属视图。让 iOS 版本保持平面的 \`List\`，让 visionOS 版本绽放空间的魅力。
