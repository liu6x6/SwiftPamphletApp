# SwiftUI Table：样式化

SwiftUI 的 `Table` 组件主要为 macOS 和 iPadOS 设计，它提供了一套强大的 API 来定制其外观和样式，以满足不同应用的设计需求，并与平台的设计规范保持一致。

## 1. 表格样式 (`.tableStyle()`)

`.tableStyle()` 是定制 `Table` 整体外观的最主要方式。在 macOS 上，它提供了几种不同的内置样式：

*   **`.automatic`**: 默认样式。通常等同于 `.inset`。
*   **`.inset`**: 内嵌样式。表格的边缘和内容之间会有一些内边距，并且在有 `Section` 时，会显示为圆角的分组样式。
*   **`.bordered`**: 边框样式。表格会有一个清晰的外部边框，并且列与列、行与行之间都有分隔线，创造出经典的电子表格外观。

```swift
import SwiftUI

struct TableStyleExample: View {
    // ... (假设有 FileItem 数据模型和 items 数组)

    var body: some View {
        Table(items) {
            TableColumn("文件名", value: \.name)
            TableColumn("大小", value: \.size) { ... }
        }
        // 应用边框样式
        .tableStyle(.bordered)
    }
}

#Preview {
    TableStyleExample()
}
```

## 2. 列的样式与布局

你可以对 `TableColumn` 应用修饰符，来单独控制每一列的宽度和对齐。

### 列宽 (`.width()`)

你可以为列指定固定的宽度，或者一个宽度范围。

```swift
Table(items) {
    TableColumn("文件名", value: \.name)
        .width(min: 150, max: 400) // 允许用户在 150 到 400 之间拖动调整宽度
    
    TableColumn("种类", value: \.kind)
        .width(100) // 固定宽度为 100
    
    TableColumn("大小", value: \.size) // 不指定宽度，会自动占据剩余空间
}
```

### 列对齐

在 `TableColumn` 的闭包中，你可以使用 `.frame(maxWidth: .infinity, alignment: ...)` 来控制单元格内容的对齐方式。

```swift
TableColumn("大小") { item in
    Text("\(item.size)")
        .frame(maxWidth: .infinity, alignment: .trailing) // 内容右对齐
}
```

## 3. 行的样式

与 `List` 类似，`Table` 也支持一些行级的样式修饰符。

### 行背景 (`.listRowBackground()`)

你可以为 `Table` 中的行设置背景。这在需要根据行内容高亮显示特定行时非常有用。

**注意**: 要为 `Table` 的行应用 `.listRowBackground`，你不能使用便捷的 `Table(items) { ... }` 初始化方法。你需要使用一个 `ForEach` 来手动创建行。

```swift
struct TableRowStyleExample: View {
    @State private var items: [FileItem] = ...
    @State private var selection = Set<FileItem.ID>()

    var body: some View {
        Table(selection: $selection) { // 使用不带 data 的初始化方法
            TableColumn("文件名", value: \.name)
            TableColumn("大小", value: \.size) { ... }
        } rows: { // 使用 rows 构建器
            ForEach(items) { item in
                TableRow(item)
                    // 根据条件设置行背景
                    .listRowBackground(item.size > 5000 ? Color.red.opacity(0.2) : Color.clear)
            }
        }
    }
}
```

### 交替行背景 (macOS)

在 macOS 上，你可以通过 `.alternatingRowBackgrounds()` 修饰符来启用经典的“斑马条纹”背景，这可以提高表格的可读性。

```swift
Table(...) { ... }
    .alternatingRowBackgrounds()
```

## 4. 表格整体背景

与 `List` 类似，从 iOS 16 和 macOS 13 开始，你可以使用 `.scrollContentBackground(.hidden)` 来移除 `Table` 的默认背景，然后用 `.background()` 来设置你自己的自定义背景。

```swift
Table(...) { ... }
    .scrollContentBackground(.hidden)
    .background(Color.cyan.opacity(0.1))
```

## 总结

`Table` 提供了一套丰富的样式化 API，让你能够构建出既美观又功能强大的数据表格。

*   **整体风格**: 使用 `.tableStyle()` (如 `.bordered`) 来定义表格的整体外观。
*   **列定义**: 通过 `.width()` 和 `.frame()` 来精确控制每一列的尺寸和内容对齐。
*   **行样式**: 使用 `.listRowBackground`（需要配合 `ForEach` 和 `TableRow`）来自定义特定行的背景。
*   **macOS 特有**: `.alternatingRowBackgrounds()` 可以快速实现交替行背景。
*   **自定义背景**: 使用 `.scrollContentBackground(.hidden)` 和 `.background()` 的组合来设置表格的整体背景。

通过组合这些样式修饰符，你可以将一个简单的数据表格，打造成一个符合你的应用设计语言、信息清晰、可读性强的专业级数据展示组件。
