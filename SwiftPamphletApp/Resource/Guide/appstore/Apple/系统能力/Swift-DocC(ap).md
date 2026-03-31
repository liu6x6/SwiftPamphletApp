# Swift 系统能力：Swift-DocC 文档生成

Swift-DocC 是苹果官方推出的、用于为 Swift 框架和包创建和发布丰富、专业级文档的工具链。它不仅仅是一个简单的 API 文档提取工具，更是一个强大的文档化平台，允许你编写包含教程、文章和交互式示例的综合性开发者文档。

DocC 会直接解析你的 Swift 源代码中的特殊格式注释，并结合额外的 Markdown 文件，最终生成一个可以被 Xcode 直接显示，或者可以被部署为静态网站的、外观精美的文档站点。

## 核心理念：源码中的文档

DocC 的核心理念是“文档即代码”。你的 API 文档应该与实现它的源代码紧密地存放在一起。这通过一种特殊的、基于 Markdown 的注释语法来实现。

### 1. 文档注释 (Documentation Comments)

你可以使用三斜线 `///` 或块注释 `/** ... */` 来为你的代码（如 `struct`, `class`, `func`, `var`）添加文档注释。

```swift
import SwiftUI

/**
 一个用于显示用户头像的视图。

 你可以通过提供一个 URL 来异步加载头像图片，并可以自定义其尺寸和形状。

 - Note: 这个视图会自动处理图片的缓存。
 */
public struct AvatarView: View {
    let url: URL
    let size: CGFloat

    /**
     创建一个新的头像视图。
     
     - Parameters:
        - url: 要加载的头像图片的 URL。
        - size: 头像视图的边长。
     */
    public init(url: URL, size: CGFloat) {
        self.url = url
        self.size = size
    }

    public var body: some View {
        // ... 视图实现
    }
}
```

DocC 使用一种特殊的 Markdown 变体，其中包含了一些用于描述代码元素的关键字，如 `- Parameters:`, `- Returns:`, `- Throws:`, `- Note:`, `- Warning:` 等。

### 2. 符号链接 (Symbol Links)

你可以使用双反引号 `` `MyType` `` 来创建一个指向你的代码中其他符号（类型、函数、变量）的链接。DocC 在生成文档时，会自动将这些链接转换为可点击的超链接。

```swift
/// 这个函数会调用 ``anotherFunction()`` 来完成任务。
```

## DocC 的两种文档类型

DocC 支持创建两种主要类型的文档内容：

### 1. API 参考 (API Reference)

这是通过解析你源代码中的文档注释自动生成的。它会为你的框架或包中的每一个 `public` 或 `internal` 的 API，创建一个详细的文档页面，其中包含了你编写的描述、参数说明、返回值等。

### 2. 文章与教程 (Articles and Tutorials)

除了 API 参考，你还可以编写更长篇的、叙事性的内容来帮助开发者更好地理解你的框架。

*   **文章 (Articles)**: 使用标准的 Markdown 文件（`.md`）编写，用于解释核心概念、架构设计或提供使用指南。
*   **教程 (Tutorials)**: 一种特殊的、交互式的文档格式。你可以创建一个多步骤的、引导式的教程，其中可以包含代码示例、图片，甚至是一个完整的、可供用户在 Xcode 中实时交互的 SwiftUI 项目。

要让 DocC 能够发现和组织这些额外的 Markdown 文件，你需要在你的项目中创建一个**文档目录 (Documentation Catalog)**。

## 文档目录 (Documentation Catalog)

文档目录是一个以 `.docc` 为扩展名的特殊文件夹。你可以通过 Xcode 的 File -> New -> File... -> Documentation Catalog 来创建它。

一个典型的 `.docc` 目录结构如下：

```
MyFramework.docc/
├── MyFramework.md  (着陆页)
├── Resources/
│   ├── image1.png
│   └── ...
└── Tutorials/
    ├── MyFirstTutorial.tutorial
    │   ├── 01-Introduction.md
    │   ├── 02-StepTwo.md
    │   └── Resources/
    └── ...
```

*   **着陆页**: 与 `.docc` 目录同名的 Markdown 文件（如 `MyFramework.md`）是你的文档站点的首页或“着陆页”。你需要在这里组织你的文档结构，提供指向其他文章、教程和 API 符号的链接。
*   **`Resources` 文件夹**: 用于存放文档中使用的所有图片和其他资源。
*   **`.tutorial` 文件**: 教程由一个 `.tutorial` 文件（一个 JSON 格式的元数据文件）和一系列的 Markdown 步骤文件组成。

## 生成文档

在 Xcode 中，生成和预览 DocC 文档非常简单。

1.  **构建文档**: 选择 Product -> Build Documentation (`Cmd+Shift+D`)。
2.  **查看文档**: Xcode 会编译你的文档，并在其内置的文档查看器中（与苹果官方文档相同的界面）显示出来。

## 发布文档

DocC 也可以将你的文档导出为一个独立的、可部署的静态网站。

1.  在 Xcode 的文档查看器中，点击右上角的 “...” 按钮。
2.  选择 “Export...”。
3.  Xcode 会生成一个包含所有 HTML, CSS, JavaScript 和资源文件的文件夹。
4.  你可以将这个文件夹部署到任何静态网站托管服务上，例如 GitHub Pages。

许多开源项目也通过持续集成（CI）流程，来自动地在每次代码更新时生成并部署他们的 DocC 网站。

## 总结

Swift-DocC 是一个功能极其强大的文档化平台，它将编写代码和编写文档的体验无缝地集成在了一起。

*   **源码即文档**: 通过在代码中编写丰富的 Markdown 注释，实现文档与代码的同步。
*   **超越 API**: 不仅能生成 API 参考，还支持创建包含图片、视频和交互式示例的教程和文章。
*   **Xcode 集成**: 在 Xcode 中可以方便地实时预览和构建文档。
*   **静态网站导出**: 可以轻松地将你的文档发布为一个专业的、可公开访问的网站。

为你的框架或库编写高质量的文档，是吸引用户、建立社区和提升其价值的关键一步。Swift-DocC 为此提供了一套完整的、由苹果官方支持的现代化工具链。
