# SwiftUI 中的 SF Symbols

SF Symbols 是苹果公司提供的一套庞大、精美且高度可配置的矢量图标库，它深度集成在 iOS, macOS, watchOS 和 tvOS 系统中。对于 SwiftUI 开发者来说，SF Symbols 是构建现代化、轻量且具有平台一致性界面的首选图标资源。

与传统的位图（PNG, JPG）或独立的矢量文件（SVG）不同，SF Symbols 的设计初衷是与系统字体（San Francisco）无缝协作。

## 核心优势

*   **矢量与可伸缩**: 所有符号都是矢量图形，可以无损地缩放到任何尺寸。
*   **与文本对齐**: 它们在光学上与文本垂直对齐，并适应不同的字重和大小，使得图文混排变得异常简单和美观。
*   **高度可配置**: 你可以像修改文本一样，轻松地改变它们的字重、比例、颜色，甚至应用多色渲染。
*   **系统内置**: 无需将成百上千的图片文件打包到你的应用中，极大地减小了应用的体积。
*   **持续更新**: 苹果会随着系统更新，不断地增加新的符号并优化现有符号。

## 基本用法

在 SwiftUI 中，使用 SF Symbols 非常简单，只需通过 `Image(systemName:)` 初始化一个 `Image` 视图即可。

```swift
import SwiftUI

struct SFSymbolBasicExample: View {
    var body: some View {
        VStack(spacing: 20) {
            // 使用 SF Symbol 的名称来创建 Image
            Image(systemName: "heart.fill")
                .font(.largeTitle) // 像文本一样调整大小
            
            Label("设置", systemImage: "gearshape.fill")
                .font(.title)
        }
    }
}

#Preview {
    SFSymbolBasicExample()
}
```

## 配置 SF Symbols

SF Symbols 的真正威力在于其丰富的配置选项。

### 1. 颜色 (`.foregroundColor`)

你可以像改变文本颜色一样，使用 `.foregroundColor()` 来改变符号的颜色。

```swift
Image(systemName: "star.fill")
    .foregroundColor(.yellow)
```

### 2. 尺寸与字重 (`.font`)

SF Symbols 的尺寸和粗细是与字体系统绑定的。你可以通过 `.font()` 修饰符来控制它们。

```swift
VStack {
    Image(systemName: "mic.fill")
        .font(.system(size: 50, weight: .light)) // 大尺寸，细字重
    
    Image(systemName: "mic.fill")
        .font(.system(size: 50, weight: .black)) // 大尺寸，粗字重
}
```

### 3. 渲染模式 (`.renderingMode`)

从 SF Symbols 3 (iOS 15) 开始，许多符号支持多种渲染模式，允许你应用多种颜色。

*   `.monochrome`: 单色模式，整个符号使用一种颜色。
*   `.hierarchical`: 层次模式，根据符号的图层结构，使用主颜色的不同透明度来区分层次。
*   `.palette`: 调色板模式，允许你为符号的每个图层分别指定一种颜色。
*   `.multicolor`: 多色模式，使用符号预设的内置颜色方案（例如，`folder.fill.badge.plus` 中的文件夹是蓝色，加号是绿色）。

```swift
struct RenderingModeExample: View {
    var body: some View {
        VStack(spacing: 30) {
            // 层次模式
            Image(systemName: "person.3.sequence.fill")
                .renderingMode(.hierarchical)
                .foregroundColor(.blue)
                .font(.system(size: 50))
            
            // 调色板模式
            Image(systemName: "person.3.sequence.fill")
                .renderingMode(.palette)
                .foregroundStyle(.blue, .green, .red) // 为三个图层分别指定颜色
                .font(.system(size: 50))
            
            // 多色模式 (如果符号支持)
            Image(systemName: "folder.fill.badge.plus")
                .renderingMode(.multicolor)
                .font(.system(size: 50))
        }
    }
}

#Preview {
    RenderingModeExample()
}
```

`.foregroundStyle()` 是 `.foregroundColor()` 的更现代、更强大的版本，特别适用于调色板模式。

### 4. 符号变体 (`VariableValue`)

从 SF Symbols 4 (iOS 16) 开始，一些符号引入了“变量”的概念，允许你通过一个 0.0 到 1.0 的 `Double` 值来改变符号的填充状态。例如，`wifi` 符号可以根据一个变量值来显示不同的信号强度。

```swift
struct VariableSymbolExample: View {
    @State private var wifiStrength: Double = 0.5

    var body: some View {
        VStack {
            // 1. 在符号名称后添加 .variable
            Image(systemName: "wifi.variable", variableValue: wifiStrength)
                .font(.system(size: 100))
            
            Slider(value: $wifiStrength, in: 0...1)
        }
        .padding()
    }
}

#Preview {
    VariableSymbolExample()
}
```

## SF Symbols App

为了浏览所有可用的符号、查看它们的名称、了解它们支持的渲染模式和图层结构，苹果提供了一个免费的 **SF Symbols** Mac 应用。这是任何苹果平台开发者都必备的工具。

你可以从 [Apple Developer 网站](https://developer.apple.com/sf-symbols/) 下载它。

## 总结

SF Symbols 是 SwiftUI 中图标系统的基石。它们提供了一种高效、灵活且符合平台设计规范的方式来在你的应用中添加图标。

*   **易于使用**: 通过 `Image(systemName:)` 即可创建。
*   **高度可配置**: 可以像文本一样调整大小、字重和颜色。
*   **多色渲染**: 支持层次、调色板和多色渲染模式，提供了丰富的视觉表现力。
*   **动态变化**: 支持可变符号，可以响应数值变化。
*   **必备工具**: 务必下载并使用 SF Symbols Mac 应用来探索和查找你需要的图标。

在你的 SwiftUI 项目中，应始终优先考虑使用 SF Symbols 作为你的图标来源，这不仅能减小应用体积，还能确保你的应用在视觉上与整个操作系统保持和谐统一。
