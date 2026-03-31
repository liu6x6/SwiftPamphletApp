# SwiftUI 中的 WheelPicker 滚轮选择器

滚轮选择器（Wheel Picker）是 SwiftUI `Picker` 的一种特定样式，它以一个或多个可滚动的轮盘形式展示选项。这种样式在 iOS 上非常经典，常用于 `DatePicker`，也适用于从一组有序或连续的数据中进行选择，例如选择身高、体重或闹钟时间。

要创建一个滚轮选择器，你只需要将 `.pickerStyle(.wheel)` 修饰符应用于一个标准的 `Picker` 即可。

## 基本用法

创建一个滚轮选择器的步骤与创建任何 `Picker` 相同，最后只需应用样式。

```swift
import SwiftUI

struct BasicWheelPickerExample: View {
    let hours = Array(0...23)
    let minutes = Array(0...59)
    
    @State private var selectedHour: Int = 8
    @State private var selectedMinute: Int = 30

    var body: some View {
        VStack {
            Text("选择时间: \(selectedHour, specifier: "%02d"):\(selectedMinute, specifier: "%02d")")
                .font(.largeTitle)
            
            HStack {
                // 小时选择器
                Picker("小时", selection: $selectedHour) {
                    ForEach(hours, id: \.self) { hour in
                        Text("\(hour) h").tag(hour)
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: 100)
                .clipped() // 裁剪掉滚轮的默认边框和背景
                
                // 分钟选择器
                Picker("分钟", selection: $selectedMinute) {
                    ForEach(minutes, id: \.self) {
                        Text("\($0) m").tag($0)
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: 100)
                .clipped()
            }
        }
    }
}

#Preview {
    BasicWheelPickerExample()
}
```

在这个例子中：
1.  我们创建了两个 `Picker`，一个用于选择小时，一个用于选择分钟，它们分别绑定到 `selectedHour` 和 `selectedMinute` 状态变量。
2.  通过将 `.pickerStyle(.wheel)` 应用于每个 `Picker`，我们将它们都转换为了滚轮样式。
3.  我们使用 `HStack` 将两个滚轮水平并排，以创建一个完整的时间选择器。
4.  `.frame()` 和 `.clipped()` 用于控制滚轮的大小并移除系统可能添加的一些额外视觉元素，使布局更紧凑。

## `WheelPicker` 的特点

*   **视觉直观**: 滚轮的样式非常直观，用户可以清晰地看到当前选项以及其上下文（前面和后面的选项）。
*   **快速滚动**: 用户可以通过快速滑动来在大量选项之间快速导航。
*   **空间占用**: 滚轮样式通常会直接显示在界面上，比 `.menu` 或 `.compact` 样式占用更多的垂直空间。
*   **触感反馈**: 在真实的 iOS 设备上，滚动滚轮通常会伴随着细腻的触感反馈（Haptic Feedback），提升了交互体验。

## 组合多个滚轮

`WheelPicker` 的一个常见用途是组合多个滚轮来选择一个复合值，例如身高（英尺+英寸）或日期（年+月+日）。上面的时间选择器例子就是一个典型的组合用法。

让我们再看一个选择身高的例子：

```swift
struct HeightPickerExample: View {
    @State private var feet: Int = 5
    @State private var inches: Int = 9

    var body: some View {
        VStack {
            Text("身高: \(feet) 英尺 \(inches) 英寸")
                .font(.headline)
            
            HStack {
                Picker("英尺", selection: $feet) {
                    ForEach(3...7, id: \.self) { Text("\($0) ft").tag($0) }
                }
                .pickerStyle(.wheel)
                
                Picker("英寸", selection: $inches) {
                    ForEach(0...11, id: \.self) { Text("\($0) in").tag($0) }
                }
                .pickerStyle(.wheel)
            }
            .frame(height: 150) // 给 HStack 一个固定的高度
            .clipped()
        }
    }
}

#Preview {
    HeightPickerExample()
}
```

## 何时使用 `WheelPicker` 样式？

`.wheel` 样式特别适合以下场景：

1.  **选择有序的数值**: 当选项是一个连续或有序的数值序列时（如时间、数字、度量单位），滚轮提供了一种非常自然的导航方式。
2.  **选项数量适中**: 如果选项非常少（如 2-3 个），`.segmented` 样式可能更合适。如果选项非常多且无序（如选择国家），滚轮可能会导致用户滚动很长时间，此时 `.menu` 或 `.navigationLink` 样式可能更好。
3.  **模仿原生体验**: 当你希望模仿系统 `DatePicker` 的感觉，或者创建类似闹钟设置的界面时，滚轮样式是最佳选择。
4.  **空间允许**: 滚轮会占用固定的屏幕空间，你需要确保你的布局能够容纳它。

## 自定义滚轮内容

滚轮中的每一项都是一个标准的 SwiftUI `View`。这意味着你可以放置任何你想要的视图，而不仅仅是 `Text`。

```swift
Picker("选择图标", selection: $selectedIcon) {
    ForEach(icons, id: \.self) { iconName in
        Label(iconName, systemImage: iconName).tag(iconName)
    }
}
.pickerStyle(.wheel)
```

在这个例子中，滚轮的每一行都显示一个 `Label`，其中包含了图标和文本，提供了更丰富的视觉信息。

## 总结

`.pickerStyle(.wheel)` 是将标准 `Picker` 转换为经典滚轮选择器的直接方式。它通过提供一种直观、触感丰富的交互，增强了从有序数据集中选择值的用户体验。

通过在 `HStack` 中组合多个滚轮，你可以构建出功能强大的复合值选择器。在设计时，请务必考虑其空间占用和是否符合你的数据类型与交互场景。
