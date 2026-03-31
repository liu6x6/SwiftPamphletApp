# targetEnvironment：精确识别运行环境

在 Swift 编译控制指令中，除了判断操作系统 (\`#if os()\`) 和模块存不存在 (\`#if canImport()\`)，还有一个非常特殊且重要的指令：**\`#if targetEnvironment()\`**。

它的核心作用是：**判断代码当前是在真机（Physical Device）、模拟器（Simulator）还是 Mac Catalyst 等特殊环境上运行的。**

## 1. 识别模拟器 (Simulator)

这是 \`targetEnvironment\` 最常用的场景。
在 iOS 开发中，有很多底层硬件能力在 Xcode 的模拟器中是**完全缺失且会引发崩溃的**，例如：
*   **摄像头 (Camera)**
*   **ARKit 增强现实**
*   **MessageUI (发送真实短信/邮件)**
*   **Metal 计算着色器的某些极其底层的特性**

为了让你的工程能够在模拟器上顺利编译和运行（方便测试非硬件相关的逻辑），你需要把硬件相关的代码隔离起来。

```swift
import AVFoundation

func startCamera() {
    // 检查当前环境是否是模拟器
    #if targetEnvironment(simulator)
        print("警告：模拟器不支持摄像头，使用占位图代替。")
        // 加载一张本地的静态图片假装是摄像头画面
        setupMockCameraView()
        
    #else
        // 这里是真机环境，放心大胆地调用底层摄像头 API
        let captureSession = AVCaptureSession()
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        // ... 继续配置真实摄像头
    #endif
}
```

## 2. 识别 Mac Catalyst 环境 (macCatalyst)

**Mac Catalyst** 是 Apple 推出的一项技术，允许开发者将 iOS (iPadOS) 应用“一键”编译并在 macOS 上运行。

在 Catalyst 环境下：
*   \`#if os(iOS)\` 的判断结果是 **true**（因为底层依赖的大部分还是 iOS 的 UIKit 逻辑）。
*   \`#if canImport(UIKit)\` 的判断结果也是 **true**。

如果你想写一段代码，**只在 Catalyst（Mac 上跑的 iOS App）中执行，而不在真正的 iPhone/iPad 上执行**（比如添加 macOS 特有的顶部菜单栏或处理鼠标悬停事件），你必须使用 \`targetEnvironment(macCatalyst)\`。

```swift
func setupUserInterface() {
    setupCommonViews()
    
    // 这段代码只有在这个 App 被打包成 Mac Catalyst 版本运行时才会编译进去
    #if targetEnvironment(macCatalyst)
        print("当前运行在 Mac 上，开启宽屏优化和鼠标指针支持")
        // 添加仅限 Mac 的 TouchBar 支持或键盘快捷键
        setupMacSpecificShortcuts()
    #else
        print("当前运行在真正的 iOS 设备上")
        // 添加仅限手机的触控震动反馈 (Haptic Feedback)
        setupHapticFeedback()
    #endif
}
```

## 3. 为什么不使用运行时的设备判断？

你可能会问，我为什么不用 \`UIDevice.current.model.contains("Simulator")\` 在运行时做 \`if - else\` 判断？

*   **编译期安全**：如果你的真机代码引入了模拟器不支持的 C 语言底层库，用运行时的 \`if\` 判断依然会导致**编译失败**。而 \`#if targetEnvironment\` 是在预编译阶段（Preprocessor）工作的，它会直接把不符合当前环境的代码文本**整块删掉**，根本不交给编译器，从而保证绝对的编译安全。
*   **包体积与性能**：被 \`#if\` 排除的代码不会生成汇编指令，也不会被打包进最终的 App 二进制文件中，减小了包体积。

## 总结

当你需要区分**“代码是在什么样的物理形态/跨平台容器中跑”**时（比如 真机 vs 模拟器，原生 iOS vs 移植版 Mac App），请毫不犹豫地使用 \`#if targetEnvironment()\` 宏。
