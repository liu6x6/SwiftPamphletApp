# SwiftUI 中的文档式应用协议

SwiftUI 提供了一套强大的、基于协议的抽象，用于构建“文档式应用”。这类应用的核心是创建、编辑和管理用户文档，例如文本编辑器、绘图应用、电子表格等。通过遵循 SwiftUI 的文档协议，你可以让你的应用自动获得许多系统级的特性，如文档的打开、保存、iCloud 同步、撤销/重做等，而无需编写大量模板代码。

这套系统的核心是 `DocumentGroup` 场景（`Scene`）以及 `FileDocument` 和 `ReferenceFileDocument` 两个核心协议。

## `DocumentGroup`

`DocumentGroup` 是一个专门用于文档式应用的 `Scene` 类型。你在应用的主入口（`App` struct）中使用它来声明你的应用是基于文档的。

```swift
import SwiftUI

@main
struct MyApp: App {
    var body: some Scene {
        // 声明一个文档组场景
        // MyDocument 是你自定义的文档模型
        // EditorView 是用于编辑该文档的视图
        DocumentGroup(newDocument: MyDocument()) { file in
            EditorView(document: file.document)
        }
    }
}
```

`DocumentGroup` 会自动处理：
*   在应用启动时显示一个文档浏览器（在 iOS/iPadOS 上）。
*   处理“文件”菜单中的“新建”、“打开”等命令（在 macOS 上）。
*   为每个打开的文档创建新的窗口或场景。

## `FileDocument` 协议

`FileDocument` 协议用于处理**基于值类型（struct）**的文档。当你的文档模型可以被视为一个独立的、完整的值时（例如一个纯文本文件、一个 JSON 文件或一个自定义的、包含简单数据的结构体），`FileDocument` 是最佳选择。它具有写时复制（copy-on-write）的特性，既安全又高效。

要遵循 `FileDocument`，你需要实现两个核心要求：

1.  **`static var readableContentTypes: [UTType]`**: 一个静态属性，声明你的文档可以读取哪些类型的内容（UTType）。
2.  **`init(configuration: ReadConfiguration)`**: 一个初始化方法，用于从磁盘加载数据并创建一个文档实例。
3.  **`fileWrapper(configuration: WriteConfiguration)`**: 一个方法，用于将你的文档内容保存到磁盘。

### 示例：一个简单的 Markdown 编辑器

```swift
import SwiftUI
import UniformTypeIdentifiers

// 1. 定义文档模型，遵循 FileDocument
struct MarkdownDocument: FileDocument {
    var text: String

    init(text: String = "# Hello, World!") {
        self.text = text
    }

    // 2. 声明可读的类型为 .markdown
    static var readableContentTypes: [UTType] { [.markdown] }

    // 3. 从磁盘数据初始化文档
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let string = String(data: data, encoding: .utf8)
        else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.text = string
    }

    // 4. 将文档内容写入磁盘
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = text.data(using: .utf8)!
        return FileWrapper(regularFileWithContents: data)
    }
}

// 编辑器视图
struct MarkdownEditorView: View {
    @Binding var document: MarkdownDocument

    var body: some View {
        TextEditor(text: $document.text)
    }
}

// 应用主入口
@main
struct MarkdownApp: App {
    var body: some Scene {
        DocumentGroup(newDocument: MarkdownDocument()) { file in
            MarkdownEditorView(document: file.$document)
        }
    }
}
```

在这个例子中：
*   `MarkdownDocument` 结构体封装了文档的核心数据（一个 `text` 字符串）。
*   它声明了自己可以处理 `.markdown` 类型的文件。
*   它实现了从 `Data` 初始化和保存为 `Data` 的逻辑。
*   `DocumentGroup` 将这个文档模型与 `MarkdownEditorView` 连接起来。注意 `file.$document`，它创建了一个到文档的绑定，使得 `TextEditor` 可以直接修改文档内容。

## `ReferenceFileDocument` 协议

`ReferenceFileDocument` 协议用于处理**基于引用类型（class）**的文档。当你的文档模型非常复杂，或者在内存中只保留一份实例更高效时（例如，一个大型的、包含多个关联对象图的绘图应用数据模型），应该使用 `ReferenceFileDocument`。

它与 `FileDocument` 的主要区别在于：

*   它处理的是 class，因此不存在写时复制。
*   它使用 `snapshot()` 方法来创建一个用于保存的、不可变的数据快照，而不是直接保存自身。

## 统一类型标识符 (UTType)

`UTType` 是苹果用于标识不同文件和数据类型的现代 API。在文档式应用中，你需要为你的自定义文档类型进行声明。

1.  **在 Xcode 项目设置中声明**: 在 `Info` -> `Exported Type Identifiers` 中添加你的自定义类型，例如 `com.myapp.mydocument`。
2.  **在代码中扩展 `UTType`**:

    ```swift
    import UniformTypeIdentifiers

    extension UTType {
        static var myCustomDocument: UTType {
            UTType(exportedAs: "com.myapp.mydocument")
        }
    }
    ```

然后你就可以在 `readableContentTypes` 中使用 `.myCustomDocument` 了。

## 总结

SwiftUI 的文档式应用协议是对构建文档类 App 的一次巨大简化。通过定义一个遵循 `FileDocument` 或 `ReferenceFileDocument` 的数据模型，并将其与 `DocumentGroup` 结合，你可以免费获得大量由系统提供的、健壮的文档管理功能。

*   **`DocumentGroup`**: 应用的场景入口，负责文档的生命周期管理。
*   **`FileDocument`**: 用于**值类型**（struct）的文档，简单、安全、高效。
*   **`ReferenceFileDocument`**: 用于**引用类型**（class）的文档，适用于复杂的数据模型。

当你需要创建一个允许用户创建、打开和保存文件的应用时，这套协议应该是你的首选架构。
