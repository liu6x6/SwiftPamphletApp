# SwiftUI 中的 Picker 选择器

`Picker` 是 SwiftUI 中一个用于让用户从一组互斥的选项中选择一个值的控件。它是一个高度灵活的组件，可以根据上下文和应用的样式，呈现为多种不同的外观，如滚轮、菜单、分段控件等。

## 核心用法：绑定与数据源

创建一个 `Picker` 的核心要素是：

1.  **`selection`**: 一个到状态变量的双向绑定 (`Binding`)，用于存储用户的当前选择。
2.  **`label`**: 一个描述 `Picker` 用途的视图。
3.  **数据源**: 在 `Picker` 的内容闭包中，使用 `ForEach` 循环来提供一组可供选择的视图。每个视图都需要通过 `.tag()` 修饰符来附加一个唯一的、与 `selection` 状态变量类型匹配的值。

```swift
import SwiftUI

struct BasicPickerExample: View {
    // 2. 数据源
    let themes = ["Light", "Dark", "System"]
    // 1. 状态变量存储当前选择
    @State private var selectedTheme: String = "System"

    var body: some View {
        VStack {
            Text("当前主题: \(selectedTheme)")
                .font(.headline)
            
            // 3. 创建 Picker
            Picker("选择主题", selection: $selectedTheme) {
                ForEach(themes, id: \.self) { theme in
                    Text(theme)
                        .tag(theme) // 关键：为每个选项设置唯一的 tag
                }
            }
        }
        .padding()
    }
}

#Preview {
    BasicPickerExample()
}
```

在这个例子中：
*   `selectedTheme` 状态变量存储了当前选中的主题字符串。
*   `Picker` 通过 `$selectedTheme` 与该状态双向绑定。
*   `ForEach` 遍历 `themes` 数组来创建三个 `Text` 视图作为选项。
*   `.tag(theme)` 是至关重要的一步。它将每个 `Text` 视图与一个唯一的字符串值（`"Light"`, `"Dark"`, `"System"`）关联起来。当用户选择某个 `Text` 时，SwiftUI 会将该 `Text` 关联的 `tag` 值赋给 `selectedTheme` 状态变量。

## `Picker` 的样式：`.pickerStyle()`

`Picker` 最强大的特性之一就是其样式的多变性。通过 `.pickerStyle()` 修饰符，你可以将同一个 `Picker` 的定义渲染成完全不同的外观，以适应不同的 UI 场景。

### 常见样式

*   `.automatic`: 默认样式，由 SwiftUI 根据上下文（如是否在 `Form` 中）自动选择最佳样式。
*   `.menu`: 表现为一个可点击的按钮，点击后弹出一个选择菜单。这是在 `Form` 之外的默认样式。
*   `.segmented`: 分段控件样式，将所有选项水平排列在一组按钮中。非常适合选项较少（通常 2-4 个）的场景。
*   `.wheel`: 滚轮样式，常用于日期和时间的输入，或当选项很多时。
*   `.inline`: 内联样式，直接在当前布局中展开所有选项，通常与 `List` 或 `Form` 结合使用。
*   `.navigationLink` (iOS 16+): 在 `Form` 或 `List` 中表现为一个导航链接，点击后进入一个新的页面来展示所有选项。

```swift
struct PickerStyleExample: View {
    let themes = ["Light", "Dark", "System"]
    @State private var selectedTheme: String = "System"

    var body: some View {
        NavigationView {
            Form {
                // 在 Form 中，.automatic 通常默认为 .menu 或 .navigationLink
                Picker("主题 (Automatic)", selection: $selectedTheme) {
                    ForEach(themes, id: \.self) { Text($0).tag($0) }
                }
                
                Picker("主题 (Segmented)", selection: $selectedTheme) {
                    ForEach(themes, id: \.self) { Text($0).tag($0) }
                }
                .pickerStyle(.segmented)
                
                Picker("主题 (Wheel)", selection: $selectedTheme) {
                    ForEach(themes, id: \.self) { Text($0).tag($0) }
                }
                .pickerStyle(.wheel)
                
                Picker("主题 (Inline)", selection: $selectedTheme) {
                    ForEach(themes, id: \.self) { Text($0).tag($0) }
                }
                .pickerStyle(.inline)
            }
            .navigationTitle("Picker 样式")
        }
    }
}

#Preview {
    PickerStyleExample()
}
```

通过简单地改变 `.pickerStyle()`，你就可以获得完全不同的用户体验，而无需修改 `Picker` 的核心逻辑。

## 使用枚举作为数据源

为了获得更好的类型安全，强烈建议使用遵循 `CaseIterable` 和 `Identifiable` 的枚举作为 `Picker` 的数据源。

```swift
enum Theme: String, CaseIterable, Identifiable {
    case light = "浅色"
    case dark = "深色"
    case system = "跟随系统"
    
    var id: Self { self }
}

struct EnumPickerExample: View {
    @State private var selectedTheme: Theme = .system

    var body: some View {
        Picker("选择主题", selection: $selectedTheme) {
            // 直接遍历枚举的所有 case
            ForEach(Theme.allCases) { theme in
                Text(theme.rawValue).tag(theme)
            }
        }
        .pickerStyle(.segmented)
        .padding()
    }
}

#Preview {
    EnumPickerExample()
}
```

在这个例子中：
*   `Theme` 枚举的 `String` 原始值用于显示文本。
*   `CaseIterable` 协议让我们可以通过 `Theme.allCases` 来获取一个包含所有 case 的数组。
*   `Identifiable` 协议（通过 `var id: Self { self }` 实现）让 `ForEach` 能够唯一地标识每个 case。
*   `selection` 状态变量的类型是 `Theme`，而不是不安全的 `String`。
*   `.tag(theme)` 附加的是整个 `Theme` 枚举 case，而不是一个简单的字符串，这保证了类型安全。

## 总结

`Picker` 是 SwiftUI 中一个用途广泛、样式多变的选择器控件。

*   **核心**: 通过与状态变量的**双向绑定**和带**`.tag()`**的选项视图来工作。
*   **样式灵活**: `.pickerStyle()` 是其最强大的特性，允许你用一套代码实现多种不同的 UI 表现。
*   **类型安全**: 强烈建议使用遵循 `CaseIterable` 和 `Identifiable` 的枚举作为数据源，以提高代码的健壮性。
*   **上下文感知**: `Picker` 的默认外观 (`.automatic`) 会智能地适应其所在的容器，如 `Form` 或 `Toolbar`。

掌握 `Picker` 及其不同的样式，是构建任何需要用户从一组选项中进行选择的界面的基础。
