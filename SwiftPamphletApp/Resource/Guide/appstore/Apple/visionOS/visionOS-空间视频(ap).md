# visionOS 空间视频与照片 (Spatial Video & Photo)

在 Apple Vision Pro 带来的所有新体验中，**空间照片 (Spatial Photos)** 和 **空间视频 (Spatial Videos)** 被公认为最具情感冲击力的功能。它们能以惊人的逼真度重现记忆，让你仿佛重新回到了拍摄的那一刻。

## 1. 什么是空间视频/照片？

传统的视频是 2D 的平面影像。而空间视频则包含了深度的 3D 信息（立体视觉）。
当用户在 Vision Pro 中观看时，左眼和右眼会分别看到角度略有不同的两帧画面，大脑经过融合，就会产生强烈的“立体感”和“景深感”，你能清晰地感知到画面中的人离你有多近、背景的树离你有多远。

## 2. 拍摄设备

目前支持拍摄空间视频的设备包括：
*   **Apple Vision Pro** 本身（拥有最好的拍摄景深和还原度，因为摄像头间距最接近人眼）。
*   **iPhone 15 Pro / Pro Max** 及后续更高阶型号。在横屏模式下，系统会同时调用主摄（Main）和超广角（Ultrawide）镜头，并将这两个镜头的画面合成为一个带有深度信息的特殊视频文件（MV-HEVC 格式）。

## 3. 技术底层：MV-HEVC 编码

空间视频并不是两个完全独立的庞大视频文件绑在一起，而是采用了一种名为 **MV-HEVC (Multiview High Efficiency Video Coding)** 的标准格式。
*   **后向兼容性**：这是一个极其聪明的工程设计。MV-HEVC 文件包含一个主视频轨（Base Track，通常是左眼画面）和一个额外的差值轨（用来构建右眼画面）。如果你在普通的 iPhone、Mac 甚至 Android 上打开这个文件，它会忽略差值数据，当成一个极其普通的 2D 视频播放，完全兼容。只有在 Vision Pro 上，才会解开双眼数据进行 3D 渲染。
*   **文件大小**：由于利用了双眼画面极高的相似性进行压缩，空间视频的大小通常只比同等清晰度的 2D 视频大一点，远没有翻倍。

## 4. 在开发者 App 中支持空间视频

如果你正在开发一个视频播放器或社交媒体应用，并希望支持空间视频播放，Apple 提供了现成的 API 封装。

### 使用 AVFoundation / AVPlayer
如果你使用 \`AVPlayer\` 或者 SwiftUI 的 \`VideoPlayer\` 视图，**在 visionOS 平台上，默认就是支持空间视频播放的！**
你不需要写任何极其复杂的 3D 渲染代码。只要你传入一个 MV-HEVC 格式的视频 URL，系统底层会自动识别，并在头显中呈现出立体效果。

### 视频的呈现模式
*   **窗口内播放**：默认在应用的 2D 窗口内播放，视频画面会有立体纵深，就像在看一个 3D 的相框。
*   **全沉浸展开 (Expansion)**：如果你的应用允许，强烈建议提供一个按钮，让视频变暗周围环境，并以极大的尺寸在空间中悬浮展开。这种体验最为震撼。

### API 检测特性
如果你需要在代码中识别某个视频文件是否是空间视频（以便在 UI 上打上特殊角标），可以通过 \`AVAsset\` 的属性来检查：
```swift
import AVFoundation

Task {
    let asset = AVURLAsset(url: videoURL)
    // 检查是否有立体视觉（双视图）轨道
    let containsSpatialVideo = try await asset.load(.containsStereoMultiviewVideo)
    if containsSpatialVideo {
        print("这是一个空间视频！")
    }
}
```

## 5. 设计准则

Apple 在 HIG 中建议，在用户的 Vision Pro 里展示空间视频时，边缘应该采用**羽化渐变 (Feathered Edges)** 的处理方式（这也是系统相册默认的做法），而不是生硬的直角边框。这种柔和的边缘能进一步打破“画框”的束缚感，让记忆更加自然地融入环境。
