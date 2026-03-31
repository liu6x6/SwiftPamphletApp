# Object Capture：将真实世界带入 visionOS

在为 visionOS 开发 3D 应用时，最大的痛点往往是：**缺乏高质量的 3D 模型素材**。
为了解决这个问题，Apple 提供了 **Object Capture (对象捕捉)** 技术，这是一种基于摄影测量学 (Photogrammetry) 的 API。它允许开发者通过拍摄真实物品的一组照片，自动生成逼真的、带有物理纹理的 USDZ 3D 模型。

## 1. 核心工作原理

Object Capture 的核心流程分为两部分：
1. **数据采集**：用户使用配备了 LiDAR 扫描仪和高清摄像头的 iOS 设备（如 iPhone 14 Pro 或 iPad Pro）围绕物体拍摄几十到上百张各个角度的照片。
2. **模型生成**：利用 macOS 上的强大算力，或者 iOS 17 引入的设备端 API，将这组照片合成、纹理映射，最终输出一个 \`.usdz\` 或 \`.obj\` 格式的三维模型文件。

## 2. API 的使用 (iOS 17+ 离线端侧捕捉)

以前只能在 macOS 上处理照片，从 iOS 17 开始，Apple 提供了 \`ObjectCaptureSession\` 和 SwiftUI 的 \`ObjectCaptureView\`，让你可以直接在 iPhone App 里完成从拍摄到生成模型的全流程。

### 第一步：引导用户拍摄
```swift
import SwiftUI
import RealityKit

struct CaptureView: View {
    // 创建一个捕捉会话
    @State private var session = ObjectCaptureSession()

    var body: some View {
        // 系统提供的强大 UI：自动提示用户“请绕着物体走一圈”、“请移动得慢一点”
        ObjectCaptureView(session: session)
            .onAppear {
                // 开启会话并指定照片保存的临时目录
                var configuration = ObjectCaptureSession.Configuration()
                configuration.checkpointDirectory = getTempURL()
                session.start(detecting: .object, configuration: configuration)
            }
    }
}
```

### 第二步：生成 3D 模型 (PhotogrammetrySession)
拍摄完毕后，利用捕捉到的数据文件夹重建模型：

```swift
import RealityKit

func reconstructModel(from imagesFolder: URL, outputURL: URL) async throws {
    // 创建重建会话
    var session = try PhotogrammetrySession(
        input: imagesFolder,
        configuration: PhotogrammetrySession.Configuration()
    )
    
    // 发起处理请求（这非常耗时，可能需要几分钟，取决于照片数量）
    let request = PhotogrammetrySession.Request.modelFile(url: outputURL, detail: .reduced)
    try session.process(requests: [request])
    
    // 异步监听处理进度和结果
    for try await output in session.outputs {
        switch output {
        case .processingComplete:
            print("模型生成完毕！保存于: \(outputURL)")
        case .requestError(let request, let error):
            print("重建失败: \(error)")
        default:
            break
        }
    }
}
```

## 3. 在 visionOS 中的意义

生成了逼真的 USDZ 模型后，你可以直接使用 \`Model3D\` 或是 Reality Composer Pro 将其放入 visionOS 场景中。

*   **电商应用**：商家可以用手机拍下鞋子、包包，生成 3D 模型并在 Vision Pro 中以 1:1 真实尺寸向顾客展示。
*   **数字博物馆/教育**：将现实中的文物或标本通过低成本的手机扫描，瞬间数字化，作为 visionOS 沉浸式体验的核心资产。
