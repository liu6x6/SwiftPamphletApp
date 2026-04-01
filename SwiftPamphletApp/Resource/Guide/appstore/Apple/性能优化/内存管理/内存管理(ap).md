# iOS/Swift 内存管理

在 iOS 和 Swift 开发中，内存管理是一个至关重要的主题。高效、正确的内存管理，是构建高性能、稳定可靠应用的基础。Swift 通过**自动引用计数（ARC）**机制，极大地简化了内存管理的复杂性，但作为开发者，仍然需要理解其背后的原理，以避免一些常见的内存问题，如**循环引用**。

## 内存的三个区域

一个应用程序的内存，通常可以分为三个主要区域：

1.  **栈 (Stack)**: 
    *   **特点**: 速度快，由系统自动管理，空间有限。
    *   **存储内容**: 主要用于存储函数调用、局部变量、参数等。当一个函数被调用时，它的“栈帧”（Stack Frame）会被推入栈顶；当函数返回时，其栈帧会被自动弹出和销毁。
    *   **Swift 中的应用**: **值类型**（如 `Struct`, `Enum`, `Tuple`）的实例，通常被分配在栈上。

2.  **堆 (Heap)**: 
    *   **特点**: 空间大，分配和释放的速度相对较慢，需要手动或自动（如 ARC）进行管理。
    *   **存储内容**: 用于存储生命周期更长、或大小在编译时无法确定的对象。
    *   **Swift 中的应用**: **引用类型**（如 `Class`）的实例，总是被分配在堆上。

3.  **静态区/全局区 (Static/Global Area)**:
    *   **存储内容**: 用于存储全局变量、静态变量和常量。这部分内存在程序的整个生命周期中都存在。

## 值类型 vs. 引用类型

理解值类型和引用类型的区别，是理解 Swift 内存管理的关键。

*   **值类型 (Value Types)**: `Struct`, `Enum`, `Tuple`
    *   **行为**: 当被赋值给一个新的变量，或作为参数传递给函数时，它们会被**复制**。每个实例都有自己独立的数据副本。
    *   **内存位置**: 通常在**栈**上分配。

*   **引用类型 (Reference Types)**: `Class`
    *   **行为**: 当被赋值给一个新的变量时，它们不会被复制。相反，新的变量会持有对**同一个**内存实例的**引用**（指针）。多个变量可以指向堆上的同一个对象。
    *   **内存位置**: 总是在**堆**上分配。

## 自动引用计数 (ARC)

ARC 是 Swift 用于管理**引用类型**（类实例）内存的机制。

*   **工作原理**: ARC 会为每个类实例，维护一个“引用计数”（Reference Count）。
    *   当一个新的强引用（strong reference）指向一个实例时，其引用计数 `+1`。
    *   当一个强引用被销毁（例如，持有它的变量被设置为 `nil` 或超出了作用域）时，其引用计数 `-1`。
    *   当一个实例的引用计数变为 `0` 时，ARC 会自动销毁该实例，并释放其占用的内存。

### 循环引用 (Retain Cycles)

这是 ARC 机制下最常见的内存泄漏问题。当两个或多个类实例，互相持有对方的强引用时，就会形成一个“循环”，导致它们的引用计数永远无法变为零，从而永远无法被释放。

```swift
class Person {
    let name: String
    var apartment: Apartment?

    init(name: String) { self.name = name }
    deinit { print("\(name) 被释放了") }
}

class Apartment {
    let unit: String
    // 这里是问题的关键：对 Person 的强引用
    var tenant: Person?

    init(unit: String) { self.unit = unit }
    deinit { print("公寓 \(unit) 被释放了") }
}

var john: Person? = Person(name: "John Appleseed")
var unit4A: Apartment? = Apartment(unit: "4A")

// 互相强引用，形成循环
john?.apartment = unit4A
unit4A?.tenant = john

// 将外部引用置为 nil
john = nil
unit4A = nil

// 此时，Person 和 Apartment 的 deinit 方法都不会被调用，因为它们的引用计数都为 1，造成了内存泄漏。
```

### 解决循环引用：`weak` 和 `unowned`

为了打破循环引用，Swift 提供了两种“弱”引用类型：

*   **`weak` (弱引用)**:
    *   不会增加实例的引用计数。
    *   它引用的实例，可以被 ARC 在其他地方释放掉。因此，`weak` 引用必须被声明为**可选类型**（`Optional`），当其引用的实例被销毁后，它会自动变为 `nil`。
    *   **适用场景**: 当两个实例的生命周期没有必然的关联，一方可以先于另一方被销毁时，使用 `weak`。

*   **`unowned` (无主引用)**:
    *   也不会增加实例的引用计数。
    *   但它**假定**其引用的实例，在自己的整个生命周期中，都**不会**被销毁。因此，`unowned` 引用总是非可选的。
    *   如果你试图访问一个已经被销毁的 `unowned` 引用，程序会**崩溃**。
    *   **适用场景**: 当两个实例的生命周期是相互绑定的，一个实例的存在，必然意味着另一个实例也存在时，使用 `unowned`。

**修复循环引用的示例**:

在上面的例子中，我们可以将 `Apartment` 中的 `tenant` 属性，声明为 `weak`。

```swift
class Apartment {
    let unit: String
    weak var tenant: Person?
    // ...
}
```

这样，`Apartment` 对 `Person` 的引用，就不会增加其引用计数，循环被打破。当 `john` 和 `unit4A` 被设置为 `nil` 时，两个实例都可以被正常地释放。

### 闭包中的循环引用

闭包是引用类型，如果一个类的实例，持有一个闭包，而这个闭包又在其内部，捕获了对该实例的强引用（`self`），也会形成循环引用。

**解决方法**: 使用**捕获列表（Capture List）**，在闭包的定义中，将对 `self` 的捕获，声明为 `[weak self]` 或 `[unowned self]`。

```swift
class HTMLElement {
    let name: String
    let text: String?

    lazy var asHTML: () -> String = {
        // 使用 [weak self] 来打破循环引用
        [weak self] in
        guard let self = self else { return "" }
        if let text = self.text {
            return "<\(self.name)>\(text)</\(self.name)>"
        } else {
            return "<\(self.name) />"
        }
    }

    // ...
}
```

## 总结

*   **值类型 vs. 引用类型**: 理解它们的区别，是进行内存管理的基础。
*   **ARC**: 自动管理引用类型的内存，但需要注意**循环引用**的问题。
*   **打破循环**: 使用 `weak` 或 `unowned` 来打破类实例之间的循环引用；在闭包中，使用 `[weak self]` 或 `[unowned self]` 的捕获列表。
*   **选择 `weak` 还是 `unowned`**: 当不确定时，优先使用更安全的 `weak`。