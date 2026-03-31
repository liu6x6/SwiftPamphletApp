# 小组件与主 App 的通信：Deep Link (深度链接)

小组件（Widget）本质上是主应用程序数据的一个“只读”快照（在 iOS 17 引入交互之前）。当用户在主屏幕上点击小组件的某个部分时，预期的行为是**打开主 App 并直接跳转到与点击内容相对应的特定页面**。
这个跳转过程就是通过 Deep Link (深度链接) 实现的。

## 1. 核心修饰符：widgetURL 与 Link

在 SwiftUI 中构建 Widget View 时，Apple 提供了两种处理点击跳转的修饰符：

### A. `.widgetURL(_ url: URL)` (整个小组件跳转)
用于指定点击**整个小组件**时打开的 URL。这对于 `.systemSmall` (小尺寸) 小组件来说是**唯一**支持的方式，因为小尺寸小组件不允许有多个点击热区。

```swift
struct MyWidgetEntryView: View {
    var entry: Provider.Entry

    var body: some View {
        VStack {
            Text(entry.title)
            Text(entry.description)
        }
        // 当用户点击小组件的任意位置时，会打开这个 URL
        .widgetURL(URL(string: "myapp://article/\(entry.articleId)"))
    }
}
```

### B. `Link(destination: URL)` (特定区域跳转)
对于 `.systemMedium` (中尺寸) 和 `.systemLarge` (大尺寸) 小组件，你可以使用 `Link` 视图来包裹特定的 UI 元素，从而实现点击不同区域跳转到 App 的不同页面。

```swift
struct MediumWidgetView: View {
    var entry: Provider.Entry

    var body: some View {
        HStack {
            // 左边区域跳转到文章 A
            Link(destination: URL(string: "myapp://article/1")!) {
                VStack {
                    Text("推荐文章 1")
                }
            }
            
            // 右边区域跳转到文章 B
            Link(destination: URL(string: "myapp://article/2")!) {
                VStack {
                    Text("推荐文章 2")
                }
            }
        }
        // 如果用户点击了 Link 之外的空白区域，会触发这里的 fallback 路由
        .widgetURL(URL(string: "myapp://home"))
    }
}
```

## 2. 在主 App 中处理 Deep Link

当用户点击小组件触发 URL 跳转后，主 App 会被唤醒（或调至前台）。你需要在主 App 的生命周期方法中捕获并处理这个 URL。

### 在纯 SwiftUI App 中处理 (`.onOpenURL`)
如果你使用的是现代的 `App` 结构，可以使用 `.onOpenURL` 修饰符：

```swift
@main
struct MyApp: App {
    @State private var selectedArticleId: String? = nil

    var body: some Scene {
        WindowGroup {
            ContentView(selectedArticleId: $selectedArticleId)
                .onOpenURL { url in
                    // 解析传入的 URL，例如: myapp://article/123
                    if url.scheme == "myapp" && url.host == "article" {
                        let articleId = url.lastPathComponent
                        // 更新状态，驱动 UI 跳转到文章详情页
                        self.selectedArticleId = articleId
                    }
                }
        }
    }
}
```

### 在 UIKit / AppDelegate 中处理
如果你依然使用传统的 AppDelegate/SceneDelegate，你需要在对应的方法中捕获：

```swift
// SceneDelegate.swift (iOS 13+)
func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    guard let url = URLContexts.first?.url else { return }
    
    if url.scheme == "myapp" {
        print("从小组件收到了链接: \(url)")
        // 执行导航控制器的 push 操作...
    }
}
```

## 总结
1. Small 小组件只能用 `widgetURL` 响应单一点击。
2. Medium/Large 小组件可以用 `Link` 实现多热区点击。
3. 主应用必须注册对应的 URL Scheme (在 Info.plist 中配置)，并在根视图通过 `onOpenURL` 拦截并解析 URL，完成路由跳转。