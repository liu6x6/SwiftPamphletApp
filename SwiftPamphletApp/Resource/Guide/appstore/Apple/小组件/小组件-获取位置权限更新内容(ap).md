# 小组件中的位置服务 (CoreLocation)

天气应用或打车应用的小组件通常需要基于用户当前的地理位置来展示信息。然而，小组件是一个极其受限的后台进程，它获取位置权限和数据的流程比主 App 要复杂和严格得多。

## 1. 核心权限：\`Widget Location\`

从 iOS 14 开始，当你的 App 包含使用了位置信息的小组件时，系统会在权限弹窗中除了 "Allow Once", "Allow While Using App" 之外，额外提供一个关于 Widget 的权限层级。

**前提条件**：
*   用户必须至少授予主 App **"使用 App 期间允许" (While Using the App)** 的权限。
*   如果用户在主 App 设置中，将“小组件”的位置权限关闭，你的小组件将无法获取定位。

## 2. \`Info.plist\` 的关键配置

为了让小组件能使用位置服务，你必须在**小组件 Target (Extension)** 的 \`Info.plist\` 中添加声明，否则定位会直接静默失败：

*   添加 \`NSWidgetWantsLocation\` 键，类型为 \`Boolean\`，值设为 \`YES\`。
*(主 App 的 \`Info.plist\` 当然也需要常规的 \`NSLocationWhenInUseUsageDescription\` 描述)*

## 3. 在 Provider 中获取位置

由于小组件的 \`getTimeline\` 方法必须尽快返回，你不能在这里设置一个长期监听（\`startUpdatingLocation\`），只能请求一次单次定位（\`requestLocation\`）。

```swift
import WidgetKit
import CoreLocation

// 让 Provider 遵循 CLLocationManagerDelegate
class LocationProvider: NSObject, TimelineProvider, CLLocationManagerDelegate {
    private var locationManager: CLLocationManager?
    private var locationCompletion: ((CLLocation?) -> Void)?

    func getTimeline(in context: Context, completion: @escaping (Timeline<LocationEntry>) -> ()) {
        // 如果是画廊预览模式，直接返回默认城市以节省时间
        if context.isPreview {
            // ...返回假数据
            return
        }

        // 异步获取位置
        fetchLocation { location in
            guard let loc = location else {
                // 定位失败，返回错误状态的 Entry 或默认城市
                completion(Timeline(entries: [...], policy: .after(...)))
                return
            }
            
            // 拿到经纬度，去请求天气 API
            fetchWeather(lat: loc.coordinate.latitude, lon: loc.coordinate.longitude) { weather in
                // 构建 Timeline 并回调
                completion(timeline)
            }
        }
    }

    private func fetchLocation(completion: @escaping (CLLocation?) -> Void) {
        self.locationCompletion = completion
        
        // 必须在主线程初始化 CLLocationManager
        DispatchQueue.main.async {
            self.locationManager = CLLocationManager()
            self.locationManager?.delegate = self
            // 降低精度要求，提高获取速度和成功率
            self.locationManager?.desiredAccuracy = kCLLocationAccuracyKilometer
            
            // 检查权限
            let status = self.locationManager?.authorizationStatus
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                // 仅请求一次位置
                self.locationManager?.requestLocation()
            } else {
                // 没有权限
                self.locationCompletion?(nil)
            }
        }
    }

    // MARK: - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // 成功获取到位置
        locationCompletion?(locations.last)
        locationCompletion = nil // 释放闭包
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Widget 定位失败: \(error)")
        locationCompletion?(nil)
        locationCompletion = nil
    }
}
```

## 4. 常见坑点与优化

*   **定位超时**：在信号差的地方，\`requestLocation\` 可能会很久不回调，导致小组件超时被杀。强烈建议用 \`DispatchQueue.main.asyncAfter\` 给定位加上一个 3-5 秒的**强制超时机制**。如果超时没拿到位置，就直接用上一次存在 AppGroup 里的旧位置，或者显示默认城市。
*   **使用 \`AppGroup\` 缓存**：当主 App 在前台成功获取到高精度位置时，应该立刻保存到共享的 \`UserDefaults(suiteName:)\` 中。小组件唤醒时，如果定位失败或超时，优先回退读取这个缓存的经纬度。这是提升小组件加载速度的最佳实践。
