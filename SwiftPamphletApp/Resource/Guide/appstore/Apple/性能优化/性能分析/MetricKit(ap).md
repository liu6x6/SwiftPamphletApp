# MetricKit：原生的线上性能收集中心

在 iOS 13 之前，如果你想知道“用户在线上使用我的 App 时，到底有多卡？一天耗了多少电？”，你必须自己写一套极其沉重的 APM 埋点系统，或者接入第三方的监控 SDK。这些 SDK 往往需要 hook 系统底层函数，这不仅不安全，其自身运行也会消耗大量的系统资源。

为了解决这个痛点，Apple 推出了官方的性能监控框架：**\`MetricKit\`**。

## 1. MetricKit 的核心哲学

MetricKit 的设计理念是：**绝对零额外开销 (Zero Overhead)**。
它不需要你写代码去监听 CPU 占用率，也不需要你定时保存数据。操作系统 (iOS 本身) 会在极其低层的内核级别，默默地全天候记录你的 App 的各种极其硬核的性能指标。

每天只有在极少数特定的时刻（通常是设备闲置充电时），系统才会把过去 24 小时的**日终报表 (Payload)** 打包好，一次性发送给你的代码。你只需要把这份 JSON 报表转发出你的服务器存起来即可。

## 2. 基础用法：订阅每日性能报表

```swift
import MetricKit

class MetricsManager: NSObject, MXMetricManagerSubscriber {
    static let shared = MetricsManager()
    
    func startMonitoring() {
        // 向系统单例注册成为订阅者
        MXMetricManager.shared.add(self)
    }
    
    // 核心代理方法：系统每天最多调用你一次，把打包好的数据交给你
    func didReceive(_ payloads: [MXMetricPayload]) {
        for payload in payloads {
            // 这份 payload 里面包含了极其丰富的数据
            
            // 1. 获取包含设备信息、系统版本的元数据
            let metaData = payload.metaData
            
            // 2. 获取极其重要的 JSON 格式字符串，直接把它发给你的后端监控平台！
            let jsonString = String(data: payload.jsonRepresentation(), encoding: .utf8)
            print("上传性能报表: \(jsonString ?? "")")
            
            // 3. (可选) 你也可以在本地解析某些具体的指标
            if let signpostMetrics = payload.signpostMetrics {
                // ...
            }
        }
    }
    
    deinit {
        MXMetricManager.shared.remove(self)
    }
}
```

## 3. MetricPayload 里面到底有什么神仙数据？

这是一份极其详尽的体检报告。它包含了以下维度（通常以直方图 \`Histogram\` 或平均值的形式呈现，以保护隐私）：

*   **\`cellularConditionMetrics\` / \`networkTransferMetrics\`**：你的 App 这一天在后台和前台一共消耗了多少 Wi-Fi 流量和蜂窝流量？
*   **\`applicationTimeMetrics\`**：你的 App 处于前台的时间有多长？在后台挂起存活的时间有多长？
*   **\`memoryMetrics\`**：内存的峰值是多少？有没有引发系统的内存警告？
*   **\`animationMetrics\`**：这是最直观的卡顿指标！它会告诉你“滑动过程中，有多少帧是完美 60fps 的，有多少帧是严重掉帧的”。
*   **\`applicationLaunchMetrics\`**：极其精准的冷启动（Cold Launch）耗时直方图。

## 4. 诊断信息 (Diagnostics) 与卡顿堆栈 (iOS 14+)

在后来的 iOS 版本中，MetricKit 从只能收集“统计数据”，进化到了能收集“车祸现场录像”。

通过实现 \`didReceive(_ payloads: [MXDiagnosticPayload])\` 代理，你可以拿到：
1. **Crash Diagnostics**：崩溃时的完整堆栈。
2. **Hang Diagnostics (极其宝贵)**：如果主线程卡死超过 250 毫秒，系统会自动拍下一张调用堆栈图。现在你能明确知道到底是谁在主线程读写大文件导致了界面无响应。
3. **Disk Write Exception**：如果在短时间内疯狂向沙盒写入了几百 MB 垃圾数据，系统会生成这个诊断报告。

## 5. 本地开发调试神器：Simulate Payload

你不需要真拿着手机等 24 小时才能测你的代码。
在 Xcode 运行 App 时，点击顶部菜单栏的 \`Debug\` -> \`Simulate MetricKit Payloads\`，Xcode 会立刻伪造一份数据包发送给你的 \`didReceive\` 代理方法，方便你测试上报逻辑。
