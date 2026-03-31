# SwiftUI 的 3D 利器：Model3D 视图

在传统 iOS 的 SwiftUI 中，我们最常用来显示视觉元素的视图是 \`Image\`。
而在 visionOS 的空间计算领域，为了让开发者能以最低的成本展示 3D 模型，Apple 为 SwiftUI 提供了一个等价于 \`Image\` 的极其简单的高层视图：**\`Model3D\`**。

## 1. 什么是 Model3D？

\`Model3D\` 是 SwiftUI 专为 visionOS（及后续支持 3D 的系统）引入的声明式视图。它的主要作用是**以非交互、仅用于展示的方式**将一个 USDZ 格式的 3D 模型渲染到界面中。

*   它**非常轻量**，适合在普通的 Window 或应用卡片中展示商品模型、小装饰物。
*   它**不支持**深度的物理引擎碰撞、动画状态机控制或复杂的子节点遍历。如果你需要对模型进行骨骼驱动或交互打击，必须降级使用更底层的 \`RealityView\`。

## 2. 基础用法

如果你在 Xcode 工程的 Bundle 中拖入了一个名为 \`shoe.usdz\` 的模型文件：

```swift
import SwiftUI
import RealityKit

struct ProductDetailView: View {
    var body: some View {
        VStack {
            Text("限量版球鞋")
                .font(.largeTitle)
            
            // 最简用法：直接加载并显示模型
            Model3D(named: "shoe") { model in
                model
                    // 允许缩放和旋转（注意：这是对整个 Model3D 视图的修饰，而不是对模型内部节点的控制）
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 300, height: 300)
            } placeholder: {
                // 加载过程中的占位视图
                ProgressView()
            }
        }
    }
}
```

## 3. 异步网络加载模型

就像 \`AsyncImage\` 可以通过 URL 加载网络图片一样，\`Model3D\` 也支持通过 URL 直接从服务器拉取并渲染 3D 模型。

```swift
Model3D(url: URL(string: "https://example.com/models/chair.usdz")!) { phase in
    switch phase {
    case .empty:
        ProgressView("下载模型中...")
    case .success(let resolvedModel):
        resolvedModel
            .resizable()
            .scaledToFit()
    case .failure(let error):
        VStack {
            Image(systemName: "exclamationmark.triangle")
            Text("加载失败: \(error.localizedDescription)")
        }
    @unknown default:
        EmptyView()
    }
}
```

## 4. 与 Reality Composer Pro 集成

在现代 visionOS 开发流中，开发者通常在 Reality Composer Pro 里搭建一个名为 \`Scene\` 的场景，然后用 \`Model3D\` 极其优雅地将其嵌入到 SwiftUI 中：

```swift
// 这里的 realityKitContentBundle 是包含在工程中的自动生成常量
Model3D(named: "Scene", bundle: realityKitContentBundle)
```

## 5. Model3D 相关的局限性
请记住，\`Model3D\` 渲染的内容是被“包裹”在一个不可见的 3D 包围盒里的。它就像网页里的一个 \`<img>\` 标签：
*   用户只能注视它，不能点击模型的某个零件使其分离。
*   你不能通过代码动态替换模型的材质贴图。
*   如果你的需求超越了“仅仅是看着它”，请立刻转向使用 **\`RealityView\`**。
