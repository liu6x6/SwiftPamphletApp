# SwiftUI 数据流：@State

`@State` 是 SwiftUI 中最基础、最核心的属性包装器之一。它用于在**单个视图内部**声明和管理一个**简单的、本地的、临时的状态**。当被 `@State` 包装的属性值发生变化时，SwiftUI 会自动重新渲染该视图及其子视图，以确保 UI 能够准确地反映最新的状态。

## 核心作用：视图的“记忆”

在 SwiftUI 中，`View` 本身是一个轻量级的结构体（`struct`）。结构体是值类型，通常是不可变的。每当视图的状态需要更新时，SwiftUI 实际上会销毁旧的视图实例并创建一个新的实例。那么，视图是如何“记住”像计数器或文本框内容这样的状态的呢？

答案就是 `@State`。当你用 `@State` 标记一个属性时，你实际上是在告诉 SwiftUI：“请在你的某个神秘的、持久的存储空间里，为我这个视图管理这个值。即使我的视图实例被销-毁和重建，这个值也需要被保留下来。”

因此，`@State` 成为了视图的“记忆”，它存储了那些只与该视图本身相关，并且会随时间变化的数据。

## 基本用法

使用 `@State` 非常简单：在属性声明前加上 `@State`，并务必将其声明为 `private`，因为 `@State` 变量应该只被其所在的视图拥有和修改。

```swift
import SwiftUI

struct CounterView: View {
    // 1. 使用 @State 声明一个私有的、本地的状态变量
    @State private var count: Int = 0

    var body: some View {
        VStack(spacing: 20) {
            // 2. UI 直接读取 count 的值
            Text("当前计数值: \(count)")
                .font(.largeTitle)
            
            HStack(spacing: 30) {
                Button("减少") {
                    // 3. 直接修改 count 的值
                    count -= 1
                }
                
                Button("增加") {
                    // SwiftUI 会自动检测到这个变化并刷新视图
                    count += 1
                }
            }
            .font(.title)
        }
    }
}

#Preview {
    CounterView()
}
```

在这个经典的计数器例子中：
1.  `count` 被声明为一个 `@State` 变量，初始值为 0。它被 SwiftUI 单独管理，其生命周期与 `CounterView` 绑定。
2.  `Text` 视图直接读取 `count` 的当前值来显示。
3.  当按钮被点击时，我们直接修改 `count` 的值。SwiftUI 会检测到这个变化，并自动重新调用 `CounterView` 的 `body` 属性，生成一个新的 `VStack`，其中包含的 `Text` 会显示更新后的 `count` 值。

## 传递 `@State`：创建绑定

`@State` 变量应该由其所在的视图“拥有”。但如果一个子视图需要能够修改这个状态呢？这时，你需要将 `@State` 变量的一个“绑定”（`Binding`）传递给子视图。

这可以通过在 `@State` 变量前加上 `$` 符号来实现。`$count` 会创建一个到 `count` 的双向绑定。

```swift
// 子视图：接收一个绑定
struct CountDisplayView: View {
    @Binding var value: Int

    var body: some View {
        Text("子视图显示的值: \(value)")
    }
}

// 父视图：拥有 @State 并传递绑定
struct ParentCounterView: View {
    @State private var count: Int = 0

    var body: some View {
        VStack {
            Text("父视图的值: \(count)")
            Button("增加") { count += 1 }
            
            Divider()
            
            // 通过 $ 将绑定传递给子视图
            CountDisplayView(value: $count)
        }
    }
}
```

在这个例子中，`ParentCounterView` 拥有 `count`，但 `CountDisplayView` 可以通过 `@Binding` 来访问和显示它。如果 `CountDisplayView` 中有能修改 `value` 的控件，那么 `ParentCounterView` 中的 `count` 也会同步更新。

## 何时使用 `@State`？

`@State` 的适用范围非常明确：

*   **简单数据类型**: 它最适合用于管理简单的值类型，如 `Int`, `String`, `Bool`, 或者小型的、本地的结构体。
*   **单个视图的本地状态**: 这个状态只与当前视图相关，不需要被其他远房亲戚视图访问。例如，一个弹窗是否应该显示、一个 `Toggle` 的开关状态等。
*   **瞬时状态**: 当视图被销毁时，这些状态也随之消失（除非视图被重新创建）。

## 不应该使用 `@State` 的场景

*   **引用类型 (Class)**: 不要用 `@State` 来包装 class 的实例。对于需要被多个视图共享和观察的 class，应该使用 `@StateObject`, `@ObservedObject`，或者在 iOS 17+ 中使用 `@Observable` 宏和 `@State`。
*   **跨多个独立视图共享的数据**: 如果一个数据需要在两个没有直接父子关系的视图之间共享，或者需要在整个应用范围内共享，那么 `@State` 就不合适了。这时应该考虑使用 `@ObservedObject` 配合依赖注入，或者 `@EnvironmentObject`。
*   **持久化数据**: `@State` 的值是临时的。如果数据需要在应用关闭后仍然被保留，应该使用 `@AppStorage` (用于 `UserDefaults`) 或其他持久化方案（如 SwiftData, Core Data）。

## 总结

`@State` 是 SwiftUI 数据流的起点和基石。它是为视图提供本地“记忆”的最简单方式。理解它的核心作用——在单个视图内部管理简单的、临时的状态——是掌握 SwiftUI 开发的第一步。

记住黄金法则：**`@State` 用于视图私有的、本地的、简单的值类型状态。** 对于更复杂的场景，SwiftUI 提供了 `@Binding`, `@StateObject`, `@EnvironmentObject` 等一系列更合适的工具。
