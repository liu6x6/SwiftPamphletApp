# iOS/macOS 系统能力：Core Location

Core Location 框架是苹果官方提供的、用于获取设备地理位置、海拔、朝向以及管理地理围栏（Geofences）和信标（Beacons）的核心服务。它是所有需要定位功能的应用（如地图、导航、天气、运动追踪等）的基础。

## 核心概念

*   **`CLLocationManager`**: 这是你与 Core Location 交互的主要入口。你需要创建一个 `CLLocationManager` 的实例，并使用它来配置定位服务的精度、请求用户授权、以及开始和停止位置更新。

*   **`CLLocation`**: 一个包含了地理位置信息（经度、纬度）、海拔、速度、路线和精确度等数据的对象。

*   **`CLLocationManagerDelegate`**: 一个协议，你需要遵循它来接收来自 `CLLocationManager` 的事件，例如位置更新、授权状态变化或发生错误。

## 实现步骤

### 1. 请求用户授权

定位是一项涉及用户隐私的敏感操作。你必须在 `Info.plist` 文件中添加相应的键值对，向用户清楚地解释你为什么需要他们的位置信息。

*   **`NSLocationWhenInUseUsageDescription`**: 当应用在前台时使用位置的描述。
*   **`NSLocationAlwaysAndWhenInUseUsageDescription`**: 当应用在前台和后台时都需要使用位置的描述。

然后，在代码中，你需要调用 `locationManager.requestWhenInUseAuthorization()` 或 `locationManager.requestAlwaysAuthorization()` 来向用户发起授权请求。

### 2. 配置和启动位置更新

```swift
import SwiftUI
import CoreLocation

// 1. 创建一个遵循 ObservableObject 的位置管理器
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    
    @Published var location: CLLocation? = nil
    @Published var authorizationStatus: CLAuthorizationStatus

    override init() {
        self.authorizationStatus = locationManager.authorizationStatus
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest // 设置期望的精度
        locationManager.distanceFilter = kCLDistanceFilterNone // 移动多少米后更新
    }

    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }

    func startUpdatingLocation() {
        locationManager.startUpdatingLocation()
    }

    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }

    // 3. 实现代理方法来接收更新
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        DispatchQueue.main.async {
            self.location = location
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            self.authorizationStatus = manager.authorizationStatus
        }
    }
}

// 在 SwiftUI 视图中使用
struct LocationView: View {
    @StateObject private var locationManager = LocationManager()

    var body: some View {
        VStack {
            if let location = locationManager.location {
                Text("纬度: \(location.coordinate.latitude)")
                Text("经度: \(location.coordinate.longitude)")
            } else {
                if locationManager.authorizationStatus == .notDetermined {
                    Text("请授权以获取位置信息")
                    Button("请求授权") {
                        locationManager.requestLocationPermission()
                    }
                } else if locationManager.authorizationStatus == .denied {
                    Text("位置服务已被禁用。请在设置中开启。")
                } else {
                    ProgressView()
                }
            }
        }
        .onAppear {
            locationManager.startUpdatingLocation()
        }
    }
}
```

在这个例子中：
1.  我们创建了一个 `LocationManager` 类来封装所有 `CoreLocation` 的逻辑，并使其成为一个 `ObservableObject`，以便在 SwiftUI 视图中轻松使用。
2.  在 `init()` 中，我们设置了 `delegate` 和定位服务的精度。
3.  我们实现了 `locationManager(_:didUpdateLocations:)` 代理方法，当获取到新的位置数据时，它会更新 `@Published` 的 `location` 属性，从而触发 SwiftUI 视图的刷新。
4.  `locationManagerDidChangeAuthorization` 代理方法用于监控授权状态的变化。
5.  在 SwiftUI 视图中，我们使用 `@StateObject` 创建 `LocationManager` 的实例，并根据其发布的 `location` 和 `authorizationStatus` 属性来显示不同的 UI。

## 精度与功耗

`desiredAccuracy` 属性对设备的电池寿命有显著影响。

*   `kCLLocationAccuracyBestForNavigation`: 最高的精度，用于导航应用，功耗最大。
*   `kCLLocationAccuracyBest`: 高精度。
*   `kCLLocationAccuracyNearestTenMeters`: 10米精度。
*   `kCLLocationAccuracyHundredMeters`: 100米精度。
*   `kCLLocationAccuracyKilometer`: 公里级精度。
*   `kCLLocationAccuracyThreeKilometers`: 三公里级精度，功耗最低。

你应该根据你的应用需求，选择**能够满足需求的最低精度**，以节省电池电量。

## 其他功能

*   **单次位置请求**: 从 iOS 15 开始，你可以使用新的 `locationManager.requestLocation()` 方法来请求一次性的位置更新，它会在获取到位置或超时后自动停止，比手动 `start/stop` 更方便。

*   **地理围栏 (Geofencing)**: 监控设备进入或离开某个地理区域的事件（`CLCircularRegion`）。

*   **信标 (Beacons)**: 监控蓝牙低功耗（BLE）信标（`CLBeaconRegion`）的接近程度。

## 总结

Core Location 是构建所有基于位置服务的应用的基础框架。

*   **核心**: `CLLocationManager` 和 `CLLocationManagerDelegate`。
*   **隐私**: 必须在 `Info.plist` 中提供使用说明，并明确地向用户请求授权。
*   **SwiftUI 集成**: 最佳实践是创建一个 `ObservableObject` 服务类来封装 Core Location 的逻辑，并将其注入到 SwiftUI 视图中。
*   **功耗**: 谨慎选择 `desiredAccuracy`，避免不必要的电量消耗。

通过 `Core Location`，你可以为你的应用赋予感知物理世界的能力，创造出丰富、智能且与用户环境紧密相关的体验。
