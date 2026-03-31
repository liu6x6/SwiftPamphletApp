# Swift Package Manager (SPM) 详解

Swift Package Manager（简称 SPM 或 SwiftPM）是 Apple 官方提供的用于管理 Swift 代码分发、依赖和构建的工具。它已经深度集成在 Swift 工具链和 Xcode 之中，目前已成为 iOS 和整个 Apple 平台生态中**最推荐**、也是最未来的包管理方案。

## 1. 为什么选择 SPM 而不是 CocoaPods / Carthage？

在过去很长一段时间，iOS 社区高度依赖第三方工具 CocoaPods (基于 Ruby)。但 SPM 的崛起改变了这一切：
*   **官方钦定**：集成在 Xcode 中，开箱即用，无需安装 Ruby 环境，不会再遇到 `pod install` 时奇奇怪怪的 Ruby 版本冲突问题。
*   **没有 Workspace 侵入**：CocoaPods 会魔改你的工程，生成 `.xcworkspace` 并修改底层的构建设置。SPM 则是以极其干净、无侵入的方式链接到现有的 `.xcodeproj` 中。
*   **跨平台原生支持**：如果你写了一个 Swift 库，使用 SPM 可以让它不仅在 iOS 上跑，还能在 macOS、Linux 甚至是 Windows 上被其他 Swift 服务端项目无缝拉取。
*   **支持二进制与资源分发**：从 Swift 5.3 开始，SPM 完美支持包含图片、Storyboard 的资源文件，以及发布闭源的 `.xcframework` 二进制包。

## 2. Package.swift：核心清单文件

每一个 Swift Package 的根目录下必须有一个 `Package.swift` 文件。它使用 Swift 语言本身来定义包的名字、产物（Products）、依赖（Dependencies）和模块（Targets）。

```swift
// swift-tools-version: 5.9
// 必须在第一行声明要求的最底 Swift 工具链版本

import PackageDescription

let package = Package(
    name: "MyNetworkingLib",         // 包的名称
    defaultLocalization: "en",       // 默认本地化语言 (包含资源时需要)
    platforms: [
        .iOS(.v15), .macOS(.v13)     // 声明支持的最低系统版本
    ],
    products: [
        // Products 定义了包向外暴露的产物。这可以是普通的库，也可以是可执行文件 (executable)
        .library(
            name: "MyNetworkingLib",
            targets: ["MyNetworkingLib"]),
    ],
    dependencies: [
        // Dependencies 定义了该包依赖的其他外部 SPM 包。通过 Git URL 和版本号拉取
        .package(url: "https://github.com/Alamofire/Alamofire.git", .upToNextMajor(from: "5.8.0"))
    ],
    targets: [
        // Targets 是代码的组织单元。一个 Target 只能依赖其他 Targets 或外部库
        .target(
            name: "MyNetworkingLib",
            dependencies: ["Alamofire"] // 引入上面声明的 Alamofire
        ),
        .testTarget(
            name: "MyNetworkingLibTests",
            dependencies: ["MyNetworkingLib"]),
    ]
)
```

## 3. 在 Xcode 中使用 SPM

*   **添加依赖**：在 Xcode 中，选择 `File` -> `Add Package Dependencies...`。在右上角搜索框粘贴 GitHub 仓库地址，选择对应的分支或版本号，点击 `Add Package` 即可。
*   **更新依赖**：右键点击 Xcode 左侧导航栏的 `Package Dependencies`，选择 `Update to Latest Package Versions`。
*   **本地包 (Local Package)**：SPM 不仅用于拉取远程库，也是实施**工程组件化**的神器。你可以直接在 Xcode 中新建一个 Local Package 拖入工程中。主 App 可以直接引用本地包。这种方式极大提升了多模块工程的清晰度和编译速度，且不需要配置复杂的 Podfile。

## 4. 命令行操作

SPM 也是一个独立的命令行工具。如果你在终端中开发（比如 Swift 后端项目）：
*   `swift package init --type executable`：初始化一个新包。
*   `swift build`：编译包。
*   `swift test`：运行 `testTarget` 中定义的测试。
*   `swift run`：如果包里有 `executableTarget`，直接运行它。