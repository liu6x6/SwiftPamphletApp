# Data：字节流的统治者

在 Swift 和 Foundation 框架中，`Data` 结构体是处理所有底层二进制数据（Bytes）的绝对核心。
无论是从网络下载的图片、从磁盘读取的文件内容，还是使用 JSONEncoder 编码后的模型，最终都会变成一坨 `Data`。

## 1. 什么是 Data？

在概念上，你可以把 `Data` 想象成一个超级巨大的、存放着无数个 `UInt8`（0 到 255 之间的无符号整数）的数组。
`Data` 的底层对其在内存中的存储进行了极其深度的优化，支持写时复制（Copy-on-Write）和连续/非连续内存的高效映射。

## 2. 基础的相互转换

这是最日常的操作：如何把人类可读的内容变成 `Data`，或者反过来。

### String 与 Data 互转
```swift
import Foundation

// 1. String 转 Data (编码)
let myString = "Hello, Swift!"
// 指定使用 UTF-8 编码规则将字符串切碎成字节
if let stringData = myString.data(using: .utf8) {
    print("字符串转换成了 \(stringData.count) 个字节的 Data")
}

// 2. Data 转 String (解码)
// 假设你从网络接收到了一段 Data，你预期它是一段文本
if let decodedString = String(data: stringData, encoding: .utf8) {
    print("解开的数据: \(decodedString)")
}
```

### JSON (Codable) 与 Data 互转
```swift
struct User: Codable { let name: String; let age: Int }
let user = User(name: "Alice", age: 30)

// 模型 -> Data (用于发送给服务器或保存到本地)
let jsonData = try? JSONEncoder().encode(user)

// Data -> 模型 (从服务器接收后解析)
let parsedUser = try? JSONDecoder().decode(User.self, from: jsonData!)
```

### 图片/文件 与 Data 互转 (iOS环境)
```swift
import UIKit

// UIImage 转 Data
let image = UIImage(named: "logo")!
let pngData = image.pngData()
let jpegData = image.jpegData(compressionQuality: 0.8)

// Data 转 UIImage
if let loadedImage = UIImage(data: pngData!) {
    // 渲染图片
}
```

## 3. 直接操作字节 (Bytes)

由于 `Data` 遵循 `Collection` 协议，你可以像操作普通数组一样直接操作它的每一个字节。

```swift
var data = Data([0x00, 0xFF, 0x1A]) // 初始化 3 个字节

// 读取第一个字节
let firstByte: UInt8 = data[0]

// 添加字节
data.append(0x2B)

// 遍历所有的字节，打印出它们的十六进制表示
for byte in data {
    print(String(format: "%02X", byte))
}
```

## 4. 高级：与 C 语言指针的交互 (Unsafe Pointers)

在调用极其底层的 C 语言库（比如 `CommonCrypto` 加解密库或 `SQLite3` 底层 API）时，C 函数通常不认识 Swift 的 `Data` 结构体，它们只接受 `const void *` 或 `uint8_t *` 这样的原始内存指针。

`Data` 提供了非常安全的方法让你临时把底层内存借给 C 函数读取：

```swift
let secretData = "TopSecret".data(using: .utf8)!

// withUnsafeBytes 会临时锁住这段内存，并把一个只读指针 (buffer) 传给闭包
let result = secretData.withUnsafeBytes { bufferPointer -> Int in
    // 将指针转换为 C 语言能看懂的基址指针
    guard let baseAddress = bufferPointer.baseAddress else { return 0 }
    
    // 调用需要指针的虚构 C 函数 (假装有这个函数)
    // return c_language_hash_function(baseAddress, bufferPointer.count)
    return bufferPointer.count
}
```
**安全警告**：绝对不要把 `baseAddress` 指针保存到闭包外部并在以后使用！当闭包结束时，这块内存可能就会被系统回收或移动，使用悬垂指针会导致极其严重的灾难性 Crash！
