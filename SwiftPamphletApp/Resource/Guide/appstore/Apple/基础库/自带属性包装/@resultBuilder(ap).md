# @resultBuilder：构建领域特定语言 (DSL)

\`@resultBuilder\` (在早期 Swift 提案中叫 \`@_functionBuilder\`) 是 Swift 语言中最具颠覆性的一项特性。它是 **SwiftUI 能够存在的基石**。

它允许你通过定义一系列短小的构建规则（Builder Rules），将一系列连续的、基于代码块（Closure）的声明，在编译期悄悄“拼接”合成一个极其复杂的树状数据结构。这就让你能在 Swift 里创造出像 HTML 或 CSS 那样直观的“领域特定语言 (DSL)”。

## 1. 为什么需要它？

想象一下在没有 SwiftUI 的时代，如果我们想用代码堆出一个垂直列表（VStack）：

```swift
// 传统的对象装配方式
let container = VStack()
let label1 = Text("Hello")
let label2 = Text("World")
container.addChild(label1)
container.addChild(label2)
return container
```

极其冗长且不直观。而有了 \`@resultBuilder\`，我们可以这样写：

```swift
// SwiftUI 声明式语法
VStack {
    Text("Hello")
    Text("World")
}
```
为什么闭包里直接写两行独立的代码（没有 return，没有加号，没有放入数组），编译器不报错，还能神奇地把它们合并起来？这就是 \`@resultBuilder\` 的魔法。

## 2. 核心原理：手写一个极简的 Builder

我们来写一个将多个字符串合并成一个带换行长字符串的 Builder。

**第一步：声明 Builder 结构体**

```swift
@resultBuilder
struct StringBuilder {
    // 这个方法是必须的。当编译器在闭包里看到多个独立表达式时，它会把这些表达式打包成一个数组传给这个方法。
    static func buildBlock(_ components: String...) -> String {
        return components.joined(separator: "\n")
    }
}
```

**第二步：应用 Builder**

我们将这个 \`@StringBuilder\` 应用到一个函数的闭包参数上：

```swift
// 告诉编译器，这个 content 闭包里写的代码，请用 StringBuilder 的规则去解析
func makePoem(@StringBuilder content: () -> String) -> String {
    return content()
}
```

**第三步：见证奇迹**

```swift
let poem = makePoem {
    "床前明月光"
    "疑是地上霜"
    "举头望明月"
    "低头思故乡"
}

// 打印结果：自动带上了换行符！
print(poem) 
```

**发生了什么？**
编译器在底层默默地将你的闭包翻译成了这样：
\`\`\`swift
let poem = makePoem(content: {
    return StringBuilder.buildBlock("床前明月光", "疑是地上霜", "举头望明月", "低头思故乡")
})
\`\`\`

## 3. 更高级的控制流：If 和 For

如果仅仅是把几个固定元素拼起来，那毫无难度。\`@resultBuilder\` 强大在于它允许你拦截并在闭包里使用原生的 \`if\` 和 \`for\` 逻辑！

你只需要在 Builder 内部实现更多的静态方法：

*   **\`buildOptional(_:) \`**：用于支持没有 \`else\` 的 \`if\` 语句。
*   **\`buildEither(first:) \` 和 \`buildEither(second:)\`**：用于支持 \`if - else\` 或是 \`switch\` 语句。
*   **\`buildArray(_:) \`**：用于支持 \`for...in\` 循环生成组件。

```swift
@resultBuilder
struct AdvancedStringBuilder {
    static func buildBlock(_ components: String...) -> String {
        components.joined(separator: " ")
    }
    
    // 支持 if 分支
    static func buildOptional(_ component: String?) -> String {
        return component ?? ""
    }
}

// 现在你可以在闭包里写 if 语句了！
let showTitle = true
let greeting = makePoem {
    "Hello,"
    if showTitle {
        "Mr. Swift"
    }
}
// greeting: "Hello, Mr. Swift"
```

## 4. 在真实项目中的应用

在日常业务开发中，除了使用别人（如 Apple 的 SwiftUI \`@ViewBuilder\`）写好的 Builder 外，你也可以利用这个特性来：
1. **构建富文本引擎**：使用声明式语法拼接 \`AttributedString\`，而不是到处 \`append\`。
2. **构建网络请求封装**：用极其直观的方式声明 HTTP Header 和 URL 参数。
3. **构建复杂的 UICollectionView 布局**（如 \`UICollectionViewCompositionalLayout\`）。
