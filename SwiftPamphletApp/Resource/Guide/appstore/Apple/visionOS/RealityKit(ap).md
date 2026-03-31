# RealityKit 框架：visionOS 的渲染核心

在 Apple 平台的 3D 和 AR/VR 生态中，**RealityKit** 是最核心的高性能 3D 渲染和物理模拟引擎。虽然它早几年就随着 iOS 上的 ARKit 一同发布，但在 visionOS 时代，它成为了构建空间应用（Spatial Apps）的绝对基石。

## 1. RealityKit 与 ARKit 的分工
很多人容易混淆这两个框架。简单来说：
*   **ARKit** 是“眼睛和大脑”：负责追踪用户的头部运动、扫描房间结构、识别手势。
*   **RealityKit** 是“画笔和物理引擎”：负责利用 ARKit 提供的数据，把 3D 模型渲染到正确的坐标上，打上逼真的光影，并处理模型之间的碰撞和重力模拟。

## 2. 核心架构：ECS (实体-组件-系统)

RealityKit 的底层架构采用了在游戏开发中极度流行的 **ECS (Entity-Component-System)** 模式。理解 ECS 是精通 RealityKit 的前提。

*   **Entity (实体)**：场景中的一个基本节点（类似于 \`UIView\`）。它本身只代表一个“位置”，没有形状和颜色。
*   **Component (组件)**：挂载在 Entity 上的数据或能力属性。例如，给实体挂载 \`ModelComponent\` 就能显示形状，挂载 \`PhysicsBodyComponent\` 就受重力影响，挂载 \`CollisionComponent\` 就能发生碰撞。
*   **System (系统)**：每一帧都会运行的逻辑代码。系统会遍历所有包含特定 Component 的 Entity 并执行计算。

## 3. 在 SwiftUI 中使用 RealityView

在 visionOS 中，如果你需要超越简单的 \`Model3D\`（纯展示），想要对 3D 对象进行复杂的交互和层级管理，你需要使用 **\`RealityView\`**。它是 SwiftUI 与 RealityKit 引擎之间的桥梁。

```swift
import SwiftUI
import RealityKit

struct InteractiveCubeView: View {
    var body: some View {
        // RealityView 的闭包提供了 content 对象，你可以往里面随意添加 Entity
        RealityView { content in
            // 1. 创建一个方块模型组件
            let mesh = MeshResource.generateBox(size: 0.2)
            // 创建一个红色材质
            let material = SimpleMaterial(color: .red, isMetallic: false)
            let modelComponent = ModelComponent(mesh: mesh, materials: [material])
            
            // 2. 创建实体并挂载组件
            let cubeEntity = Entity()
            cubeEntity.components.set(modelComponent)
            
            // 3. 为了让它能被用户手势点击，必须挂载碰撞组件和输入目标组件
            cubeEntity.components.set(CollisionComponent(shapes: [.generateBox(size: [0.2, 0.2, 0.2])]))
            cubeEntity.components.set(InputTargetComponent())
            
            // 将实体加入到场景中
            content.add(cubeEntity)
            
        } update: { content in
            // 当 SwiftUI 的状态改变时，这里会被调用，用于更新已有的实体属性
        }
        // 4. 监听针对这个 RealityView 的 3D 空间拖拽手势
        .gesture(
            DragGesture()
                .targetedToAnyEntity() // 过滤出只针对 Entity 的拖拽
                .onChanged { value in
                    // 在空间中移动方块
                    value.entity.position = value.convert(value.location3D, from: .local, to: .scene)
                }
        )
    }
}
```

## 4. 核心能力优势
*   **极简的光照与阴影**：RealityKit 能够自动分析周围的真实物理环境（利用设备的摄像头），动态生成环境光照贴图 (IBL)。你的虚拟物体会自动反射用户真实房间的灯光，拥有绝佳的真实感。
*   **动画支持**：支持直接播放 USDZ 文件中内置的骨骼动画 (Skeletal Animations) 或通过代码生成补间动画。
*   **空间音频 (Spatial Audio)**：自带与物理空间完美契合的音频引擎。
