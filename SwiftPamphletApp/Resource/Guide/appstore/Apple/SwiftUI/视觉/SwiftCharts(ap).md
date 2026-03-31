# SwiftUI 中的 Swift Charts (iOS 16+)

Swift Charts 是苹果在 WWDC 2022 (iOS 16) 中推出的一个强大、灵活且声明式的数据可视化框架。它使得在 SwiftUI 应用中创建各种美观、可交互、可访问的图表变得前所未有的简单。

在此之前，开发者通常需要依赖第三方库或自己从头开始绘制图表，而 Swift Charts 将这一能力直接集成到了系统框架中。

## 核心概念：`Chart` 与 `Mark`

Swift Charts 的核心是 `Chart` 视图和各种“标记”（Mark）类型。

1.  **`Chart`**: 这是一个容器视图，你将所有的图表内容都放置在它的闭包内部。
2.  **`Mark`**: 标记是图表中数据的视觉表现形式。每一种标记都对应一种常见的图表类型。你通过 `ForEach` 循环遍历你的数据模型，并为每个数据点创建一个标记。

常见的标记类型包括：

*   **`BarMark`**: 用于创建条形图。
*   **`LineMark`**: 用于创建折线图。
*   **`PointMark`**: 用于创建散点图。
*   **`AreaMark`**: 用于创建面积图。
*   **`RectangleMark`**: 用于创建矩形图（如热力图）。
*   **`RuleMark`**: 用于创建一条水平或垂直的规则线（如平均值线）。

## 基本用法：创建一个条形图

让我们通过一个例子来展示创建一个简单的条形图是多么容易。

```swift
import SwiftUI
import Charts

// 1. 定义数据模型
struct MonthlySales: Identifiable {
    let id = UUID()
    let month: String
    let sales: Int
}

let salesData: [MonthlySales] = [
    .init(month: "一月", sales: 120),
    .init(month: "二月", sales: 150),
    .init(month: "三月", sales: 90),
    .init(month: "四月", sales: 210),
]

struct BasicBarChart: View {
    var body: some View {
        // 2. 创建 Chart 容器
        Chart {
            // 3. 遍历数据并创建 Mark
            ForEach(salesData) { sale in
                BarMark(
                    x: .value("月份", sale.month),
                    y: .value("销量", sale.sales)
                )
            }
        }
        .padding()
    }
}

#Preview {
    BasicBarChart()
}
```

在这个例子中：
1.  我们定义了一个 `MonthlySales` 结构体来表示我们的数据。
2.  在 `Chart` 视图内部，我们使用 `ForEach` 遍历 `salesData` 数组。
3.  对于每个 `sale` 数据点，我们创建一个 `BarMark`。`x` 和 `y` 参数是关键，它们通过 `.value(label, value)` 来将数据的维度映射到图表的坐标轴上。Swift Charts 会自动处理坐标轴的生成、刻度和标签。

## 组合不同的 Mark

Swift Charts 的强大之处在于其组合能力。你可以在同一个 `Chart` 中叠加不同类型的标记，来创建更复杂的、信息更丰富的图表。

### 示例：折线图与面积图的叠加

```swift
struct CombinedChart: View {
    var body: some View {
        Chart(salesData) { sale in
            // 1. 创建面积图，作为背景
            AreaMark(
                x: .value("月份", sale.month),
                y: .value("销量", sale.sales)
            )
            .foregroundStyle(Color.blue.opacity(0.3))
            
            // 2. 叠加折线图
            LineMark(
                x: .value("月份", sale.month),
                y: .value("销量", sale.sales)
            )
            .foregroundStyle(Color.blue)
            .symbol(by: .value("月份", sale.month)) // 为每个数据点添加一个符号
        }
        .padding()
    }
}
```

在这个例子中，我们为同一份数据同时创建了 `AreaMark` 和 `LineMark`。`AreaMark` 提供了一个填充的背景区域，而 `LineMark` 则清晰地勾勒出数据的变化趋势。`.symbol()` 修饰符还为折线图的每个数据点添加了可视化的标记。

## 自定义图表外观

你可以通过一系列修饰符来精细地控制图表的外观。

### `.foregroundStyle()`

用于改变标记的颜色。它可以接受一个固定的颜色，也可以通过 `.value` 来根据数据的某个维度进行着色，从而自动生成图例。

```swift
// ... 假设有不同产品类别的数据
BarMark(...)
    .foregroundStyle(by: .value("产品类别", sale.category))
```

### `.chartXAxis` & `.chartYAxis`

用于自定义坐标轴的标签、刻度和网格线。

```swift
Chart { ... }
    .chartYAxis {
        AxisMarks(position: .leading, values: .automatic) {
            AxisGridLine()
            AxisTick()
            AxisValueLabel()
        }
    }
```

### `.chartLegend()`

控制图例的位置和可见性。

```swift
Chart { ... }
    .chartLegend(position: .top, alignment: .leading)
```

## 交互性 (iOS 17+)

从 iOS 17 开始，Swift Charts 增加了强大的交互功能。

*   **`.chartScrollableAxes()`**: 让图表可以在某个轴向上滚动，以显示大量数据。
*   **`.chartXSelection()` & `.chartYSelection()`**: 允许用户通过拖动来选择图表上的某个值或范围。
*   **`ChartReader`**: 类似于 `GeometryReader`，它提供了一个代理，可以让你获取关于图表当前状态（如用户触摸位置、坐标轴范围等）的信息。

```swift
struct InteractiveChart: View {
    @State private var selectedSales: Int?

    var body: some View {
        Chart(salesData) { ... }
            .chartXSelection(value: $selectedSales)
            .overlay {
                if let selectedSales {
                    Text("选中销量: \(selectedSales)")
                }
            }
    }
}
```

## 总结

Swift Charts 是一个革命性的框架，它将复杂的数据可视化任务转变为一个声明式、易于理解的过程。

*   **声明式**: 你只需要描述你的数据如何映射到视觉标记（`Mark`）上，而无需关心具体的绘制细节。
*   **可组合**: 可以轻松地在同一个图表中叠加多种类型的标记，创建丰富的视觉效果。
*   **可定制**: 提供了丰富的修饰符来控制颜色、坐标轴、图例等外观元素。
*   **可交互**: 支持滚动、选择和读取用户交互，以创建动态的、响应式的图表。
*   **可访问**: 自动集成了 VoiceOver 等辅助功能，确保图表信息对所有用户都可用。

对于任何需要在 SwiftUI 应用中进行数据可视化的场景，Swift Charts 都应该是你的首选工具。它极大地降低了创建高质量图表的门槛，让开发者可以更专注于数据本身，而不是复杂的绘图代码。
