# iOS/macOS 系统能力：Core Motion

Core Motion 框架为开发者提供了访问设备内置的运动与环境传感器的能力，包括加速度计、陀螺仪、磁力计和气压计等。通过这些传感器数据，你可以检测设备的运动、方向和姿态，从而为应用（尤其是游戏、运动健康和增强现实类应用）带来丰富的交互体验。

## 核心概念

*   **`CMMotionManager`**: 这是你与 Core Motion 交互的主要入口。你需要创建一个 `CMMotionManager` 的实例，并使用它来检查传感器的可用性、设置更新频率，以及开始和停止接收传感器数据。

*   **Push vs. Pull**: Core Motion 提供了两种获取数据的方式：
    *   **Push (推送)**: 你提供一个闭包和一个操作队列（`OperationQueue`），Core Motion 会以指定的频率，持续地将新的传感器数据“推送”到你的闭包中。这是获取实时、高频数据的标准方式。
    *   **Pull (拉取)**: 你可以随时主动地从 `CMMotionManager` 中读取最新的、单个的传感器数据。这适用于只需要偶尔获取一次数据的场景。

## 可用的传感器数据

### 1. 加速度计 (Accelerometer)

加速度计测量设备在三个轴（x, y, z）上感受到的加速度，单位是 G（1G 约等于 9.8 m/s²）。这个数据包含了重力加速度和用户施加的加速度。

*   **数据类型**: `CMAccelerometerData`，包含一个 `CMAcceleration` 结构体。
*   **用途**: 检测设备的晃动（摇一摇）、瞬间的冲击或基本的方向（通过重力分量）。

```swift
let motionManager = CMMotionManager()

if motionManager.isAccelerometerAvailable {
    motionManager.accelerometerUpdateInterval = 0.1 // 每秒 10 次
    motionManager.startAccelerometerUpdates(to: .main) { (data, error) in
        guard let acceleration = data?.acceleration else { return }
        print("加速度: x=\(acceleration.x), y=\(acceleration.y), z=\(acceleration.z)")
    }
}
```

### 2. 陀螺仪 (Gyroscope)

陀螺仪测量设备围绕三个轴（x, y, z）的旋转速率，单位是弧度/秒。

*   **数据类型**: `CMGyroData`，包含一个 `CMRotationRate` 结构体。
*   **用途**: 精确地捕捉设备的旋转手势，例如倾斜、摇摆和转动。

```swift
if motionManager.isGyroAvailable {
    motionManager.gyroUpdateInterval = 0.1
    motionManager.startGyroUpdates(to: .main) { (data, error) in
        guard let rotationRate = data?.rotationRate else { return }
        // ...
    }
}
```

### 3. 设备运动 (Device Motion)

`Device Motion` 是 Core Motion 提供的一个更高级、更强大的 API。它融合了加速度计、陀螺仪和磁力计的数据，通过复杂的传感器融合算法，为你提供了关于设备**姿态 (Attitude)**、**用户施加的加速度**和**旋转速率**的、经过处理的高级信息。

*   **数据类型**: `CMDeviceMotion`。
*   **核心属性**:
    *   **`attitude`**: 一个 `CMAttitude` 对象，描述了设备相对于一个参考坐标系的方向，可以用四元数（`quaternion`）、旋转矩阵（`rotationMatrix`）或欧拉角（`pitch`, `roll`, `yaw`）来表示。
    *   **`userAcceleration`**: 移除了重力分量后，由用户直接施加在设备上的加速度。
    *   **`gravity`**: 从加速度计数据中分离出来的重力向量，它始终指向地心。
    *   **`rotationRate`**: 经过校准的旋转速率。

**强烈建议**: 只要有可能，都应该**优先使用 Device Motion**，而不是单独使用原始的加速度计和陀螺仪数据。因为 Device Motion 已经为你处理了复杂的传感器数据融合和校准工作。

```swift
if motionManager.isDeviceMotionAvailable {
    motionManager.deviceMotionUpdateInterval = 0.1
    motionManager.startDeviceMotionUpdates(to: .main) { (data, error) in
        guard let attitude = data?.attitude else { return }
        let roll = attitude.roll
        let pitch = attitude.pitch
        let yaw = attitude.yaw
        // ... 用这些姿态数据来更新你的 UI 或游戏逻辑
    }
}
```

### 4. 计步器 (`CMPedometer`)

`CMPedometer` 用于追踪用户的计步信息。

*   **`startUpdates(from:withHandler:)`**: 开始接收实时的计步更新（步数、距离、上/下楼层数等）。
*   **`queryPedometerData(from:to:withHandler:)`**: 查询过去某个时间段内的计步历史数据。

### 5. 高度计 (`CMAltimeter`)

`CMAltimeter` 使用设备的气压计来提供高度变化信息。

*   **数据类型**: `CMAltitudeData`，包含相对高度变化（`relativeAltitude`）和气压（`pressure`）。

## 在 SwiftUI 中集成

与 Core Location 类似，最佳实践也是创建一个 `ObservableObject` 服务类来封装 `CMMotionManager` 的逻辑，然后通过 `@StateObject` 和 `@EnvironmentObject` 在 SwiftUI 视图中使用。

```swift
@MainActor
class MotionManager: ObservableObject {
    private let motionManager = CMMotionManager()
    @Published var pitch: Double = 0.0
    @Published var roll: Double = 0.0

    init() {
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 0.1
            motionManager.startDeviceMotionUpdates(to: .main) { [weak self] (data, error) in
                guard let self = self, let data = data else { return }
                self.pitch = data.attitude.pitch
                self.roll = data.attitude.roll
            }
        }
    }
}

struct MotionView: View {
    @StateObject private var motionManager = MotionManager()

    var body: some View {
        Text("Hello, World!")
            .rotation3DEffect(.degrees(motionManager.pitch * 50), axis: (x: 1, y: 0, z: 0))
            .rotation3DEffect(.degrees(motionManager.roll * 50), axis: (x: 0, y: 1, z: 0))
    }
}
```

## 总结

Core Motion 框架为你的应用赋予了感知设备物理运动和姿态的能力。

*   **核心 API**: `CMMotionManager`。
*   **首选数据**: **优先使用 `Device Motion`**，因为它提供了经过传感器融合算法处理的、更稳定、更高级的姿态和加速度数据。
*   **数据获取**: 使用“Push”模式（`start...Updates`）来获取实时、连续的数据流。
*   **SwiftUI 集成**: 将 `CMMotionManager` 封装在一个 `ObservableObject` 中，并通过 `@Published` 属性将数据发布给你的 SwiftUI 视图。

通过 Core Motion，你可以创建出响应用户真实世界动作的、更具沉浸感和趣味性的交互体验。
