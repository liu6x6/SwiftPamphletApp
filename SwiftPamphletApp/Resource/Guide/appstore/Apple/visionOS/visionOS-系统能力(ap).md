# visionOS 专属的系统能力与隐私权限

在 visionOS 开发中，许多在 iOS 上习以为常的底层系统能力（如直接获取摄像头画面、精确获取手指屏幕坐标）因为严苛的**隐私保护**而被重新设计或直接屏蔽。理解这些限制和新能力，是开发高级空间应用的前提。

## 1. 企业级 API：Enterprise API
Apple 明确区分了“普通消费级应用”和“企业级内部应用”。
如果你开发的是上架 App Store 的普通应用，你是**绝对无法**拿到设备外部摄像头（Passthrough）的原始视频数据流的。

但如果是医疗手术、重工业制造等企业内部场景，Apple 提供了 **Enterprise API**。
*   你需要向 Apple 提交特殊申请以获得此 Entitlement。
*   获取后，你的 App 可以通过 \`ARKit\` 获取高质量的主摄像头视频帧（Main Camera Video Access），从而实现自定义的复杂计算机视觉算法（如极其精确的特定机械零件识别）。

## 2. ARKit 的全新权限模型

在普通的 Immersive Space (完全沉浸空间) 中，虽然你拿不到摄像头视频，但你可以通过 \`ARKit\` 申请系统计算好的**高阶追踪数据**。这会弹出一个类似于 iOS 申请位置权限的弹窗。

你可以申请以下数据：
1.  **手部追踪 (Hand Tracking)**：极其精确的双手 26 个关节的 3D 坐标数据。用于实现弹琴、抓取复杂物体的交互。
2.  **世界感知 (World Tracking)**：获取用户房间的粗糙 3D 网格模型 (Scene Reconstruction) 和平面检测数据 (Plane Detection)。这让你能把虚拟的球扔到真实的墙上并反弹。
3.  **图像追踪 (Image Tracking)**：识别特定的 2D 图片（如一张海报），并在其上叠加 3D 内容。

```swift
import ARKit

// 必须在 ImmersiveSpace 内执行
func startTracking() async {
    let session = ARKitSession()
    let handProvider = HandTrackingProvider()
    let sceneProvider = SceneReconstructionProvider()
    
    // 向用户申请权限并启动追踪
    do {
        try await session.run([handProvider, sceneProvider])
    } catch {
        print("ARKit 会话启动失败")
    }
}
```

## 3. SharePlay 与 空间 Persona

这是 visionOS 最具魔力的系统能力之一：让相隔千里的用户在同一个虚拟空间里协作。
*   **Persona (空间角色)**：系统利用前置摄像头扫描用户面部，生成极其逼真的 3D 虚拟化身。
*   **Group Activities API**：结合 FaceTime 的 SharePlay，开发者只需极少的代码，就能让你的 App 支持多人同时在线。系统会自动处理 Persona 的相对位置（比如你可以把朋友的 Persona 放在你左边，一起看同一个 3D 模型）。你只需要负责同步 App 内部的数据状态（比如当前放的是哪首歌、模型旋转到了多少度）。

## 4. 虚拟键盘与输入法适配

在 visionOS 中，系统输入法是一块悬浮在空中的虚拟键盘。用户可以通过眼动+手指捏合，或者直接伸出双手像在真实键盘上那样**悬空敲击**。

作为开发者：
*   不要假设键盘总是从屏幕底部弹出（像 iOS 那样推高视图）。
*   虚拟键盘可能遮挡你的 UI，必须合理使用 SwiftUI 的 \`safeAreaInset\` 或监控键盘通知来保证输入框不被遮挡。
*   系统支持直接看向麦克风图标进行精准的语音听写，尽量减少需要大量文本输入的设计。
