# VSCode 中的 Swift 开发

Visual Studio Code (VSCode) 是目前全球最受欢迎的轻量级代码编辑器。虽然对于开发纯正的 iOS/macOS 客户端 App，Xcode 仍然是无可替代的选择（因为签名、打包、模拟器调试等链路），但是对于 **Swift 服务端开发 (Server-Side Swift)**、**跨平台 Swift 库开发**以及 **Swift 脚本编写**，VSCode 提供了极其出色的体验。

## 1. 核心环境配置

要在 VSCode 中愉快地编写 Swift，你需要两个关键步骤：

### 第一步：安装 Swift 工具链
在 macOS 上，你通常只需要安装 Xcode 命令行工具 (`xcode-select --install`)，它就已经自带了完整的 Swift 编译器。如果你在 Linux (如 Ubuntu) 或 Windows 上，需要从 swift.org 官方下载对应平台的 Toolchain。

### 第二步：安装官方插件
在 VSCode 的插件市场搜索并安装由 **Apple 官方维护**的插件：`Swift` (由 Swift Server Workgroup 提供)。

这个官方插件背后依赖于 `SourceKit-LSP` (Language Server Protocol)，它能提供：
*   精准的代码自动补全。
*   跳转到定义 (Go to Definition) 和查找引用。
*   实时语法错误提示和代码悬浮文档。
*   自动发现并集成 Swift Package Manager (SPM)。

## 2. 调试 (Debugging) 支持

仅仅有代码高亮是不够的，我们需要能打断点调试。为此你需要安装另一个插件：**`CodeLLDB`** (作者：Vadim Chugunov)。

**如何调试：**
当你在 VSCode 中打开一个包含 `Package.swift` 的 SPM 工程时，Swift 插件会自动检测到它。
1.  按 `Cmd + Shift + P` (或 Ctrl+Shift+P)，输入 `Swift: Generate Launch Configurations`。
2.  这会在 `.vscode/launch.json` 中自动生成调用 CodeLLDB 的调试配置。
3.  在代码行号左侧点击添加红色的断点。
4.  按下 `F5` 即可启动编译并在断点处暂停，你可以查看变量树和调用栈。

## 3. 在 VSCode 中开发 iOS 应用？

虽然极度不推荐（因为你要与整个生态对抗），但在理论上和极客折腾的层面，是可行的：

1.  **代码编辑**：你可以用 VSCode 打开 iOS 项目的主目录来编写 `.swift` 文件，享受更快的打开速度和 Copilot 补全。
2.  **构建与运行**：你需要借助 `xcodebuild` 命令行工具或者 `Fastlane` 来编译项目，并通过 `xcrun simctl` 命令将打包好的 `.app` 安装到模拟器上。
3.  **UI 预览缺失**：你将完全失去 SwiftUI Previews 和 Storyboard/XIB 的图形化编辑能力。这也是绝大多数客户端开发者最终回到 Xcode 的原因。

## 4. 推荐的 VSCode 插件包 (Swift 开发者)
除了核心的 `Swift` 和 `CodeLLDB`，以下插件能大幅提升体验：
*   **SwiftLint**：如果你在项目中使用了 SwiftLint 规范，这个插件能在你写代码时实时画红线提示格式问题。
*   **GitHub Copilot / Cursor**：AI 辅助编程。
*   **GitLens**：强大的 Git 记录可视化，了解每一行代码是谁在什么时候写的。