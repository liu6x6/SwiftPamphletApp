# iOS 开发中的第三方编辑器与工具

虽然 Xcode 是苹果官方钦定的、最主流的 iOS/macOS 开发工具，但在某些特定场景或为了提高开发效率，开发者也会借助或完全转向其他第三方编辑器和工具链。

## 1. AppCode (由 JetBrains 开发，已停止更新)

在很长一段时间里，AppCode 是除了 Xcode 之外最著名的 iOS IDE。
- **优势**：它继承了 JetBrains 家族（如 IntelliJ IDEA, WebStorm）极其强大的代码重构、智能提示、快捷键体系以及强大的 Git 集成。对于习惯了 IntelliJ 体系的开发者来说，写 Objective-C 和 Swift 会非常顺手。
- **劣势**：由于 Apple 没有开源其闭源构建系统和 SwiftUI 的实时预览，AppCode 始终需要依赖 Xcode 的命令行工具。它在支持 SwiftUI 预览、Storyboard 甚至最新的 Swift 语言特性上经常慢半拍。
- **现状**：JetBrains 已经于 2022 年底宣布**停止**对 AppCode 的后续开发和销售。

## 2. Visual Studio Code (VSCode)

随着 Swift 开源和跨平台化，VSCode 在 Swift 服务端开发和跨平台开发中占据了统治地位。
- **使用场景**：主要用于 Swift Server (如 Vapor, Perfect)、编写 Swift 脚本、或是浏览大型跨平台项目（如 React Native, Flutter 项目中涉及少量 iOS 原生代码时）。
- **核心插件**：
  - **Swift (由 Apple 官方维护)**：提供了语法高亮、基于 SourceKit-LSP 的代码补全、重构和调试支持。
  - **CodeLLDB**：用于在 VSCode 中调试 Swift 编译出的二进制文件。
- **限制**：虽然你可以用 VSCode 写 Swift 代码，但由于缺乏对 Xcode 工程文件（`.xcodeproj`）、Asset Catalog 编译以及 iOS 模拟器启动链路的深度集成，你很难用 VSCode 独立完成一个纯血 iOS App 的开发和上架。

## 3. Cursor / GitHub Copilot 等 AI 编辑器

这是近年来的新趋势。
- **Cursor** 是一款基于 VSCode 深度定制的、AI First 的编辑器。通过强大的大语言模型（如 Claude 3.5 Sonnet / GPT-4o），它可以直接阅读你的整个工程 codebase 并生成大量的 boilerplate 代码。
- **在 iOS 中的应用**：目前许多 iOS 开发者会在 Xcode 中利用 GitHub Copilot (现在 Xcode 也有了原生的苹果智能补全)，或者在遇到复杂算法和架构设计时，把代码复制到 Cursor 中进行 AI 结对编程。

## 4. 辅助工具

除了核心 IDE，iOS 开发者常备的第三方辅助工具包括：
- **Reveal** / **Lookin**：极其强大的第三方 UI 视图层级调试工具（比 Xcode 自带的 View Debugger 更好用）。
- **Charles** / **Proxyman**：网络抓包工具，用于查看和模拟网络请求。
- **Fastlane**：用 Ruby 编写的自动化工具集，主要用于 iOS 应用的自动化打包、截图和 TestFlight 上架。