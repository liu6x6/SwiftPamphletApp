# SwiftUI 中的字体选择器 (FontPicker)

在 SwiftUI 中，并没有一个像 `DatePicker` 或 `ColorPicker` 那样现成的、名为 `FontPicker` 的标准系统组件。然而，构建一个字体选择器是展示 `Picker` 控件灵活性和自定义能力的一个绝佳示例。一个字体选择器通常允许用户从一系列预设的字体中进行选择，并实时预览其效果。

本指南将向你展示如何使用标准的 `Picker` 和 `Font` API 来构建一个功能完善的字体选择器。

## 核心思路

构建字体选择器的核心思路如下：

1.  **定义数据源**: 创建一个包含所有可选字体名称的数组。为了更好的封装，我们可以创建一个 `Font` 的扩展或者一个专门的数据模型。
2.  **状态管理**: 使用一个 `@State` 变量来存储用户当前选择的字体名称。
3.  **构建 `Picker`**: 创建一个 `Picker`，将其选择状态绑定到 `@State` 变量，并遍历数据源来生成选项。
4.  **应用字体**: 将 `@State` 变量中存储的字体名称应用到一个示例文本上，以实现实时预览。

## 示例：构建一个基础的字体选择器

```swift
import SwiftUI

struct FontPickerExample: View {
    // 1. 定义字体数据源
    let fontNames = ["Arial", "Times New Roman", "Georgia", "Helvetica", "Courier New"]
    
    // 2. 状态变量存储当前选择
    @State private var selectedFontName: String = "Arial"

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("字体选择")) {
                    // 3. 构建 Picker
                    Picker("选择字体", selection: $selectedFontName) {
                        ForEach(fontNames, id: \.self) { fontName in
                            Text(fontName)
                                .font(.custom(fontName, size: 16)) // 在选项中预览字体
                                .tag(fontName)
                        }
                    }
                    // 在 iOS 16+ 上，.navigationLink 样式提供了很好的用户体验
                    .pickerStyle(.navigationLink)
                }
                
                Section(header: Text("预览")) {
                    // 4. 应用选择的字体进行实时预览
                    Text("The quick brown fox jumps over the lazy dog.")
                        .font(.custom(selectedFontName, size: 20))
                        .frame(height: 100, alignment: .top)
                }
            }
            .navigationTitle("字体选择器")
        }
    }
}

#Preview {
    FontPickerExample()
}
```

在这个例子中：
*   我们创建了一个 `fontNames` 数组作为数据源。
*   `selectedFontName` 存储了用户当前的选择。
*   `Picker` 遍历 `fontNames` 数组。一个巧妙的设计是，在 `ForEach` 内部，我们直接将 `Text` 的字体设置为它所代表的字体，这样用户在选择列表中就能直接看到每种字体的预览效果。
*   `.pickerStyle(.navigationLink)` (适用于 `Form` 或 `List` 中) 会创建一个新的页面来展示所有选项，这对于选项较多的情况非常友好。
*   预览区域的 `Text` 的字体通过 `.font(.custom(selectedFontName, size: 20))` 与 `@State` 变量联动，实现了实时预览。

## 改进：使用 `Font.Design` 枚举

对于系统字体，使用 `Font.Design` 枚举可以提供更可靠、更具语义化的方式来选择字体，而不是依赖于硬编码的字符串名称。

```swift
struct SystemFontPickerExample: View {
    // 1. 使用 Font.Design 作为数据源
    let fontDesigns: [Font.Design] = [.standard, .serif, .monospaced, .rounded]
    
    // 2. 状态变量的类型变为 Font.Design
    @State private var selectedDesign: Font.Design = .standard

    var body: some View {
        VStack {
            Picker("选择字体设计", selection: $selectedDesign) {
                ForEach(fontDesigns, id: \.self) { design in
                    Text(String(describing: design).capitalized)
                        .tag(design)
                }
            }
            .pickerStyle(.segmented)
            .padding()
            
            Text("Preview Text")
                .font(.system(size: 32, design: selectedDesign)) // 4. 应用选择的 design
        }
    }
}

#Preview {
    SystemFontPickerExample()
}
```

这个例子展示了如何选择不同的系统字体设计（`standard` 是默认的 San Francisco, `serif` 是 New York, `monospaced` 是 SF Mono, `rounded` 是 SF Rounded）。这种方式比使用字符串更安全，因为你不会因为拼写错误而出错。

## 封装成可复用组件

为了在应用中多处使用，我们可以将字体选择器封装成一个可复用的子视图。这需要使用 `@Binding` 来接收外部的状态。

```swift
// 可复用的字体选择器组件
struct FontPickerView: View {
    @Binding var selectedFontName: String
    let fontNames = ["Arial", "Times New Roman", "Georgia", "Helvetica", "Courier New"]

    var body: some View {
        Picker("选择字体", selection: $selectedFontName) {
            ForEach(fontNames, id: \.self) { fontName in
                Text(fontName).font(.custom(fontName, size: 16)).tag(fontName)
            }
        }
    }
}

// 父视图
struct ParentView: View {
    @State private var appFont: String = "Helvetica"

    var body: some View {
        Form {
            // 使用可复用组件
            FontPickerView(selectedFontName: $appFont)
            
            Section(header: Text("我的文本")) {
                Text("Hello, World!")
                    .font(.custom(appFont, size: 24))
            }
        }
    }
}

#Preview {
    ParentView()
}
```

在这个结构中，`FontPickerView` 是一个独立的、可复用的组件，它不拥有字体选择的状态，而是通过 `@Binding` 来修改其父视图 `ParentView` 中的 `appFont` 状态。

## 总结

尽管 SwiftUI 没有提供一个现成的 `FontPicker`，但通过组合 `Picker`、`ForEach` 和 `.font()` 修饰符，我们可以轻松地构建出功能完善且用户体验良好的字体选择器。

关键步骤是：

1.  **准备数据源**：一个包含字体名称或 `Font.Design` 的数组。
2.  **绑定状态**: 使用 `@State` (在拥有视图中) 和 `@Binding` (在可复用组件中) 来管理当前的选择。
3.  **构建 `Picker`**: 使用 `ForEach` 和 `.tag()` 来创建选项。
4.  **应用选择**: 将选择的状态应用到预览文本或整个应用的视图上。

通过这种方式，你可以为你的用户提供丰富的文本定制功能。
