# iOS/macOS 网络：截获网络请求数据

在移动应用开发和调试过程中，检查、修改或模拟网络请求和响应是一个非常常见的需求。这对于调试 API 问题、处理不同的服务器响应、或者在没有网络的环境下进行开发都至关重要。在苹果生态中，实现网络请求截获的主要方式是使用 `URLProtocol`。

## `URLProtocol`：网络请求的抽象层

`URLProtocol` 是 `Foundation` 框架中一个强大的、但相对底层的类。它允许你创建自定义的 URL 协议处理器，从而**截获**几乎所有通过标准 `URL Loading System`（包括 `URLSession` 和 `WKWebView`）发出的网络请求。

它的工作原理是，你可以注册一个自定义的 `URLProtocol` 子类。一旦注册，系统在发起任何网络请求之前，都会先询问你的自定义协议：“你能处理这个请求吗？”。如果你回答“能”，那么这个请求的整个生命周期（发送、接收响应、接收数据）都将由你的自定义协议来全权负责。

这为你提供了一个在网络请求到达真正的网络层之前，对其进行检查、修改甚至完全伪造（mock）的强大能力。

## 实现一个自定义 `URLProtocol`

创建一个自定义的 `URLProtocol` 子类需要实现几个关键的方法：

1.  **`canInit(with:) -> Bool`**: 这是最重要的类方法。系统会用每个网络请求来调用它。你在这里决定你的协议是否要处理这个请求。如果返回 `true`，这个请求就会被你的协议接管。

2.  **`canonicalRequest(for:) -> URLRequest`**: 在这里，你可以对请求进行规范化处理，但通常直接返回原始请求即可。

3.  **`startLoading()`**: 当你的协议接管一个请求后，这个方法会被调用。你需要在这里开始执行网络请求的逻辑。你可以：
    *   **转发请求**: 创建一个新的 `URLSessionDataTask` 来将原始请求发送到网络。
    *   **修改请求**: 在转发之前，修改请求的 URL、Header 或 Body。
    *   **伪造响应**: 完全不发送网络请求，而是直接创建一个假的 `HTTPURLResponse` 和 `Data`，来模拟一个服务器响应。

4.  **`stopLoading()`**: 当请求被取消或完成时，这个方法会被调用。你需要在这里停止所有正在进行的操作。

在 `startLoading()` 的过程中，你需要通过 `self.client` 属性，向系统报告网络事件：
*   `client?.urlProtocol(self, didReceive: response, cachePolicy: .notAllowed)`: 报告收到了响应头。
*   `client?.urlProtocol(self, didLoad: data)`: 报告收到了数据块。
*   `client?.urlProtocolDidFinishLoading(self)`: 报告请求成功完成。
*   `client?.urlProtocol(self, didFailWithError: error)`: 报告请求失败。

### 示例：一个简单的网络日志记录器

```swift
import Foundation

class LoggingURLProtocol: URLProtocol {

    override class func canInit(with request: URLRequest) -> Bool {
        // 打印所有即将发出的请求，并决定处理它们
        print("Intercepted request: \(request.url?.absoluteString ?? "")")
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    private var dataTask: URLSessionDataTask?

    override func startLoading() {
        // 创建一个新的 dataTask 来实际发送网络请求
        self.dataTask = URLSession.shared.dataTask(with: self.request) { data, response, error in
            if let error = error {
                self.client?.urlProtocol(self, didFailWithError: error)
                return
            }
            if let response = response {
                self.client?.urlProtocol(self, didReceive: response, cachePolicy: .notAllowed)
            }
            if let data = data {
                print("Received data: \(String(data: data, encoding: .utf8) ?? "")")
                self.client?.urlProtocol(self, didLoad: data)
            }
            self.client?.urlProtocolDidFinishLoading(self)
        }
        self.dataTask?.resume()
    }

    override func stopLoading() {
        self.dataTask?.cancel()
    }
}
```

### 注册和取消注册 `URLProtocol`

要让你的自定义协议生效，你需要在 `URLSessionConfiguration` 中注册它。

```swift
// 获取默认的 URLSession 配置
let config = URLSessionConfiguration.default

// 将你的自定义协议添加到协议类数组的开头
// 确保它在系统默认的 http/https 协议之前被检查
config.protocolClasses = [LoggingURLProtocol.self] + (config.protocolClasses ?? [])

// 使用这个配置创建一个新的 URLSession
let session = URLSession(configuration: config)

// 之后，所有通过这个 session 发出的请求都会被 LoggingURLProtocol 截获
```

通常，你会在应用启动时（例如在 `AppDelegate` 或 `App` 的 `init` 中）进行注册。

## 常用的第三方库

虽然 `URLProtocol` 非常强大，但直接使用它需要编写大量的模板代码，并且要处理多线程、数据流等复杂问题。社区中有许多优秀的第三方库，它们基于 `URLProtocol` 提供了更简单、更易于使用的 API。

*   **OHHTTPStubs**: 一个历史悠久、非常流行的 Objective-C 库，专门用于伪造（stub）网络请求。你可以轻松地定义规则，例如“当请求的 URL 匹配这个正则表达式时，返回这个预设的 JSON 文件”。它对于编写网络层的单元测试非常有用。

*   **Mocker**: 一个用 Swift 编写的、轻量级的 `URLProtocol` 封装，用于模拟和伪造网络请求。

*   **Proxyman / Charles / Fiddler**: 这些是功能更强大的**外部代理工具**。它们不是在你的应用代码中运行，而是作为一个系统代理，截获你设备上所有应用（包括你自己的）发出的所有网络流量。它们提供了图形化的界面，让你能够方便地查看、修改、重放和模拟网络请求，是移动开发和调试中必不可少的利器。

## 总结

截获网络请求是移动开发中一项高级但非常实用的调试技巧。

*   **核心技术**: `URLProtocol` 是苹果官方提供的、用于截获 `URL Loading System` 请求的底层 API。
*   **工作原理**: 通过注册一个自定义的 `URLProtocol` 子类，你可以接管网络请求的生命周期，从而实现检查、修改或伪造请求和响应。
*   **主要用途**: 
    *   **日志记录**: 打印所有网络请求的详细信息。
    *   **请求修改**: 动态地为所有请求添加统一的 Header（如认证 token）。
    *   **模拟数据 (Mocking/Stubbing)**: 在没有后端或网络的情况下，返回预设的假数据，方便 UI 开发和单元测试。
*   **工具选择**: 
    *   对于简单的日志或请求修改，可以自己实现 `URLProtocol`。
    *   对于复杂的 Mocking，使用 `OHHTTPStubs` 等库更高效。
    *   对于全面的、可视化的网络流量分析和调试，使用 **Proxyman** 或 **Charles** 等外部代理工具是最佳实践。

通过掌握网络截获技术，你可以获得对应用网络层的完全控制，极大地提升调试效率和应对复杂网络环境的能力。
