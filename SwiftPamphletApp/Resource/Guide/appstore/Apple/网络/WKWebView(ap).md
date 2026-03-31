# 在 SwiftUI 中使用 WKWebView

尽管 SwiftUI 提供了 `Link` 视图来打开网页，但它会跳转到外部的 Safari 浏览器。要在应用**内部**显示一个功能完善的、可交互的网页，你仍然需要使用 `WebKit` 框架中的 `WKWebView`。`WKWebView` 是苹果官方推荐的、用于在原生应用中嵌入 Web 内容的现代组件。

由于 `WKWebView` 是一个 `UIKit` (或 `AppKit`) 组件，在 SwiftUI 中使用它的标准方式是将其封装在一个遵循 `UIViewRepresentable` (iOS) 或 `NSViewRepresentable` (macOS) 协议的结构体中。

## 核心用法：创建 `UIViewRepresentable`

创建一个 `WKWebView` 的 SwiftUI 封装体，主要包含以下步骤：

1.  **创建结构体**: 定义一个遵循 `UIViewRepresentable` 的结构体。
2.  **`makeUIView(context:)`**: 在这个方法中，创建并返回一个 `WKWebView` 的实例。这个方法只会被调用一次。
3.  **`updateUIView(_:context:)`**: 在这个方法中，用 SwiftUI 视图的当前状态来更新 `WKWebView`。例如，当 URL 发生变化时，你可以在这里命令 `WKWebView` 加载新的 URL。

```swift
import SwiftUI
import WebKit

// 1. 创建一个遵循 UIViewRepresentable 的结构体
struct WebView: UIViewRepresentable {
    let url: URL

    // 2. 创建并配置 WKWebView
    func makeUIView(context: Context) -> WKWebView {
        return WKWebView()
    }

    // 3. 当 SwiftUI 视图更新时，更新 WKWebView
    func updateUIView(_ webView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        webView.load(request)
    }
}

// 在 SwiftUI 视图中使用
struct WebViewExample: View {
    var body: some View {
        NavigationView {
            WebView(url: URL(string: "https://www.apple.com")!)
                .navigationTitle("Apple 官网")
        }
    }
}

#Preview {
    WebViewExample()
}
```

在这个最基础的例子中，`WebView` 结构体接收一个 `URL`，并在 `updateUIView` 中加载它。每当 `WebView` 的 `url` 属性发生变化时，`updateUIView` 都会被调用，从而加载新的网页。

## 实现双向通信：`Coordinator`

通常，你不仅需要向 `WKWebView` 发送指令，还需要从 `WKWebView` 接收事件，例如页面加载进度、标题变化、或者网页通过 JavaScript 发送的消息。这就需要使用 `Coordinator`。

`Coordinator` 是一个充当**代理 (Delegate)** 的类，它是在 `UIViewRepresentable` 和 `UIKit` 组件之间进行双向通信的桥梁。

### 示例：显示加载进度并获取页面标题

```swift
struct AdvancedWebView: UIViewRepresentable {
    let url: URL
    @Binding var isLoading: Bool
    @Binding var pageTitle: String

    // 1. 创建 Coordinator
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        // 2. 设置 Coordinator 为 WKWebView 的导航代理
        webView.navigationDelegate = context.coordinator
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        webView.load(request)
    }

    // 3. 定义 Coordinator 类
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: AdvancedWebView

        init(_ parent: AdvancedWebView) {
            self.parent = parent
        }

        // 页面开始加载时调用
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            parent.isLoading = true
        }

        // 页面加载完成时调用
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.isLoading = false
            // 获取并更新页面标题
            parent.pageTitle = webView.title ?? ""
        }

        // 页面加载失败时调用
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            parent.isLoading = false
            // 在这里可以处理错误
        }
    }
}

// 在 SwiftUI 视图中使用
struct AdvancedWebViewExample: View {
    @State private var isLoading = false
    @State private var pageTitle = ""

    var body: some View {
        VStack {
            if isLoading {
                ProgressView()
            }
            Text("页面标题: \(pageTitle)").font(.caption)
            AdvancedWebView(
                url: URL(string: "https://www.hackingwithswift.com")!,
                isLoading: $isLoading,
                pageTitle: $pageTitle
            )
        }
    }
}
```

在这个更高级的例子中：
1.  我们创建了一个 `Coordinator` 内部类，它遵循 `WKNavigationDelegate` 协议。
2.  在 `makeUIView` 中，我们将 `Coordinator` 实例设置为 `WKWebView` 的 `navigationDelegate`。
3.  `Coordinator` 实现了 `WKNavigationDelegate` 的几个关键方法（如 `didStartProvisionalNavigation`, `didFinish`）。
4.  在这些代理方法中，`Coordinator` 通过其持有的 `parent` 引用，来**更新** SwiftUI 视图传递给它的 `@Binding` 变量（`isLoading` 和 `pageTitle`）。

这样，就实现了从 `WKWebView` 到 SwiftUI 的**反向通信**。

## 与 JavaScript 交互

`WKWebView` 还允许你的原生应用与网页中的 JavaScript 进行双向通信。

*   **Swift 调用 JavaScript**: 使用 `webView.evaluateJavaScript(...)` 方法。
*   **JavaScript 调用 Swift**: 
    1.  通过 `WKUserContentController` 和 `add(_:name:)` 方法，向 JavaScript 暴露一个或多个“消息处理器”（`WKScriptMessageHandler`）。
    2.  在 JavaScript 中，使用 `window.webkit.messageHandlers.<name>.postMessage(...)` 来向你的应用发送消息。
    3.  你的 `Coordinator`（它需要遵循 `WKScriptMessageHandler`）会在 `userContentController(_:didReceive:)` 方法中接收到这些消息。

## 总结

在 SwiftUI 中集成 `WKWebView` 是混合应用开发的关键一步，它允许你利用 Web 技术的灵活性来展示复杂内容。

*   **基础**: 使用 `UIViewRepresentable` (或 `NSViewRepresentable`) 来封装 `WKWebView`。
*   **单向通信 (SwiftUI -> WebView)**: 在 `updateUIView` 方法中，根据 SwiftUI 的状态来调用 `webView.load()` 等方法。
*   **双向通信 (WebView -> SwiftUI)**: 使用 `Coordinator` 作为 `WKWebView` 的代理（如 `WKNavigationDelegate`, `WKUIDelegate`, `WKScriptMessageHandler`），并在代理方法中更新传递给 `UIViewRepresentable` 的 `@Binding`。

通过这种方式，你可以将功能强大的 `WKWebView` 无缝地集成到你的声明式 SwiftUI 界面中，实现原生与 Web 的完美结合。
