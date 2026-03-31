# Hashable 协议深度解析

在 Swift 中，\`Hashable\` 是一个极其核心的内置协议。如果一个类型遵循了 \`Hashable\`，就意味着它的实例可以被计算出一个整型的哈希值（Hash Value）。

## 1. 为什么需要 Hashable？

\`Hashable\` 的核心作用是为了支持基于哈希表的数据结构，最典型的代表就是：
*   **\`Set\` (集合)**：集合要求内部元素绝对唯一。它通过比较元素的哈希值来瞬间判断一个元素是否已经存在。
*   **\`Dictionary\` (字典)**：字典的键 (Key) 必须遵循 \`Hashable\`，这样字典底层才能通过哈希算法，实现 O(1) 级别的极速查找。

此外，在 SwiftUI 中，\`ForEach\` 的 \`id: \.self\` 语法，以及用于驱动 \`NavigationStack\` 路由的类型，都严格要求必须是 \`Hashable\`。

## 2. Hashable 的自动合成 (Synthesized Implementation)

Swift 编译器非常聪明。对于绝大多数的自定义结构体 (\`struct\`) 和枚举 (\`enum\`)，**只要它内部包含的所有存储属性都已经是 \`Hashable\` 的**（比如 \`String\`, \`Int\`, \`Bool\`, \`UUID\` 等），你只需要在定义时声明遵循 \`Hashable\`，**不需要写任何额外的代码**。

```swift
// 因为 String 和 Int 都是系统自带的 Hashable
// 所以 User 自动获得了完美的 Hashable 能力
struct User: Hashable {
    let name: String
    let age: Int
}

let set: Set<User> = [User(name: "A", age: 10), User(name: "B", age: 20)]
```

## 3. 手动实现 Hashable

如果你遇到以下情况，你需要手动实现 \`Hashable\` 协议：
1. 你的结构体中包含了一个非 \`Hashable\` 的类型（比如一个闭包 \`() -> Void\`）。
2. 你是一个 \`class\` (引用类型，即使属性都是 Hashable，编译器也不会为 class 自动合成)。
3. 你想自定义哈希逻辑（比如只用 \`id\` 属性来区分唯一性，而忽略其他经常改变的属性，以提升性能）。

**注意**：遵循 \`Hashable\` 必须同时遵循 \`Equatable\` (即可以使用 \`==\` 比较)。

```swift
class Product: Hashable {
    let id: UUID
    var title: String
    var price: Double
    
    init(id: UUID = UUID(), title: String, price: Double) {
        self.id = id; self.title = title; self.price = price
    }
    
    // 1. 实现 Equatable 的 == 静态方法
    // 我们认为只要 id 一样，就是同一个商品
    static func == (lhs: Product, rhs: Product) -> Bool {
        return lhs.id == rhs.id
    }
    
    // 2. 实现 Hashable 的 hash(into:) 方法
    // 将我们用来区分唯一性的属性喂给 hasher
    func hash(into hasher: inout Hasher) {
        // 这里的属性必须和上面 `==` 方法中用来比较的属性保持绝对一致！
        hasher.combine(id)
        
        // 错误做法：hasher.combine(title) 
        // 如果这里加了 title，而 `==` 里没加，会导致哈希冲突极其严重的未定义行为！
    }
}
```

## 4. 最佳实践与避坑

*   **哈希一致性铁律**：如果两个对象满足 \`a == b\`，那么它们的哈希值必定相等（\`a.hashValue == b.hashValue\`）。反之，如果 \`a != b\`，它们的哈希值**尽量**不相等（允许极低概率的哈希冲突，哈希表底层会处理，但频繁冲突会严重拖慢性能）。
*   **安全性**：Swift 每次运行 App 时的哈希种子（Hash Seed）是随机生成的。这意味着同一个字符串 \`"Apple"\` 在两次 App 启动时计算出的 \`hashValue\` 是不同的。**绝对不要将对象的 \`hashValue\` 存储到数据库或 UserDefaults 中作为持久化标识**，只应在单次运行周期的内存中使用它。
