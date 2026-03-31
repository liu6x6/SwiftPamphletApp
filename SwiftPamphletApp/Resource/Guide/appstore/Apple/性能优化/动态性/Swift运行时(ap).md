# Swift 的运行时特性 (Swift Runtime)

很多从 Objective-C 转过来的老 iOS 开发者会觉得：“Swift 是一门完全静态的语言，失去了 OC 引以为傲的 Runtime 魔力”。
这句话只对了一半。Swift 确实更加强调**编译期安全**和**静态派发**，以换取极致的性能。但为了保持强大的灵活性（如 SwiftUI 的反射魔法和与 OC 的互操作），Swift 同样拥有一套自己的运行时（Runtime）机制。

## 1. Swift 的三种方法派发机制

理解 Swift 运行时的第一步，是理解它在调用一个函数时，到底是怎么寻找代码地址的。

1.  **静态/直接派发 (Static/Direct Dispatch)**
    *   **原理**：在编译期，编译器就已经知道这个函数所在的绝对内存地址。执行时直接跳转，性能极高（且能被内联优化 Inlined）。
    *   **触发条件**：结构体 (Struct) / 枚举 (Enum) 的方法、被 \`final\` 标记的类的方法、在 extension 中定义的方法。
2.  **函数表派发 (Table Dispatch)**
    *   **原理**：相当于 C++ 的虚函数表 (vtable) 或 Swift 中的 Witness Table。类在内存中维护一个表，记录其所有重写方法的地址。调用时需要在运行时查表再跳转，比直接派发慢一点。
    *   **触发条件**：普通类 (Class) 中定义的普通方法，以及协议 (Protocol) 的要求方法。
3.  **消息派发 (Message Dispatch)**
    *   **原理**：这就是大名鼎鼎的 Objective-C Runtime (objc_msgSend)。极其动态，可以在运行时利用 \`isa\` 指针顺着继承树往上找，甚至可以方法交换（Method Swizzling）。
    *   **触发条件**：被 \`@objc dynamic\` 标记的方法。

## 2. Swift 专属的运行时反射：Mirror

虽然 Swift 不能像 OC 那样在运行时动态地给类增加一个属性，但它提供了强大的**只读**反射能力：\`Mirror\`。

你可以使用 \`Mirror\` 在运行时剖析任何一个未知的对象（不管是 \`class\` 还是 \`struct\`），遍历它的所有属性名和值。这也是很多 Swift 底层 JSON 序列化库或深拷贝工具的原理。

```swift
struct User {
    let name: String
    let age: Int
}

let user = User(name: "Alice", age: 30)
let mirror = Mirror(reflecting: user)

// 在运行时动态遍历这个结构体里到底装了什么
for child in mirror.children {
    if let propertyName = child.label {
        print("属性名: \(propertyName), 值: \(child.value)")
    }
}
// 输出:
// 属性名: name, 值: Alice
// 属性名: age, 值: 30
```

## 3. Metadata：Swift 底层的类型元数据

当你使用 \`Mirror\`，或者使用 \`is\` (类型检查), \`as?\` (类型转换) 时，系统是怎么知道某个内存块到底是什么类型的呢？

这是因为 Swift 编译器在编译时，会在二进制文件里为每一个类型（甚至包括泛型类型的特定实例如 \`Array<Int>\`）注入一段名为 **Metadata** 的数据结构。

在高级性能优化和逆向工程中，开发者会通过解析 Mach-O 文件的 \`__swift5_types\` 等 Section，来读取这些 Metadata，从而在运行时拿到 Swift 类的布局结构、字段偏移量（Field Offsets），以此实现某些变态的黑科技（如 Swift 原生内存级的 AOP 拦截）。

## 4. 与 OC 运行时的缝合：@objc

当你必须使用旧时代基于 KVO 或消息转发的黑魔法时，你可以通过在类前加 \`@objcMembers\` 或者在方法前加 \`@objc dynamic\`，强行逼迫 Swift 编译器为这个方法生成 OC 的消息派发存根（Thunk）。

**性能代价**：只要你加上了 \`@objc dynamic\`，这个方法的调用就丧失了 Swift 的极速性能，退化回了慢速的 \`objc_msgSend\`。
