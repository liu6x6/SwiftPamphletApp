# visionOS 开发入门指南

Apple Vision Pro 和 visionOS 代表了自 iPhone 发布以来最大的一次平台范式转移。对于已经熟悉 iOS 的开发者来说，好消息是：**你现有的知识有 80% 可以直接平移**。但那剩余的 20% 空间维度的知识，需要你彻底转变思维。

## 1. 核心技术栈

开发 visionOS 应用的核心工具链是：
*   **SwiftUI**：构建用户界面（UI）的绝对主力。所有的 2D 窗口和 3D 容器都由 SwiftUI 声明和管理。
*   **RealityKit**：Apple 的 3D 渲染和物理引擎。负责渲染 3D 模型、处理光影和物理碰撞。
*   **ARKit**：提供对真实世界的理解（如平面检测、手势追踪、环境映射）。
*   **Reality Composer Pro**：集成在 Xcode 中的 3D 场景和材质编辑器。

## 2. 三种沉浸形态 (Scenes)

在 \`@main\` App 结构体中，你决定了应用的呈现形态：

1.  **Windows (窗口)**：
    使用 \`WindowGroup\`。这就像是在空中悬浮了一个 iPad 屏幕。你可以把现有的 iOS/iPadOS 移植过来，默认就会以窗口形式呈现。用户可以看到你的 2D UI，同时也能看到周围的真实世界。
2.  **Volumes (体积)**：
    同样使用 \`WindowGroup\`，但通过 \`.windowStyle(.volumetric)\` 修饰符声明。这是一个定义了长宽高的 3D 边界框（Bounding Box）。在这个框里，你可以渲染 3D 模型，用户可以绕着这个“盒子”走动查看。
3.  **Spaces (沉浸空间)**：
    使用 \`ImmersiveSpace\`。当应用进入这种模式时，其他应用的窗口会被隐藏。你可以选择混合模式（将 3D 物体融合在用户的真实房间里）或全虚拟模式（VR，完全用你的虚拟场景替换用户的真实视野）。

```swift
@main
struct MyApp: App {
    var body: some Scene {
        // 1. 默认的 2D 窗口
        WindowGroup {
            ContentView()
        }

        // 2. 用于展示 3D 模型的体积
        WindowGroup(id: "model-volume") {
            ModelViewer()
        }
        .windowStyle(.volumetric)

        // 3. 完全沉浸的虚拟空间
        ImmersiveSpace(id: "virtual-world") {
            ImmersiveView()
        }
        .immersionStyle(selection: .constant(.full), in: .full)
    }
}
```

## 3. 开发环境要求

*   **硬件**：必须是一台搭载 **Apple Silicon (M1/M2/M3)** 芯片的 Mac。Intel Mac 无法运行 visionOS 模拟器。
*   **软件**：最新的 macOS (通常要求最新正式版或更高) 以及最新的 Xcode (需在安装时勾选下载 visionOS SDK)。

## 4. 交互方式的剧变

在 iOS 上，你是“点击 (Tap)”；在 visionOS 上，你是**“注视并捏合 (Look and Tap)”**。
*   你的眼睛充当了鼠标指针。
*   你的手指捏合动作充当了鼠标左键。
*   由于眼动追踪由系统底层完全接管（出于极其严苛的隐私保护），**你的 App 代码是绝对无法知道用户目前正在看屏幕上的哪个具体坐标的**，除非用户此时进行了手指捏合（触发了点击事件）。
*   系统原生提供了注视高亮反馈（Hover Effect），开发者只需使用标准 SwiftUI 按钮，系统会自动处理高亮发光效果。

## 5. 入门第一步建议

不要一上来就尝试写复杂的 3D 游戏。
最好的入门方式是：打开 Xcode，新建一个 visionOS App，选择 \`Window\` 形态，把你之前写过的一个普通的 iOS SwiftUI App 跑起来。看看它在空间中悬浮的样子，感受玻璃材质的背景，然后再慢慢往里面加入 \`Model3D\` 视图。
