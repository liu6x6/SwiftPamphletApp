# SwiftUI 中的 ShareLink (iOS 16+)

从 iOS 16 开始，SwiftUI 引入了一个全新的、现代化的视图来处理分享功能：`ShareLink`。它极大地简化了将文本、URL、图片等数据分享到其他应用（如信息、邮件、隔空投送等）的过程，取代了以往需要封装 `UIActivityViewController` 的复杂做法。

## 核心用法

`ShareLink` 的使用非常直观。你只需要提供你想要分享的内容，它就会自动渲染为一个带有标准分享图标和“分享”字样的按钮。当用户点击它时，系统会弹出一个标准的分享面板（Share Sheet）。

```swift
import SwiftUI

struct BasicShareLinkExample: View {
    private let urlToShare = URL(string: "https://www.apple.com/swiftui")!

    var body: some View {
        VStack(spacing: 20) {
            // 1. 分享一个简单的 URL
            ShareLink(item: urlToShare)
            
            // 2. 分享简单的文本
            ShareLink(item: "了解一下 SwiftUI！")
        }
    }
}

#Preview {
    BasicShareLinkExample()
}
```

在这个例子中，`ShareLink` 会自动处理 `URL` 和 `String` 类型的数据，并为它们提供合适的分享表示。

## 自定义 `ShareLink` 的外观

与 `Button` 和 `Link` 类似，`ShareLink` 的标签（`label`）也是完全可定制的。你可以使用一个自定义的视图闭包来创建任何你想要的外观。

```swift
struct CustomShareLinkExample: View {
    private let photo = Image(systemName: "swift") // 假设这是我们要分享的图片

    var body: some View {
        ShareLink(item: photo, preview: SharePreview("Swift Logo", image: photo)) {
            // 自定义标签视图
            Label("分享 Swift Logo", systemImage: "square.and.arrow.up")
        }
        .buttonStyle(.borderedProminent)
    }
}
```

在这个例子中：
*   我们使用一个 `Label` 视图作为 `ShareLink` 的标签，使其看起来更像一个自定义的按钮。
*   我们分享的是一个 `Image`。为了让分享面板能够正确地显示预览，我们提供了一个 `SharePreview` 实例。

## `SharePreview`：自定义预览内容

当你在分享面板中分享一个项目时，系统会尝试生成一个预览来向用户展示他们正在分享什么。对于 URL，它会是一个富链接预览；对于图片，它会是图片本身。但有时，你可能想对这个预览进行更精细的控制。

`SharePreview` 允许你为分享的项目提供一个自定义的标题和预览图像。

```swift
struct SharePreviewExample: View {
    let bookURL = URL(string: "https://www.example.com/my-great-book")!
    let bookCover = Image("book-cover")

    var body: some View {
        ShareLink(
            item: bookURL,
            // 提供一个自定义的预览
            preview: SharePreview(
                "《SwiftUI 编程思想》",
                image: bookCover
            )
        )
    }
}
```

在这个例子中，即使用户分享的是一个 URL，分享面板中显示的预览也会是我们提供的书籍封面图片和标题，而不是系统自动抓取的网页预览，这提供了更丰富的上下文和品牌展示机会。

## 分享多种数据

`ShareLink` 可以一次性分享多个项目。你只需要将一个包含多个 `Transferable` 项的数组传递给 `item` 参数即可。

```swift
ShareLink(items: ["一条消息", urlToShare, imageToShare])
```

## `Transferable` 协议

`ShareLink` 的强大功能建立在 `Transferable` 协议之上。这个协议定义了一个类型如何将自身转换为一种或多种可供传输的数据表示（例如 `Data`, `String`, `Image`）。

Swift 中许多内置的类型，如 `String`, `URL`, `Data`, `Image`, `AttributedString` 等，都已经默认遵循了 `Transferable`。

你也可以让你自己的自定义数据类型遵循 `Transferable`，以便能够通过 `ShareLink` 进行分享。这通常通过使其遵循 `Codable` 并使用 `CodableRepresentation` 来实现。

```swift
import UniformTypeIdentifiers

// 1. 自定义数据类型
struct MyRecipe: Codable, Transferable {
    var title: String
    var ingredients: [String]
    
    // 2. 实现 Transferable
    static var transferRepresentation: some TransferRepresentation {
        // 使用 Codable 进行序列化，并指定一个自定义的文件类型
        CodableRepresentation(contentType: .myRecipe)
    }
}

// 3. 定义自定义的 UTType
extension UTType {
    static let myRecipe = UTType(exportedAs: "com.example.myrecipe")
}

// 4. 在 ShareLink 中使用
struct ShareCustomDataExample: View {
    let recipe = MyRecipe(title: "蛋糕", ingredients: ["面粉", "鸡蛋", "糖"])

    var body: some View {
        ShareLink(
            item: recipe,
            preview: SharePreview("分享食谱: \(recipe.title)")
        )
    }
}
```

在这个例子中，当用户分享 `MyRecipe` 对象时，它会被编码成一个文件，并可以通过“文件”或“隔空投送”等方式发送给其他能够识别 `.myRecipe` 文件类型的应用。

## 总结

`ShareLink` 是 SwiftUI 中实现分享功能的现代化、简洁且强大的方式。

*   **简单易用**: 只需提供要分享的项目，即可创建一个功能完备的分享按钮。
*   **可定制**: 支持完全自定义的标签视图和分享预览。
*   **类型安全**: 基于 `Transferable` 协议，可以安全地分享各种系统内置类型和自定义类型的数据。
*   **隐私友好**: 与 `PhotosPicker` 类似，它通过系统服务来处理分享，保护了用户数据。

在任何需要提供“分享”功能的场景下，`ShareLink` 都应该是你的首选工具。
