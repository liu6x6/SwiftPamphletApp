# visionOS 与 Unity (游戏引擎开发)

虽然 Apple 提供了基于 Swift 的原生的 SwiftUI 和 RealityKit 来构建空间应用，但对于极其庞大的 3D 游戏产业，甚至许多已有的跨平台工业软件来说，**Unity** 引擎才是不可替代的主力军。

为了吸引游戏开发者，Apple 破天荒地与 Unity 进行了极其深度的合作，在 visionOS 发布的第一天就宣布了官方的联合支持。

## 1. Unity 开发 visionOS 的三种模式

使用 Unity 开发 Vision Pro 应用，并不是简单地把原有的 VR 游戏导出一下，你必须在三种截然不同的体验模式中做出选择：

### A. Windowed Apps (2D 窗口模式)
这是最简单的移植方式。你的 Unity 游戏就像运行在 iPad 上一样，被封装在一个平面的悬浮窗口里。
*   **适用场景**：已有的 2D 手游（如《愤怒的小鸟》）、策略游戏。
*   **技术特点**：不需要复杂的修改，系统会将用户的眼睛注视和捏合映射为传统的鼠标/触摸事件（\`Input.GetMouseButtonDown\`）。

### B. Fully Immersive VR (全沉浸式 VR)
你的游戏接管了用户的整个视野，周围真实的物理世界被完全关闭。
*   **适用场景**：第一人称射击、沉浸式解谜游戏、传统的 SteamVR 游戏移植。
*   **技术架构**：Unity 使用其独有的渲染管线（URP 或内置），独占设备的 GPU。此时你必须使用 Apple 提供的 **Unity visionOS 插件 (PolySpatial 的一部分)** 和 **AR Foundation** 库，将苹果底层的头部追踪和骨骼手势数据桥接到 Unity 的 Input System 中。

### C. Shared Space (共享空间 / MR 混合现实)
**这是 visionOS 独有且革命性的模式**。Unity 中渲染的 3D 模型可以直接放置在用户的真实房间里（例如在用户的桌子上放一个虚拟的国际象棋盘），并且这些模型可以与周围其他原生的 iOS/visionOS 窗口共存！
*   **底层技术：PolySpatial**
    在 Shared Space 模式下，Unity **不能**使用自己传统的渲染管线和 Shader。因为如果要与系统的其他 App 混合显示，必须由操作系统的统一渲染进程来决定一切的光影。
    因此，Unity 和 Apple 联合开发了 **PolySpatial** 技术。它的作用是在底层“劫持” Unity 的场景节点，并将它们实时翻译成 Apple 的 **RealityKit** 实体。然后交由 visionOS 的系统服务来渲染。
*   **挑战**：因为最终是 RealityKit 负责画图，你在 Unity 里写的复杂的自定义 Shader (HLSL) 大概率会失效或者被转译得极其难看。你需要尽量使用基于物理的渲染 (PBR) 材质，遵循 PolySpatial 的严格规范。

## 2. 交互与输入体系的巨变

如果你的 Unity VR 游戏原来是基于 Meta Quest 的双持物理手柄开发的，在移植到 visionOS 时将面临重新设计的挑战：
*   **Vision Pro 没有手柄！**
*   你必须利用 Unity 中的 **AR Foundation 手部追踪 (Hand Tracking) API**，把手柄射线的逻辑改成：要么判断用户的视线焦点（Gaze），要么渲染出一双虚拟的手，判断手指关节和 3D 物体是否有物理碰撞。

## 3. 开发环境配置

如果你想用 Unity 为 visionOS 开发：
1.  **硬件要求**：必须是 Apple Silicon (M1+) 的 Mac。
2.  **Unity 版本**：必须下载支持 visionOS 的特定 Unity 版本（通常是 Unity 2022.3 的极高版本或更高）。
3.  **Pro 订阅**：对于想要使用高级的 PolySpatial 混合现实技术的开发者，目前 Unity 可能会要求特定的授权层级（需查阅 Unity 官网最新政策）。
4.  **Xcode**：即使你使用 Unity 编写 C# 逻辑，最终导出的依然是一个 Xcode 工程。你必须在 Xcode 中进行签名并将其部署到模拟器或真机上。
