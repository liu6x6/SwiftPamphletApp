# SwiftUI 中的自定义修饰符

在 SwiftUI 中，我们经常会通过链式调用一系列修饰符（如 `.padding()`, `.background()`, `.font()`）来构建视图的样式。当某个样式组合在应用中被反复使用时，为了避免代码重复并提高可维护性，我们可以将这个组合封装成一个**自定义修饰符**。

创建自定义修饰符是遵循 DRY (Don't Repeat Yourself) 原则的绝佳实践。

## 核心概念：`ViewModifier`

要创建自定义修饰符，你需要定义一个遵循 `ViewModifier` 协议的结构体。这个协议只有一个必须实现的要求：

*   **`body(content:)` 方法**: 这个方法接收一个 `content` 参数，它代表了被修饰的原始视图。你可以在这个方法内部，对 `content` 应用任意你想要的修饰符组合，并返回最终的视图。

## 如何创建和使用自定义修饰符

让我们通过一个例子来学习。假设我们想创建一个标准的标题样式：大号字体、蓝色、底部有一条灰色分隔线。

### 1. 定义 `ViewModifier`

我们首先创建一个名为 `StandardTitleModifier` 的结构体，并让它遵循 `ViewModifier` 协议。

```swift
import SwiftUI

struct StandardTitleModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.largeTitle)
            .foregroundColor(.blue)
            .padding(.bottom, 5)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(.gray)
            }
    }
}
```

在这个 `body` 方法中，`content` 就是我们应用这个修饰符的那个视图（例如一个 `Text`）。我们依次为它添加了字体、颜色、内边距和一个底部的 `overlay` 作为分隔线。

### 2. 应用自定义修饰符

要使用我们刚创建的修饰符，可以调用视图的 `.modifier()` 方法。

```swift
struct CustomModifierExample: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("主标题")
                .modifier(StandardTitleModifier())
            
            Text("这里是一些正文内容，它不受自定义修饰符的影响。")
            
            Text("另一个标题")
                .modifier(StandardTitleModifier())
        }
        .padding()
    }
}

#Preview {
    CustomModifierExample()
}
```

现在，每当我们需要一个标准标题时，只需调用 `.modifier(StandardTitleModifier())` 即可，无需重复编写那一大串修饰符。

## 提升易用性：扩展 `View`

虽然 `.modifier()` 已经很有效，但每次都写 `StandardTitleModifier()` 还是有点冗长。为了让自定义修饰符的使用体验像系统内置修饰符一样流畅，我们可以为 `View` 协议创建一个便利的扩展方法。

```swift
extension View {
    func standardTitle() -> some View {
        self.modifier(StandardTitleModifier())
    }
}
```

通过这个扩展，我们就可以用更简洁、更具可读性的方式来调用我们的自定义修饰符了：

```swift
struct CustomModifierExtensionExample: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("主标题")
                .standardTitle() // 使用起来就像系统内置修饰符一样！
            
            Text("这里是一些正文内容。")
            
            Text("另一个标题")
                .standardTitle()
        }
        .padding()
    }
}

#Preview {
    CustomModifierExtensionExample()
}
```

## 带有参数的自定义修饰符

自定义修饰符也可以接受参数，从而使其更加灵活和可配置。例如，我们可以让标题的颜色变成可配置的。

```swift
// 1. 修改 ViewModifier 以接受参数
struct ConfigurableTitleModifier: ViewModifier {
    let color: Color

    func body(content: Content) -> some View {
        content
            .font(.largeTitle)
            .foregroundColor(color) // 使用传入的颜色
            .padding(.bottom, 5)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(.gray)
            }
    }
}

// 2. 更新 View 扩展以传递参数
extension View {
    func configurableTitle(color: Color) -> some View {
        self.modifier(ConfigurableTitleModifier(color: color))
    }
}

// 3. 使用带参数的修饰符
struct ParametricModifierExample: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("主标题")
                .configurableTitle(color: .purple)
            
            Text("另一个标题")
                .configurableTitle(color: .orange)
        }
        .padding()
    }
}

#Preview {
    ParametricModifierExample()
}
```

## 总结

自定义修饰符是 SwiftUI 中保持代码整洁、实现样式复用的关键工具。它的核心优势包括：

*   **代码复用**: 将通用的样式组合封装起来，在整个应用中重复使用。
*   **可维护性**: 当需要修改某个通用样式时，只需修改对应的 `ViewModifier` 定义即可，所有使用该修饰符的地方都会自动更新。
*   **可读性**: 通过为 `View` 创建扩展，自定义修饰符的调用可以变得非常简洁和语义化，使代码更易于理解。

当你发现自己正在一遍又一遍地编写相同的修饰符序列时，就应该考虑将它提取到一个自定义的 `ViewModifier` 中了。
