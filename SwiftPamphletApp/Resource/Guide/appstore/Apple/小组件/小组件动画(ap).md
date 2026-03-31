# 小组件中的动画 (Widget Animations)

在传统的观念中，小组件是静态的快照，不支持任何动画。但在 iOS 17 引入**交互式小组件**和 SwiftUI 新的动画 API 后，小组件终于拥有了有限但极其惊艳的动画能力。

## 1. 动画的限制

在小组件中，你**不能**像主 App 那样使用：
*   \`withAnimation\` 包裹一段无限循环的代码。
*   基于 \`Timer\` 或 \`CADisplayLink\` 的持续重绘动画。
*   视频播放或复杂的 Lottie 渲染。

系统只允许**两种**特定场景下的动画：
1. **视图过渡动画 (Transition)**：当 Timeline 的数据节点发生改变时，旧视图离开、新视图进入的过渡效果。
2. **交互式状态动画 (Interactive Animation)**：在 iOS 17+ 中，当用户点击了绑定 \`AppIntent\` 的 \`Button\` 或 \`Toggle\` 时触发的反馈动画。

## 2. iOS 17+ 交互式动画：\`invalidatableContent()\`

在 iOS 17 中，当你点击一个按钮（比如将待办事项打钩），你希望那个条目立刻出现被划掉的动画。这需要用到 \`.invalidatableContent()\` 修饰符。

```swift
struct TodoItemView: View {
    var todo: TodoModel
    
    var body: some View {
        HStack {
            // 绑定了 Intent 的按钮
            Button(intent: ToggleTodoIntent(id: todo.id)) {
                Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
            }
            // 关键：告诉系统当这个视图状态改变时，应用默认的系统过渡动画
            .invalidatableContent()

            Text(todo.title)
                .strikethrough(todo.isCompleted)
                // 对文字的改变也应用隐式动画
                .animation(.default, value: todo.isCompleted)
        }
    }
}
```

## 3. SwiftUI 专属转场动画：\`contentTransition()\`

如果你有一个计时器小组件或者数字变化的看板，你可以使用强大的 \`contentTransition\` 来让文字和数字的变化变得生动。

```swift
struct StatsWidgetView: View {
    var entry: StatsEntry

    var body: some View {
        VStack {
            Text("当前在线人数")
            
            Text("\(entry.userCount)")
                .font(.system(size: 40, weight: .bold, design: .rounded))
                // 当 userCount 变化时，系统会自动应用类似老虎机数字翻滚的动画
                .contentTransition(.numericText())
                // 必须配合 animation 触发
                .animation(.bouncy, value: entry.userCount)
        }
    }
}
```

## 4. 时间线刷新动画

当 \`Provider\` 提供下一个时间线节点时，整个界面的刷新也可以带有动画。默认情况下系统会有轻微的交叉淡入淡出 (Cross-fade)。
如果你通过 SwiftUI 的 \`id\` 绑定了特定组件，系统在替换时可以进行位置插值（比如新卡片滑入，旧卡片滑出）。但整体原则依然是：**少即是多**。小组件动画必须极度克制，以节省电量。
