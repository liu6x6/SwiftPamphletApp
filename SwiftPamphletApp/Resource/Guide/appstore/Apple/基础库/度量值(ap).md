# 度量值与单位转换 (Measurement & Unit)

在开发涉及到距离、重量、温度、速度或面积的应用时，硬编码数字和手动计算转换公式（比如 \`fahrenheit = celsius * 1.8 + 32\`）是极其痛苦且容易出错的。

Apple 在 Foundation 框架中提供了一套极其强大、类型安全且支持多语言本地化的度量单位处理系统：**\`Measurement\`** 和 **\`Unit\`**。

## 1. 核心概念

*   **\`Unit\` (单位)**：表示物理量的单位。Apple 内置了大量子类，如 \`UnitLength\`(长度), \`UnitMass\`(质量), \`UnitTemperature\`(温度), \`UnitSpeed\`(速度) 等。
*   **\`Measurement\` (度量)**：将一个具体的数值（\`Double\`）与一个 \`Unit\` 绑定在一起形成的结构体。

## 2. 基础创建与类型安全的计算

当你使用 \`Measurement\` 时，Swift 编译器会保护你，防止你把“千克”和“公里”加在一起。

```swift
import Foundation

// 创建一个距离：5 千米
let distance1 = Measurement(value: 5, unit: UnitLength.kilometers)

// 创建一个距离：300 米
let distance2 = Measurement(value: 300, unit: UnitLength.meters)

// 直接相加！系统会自动在底层将它们转换为相同的基本单位进行计算
// 不需要你手动把千米乘以 1000
let totalDistance = distance1 + distance2
print(totalDistance) // 5300.0 m
```

## 3. 极其优雅的单位转换

不再需要去查 Google 的换算公式了。

```swift
let tempCelsius = Measurement(value: 25, unit: UnitTemperature.celsius)

// 一键转换为华氏度
let tempFahrenheit = tempCelsius.converted(to: .fahrenheit)
print(tempFahrenheit.value) // 77.0

// 一键转换为开尔文
let tempKelvin = tempCelsius.converted(to: .kelvin)
print(tempKelvin.value) // 298.15
```

## 4. 与 MeasurementFormatter 结合的本地化输出

这套系统最强大的地方在于本地化展示。
如果你有一个“5公里”的数据，在一个美国的用户的手机上，它应该自动显示为“英里(miles)”；在中文手机上，应该显示为“公里”。\`MeasurementFormatter\` 会自动读取用户的系统地区设置 (Locale) 帮你完成这一切。

```swift
let runDistance = Measurement(value: 5, unit: UnitLength.kilometers)

let formatter = MeasurementFormatter()
// 让格式化器根据用户的系统语言和地区自动选择合适的单位
formatter.unitOptions = .naturalScale 
// 设置数字保留几位小数
formatter.numberFormatter.maximumFractionDigits = 1

// 在中文系统下，可能输出："5 公里"
// 如果你把手机系统切换到美国地区 (en_US)，会自动输出："3.1 mi"
let displayString = formatter.string(from: runDistance)
print(displayString)
```

## 5. 自定义单位

如果 Apple 内置的单位（甚至包含了光照强度 \`UnitIlluminance\`、燃油效率 \`UnitFuelEfficiency\`）还不够你用，你可以极其容易地创建自己的专属单位。

假设你要开发一个游戏，定义一个名为“金币(Coins)”和“钻石(Diamonds)”的资产单位，且 1 钻石 = 100 金币。

```swift
// 继承自基础维度 Dimension
class UnitCurrency: Dimension {
    // 必须定义一个基准单位 (Base Unit)
    static let coins = UnitCurrency(symbol: "金币", converter: UnitConverterLinear(coefficient: 1.0))
    // 其他单位定义为基准单位的倍数
    static let diamonds = UnitCurrency(symbol: "钻石", converter: UnitConverterLinear(coefficient: 100.0))
    
    override class func baseUnit() -> UnitCurrency {
        return coins
    }
}

// 现在你可以进行换算了！
let myWealth = Measurement(value: 5, unit: UnitCurrency.diamonds)
let coinsWealth = myWealth.converted(to: .coins)
print("\(coinsWealth.value) \(coinsWealth.unit.symbol)") // 输出: 500.0 金币
```

## 总结
在处理物理量和科学计算时，**抛弃裸露的 \`Double\` 变量**。全面拥抱 \`Measurement\`，它能为你带来绝对的类型安全、零心智负担的公式换算以及无缝的全球化支持。
