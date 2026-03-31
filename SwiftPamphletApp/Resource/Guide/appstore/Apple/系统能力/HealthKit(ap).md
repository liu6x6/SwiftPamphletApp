# iOS/macOS 系统能力：HealthKit

HealthKit 是苹果官方提供的、用于管理和访问用户健康与健身数据的中心化、安全的框架。它允许你的应用在获得用户明确授权后，读取或写入用户的健康数据（如步数、心率、睡眠分析、锻炼记录等）。所有这些数据都安全地存储在系统级的“健康（Health）”应用中。

## 核心理念：隐私与授权

健康数据是用户最敏感的个人信息之一。因此，HealthKit 的设计将**用户隐私和控制权**放在了首位。

*   **用户授权**: 你的应用**必须**在访问任何健康数据之前，向用户清晰地请求授权。你需要明确地列出你希望读取和写入的**每一种**数据类型。
*   **细粒度权限**: 用户可以独立地为你请求的每一种数据类型授予或拒绝权限。
*   **透明度**: 用户可以随时在系统的“健康”应用中，查看哪些应用访问了他们的哪些数据，并可以随时撤销授权。

## 实现步骤

### 1. 启用 HealthKit

在 Xcode 项目的 “Signing & Capabilities” 标签页中，添加 “HealthKit” 能力。你还需要在 `Info.plist` 文件中，为每一种你需要访问的健康数据，提供一个使用说明的键值对。

*   **`NSHealthShareUsageDescription`**: 请求读取权限的说明。
*   **`NSHealthUpdateUsageDescription`**: 请求写入权限的说明。

### 2. 检查可用性

在使用 HealthKit 之前，你应该先检查当前设备是否支持 HealthKit。

```swift
if HKHealthStore.isHealthDataAvailable() {
    // HealthKit 可用
} else {
    // HealthKit 在当前设备上不可用（例如，在 iPad 上）
}
```

### 3. 请求授权

这是最关键的一步。你需要创建一个 `HKHealthStore` 的实例，并调用其 `requestAuthorization(toShare:read:completion:)` 方法。

```swift
import HealthKit

let healthStore = HKHealthStore()

func requestHealthKitAuthorization() {
    // 1. 定义你想要写入的数据类型
    let typesToShare: Set = [
        HKObjectType.workoutType() // 写入锻炼数据
    ]
    
    // 2. 定义你想要读取的数据类型
    let typesToRead: Set = [
        HKObjectType.quantityType(forIdentifier: .heartRate)!,
        HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
        HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!
    ]

    // 3. 发起授权请求
    healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { (success, error) in
        if !success {
            // 处理错误或用户拒绝的情况
            print("授权失败: \(error?.localizedDescription ?? "未知错误")")
        }
    }
}
```

这个方法会触发系统弹出一个标准的授权界面，其中会列出你在 `typesToShare` 和 `typesToRead` 中定义的所有数据类型，供用户逐一选择。

### 4. 读取数据 (Querying Data)

HealthKit 提供了多种类型的查询（`HKQuery` 的子类）来从健康数据库中读取数据。

*   **`HKSampleQuery`**: 最常用的查询类型，用于获取一系列的健康数据样本（`HKSample`），例如在某个时间段内的所有心率读数。
*   **`HKStatisticsQuery`**: 用于对某个时间段内的数据进行统计计算，例如计算总步数、平均心率或消耗的总卡路里。
*   **`HKObserverQuery`**: 一个长时间运行的查询，当有新的、符合条件的数据被添加到健康数据库时，它会通知你的应用。

#### 示例：读取今天的总步数

```swift
func fetchTodaysStepCount() {
    guard let stepType = HKObjectType.quantityType(forIdentifier: .stepCount) else {
        return
    }
    
    let now = Date()
    let startOfDay = Calendar.current.startOfDay(for: now)
    let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
    
    let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
        guard let result = result, let sum = result.sumQuantity() else {
            print("获取步数失败: \(error?.localizedDescription ?? "")")
            return
        }
        
        let stepCount = sum.doubleValue(for: .count())
        print("今天的总步数: \(stepCount)")
    }
    
    healthStore.execute(query)
}
```

### 5. 写入数据 (Saving Data)

要向 HealthKit 写入数据，你需要创建一个代表该数据的 `HKSample` 子类的实例（例如 `HKQuantitySample` 用于带单位的数值，`HKWorkout` 用于锻炼记录），然后调用 `healthStore.save(_:withCompletion:)` 方法。

#### 示例：保存一次锻炼记录

```swift
func saveWorkout() {
    let startDate = Date().addingTimeInterval(-3600) // 1 小时前开始
    let endDate = Date() // 现在结束
    
    let workout = HKWorkout(
        activityType: .running, // 锻炼类型为跑步
        start: startDate,
        end: endDate,
        duration: 3600, // 总时长
        totalEnergyBurned: HKQuantity(unit: .kilocalorie(), doubleValue: 450), // 总能量消耗
        totalDistance: HKQuantity(unit: .meter(), doubleValue: 5200) // 总距离
    )
    
    healthStore.save(workout) { (success, error) in
        if success {
            print("锻炼记录保存成功！")
        } else {
            print("锻炼记录保存失败: \(error?.localizedDescription ?? "")")
        }
    }
}
```

## 在 SwiftUI 中集成

与 Core Location 和 Core Motion 类似，最佳实践是将所有 HealthKit 的交互逻辑封装到一个 `ObservableObject` 服务类中，然后在 SwiftUI 视图中通过 `@StateObject` 和 `@EnvironmentObject` 来使用它。

## 总结

HealthKit 是一个强大但复杂的框架，它为开发者提供了访问用户健康数据的标准化入口，但同时也强制要求开发者必须尊重和保护用户隐私。

*   **隐私第一**: 必须在 `Info.plist` 中声明用途，并通过 `requestAuthorization` 明确请求用户对**每一种**数据类型的授权。
*   **核心对象**: `HKHealthStore` 是所有操作的入口。
*   **读取数据**: 使用 `HKQuery` 的不同子类（如 `HKSampleQuery`, `HKStatisticsQuery`）来获取数据。
*   **写入数据**: 创建 `HKSample` 的实例（如 `HKWorkout`, `HKQuantitySample`）并调用 `healthStore.save()`。
*   **SwiftUI 集成**: 将 HealthKit 逻辑封装在 `ObservableObject` 中，以实现与视图的解耦。

通过集成 HealthKit，你的应用可以成为用户个人健康生态系统的一部分，提供更个性化、更有价值的服务。
