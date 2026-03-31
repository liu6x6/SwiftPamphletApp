# iOS/macOS 网络：网络状态检查

在移动应用中，实时地监控网络连接状态是一项至关重要的功能。它能让你的应用：

*   在无网络时，向用户显示一个友好的提示，而不是一个无休止的加载指示器。
*   根据网络类型（Wi-Fi 或蜂窝网络）调整行为，例如只在 Wi-Fi 环境下下载大文件或播放高清视频。
*   在网络从断开到恢复时，自动重试失败的请求。

苹果官方提供了 **`Network` 框架**，这是自 iOS 12 起推荐的、用于处理网络连接的现代化 API。它取代了旧的、基于 `SCNetworkReachability` 的方式。

## `NWPathMonitor`：现代化的网络状态监控

`NWPathMonitor` 是 `Network` 框架中用于监控网络路径变化的核心类。你可以创建一个 `NWPathMonitor` 的实例，并为它设置一个更新处理器（update handler），每当网络状态发生变化时，这个处理器就会被调用。

### 核心用法

1.  **创建 `NWPathMonitor`**: 创建一个 `NWPathMonitor` 的实例。
2.  **设置 `pathUpdateHandler`**: 提供一个闭包，该闭包会接收一个 `NWPath` 对象。`NWPath` 对象包含了当前网络路径的所有信息。
3.  **启动监控**: 调用 `start(queue:)` 方法，并提供一个用于执行 `pathUpdateHandler` 的调度队列（`DispatchQueue`）。
4.  **停止监控**: 在不再需要时（例如，对象被销毁时），调用 `cancel()` 来停止监控，以释放资源。

## 在 SwiftUI 中集成网络状态检查

要在整个 SwiftUI 应用中方便地使用网络状态，最佳实践是创建一个遵循 `ObservableObject` 的服务类，并将其作为 `EnvironmentObject` 注入到视图层级中。

### 1. 创建 `NetworkMonitor` 服务

```swift
import Foundation
import Network

// 1. 创建一个 ObservableObject 来封装网络监控逻辑
@MainActor // 确保对 @Published 属性的更新在主线程上
class NetworkMonitor: ObservableObject {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")

    // 2. 发布网络状态和连接类型
    @Published var isConnected = true
    @Published var connectionType: NWInterface.InterfaceType = .other

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            // 在主线程上更新发布的属性
            DispatchQueue.main.async {
                self?.isConnected = (path.status == .satisfied)
                self?.updateConnectionType(path)
            }
        }
        monitor.start(queue: queue)
    }

    private func updateConnectionType(_ path: NWPath) {
        if path.usesInterfaceType(.wifi) {
            connectionType = .wifi
        } else if path.usesInterfaceType(.cellular) {
            connectionType = .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            connectionType = .wiredEthernet
        } else {
            connectionType = .other
        }
    }
    
    deinit {
        monitor.cancel()
    }
}
```

在这个 `NetworkMonitor` 类中：
*   我们创建了一个 `NWPathMonitor` 实例。
*   我们发布了两个属性：`isConnected` (一个布尔值) 和 `connectionType` (一个枚举)。
*   在 `init()` 中，我们设置了 `pathUpdateHandler`。当网络路径更新时，这个闭包会检查 `path.status` 并更新 `isConnected`。我们还添加了一个辅助函数来判断并更新连接类型。
*   **关键**: 所有对 `@Published` 属性的更新都必须在主线程上进行，因此我们使用了 `DispatchQueue.main.async`。
*   在 `deinit` 中，我们调用 `monitor.cancel()` 来清理资源。

### 2. 在应用中注入和使用

```swift
import SwiftUI

@main
struct MyApp: App {
    // 1. 创建 NetworkMonitor 的实例
    @StateObject private var networkMonitor = NetworkMonitor()

    var body: some Scene {
        WindowGroup {
            ContentView()
                // 2. 将其作为 EnvironmentObject 注入到视图层级中
                .environmentObject(networkMonitor)
        }
    }
}

struct ContentView: View {
    // 3. 在任何子视图中，通过 @EnvironmentObject 读取网络状态
    @EnvironmentObject var networkMonitor: NetworkMonitor

    var body: some View {
        VStack(spacing: 20) {
            if networkMonitor.isConnected {
                Text("网络已连接")
                    .foregroundColor(.green)
                
                switch networkMonitor.connectionType {
                case .wifi:
                    Label("Wi-Fi", systemImage: "wifi")
                case .cellular:
                    Label("蜂窝网络", systemImage: "antenna.radiowaves.left.and.right")
                default:
                    Label("其他网络", systemImage: "questionmark.circle")
                }
            } else {
                Text("网络未连接")
                    .foregroundColor(.red)
            }
        }
        .font(.largeTitle)
    }
}
```

在这个例子中：
1.  我们在 `App` 的主入口创建了一个 `@StateObject` 的 `NetworkMonitor` 实例，确保它的生命周期与应用相同。
2.  我们使用 `.environmentObject()` 将这个实例注入到整个视图层级。
3.  在 `ContentView`（或其任何子视图）中，我们通过 `@EnvironmentObject` 属性包装器来轻松地访问 `networkMonitor` 的 `isConnected` 和 `connectionType` 属性。
4.  因为这些属性是 `@Published` 的，所以当网络状态发生变化时，`ContentView` 会自动刷新以显示最新的状态。

## 总结

通过 `Network` 框架的 `NWPathMonitor`，我们可以构建一个现代、可靠且高效的网络状态监控服务。

*   **核心 API**: `NWPathMonitor`。
*   **最佳实践**: 将监控逻辑封装在一个 `ObservableObject` 服务类中。
*   **SwiftUI 集成**: 将该服务实例作为 `@StateObject` 在顶层创建，并使用 `.environmentObject()` 将其注入到整个应用中。
*   **响应式 UI**: 在任何需要根据网络状态调整行为的视图中，通过 `@EnvironmentObject` 来订阅和响应网络状态的变化。

这种架构模式实现了业务逻辑（网络监控）与视图的清晰分离，使得代码更易于管理、测试和复用。
