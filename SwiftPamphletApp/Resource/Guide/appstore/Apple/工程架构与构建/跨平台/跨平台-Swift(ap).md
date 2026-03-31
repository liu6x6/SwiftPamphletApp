# Swift 跨平台开发 (Cross-Platform Swift)

长久以来，Swift 被认为仅仅是 Apple 平台的“私有资产”。然而，自从 Apple 在 2015 年将 Swift 开源后，Swift 的跨平台能力一直在稳步提升。现在的 Swift 已经可以被视为一种全栈和跨平台的通用编程语言。

## 1. 为什么用 Swift 做跨平台？

如果你的团队本身就是深度的 iOS 团队，精通 Swift 语言，那么将核心的业务逻辑（网络请求、数据库模型、核心算法）用纯 Swift 编写，并跨平台复用到 Android 或 Windows 上，能够大幅节省开发和维护成本，同时保持极高的执行性能和类型安全。

## 2. 服务端 Swift (Server-Side Swift)

这是目前 Swift 跨平台最成熟的领域。Apple 官方成立了 Swift Server Workgroup (SSWG)，并在 Linux 环境下提供了完美的底层支持。

*   **Vapor**：目前最流行、生态最繁荣的 Swift Web 框架。
*   **Hummingbird**：基于 Swift 最新并发模型（async/await）构建的轻量级、高性能服务端框架。
*   **优势**：极低的内存占用（相比 JVM 和 Node.js），与 iOS 客户端共享数据模型和加解密逻辑（直接复用一套 Codable 结构体）。

## 3. 在 Android 上运行 Swift

利用 Swift 工具链的跨平台编译能力，你可以把 Swift 代码编译成 Android 能调用的动态链接库（.so）。

*   **Swift-Java/Kotlin 互操作**：目前最前沿的工具是 **Skip (skip.tools)**。它是一个极其神奇的转译器，能够将你的 Swift / SwiftUI 代码**直接转译**成 Android 的 Kotlin / Compose 代码，从而真正实现“一套 Swift 代码，两端原生运行”。
*   **SCADE**：另一款商业的跨平台框架，允许你用 Swift 编写 Android 应用。
*   如果你只想共享底层逻辑：你可以使用 `swift-jni` 等库，或者通过底层的 C ABI，让 Android 的 JNI (Java Native Interface) 调用你用 Swift 编译出的共享库。

## 4. Windows 与 Linux 开发

*   **Windows 支持**：苹果官方现在提供了针对 Windows 的原生 Swift 工具链安装包。开发者可以在 Windows 上使用 Visual Studio / VSCode 编写和编译 `.exe` 的 Swift 应用。
*   **Foundation 与跨平台标准库**：Apple 正在使用纯 Swift 重写底层的 `Foundation` 框架（此前 Linux 上的 Foundation 是基于 C 的 `corelibs-foundation` 模拟的，存在很多不一致的 Bug）。新的开源 Foundation 确保了 String, Date, JSONDecoder 在所有平台上的行为绝对一致。

## 5. Swift for Wasm (WebAssembly)

这是极其令人兴奋的领域。通过社区的 `SwiftWasm` 项目，你可以将 Swift 代码编译成 WebAssembly 字节码，直接在网页浏览器里运行。
*   **Tokamak**：一个基于 SwiftWasm 的前端框架，允许你使用类似 SwiftUI 的语法和纯 Swift 语言来编写能够在浏览器中运行的 Web 应用。

## 总结

虽然在跨平台 UI 领域（如对抗 Flutter 或 React Native），Swift 依然面临巨大的挑战（目前缺乏官方统一定义的跨平台视图渲染层），但在**逻辑层跨平台**和**服务端/脚本领域**，跨平台 Swift 已经完全具备了工业级的生产能力。