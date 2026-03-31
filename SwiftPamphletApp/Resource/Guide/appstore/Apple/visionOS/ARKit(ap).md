# ARKit：连接虚拟与现实的桥梁

**ARKit** 是 Apple 平台上负责增强现实（Augmented Reality）底层追踪和场景理解的框架。
在 iOS/iPadOS 上，它是构建 AR 应用的基石；在 visionOS 上，它退居幕后，成为提供极其精确环境数据的底层服务提供商。

## 1. ARKit 的三大核心能力

无论是在 iPhone 还是 Vision Pro 上，ARKit 的核心任务可以归结为三点：

### A. 追踪 (Tracking) - "我在哪里？"
利用设备的摄像头、陀螺仪和加速度计，ARKit 使用视觉惯性里程计 (VIO) 技术，实时、极其精确地计算出设备在真实三维空间中的位置 (x, y, z) 和姿态 (Pitch, Yaw, Roll)。这确保了虚拟物体能“死死地钉在”真实世界的某个位置，即使你转头或走动。

### B. 场景理解 (Scene Understanding) - "周围有什么？"
*   **平面检测 (Plane Detection)**：自动找出房间里的地板、桌面和墙壁。这是把虚拟沙发稳稳放在真实地板上的前提。
*   **光照估计 (Light Estimation)**：分析摄像头画面，推断当前房间的环境光强度和色温，从而让虚拟物体渲染出极其逼真的阴影和高光。
*   **场景重建 (Scene Reconstruction)**：利用配备了 LiDAR（激光雷达）的 iPad Pro 或 Vision Pro，瞬间生成整个房间的真实 3D 网格模型，使得虚拟的球可以顺着真实的楼梯滚下去，或者被真实的沙发挡住视线 (Occlusion)。

### C. 渲染 (Rendering) - "把它画出来"
在传统的 iOS 开发中，ARKit 通常与 \`ARSCNView\` (SceneKit) 或 \`ARView\` (RealityKit) 绑定在一起，负责将虚拟内容叠加到摄像头画面上。

## 2. ARKit 在不同平台的差异

### 在 iOS / iPadOS 上的开发模式
开发者掌握着绝对的控制权。
```swift
// iOS 典型的 ARKit 启动流程
let session = ARSession()
// 配置想要追踪什么（比如水平面和垂直面）
let configuration = ARWorldTrackingConfiguration()
configuration.planeDetection = [.horizontal, .vertical]
configuration.environmentTexturing = .automatic // 开启自动光照

session.run(configuration)
```

### 在 visionOS 上的范式转变
由于 visionOS 是一个系统级始终运行在 3D 空间中的操作系统，**系统自己**已经接管了基础的世界追踪和渲染（为了多 App 共享空间）。

在 visionOS 的普通 Window 或 Volume 模式中，你**根本不需要也不允许**去调用传统的 \`ARSession\`。系统自动负责让你的 3D 模型稳定在空中。

你只有在开启了完全的 **Immersive Space (沉浸空间)** 时，才能使用 visionOS 专属的新版 ARKit API（Data Providers）去申请获取极其详细的用户双手骨骼数据或房间扫描网格（参见 \`visionOS-系统能力.md\`）。

## 3. 面部追踪与身体追踪

除了房间，ARKit 对人的追踪也达到了极其恐怖的精度：
*   **面部追踪 (Face Tracking)**：利用前置的 TrueDepth 摄像头（即 Face ID 组件），实时追踪人脸的 50 多种肌肉微表情（如眨眼、张嘴、皱眉）。这是 Animoji 甚至虚拟主播 (VTuber) 软件背后的核心技术。
*   **身体追踪 (Body Tracking)**：通过单颗后置摄像头，就能从 2D 画面中提取出人体的 3D 骨架结构，用于动作捕捉（Motion Capture）或让虚拟服装穿在真实人物身上。
