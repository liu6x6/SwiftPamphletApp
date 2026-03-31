# 格式化度量值：MeasurementFormatter

在应用中展示长度、重量、温度等物理量时，我们不能仅仅把数字拼上单位（如 `print("\(weight) kg")`），因为这完全没有考虑到用户的地区偏好（美国用户习惯磅 lb，欧洲用户习惯千克 kg）。

`MeasurementFormatter` 是苹果官方提供的一把极其锋利的瑞士军刀，它能自动根据用户手机的 Locale（区域语言设置），将抽象的 `Measurement` 转化为完美的本地化字符串。

## 1. 基础自动本地化

假设你的服务器返回了一段以“公里”为单位的距离。

```swift
import Foundation

// 1. 构造一个绝对准确的度量值对象（5公里）
let rawDistance = Measurement(value: 5, unit: UnitLength.kilometers)

// 2. 创建格式化器
let formatter = MeasurementFormatter()

// 3. 输出字符串
let displayString = formatter.string(from: rawDistance)
print(displayString)
```
**魔法就在这里发生**：
*   如果用户的 iPhone 是**中国区域 (zh_CN)**，输出可能是：`"5 公里"`。
*   如果用户的 iPhone 是**美国区域 (en_US)**，系统会自动把 5 公里转换成英制，输出可能是：`"3.107 miles"`。
*   你完全不需要自己写 `if locale == "US" { ... }` 这种极其丑陋的转换代码！

## 2. 核心属性与配置选项

你可以通过配置 `MeasurementFormatter` 的属性，精细控制输出的样式。

### A. unitOptions：单位转换策略
*   `.naturalScale` (默认值)：极其聪明。如果你传入的是 `0.001` 公里，它觉得这太怪了，会自动帮你缩放并显示为 `"1 米"`。
*   `.providedUnit`：**强行禁用自动转换**。就算用户是美国人，只要你代码里指定的是千米，就必须输出为千米（比如在进行极其专业的国际物理学术报告展示时）。
*   `.temperatureWithoutUnit`：只显示数字，不显示 °C 或 °F（极少使用）。

```swift
formatter.unitOptions = .providedUnit // 强制只用我提供的单位
```

### B. unitStyle：单位的长度风格
用于控制单位单词的缩写程度。
```swift
let temp = Measurement(value: 30, unit: UnitTemperature.celsius)
let styleFormatter = MeasurementFormatter()

// 1. .short (默认) -> "30°C" 
styleFormatter.unitStyle = .short

// 2. .medium -> "30 °C" (间距略微不同)
styleFormatter.unitStyle = .medium

// 3. .long -> "30 degrees Celsius" 或 "30摄氏度"
styleFormatter.unitStyle = .long
```

### C. numberFormatter：控制核心数字的精度
`MeasurementFormatter` 内部包含了一个 `NumberFormatter`，你可以通过修改它来控制数字要保留几位小数。

```swift
let weight = Measurement(value: 85.3456, unit: UnitMass.kilograms)
let numFormatter = MeasurementFormatter()

// 告诉内部的数字格式化器：最多只保留 1 位小数
numFormatter.numberFormatter.maximumFractionDigits = 1
numFormatter.numberFormatter.minimumFractionDigits = 1

print(numFormatter.string(from: weight)) 
// 中文区输出: "85.3 公斤"
```

## 3. 在 SwiftUI 中的现代替代方案：.formatted()

与日期格式化一样，如果你使用 iOS 15 及以上的版本，苹果在 SwiftUI 体系中也为 `Measurement` 提供了极其优雅的 `.formatted()` 扩展宏，可以完全抛弃实例化 `MeasurementFormatter` 的繁琐过程。

```swift
import SwiftUI

struct WorkoutView: View {
    let runDistance = Measurement(value: 12.5, unit: UnitLength.kilometers)
    
    var body: some View {
        // 直接在 Text 视图中使用 format！
        // .measurement(...) 参数内部同样可以配置使用本地缩放、长度风格等
        Text(runDistance, format: .measurement(width: .abbreviated, usage: .asProvided))
            .font(.title)
    }
}
```
**总结**：在处理国际化应用的各种物理单位展示时，让底层框架来做单位的缩放（米变公里）和度量衡体系的切换（公制变英制），永远不要相信自己手写的乘除法换算公式。
