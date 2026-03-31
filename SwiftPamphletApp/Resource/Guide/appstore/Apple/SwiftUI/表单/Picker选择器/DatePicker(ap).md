# SwiftUI 中的 DatePicker 日期选择器

`DatePicker` 是 SwiftUI 提供的一个标准控件，用于让用户方便地选择一个特定的日期、时间，或者日期和时间的组合。它会根据不同的平台和上下文，自动显示为最合适的系统原生界面，例如在 iOS 上可能会显示为一个紧凑的标签，点击后在底部弹出滚轮选择器或日历视图。

## 核心用法：绑定与范围

创建一个 `DatePicker` 的核心是将其 `selection` 参数双向绑定到一个 `Date` 类型的 `@State` 变量。

```swift
import SwiftUI

struct BasicDatePickerExample: View {
    // 1. 状态变量存储选中的日期
    @State private var selectedDate: Date = Date()

    var body: some View {
        VStack {
            Text("选中的日期是:")
            // 将 Date 直接传递给 Text 会使用默认格式
            Text(selectedDate)
                .font(.title2)
                .foregroundColor(.red)
            
            // 2. 创建 DatePicker
            DatePicker(
                "请选择日期",
                selection: $selectedDate, // 绑定到状态变量
                displayedComponents: .date // 指定只显示日期部分
            )
            .padding()
        }
    }
}

#Preview {
    BasicDatePickerExample()
}
```

在这个例子中：
*   `selectedDate` 状态变量存储了用户当前选中的日期和时间。
*   `DatePicker` 通过 `$selectedDate` 与该状态双向绑定。当用户在日期选择器中做出新的选择时，`selectedDate` 的值会立即更新，从而刷新 `Text` 的显示。
*   `"请选择日期"` 是 `DatePicker` 的标签，用于向用户说明其用途。

## 控制显示的组件

`displayedComponents` 参数允许你精确控制选择器中应该包含哪些部分。它可以是以下值或它们的组合：

*   `.date`: 只显示日期（年、月、日）。
*   `.hourAndMinute`: 只显示时间（小时、分钟）。

你可以通过一个数组来组合它们，例如 `[.date, .hourAndMinute]`，这会同时显示日期和时间。

```swift
struct ComponentDatePickerExample: View {
    @State private var eventDate = Date()

    var body: some View {
        Form {
            // 只选择日期
            DatePicker("日期", selection: $eventDate, displayedComponents: .date)
            
            // 只选择时间
            DatePicker("时间", selection: $eventDate, displayedComponents: .hourAndMinute)
            
            // 同时选择日期和时间
            DatePicker("日期和时间", selection: $eventDate, displayedComponents: [.date, .hourAndMinute])
        }
    }
}

#Preview {
    ComponentDatePickerExample()
}
```

## 限制可选日期范围

很多时候，你需要限制用户只能在某个特定的时间范围内进行选择，例如，预订未来的航班或选择一个过去的生日。这可以通过 `in` 参数来实现，它接受一个日期范围。

```swift
struct RangedDatePickerExample: View {
    @State private var deliveryDate = Date()
    
    // 创建一个从今天开始的开放范围
    var dateRange: Range<Date> {
        let today = Date()
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: today) // 当天的开始
        return start..<Date.distantFuture
    }
    
    // 创建一个到今天为止的闭合范围
    var birthdayRange: ClosedRange<Date> {
        let distantPast = Date.distantPast
        let today = Date()
        return distantPast...today
    }

    var body: some View {
        Form {
            Section(header: Text("送货日期")) {
                // 用户只能选择从今天开始的未来日期
                DatePicker(
                    "选择日期",
                    selection: $deliveryDate,
                    in: dateRange, // 应用范围限制
                    displayedComponents: .date
                )
            }
            
            Section(header: Text("出生日期")) {
                DatePicker(
                    "选择生日",
                    selection: $deliveryDate,
                    in: birthdayRange, // 只能选择过去的日期
                    displayedComponents: .date
                )
            }
        }
    }
}

#Preview {
    RangedDatePickerExample()
}
```

在这个例子中：
*   我们为送货日期创建了一个从今天开始到遥远未来的范围 `Range<Date>`。
*   我们为生日选择创建了一个从遥远过去到今天的闭合范围 `ClosedRange<Date>`。
*   将这些范围传递给 `in` 参数后，`DatePicker` 会自动禁用范围之外的日期，用户将无法选择它们。

## `DatePicker` 的样式

你可以使用 `.datePickerStyle()` 修饰符来改变 `DatePicker` 的外观。常见的样式包括：

*   `.automatic`: 默认样式，由 SwiftUI 根据上下文自动选择。
*   `.compact`: 紧凑样式，在 iOS 上表现为一个可点击的标签，点击后弹出选择器。
*   `.graphical`: 图形化样式，在 iOS 上直接显示一个可交互的日历视图。
*   `.wheel`: 滚轮样式，在 iOS 上直接显示滚轮选择器。

```swift
struct DatePickerStyleExample: View {
    @State private var selectedDate = Date()

    var body: some View {
        VStack {
            DatePicker("选择日期", selection: $selectedDate)
                .datePickerStyle(.graphical) // 直接显示日历
            
            DatePicker("选择时间", selection: $selectedDate, displayedComponents: .hourAndMinute)
                .datePickerStyle(.wheel) // 直接显示滚轮
        }
        .padding()
    }
}

#Preview {
    DatePickerStyleExample()
}
```

选择哪种样式取决于你的 UI 设计和可用空间。`.graphical` 和 `.wheel` 样式会占用更多的屏幕空间，但提供了更直接的交互方式。

## 总结

`DatePicker` 是一个功能强大且易于使用的控件，用于从用户那里获取日期和时间输入。

*   **核心**: 通过与 `@State` `Date` 变量的双向绑定来工作。
*   **控制**: 使用 `displayedComponents` 来指定显示的部分（日期/时间），使用 `in` 来限制可选范围。
*   **样式**: 通过 `.datePickerStyle()` 可以改变其外观，以更好地融入你的界面设计。
*   **平台适应性**: 它会自动渲染为符合当前平台设计规范的原生样式。

通过组合这些功能，你可以轻松地在你的 SwiftUI 应用中实现各种日期和时间的选择需求。
