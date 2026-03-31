# SwiftUI 数据传输：Transferable 协议 (iOS 16+)

`Transferable` 是苹果在 WWDC 2022 (iOS 16) 中引入的一个强大的协议，它旨在统一和简化 SwiftUI 中所有与**数据传输**相关的操作，包括拖放（Drag and Drop）、复制粘贴（Copy and Paste）、以及通过 `ShareLink` 进行分享。

通过让你的自定义数据类型遵循 `Transferable`，你可以告诉系统这个类型的数据是如何被序列化（编码）以便传输，以及如何从接收到的数据中反序列化（解码）的。

## 核心理念：统一的数据表示

在 `Transferable` 出现之前，处理拖放、复制粘贴等操作需要为不同的场景实现不同的协议和回调（如 `NSItemProvider`），代码非常繁琐且难以复用。

`Transferable` 的核心思想是，任何一个可传输的数据类型，都应该能够为自己“代言”，即**声明**它可以被表示成哪些通用的、可传输的格式。

例如，一个自定义的 `Recipe` (食谱) 类型，可以声明它能被表示为：
1.  一个自定义的、包含完整信息的 `Data` 包（用于在自己的应用之间传输）。
2.  一个纯文本 `String`（用于分享到短信或邮件）。
3.  一张代表食谱的 `Image`（用于在分享面板中生成预览）。

## 如何遵循 `Transferable`

要让你的自定义类型变得“可传输”，你需要让它遵循 `Transferable` 协议，并实现一个核心的静态计算属性：

*   **`static var transferRepresentation: some TransferRepresentation`**: 这个属性返回一个 `TransferRepresentation` 类型的对象，你在其中定义了你的类型可以如何被编码和解码。

### 1. 使用 `CodableRepresentation` (最简单的方式)

如果你的数据类型已经遵循了 `Codable`，那么实现 `Transferable` 会非常简单。你只需要使用 `CodableRepresentation` 即可。

```swift
import SwiftUI
import UniformTypeIdentifiers

// 1. 确保你的数据类型遵循 Codable 和 Hashable/Identifiable
struct Recipe: Codable, Identifiable, Hashable {
    let id = UUID()
    var title: String
    var ingredients: [String]
}

// 2. 定义一个唯一的统一类型标识符 (UTType)
extension UTType {
    static let recipe = UTType(exportedAs: "com.example.recipe")
}

// 3. 遵循 Transferable
extension Recipe: Transferable {
    static var transferRepresentation: some TransferRepresentation {
        // 使用 CodableRepresentation 来自动处理编码和解码
        CodableRepresentation(contentType: .recipe)
    }
}
```

在这个例子中，`CodableRepresentation` 会在需要传输 `Recipe` 对象时，自动使用 `JSONEncoder` 将其编码为 `Data`，并在接收端使用 `JSONDecoder` 将 `Data` 解码回 `Recipe` 对象。`contentType: .recipe` 指定了这种数据在系统中的唯一类型。

### 2. 使用 `DataRepresentation` (更底层的控制)

如果你需要手动控制序列化和反序列化的过程（例如，你的数据格式不是 JSON），你可以使用 `DataRepresentation`。

```swift
extension MyDataType: Transferable {
    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(
            contentType: .myDataType,
            exporting: { myData in
                // 手动将你的类型编码为 Data
                return try myData.customEncode()
            },
            importing: { data in
                // 手动从 Data 解码为你的类型
                return try MyDataType(customDecode: data)
            }
        )
    }
}
```

### 3. 提供多种表示 (`ProxyRepresentation`)

`ProxyRepresentation` 允许你为一个类型提供多种不同的、降级的表示方式。这在需要与不理解你自定义类型的应用进行交互时非常有用。

```swift
extension Recipe: Transferable {
    static var transferRepresentation: some TransferRepresentation {
        // 首选方式：传输完整的 Recipe 对象
        CodableRepresentation(contentType: .recipe)
        
        // 备选方式：如果接收方不支持 .recipe 类型，则提供一个纯文本表示
        ProxyRepresentation(exporting: { recipe in
            "食谱：\(recipe.title)\n\n成分：\(recipe.ingredients.joined(separator: ", "))"
        })
    }
}
```

当用户通过 `ShareLink` 分享这个 `Recipe` 时：
*   如果他们选择“隔空投送”给另一个安装了你的应用的用户，对方会收到完整的 `Recipe` 对象。
*   如果他们选择“信息”或“邮件”，对方会收到一段格式化的纯文本。

## `Transferable` 的应用

一旦你的类型遵循了 `Transferable`，你就可以在所有支持该协议的 SwiftUI API 中无缝地使用它。

### `ShareLink`

```swift
ShareLink(item: myRecipe, preview: SharePreview(myRecipe.title))
```

### 拖放 (Drag and Drop)

*   **`.draggable()`**: 让一个视图变得可拖动。

    ```swift
    MyRecipeView(recipe: myRecipe)
        .draggable(myRecipe) // 直接传递 Transferable 对象
    ```

*   **`.dropDestination()`**: 创建一个可以接收拖放项目的区域。

    ```swift
    MyDropArea()
        .dropDestination(for: Recipe.self) { droppedRecipes, location in
            // 处理接收到的 Recipe 数组
            return true // 返回 true 表示成功处理
        }
    ```

### `PhotosPicker`

`PhotosPicker` 使用 `Transferable` 来加载用户选择的图片数据。

```swift
.onChange(of: selectedPhotoItem) { item in
    Task {
        // Data 和 Image 都遵循 Transferable
        if let data = try? await item?.loadTransferable(type: Data.self) {
            // ...
        }
    }
}
```

## 总结

`Transferable` 协议是 SwiftUI 中一个用于统一数据传输的、极其重要的现代化 API。

*   **统一接口**: 为拖放、复制粘贴、分享等多种操作提供了单一、一致的数据表示方式。
*   **声明式**: 你只需要在你的数据模型上声明它如何被传输，而无需为每个场景编写重复的序列化/反序列化代码。
*   **可组合性**: 允许你为一个数据类型提供多种不同的表示（如自定义 `Codable` 对象、纯文本、图片），系统会自动选择最合适的一种。
*   **简化 API**: 使得 `.draggable`, `.dropDestination`, `ShareLink` 等 API 的使用变得异常简洁和类型安全。

对于任何需要在应用内部或应用之间进行数据交换的场景，花时间让你的数据模型遵循 `Transferable` 协议，都将极大地简化你的代码，并提升其健壮性和可扩展性。
