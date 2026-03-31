# 格式化核心数据 (数字、货币与百分比)

无论是显示电商商品的价格、股票的涨跌幅、还是文件的兆字节大小，将纯数字正确地展示给用户是基础中的基础。

## 1. 传统利器：NumberFormatter

\`NumberFormatter\` 是极其强大的数字格式化引擎。

### A. 普通数字与千分位
```swift
import Foundation

let number = 1234567.89

let formatter = NumberFormatter()
// .decimal: 最常用的风格，自动添加千分位和小数点
formatter.numberStyle = .decimal 
// 强制保留两位小数
formatter.minimumFractionDigits = 2
formatter.maximumFractionDigits = 2

// 在美国环境输出: "1,234,567.89"
// 在德国环境输出: "1.234.567,89" (注意逗号和点是反的！)
print(formatter.string(from: NSNumber(value: number))!)
```

### B. 货币格式 (Currency)
这是电商 App 必须使用的风格。它会自动加上货币符号，并处理某些不需要小数的货币（比如日元没有“分”的概念，会自动去掉小数）。

```swift
formatter.numberStyle = .currency
formatter.currencyCode = "CNY" // 人民币
// 输出: "¥1,234,567.89" (如果在中国区)
```

### C. 百分比 (Percent)
当你想把 `0.45` 显示为 `45%` 时，千万不要自己乘以 100 再拼上 "%" 号。

```swift
let ratio = 0.456
formatter.numberStyle = .percent
// 输出: "46%" (系统自动进行了四舍五入并乘了 100)
```

## 2. 现代 Swift 替代方案：.formatted() (iOS 15+)

告别繁琐的 `NumberFormatter` 实例，直接调用方法。

```swift
let number = 1234.567

// 1. 普通数字
// "1,234.567"
let str1 = number.formatted()

// 2. 货币
// "$1,234.57"
let str2 = number.formatted(.currency(code: "USD"))

// 3. 百分比
let ratio = 0.85
// "85%"
let str3 = ratio.formatted(.percent)

// 4. 精确控制小数位数！
// "1,234.57" (系统自动四舍五入)
let str4 = number.formatted(
    .number.precision(.fractionLength(2))
)
```

## 3. 文件大小格式化：ByteCountFormatter

如果你做了一个下载器应用，需要把 `1048576` 变成 `"1 MB"`。

```swift
let bytes: Int64 = 1048576 * 15 // 15 MB

let byteFormatter = ByteCountFormatter()
// 允许使用所有的单位 (KB, MB, GB, TB)
byteFormatter.allowedUnits = .useAll
// countStyle 决定了底层的除法是除以 1000 还是 1024
// .file (默认): 苹果自 Mac OS X Snow Leopard 以来，文件大小计算一律除以 1000。所以这里会显示 "15.7 MB"
// .memory: 经典的程序员计算方式，除以 1024。这里会显示 "15 MB"
byteFormatter.countStyle = .file 

print(byteFormatter.string(fromByteCount: bytes))
```

**现代写法 (iOS 15+)：**
```swift
let bytes: Int64 = 15_000_000
// 输出: "15 MB"
let byteString = bytes.formatted(.byteCount(style: .file))
```
